// Created with love by Igor Klyuzhev in 2023

import Accelerate
import AVFoundation
import Foundation

struct WaveformAnalysis {
  let amplitudes: [Float]
  let fft: [TempiFFT]?
}

/// Calculates the waveform of the initialized asset URL.
class WaveformAnalyzer {
  private let assetReader: AVAssetReader
  private let audioAssetTrack: AVAssetTrack

  init?(audioAssetURL: URL) {
    let audioAsset = AVURLAsset(url: audioAssetURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])

    guard
      let assetReader = try? AVAssetReader(asset: audioAsset),
      let assetTrack = audioAsset.tracks(withMediaType: .audio).first
    else {
      Logger.log("ERROR loading asset / audio track")
      return nil
    }

    self.assetReader = assetReader
    audioAssetTrack = assetTrack
  }

  init?(asset: AVAsset) {
    let audioAsset = asset

    guard
      let assetReader = try? AVAssetReader(asset: audioAsset),
      let assetTrack = audioAsset.tracks(withMediaType: .audio).first
    else {
      Logger.log("ERROR loading asset / audio track")
      return nil
    }

    self.assetReader = assetReader
    audioAssetTrack = assetTrack
  }

  /// Returns the calculated waveform of the initialized asset URL.
  func samples(
    count: Int,
    qos: DispatchQoS.QoSClass = .userInitiated,
    completionHandler: @escaping (_ amplitudes: [Float]?) -> Void
  ) {
    if count <= 0 {
      completionHandler([])
      return
    }
    waveformSamples(count: count, qos: qos, fftBands: nil) { analysis in
      completionHandler(analysis?.amplitudes)
    }
  }
}

// MARK: - Private

extension WaveformAnalyzer {
  private var silenceDbThreshold: Float { -50.0 } // everything below -50 dB will be clipped

  fileprivate func waveformSamples(
    count requiredNumberOfSamples: Int,
    qos: DispatchQoS.QoSClass,
    fftBands: Int?,
    completionHandler: @escaping (_ analysis: WaveformAnalysis?) -> Void
  ) {
    let trackOutput = AVAssetReaderTrackOutput(track: audioAssetTrack, outputSettings: outputSettings())
    assetReader.add(trackOutput)

    assetReader.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
      var error: NSError?
      let status = self.assetReader.asset.statusOfValue(forKey: "duration", error: &error)
      switch status {
      case .loaded:
        let totalSamples = self.totalSamplesOfTrack()
        DispatchQueue.global(qos: qos).async {
          let analysis = self.extract(totalSamples: totalSamples, downsampledTo: requiredNumberOfSamples, fftBands: fftBands)

          switch self.assetReader.status {
          case .completed:
            completionHandler(analysis)
          default:
            Logger.log("ERROR: reading waveform audio data has failed \(self.assetReader.status)")
            completionHandler(nil)
          }
        }

      case .failed, .cancelled, .loading, .unknown:
        Logger.log("failed to load due to: \(error?.localizedDescription ?? "unknown error")")
        completionHandler(nil)
      @unknown default:
        Logger.log("failed to load due to: \(error?.localizedDescription ?? "unknown error")")
        completionHandler(nil)
      }
    }
  }

  fileprivate func extract(
    totalSamples: Int,
    downsampledTo targetSampleCount: Int,
    fftBands: Int?
  ) -> WaveformAnalysis {
    var outputSamples = [Float]()
    var outputFFT = fftBands == nil ? nil : [TempiFFT]()
    var sampleBuffer = Data()
    var sampleBufferFFT = Data()

    // read upfront to avoid frequent re-calculation (and memory bloat from C-bridging)
    let samplesPerPixel = max(1, totalSamples / targetSampleCount)
    let samplesPerFFT = 4096 // ~100ms at 44.1kHz, rounded to closest pow(2) for FFT

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
      CMBlockBufferGetDataPointer(
        blockBuffer,
        atOffset: 0,
        lengthAtOffsetOut: &readBufferLength,
        totalLengthOut: nil,
        dataPointerOut: &readBufferPointer
      )
      sampleBuffer.append(UnsafeBufferPointer(start: readBufferPointer, count: readBufferLength))
      sampleBufferFFT.append(UnsafeBufferPointer(start: readBufferPointer, count: readBufferLength))
      CMSampleBufferInvalidate(nextSampleBuffer)

      let processedSamples = process(sampleBuffer, from: assetReader, downsampleTo: samplesPerPixel)
      outputSamples += processedSamples

      if processedSamples.count > 0 {
        // vDSP_desamp uses strides of samplesPerPixel; remove only the processed ones
        sampleBuffer.removeFirst(processedSamples.count * samplesPerPixel * MemoryLayout<Int16>.size)
      }

      if let fftBands = fftBands, sampleBufferFFT.count / MemoryLayout<Int16>.size >= samplesPerFFT {
        let processedFFTs = process(sampleBufferFFT, samplesPerFFT: samplesPerFFT, fftBands: fftBands)
        sampleBufferFFT.removeFirst(processedFFTs.count * samplesPerFFT * MemoryLayout<Int16>.size)
        outputFFT? += processedFFTs
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

    return WaveformAnalysis(amplitudes: normalize(outputSamples), fft: outputFFT)
  }

  private func process(
    _ sampleBuffer: Data,
    from _: AVAssetReader,
    downsampleTo samplesPerPixel: Int
  ) -> [Float] {
    var downSampledData = [Float]()
    let sampleLength = sampleBuffer.count / MemoryLayout<Int16>.size
    sampleBuffer.withUnsafeBytes { (samplesRawPointer: UnsafeRawBufferPointer) in
      let unsafeSamplesBufferPointer = samplesRawPointer.bindMemory(to: Int16.self)
      let unsafeSamplesPointer = unsafeSamplesBufferPointer.baseAddress!
      var loudestClipValue: Float = 0.0
      var quietestClipValue = silenceDbThreshold
      var zeroDbEquivalent = Float(Int16.max) // maximum amplitude storable in Int16 = 0 Db (loudest)
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

  private func process(
    _ sampleBuffer: Data,
    samplesPerFFT: Int,
    fftBands: Int
  ) -> [TempiFFT] {
    var ffts = [TempiFFT]()
    let sampleLength = sampleBuffer.count / MemoryLayout<Int16>.size
    sampleBuffer.withUnsafeBytes { (samplesRawPointer: UnsafeRawBufferPointer) in
      let unsafeSamplesBufferPointer = samplesRawPointer.bindMemory(to: Int16.self)
      let unsafeSamplesPointer = unsafeSamplesBufferPointer.baseAddress!
      let samplesToProcess = vDSP_Length(sampleLength)

      var processingBuffer = [Float](repeating: 0.0, count: Int(samplesToProcess))
      vDSP_vflt16(unsafeSamplesPointer, 1, &processingBuffer, 1, samplesToProcess) // convert 16bit int to float

      repeat {
        let fftBuffer = processingBuffer[0 ..< samplesPerFFT]
        let fft = TempiFFT(withSize: samplesPerFFT, sampleRate: 44100.0)
        fft.windowType = TempiFFTWindowType.hanning
        fft.fftForward(Array(fftBuffer))
        fft.calculateLinearBands(minFrequency: 0, maxFrequency: fft.nyquistFrequency, numberOfBands: fftBands)
        ffts.append(fft)

        processingBuffer.removeFirst(samplesPerFFT)
      } while processingBuffer.count >= samplesPerFFT
    }
    return ffts
  }

  fileprivate func normalize(_ samples: [Float]) -> [Float] {
    samples.map { $0 / silenceDbThreshold }
  }

  // swiftlint:disable force_cast
  private func totalSamplesOfTrack() -> Int {
    var totalSamples = 0

    autoreleasepool {
      let descriptions = audioAssetTrack.formatDescriptions as! [CMFormatDescription]
      descriptions.forEach { formatDescription in
        guard let basicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription) else { return }
        let channelCount = Int(basicDescription.pointee.mChannelsPerFrame)
        let sampleRate = basicDescription.pointee.mSampleRate
        let duration = Double(assetReader.asset.duration.value)
        let timescale = Double(assetReader.asset.duration.timescale)
        let totalDuration = duration / timescale
        totalSamples = Int(sampleRate * totalDuration) * channelCount
      }
    }

    return totalSamples
  }
  // swiftlint:enable force_cast
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
}

//
//  TempiFFT.swift
//  TempiBeatDetection
//
//  Created by John Scalo on 1/12/16.
//  Copyright © 2016 John Scalo. See accompanying License.txt for terms.

/*  A functional FFT built atop Apple's Accelerate framework for optimum performance on any device. In addition to simply performing the FFT and providing access to the resulting data, TempiFFT provides the ability to map the FFT spectrum data into logical bands, either linear or logarithmic, for further analysis.

 E.g.

 let fft = TempiFFT(withSize: frameSize, sampleRate: 44100)

 // Setting a window type reduces errors
 fft.windowType = TempiFFTWindowType.hanning

 // Perform the FFT
 fft.fftForward(samples)

 // Map FFT data to logical bands. This gives 4 bands per octave across 7 octaves = 28 bands.
 fft.calculateLogarithmicBands(minFrequency: 100, maxFrequency: 11025, bandsPerOctave: 4)

 // Process some data
 for i in 0..<fft.numberOfBands {
 let f = fft.frequencyAtBand(i)
 let m = fft.magnitudeAtBand(i)
 }

 Note that TempiFFT expects a mono signal (i.e. numChannels == 1) which is ideal for performance.
 */

import Accelerate
import Foundation

@objc enum TempiFFTWindowType: NSInteger {
  case none
  case hanning
  case hamming
}

@objc class TempiFFT: NSObject {
  /// The length of the sample buffer we'll be analyzing.
  private(set) var size: Int

  /// The sample rate provided at init time.
  private(set) var sampleRate: Float

  /// The Nyquist frequency is ```sampleRate``` / 2
  var nyquistFrequency: Float {
    sampleRate / 2.0
  }

  // After performing the FFT, contains size/2 magnitudes, one for each frequency band.
  private var magnitudes: [Float] = []

  /// After calling calculateLinearBands() or calculateLogarithmicBands(), contains a magnitude for each band.
  private(set) var bandMagnitudes: [Float]!

  /// After calling calculateLinearBands() or calculateLogarithmicBands(), contains the average frequency for each band
  private(set) var bandFrequencies: [Float]!

  /// The average bandwidth throughout the spectrum (nyquist / magnitudes.count)
  var bandwidth: Float {
    nyquistFrequency / Float(magnitudes.count)
  }

  /// The number of calculated bands (must call calculateLinearBands() or calculateLogarithmicBands() first).
  private(set) var numberOfBands: Int = 0

  /// The minimum and maximum frequencies in the calculated band spectrum (must call calculateLinearBands() or calculateLogarithmicBands() first).
  private(set) var bandMinFreq, bandMaxFreq: Float!

  /// Supplying a window type (hanning or hamming) smooths the edges of the incoming waveform and reduces output errors from the FFT function (aka "spectral
  /// leakage" - ewww).
  var windowType = TempiFFTWindowType.none

  private var halfSize: Int
  private var log2Size: Int
  private var window: [Float] = []
  private var fftSetup: FFTSetup
  private var hasPerformedFFT: Bool = false
  private var complexBuffer: DSPSplitComplex!

  /// Instantiate the FFT.
  /// - Parameter withSize: The length of the sample buffer we'll be analyzing. Must be a power of 2. The resulting ```magnitudes``` are of length
  /// ```inSize/2```.
  /// - Parameter sampleRate: Sampling rate of the provided audio data.
  init(withSize inSize: Int, sampleRate inSampleRate: Float) {
    let sizeFloat = Float(inSize)

    sampleRate = inSampleRate

    // Check if the size is a power of two
    let lg2 = logbf(sizeFloat)
    assert(remainderf(sizeFloat, powf(2.0, lg2)) == 0, "size must be a power of 2")

    size = inSize
    halfSize = inSize / 2

    // create fft setup
    log2Size = Int(log2f(sizeFloat))
    fftSetup = vDSP_create_fftsetup(UInt(log2Size), FFTRadix(FFT_RADIX2))!

    // Init the complexBuffer
    let realp = UnsafeMutablePointer<Float>.allocate(capacity: halfSize)
    realp.initialize(repeating: 0, count: halfSize)
    let imagp = UnsafeMutablePointer<Float>.allocate(capacity: halfSize)
    imagp.initialize(repeating: 0, count: halfSize)
    complexBuffer = DSPSplitComplex(realp: realp, imagp: imagp)
  }

  deinit {
    // destroy the fft setup object
    vDSP_destroy_fftsetup(fftSetup)
  }

  /// Perform a forward FFT on the provided single-channel audio data. When complete, the instance can be queried for information about the analysis or the
  /// magnitudes can be accessed directly.
  /// - Parameter inMonoBuffer: Audio data in mono format
  func fftForward(_ inMonoBuffer: [Float]) {
    var analysisBuffer = inMonoBuffer

    // If we have a window, apply it now. Since 99.9% of the time the window array will be exactly the same, an optimization would be to create it once and
    // cache it, possibly caching it by size.
    if windowType != .none {
      if window.isEmpty {
        window = [Float](repeating: 0.0, count: size)

        switch windowType {
        case .hamming:
          vDSP_hamm_window(&window, UInt(size), 0)
        case .hanning:
          vDSP_hann_window(&window, UInt(size), Int32(vDSP_HANN_NORM))
        default:
          break
        }
      }

      // Apply the window
      vDSP_vmul(inMonoBuffer, 1, window, 1, &analysisBuffer, 1, UInt(inMonoBuffer.count))
    }

    // vDSP_ctoz converts an interleaved vector into a complex split vector. i.e. moves the even indexed samples into frame.buffer.realp and the odd indexed
    // samples into frame.buffer.imagp.
    //        var imaginary = [Float](repeating: 0.0, count: analysisBuffer.count)
    //        var splitComplex = DSPSplitComplex(realp: &analysisBuffer, imagp: &imaginary)
    //        let length = vDSP_Length(self.log2Size)
    //        vDSP_fft_zip(self.fftSetup, &splitComplex, 1, length, FFTDirection(FFT_FORWARD))

    // Doing the job of vDSP_ctoz 😒. (See below.)

    var reals = [Float]()
    var imags = [Float]()
    for (idx, element) in analysisBuffer.enumerated() {
      if idx % 2 == 0 {
        reals.append(element)
      } else {
        imags.append(element)
      }
    }
    let realsPointer = UnsafeMutablePointer<Float>.allocate(capacity: reals.count)
    realsPointer.initialize(from: reals, count: reals.count)
    let imagsPointer = UnsafeMutablePointer<Float>.allocate(capacity: imags.count)
    imagsPointer.initialize(from: imags, count: imags.count)
    complexBuffer = DSPSplitComplex(realp: realsPointer, imagp: imagsPointer)

    // This compiles without error but doesn't actually work. It results in garbage values being stored to the complexBuffer's real and imag parts. Why? The
    // above workaround is undoubtedly tons slower so it would be good to get vDSP_ctoz working again.
    //        withUnsafePointer(to: &analysisBuffer, { $0.withMemoryRebound(to: DSPComplex.self, capacity: analysisBuffer.count) {
    //            vDSP_ctoz($0, 2, &(self.complexBuffer!), 1, UInt(self.halfSize))
    //            }
    //        })
    // Verifying garbage values.
    //        let rFloats = [Float](UnsafeBufferPointer(start: self.complexBuffer.realp, count: self.halfSize))
    //        let iFloats = [Float](UnsafeBufferPointer(start: self.complexBuffer.imagp, count: self.halfSize))

    // Perform a forward FFT
    vDSP_fft_zrip(fftSetup, &(complexBuffer!), 1, UInt(log2Size), Int32(FFT_FORWARD))

    // Store and square (for better visualization & conversion to db) the magnitudes
    magnitudes = [Float](repeating: 0.0, count: halfSize)
    vDSP_zvmags(&(complexBuffer!), 1, &magnitudes, 1, UInt(halfSize))

    hasPerformedFFT = true
  }

  /// Applies logical banding on top of the spectrum data. The bands are spaced linearly throughout the spectrum.
  func calculateLinearBands(minFrequency: Float, maxFrequency: Float, numberOfBands: Int) {
    assert(hasPerformedFFT, "*** Perform the FFT first.")

    let actualMaxFrequency = min(nyquistFrequency, maxFrequency)

    self.numberOfBands = numberOfBands
    bandMagnitudes = [Float](repeating: 0.0, count: numberOfBands)
    bandFrequencies = [Float](repeating: 0.0, count: numberOfBands)

    let magLowerRange = magIndexForFreq(minFrequency)
    let magUpperRange = magIndexForFreq(actualMaxFrequency)
    let ratio = Float(magUpperRange - magLowerRange) / Float(numberOfBands)

    for i in 0 ..< numberOfBands {
      let magsStartIdx = Int(floorf(Float(i) * ratio)) + magLowerRange
      let magsEndIdx = Int(floorf(Float(i + 1) * ratio)) + magLowerRange
      var magsAvg: Float
      if magsEndIdx == magsStartIdx {
        // Can happen when numberOfBands < # of magnitudes. No need to average anything.
        magsAvg = magnitudes[magsStartIdx]
      } else {
        magsAvg = fastAverage(magnitudes, magsStartIdx, magsEndIdx)
      }
      bandMagnitudes[i] = magsAvg
      bandFrequencies[i] = averageFrequencyInRange(magsStartIdx, magsEndIdx)
    }

    bandMinFreq = bandFrequencies[0]
    bandMaxFreq = bandFrequencies.last
  }

  private func magIndexForFreq(_ freq: Float) -> Int {
    Int(Float(magnitudes.count) * freq / nyquistFrequency)
  }

  // On arrays of 1024 elements, this is ~35x faster than an iterational algorithm. Thanks Accelerate.framework!
  @inline(__always)
  private func fastAverage(_ array: [Float], _ startIdx: Int, _ stopIdx: Int) -> Float {
    var mean: Float = 0
    let ptr = UnsafeMutablePointer<Float>.allocate(capacity: array.count)
    ptr.initialize(from: array, count: array.count)
    vDSP_meanv(ptr + startIdx, 1, &mean, UInt(stopIdx - startIdx))

    return mean
  }

  @inline(__always)
  private func averageFrequencyInRange(_ startIndex: Int, _ endIndex: Int) -> Float {
    (bandwidth * Float(startIndex) + bandwidth * Float(endIndex)) / 2
  }

  /// Get the magnitude for the specified frequency band.
  /// - Parameter inBand: The frequency band you want a magnitude for.
  func magnitudeAtBand(_ inBand: Int) -> Float {
    assert(hasPerformedFFT, "*** Perform the FFT first.")
    assert(bandMagnitudes != nil, "*** Call calculateLinearBands() or calculateLogarithmicBands() first")

    return bandMagnitudes[inBand]
  }

  /// Get the magnitude of the requested frequency in the spectrum.
  /// - Parameter inFrequency: The requested frequency. Must be less than the Nyquist frequency (```sampleRate/2```).
  /// - Returns: A magnitude.
  func magnitudeAtFrequency(_ inFrequency: Float) -> Float {
    assert(hasPerformedFFT, "*** Perform the FFT first.")
    let index = Int(floorf(inFrequency / bandwidth))
    return magnitudes[index]
  }

  /// Get the middle frequency of the Nth band.
  /// - Parameter inBand: An index where 0 <= inBand < size / 2.
  /// - Returns: The middle frequency of the provided band.
  func frequencyAtBand(_ inBand: Int) -> Float {
    assert(hasPerformedFFT, "*** Perform the FFT first.")
    assert(bandMagnitudes != nil, "*** Call calculateLinearBands() or calculateLogarithmicBands() first")
    return bandFrequencies[inBand]
  }

  /// A convenience function that converts a linear magnitude (like those stored in ```magnitudes```) to db (which is log 10).
  class func toDB(_ inMagnitude: Float) -> Float {
    // ceil to 128db in order to avoid log10'ing 0
    let magnitude = max(inMagnitude, 0.000000000001)
    return 10 * log10f(magnitude)
  }
}
