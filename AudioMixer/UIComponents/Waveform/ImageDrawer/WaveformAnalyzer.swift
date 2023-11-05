// Created with love by Igor Klyuzhev in 2023

import Accelerate
import AVFoundation
import Foundation

struct WaveformAnalysis {
  let amplitudes: [Float]
}

public struct WaveformAnalyzer: Sendable {
  public enum AnalyzeError: Error { case generic, userError, emptyTracks, readerError(AVAssetReader.Status) }

  public var noiseFloorDecibelCutoff: Float = -50.0

  public init() {}

  public func samples(fromAudioAt audioAssetURL: URL, count: Int, qos: DispatchQoS.QoSClass = .userInitiated) async throws -> [Float] {
    try await Task(priority: taskPriority(qos: qos)) {
      let audioAsset = AVURLAsset(url: audioAssetURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
      let assetReader = try AVAssetReader(asset: audioAsset)

      guard let assetTrack = try await audioAsset.loadTracks(withMediaType: .audio).first else {
        throw AnalyzeError.emptyTracks
      }

      return try await waveformSamples(track: assetTrack, reader: assetReader, count: count, fftBands: nil).amplitudes
    }.value
  }
}

// MARK: - Private

extension WaveformAnalyzer {
  fileprivate func waveformSamples(
    track audioAssetTrack: AVAssetTrack,
    reader assetReader: AVAssetReader,
    count requiredNumberOfSamples: Int,
    fftBands: Int?
  ) async throws -> WaveformAnalysis {
    guard requiredNumberOfSamples > 0 else {
      throw AnalyzeError.userError
    }

    let trackOutput = AVAssetReaderTrackOutput(track: audioAssetTrack, outputSettings: outputSettings())
    assetReader.add(trackOutput)

    let totalSamples = try await totalSamples(of: audioAssetTrack)
    let analysis = extract(totalSamples, downsampledTo: requiredNumberOfSamples, from: assetReader, fftBands: fftBands)

    switch assetReader.status {
    case .completed:
      return analysis
    default:
      print("ERROR: reading waveform audio data has failed \(assetReader.status)")
      throw AnalyzeError.readerError(assetReader.status)
    }
  }

  fileprivate func extract(
    _ totalSamples: Int,
    downsampledTo targetSampleCount: Int,
    from assetReader: AVAssetReader,
    fftBands: Int?
  ) -> WaveformAnalysis {
    var outputSamples = [Float]()
    var sampleBuffer = Data()
    var sampleBufferFFT = Data()
    let samplesPerPixel = max(1, totalSamples / targetSampleCount)

    assetReader.startReading()
    while assetReader.status == .reading {
      let trackOutput = assetReader.outputs.first!

      guard let nextSampleBuffer = trackOutput.copyNextSampleBuffer(),
            let blockBuffer = CMSampleBufferGetDataBuffer(nextSampleBuffer)
      else {
        break
      }

      var readBufferLength = 0
      var readBufferPointer: UnsafeMutablePointer<Int8>?
      CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: &readBufferLength, totalLengthOut: nil, dataPointerOut: &readBufferPointer)
      sampleBuffer.append(UnsafeBufferPointer(start: readBufferPointer, count: readBufferLength))
      if fftBands != nil {
        // don't append data to this buffer unless we're going to use it.
        sampleBufferFFT.append(UnsafeBufferPointer(start: readBufferPointer, count: readBufferLength))
      }
      CMSampleBufferInvalidate(nextSampleBuffer)

      let processedSamples = process(sampleBuffer, from: assetReader, downsampleTo: samplesPerPixel)
      outputSamples += processedSamples

      if processedSamples.count > 0 {
        // vDSP_desamp uses strides of samplesPerPixel; remove only the processed ones
        sampleBuffer.removeFirst(processedSamples.count * samplesPerPixel * MemoryLayout<Int16>.size)

        // this takes care of a memory leak where Memory continues to increase even though it should clear after calling .removeFirst(…) above.
        sampleBuffer = Data(sampleBuffer)
      }
    }

    // if we don't have enough pixels yet,
    // process leftover samples with padding (to reach multiple of samplesPerPixel for vDSP_desamp)
    if outputSamples.count < targetSampleCount {
      let missingSampleCount = (targetSampleCount - outputSamples.count) * samplesPerPixel
      let backfillPaddingSampleCount = missingSampleCount - (sampleBuffer.count / MemoryLayout<Int16>.size)
      let backfillPaddingSampleCount16 = backfillPaddingSampleCount * MemoryLayout<Int16>.size
      let backfillPaddingSamples = [UInt8](repeating: 0, count: backfillPaddingSampleCount16)
      sampleBuffer.append(backfillPaddingSamples, count: backfillPaddingSampleCount16)
      let processedSamples = process(sampleBuffer, from: assetReader, downsampleTo: samplesPerPixel)
      outputSamples += processedSamples
    }

    let targetSamples = Array(outputSamples[0 ..< targetSampleCount])
    return WaveformAnalysis(amplitudes: normalize(targetSamples))
  }

  private func process(_ sampleBuffer: Data, from assetReader: AVAssetReader, downsampleTo samplesPerPixel: Int) -> [Float] {
    var downSampledData = [Float]()
    let sampleLength = sampleBuffer.count / MemoryLayout<Int16>.size

    // guard for crash in very long audio files
    guard sampleLength / samplesPerPixel > 0 else { return downSampledData }

    sampleBuffer.withUnsafeBytes { (samplesRawPointer: UnsafeRawBufferPointer) in
      let unsafeSamplesBufferPointer = samplesRawPointer.bindMemory(to: Int16.self)
      let unsafeSamplesPointer = unsafeSamplesBufferPointer.baseAddress!
      var loudestClipValue: Float = 0.0
      var quietestClipValue = noiseFloorDecibelCutoff
      var zeroDbEquivalent: Float = Float(Int16.max) // maximum amplitude storable in Int16 = 0 Db (loudest)
      let samplesToProcess = vDSP_Length(sampleLength)

      var processingBuffer = [Float](repeating: 0.0, count: Int(samplesToProcess))
      vDSP_vflt16(unsafeSamplesPointer, 1, &processingBuffer, 1, samplesToProcess) // convert 16bit int to float (
      vDSP_vabs(processingBuffer, 1, &processingBuffer, 1, samplesToProcess) // absolute amplitude value
      vDSP_vdbcon(processingBuffer, 1, &zeroDbEquivalent, &processingBuffer, 1, samplesToProcess, 1) // convert to DB
      vDSP_vclip(processingBuffer, 1, &quietestClipValue, &loudestClipValue, &processingBuffer, 1, samplesToProcess)

      let filter = [Float](repeating: 1.0 / Float(samplesPerPixel), count: samplesPerPixel)
      let downSampledLength = sampleLength / samplesPerPixel
      downSampledData = [Float](repeating: 0.0, count: downSampledLength)

      vDSP_desamp(processingBuffer,
                  vDSP_Stride(samplesPerPixel),
                  filter,
                  &downSampledData,
                  vDSP_Length(downSampledLength),
                  vDSP_Length(samplesPerPixel))
    }

    return downSampledData
  }

  fileprivate func normalize(_ samples: [Float]) -> [Float] {
    samples.map { $0 / noiseFloorDecibelCutoff }
  }

  private func totalSamples(of audioAssetTrack: AVAssetTrack) async throws -> Int {
    var totalSamples = 0
    let (descriptions, timeRange) = try await audioAssetTrack.load(.formatDescriptions, .timeRange)

    descriptions.forEach { formatDescription in
      guard let basicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription) else { return }
      let channelCount = Int(basicDescription.pointee.mChannelsPerFrame)
      let sampleRate = basicDescription.pointee.mSampleRate
      totalSamples = Int(sampleRate * timeRange.duration.seconds) * channelCount
    }
    return totalSamples
  }
}

// MARK: - Configuration

extension WaveformAnalyzer {
  fileprivate func outputSettings() -> [String: Any] {
    [
      AVFormatIDKey: kAudioFormatLinearPCM,
      AVLinearPCMBitDepthKey: 16,
      AVLinearPCMIsBigEndianKey: false,
      AVLinearPCMIsFloatKey: false,
      AVLinearPCMIsNonInterleaved: false,
    ]
  }

  fileprivate func taskPriority(qos: DispatchQoS.QoSClass) -> TaskPriority {
    switch qos {
    case .background: return .background
    case .utility: return .utility
    case .default: return .medium
    case .userInitiated: return .userInitiated
    case .userInteractive: return .high
    case .unspecified: return .medium
    @unknown default: return .medium
    }
  }
}
