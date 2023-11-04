import Accelerate
import AVFoundation

extension AVAudioPCMBuffer {
  public convenience init?(url: URL) throws {
    guard let file = try? AVAudioFile(forReading: url) else { return nil }
    try self.init(file: file)
  }

  public convenience init?(file: AVAudioFile) throws {
    file.framePosition = 0

    self.init(pcmFormat: file.processingFormat,
              frameCapacity: AVAudioFrameCount(file.length))

    try file.read(into: self)
  }
}

extension AVAudioPCMBuffer {
  public struct Peak {
    public init() {}
    internal static let min: Float = -10000.0
    public var time: Double = 0
    public var framePosition: Int = 0
    public var amplitude: Float = 1
  }

  public func peak() -> Peak? {
    guard frameLength > 0 else { return nil }
    guard let floatData = floatChannelData else { return nil }

    var value = Peak()
    var position = 0
    var peakValue: Float = Peak.min
    let chunkLength = 512
    let channelCount = Int(format.channelCount)

    while true {
      if position + chunkLength >= frameLength {
        break
      }
      for channel in 0 ..< channelCount {
        var block = Array(repeating: Float(0), count: chunkLength)

        for i in 0 ..< block.count {
          if i + position >= frameLength {
            break
          }
          block[i] = floatData[channel][i + position]
        }
        let blockPeak = getPeakAmplitude(from: block)

        if blockPeak > peakValue {
          value.framePosition = position
          value.time = Double(position) / Double(format.sampleRate)
          peakValue = blockPeak
        }
        position += block.count
      }
    }

    value.amplitude = peakValue
    return value
  }

  private func getPeakAmplitude(from buffer: [Float]) -> Float {
    var peak: Float = Peak.min

    for i in 0 ..< buffer.count {
      let absSample = abs(buffer[i])
      peak = max(peak, absSample)
    }
    return peak
  }

  public func normalize() -> AVAudioPCMBuffer? {
    guard let floatData = floatChannelData else { return self }

    let normalizedBuffer = AVAudioPCMBuffer(pcmFormat: format,
                                            frameCapacity: frameCapacity)

    let length: AVAudioFrameCount = frameLength
    let channelCount = Int(format.channelCount)

    guard let peak: AVAudioPCMBuffer.Peak = peak() else {
      Logger.log("Failed getting peak amplitude, returning original buffer")
      return self
    }

    let gainFactor: Float = 1 / peak.amplitude

    for i in 0 ..< Int(length) {
      for n in 0 ..< channelCount {
        let sample = floatData[n][i] * gainFactor
        normalizedBuffer?.floatChannelData?[n][i] = sample
      }
    }
    normalizedBuffer?.frameLength = length

    return normalizedBuffer
  }

  public func reverse() -> AVAudioPCMBuffer? {
    let reversedBuffer = AVAudioPCMBuffer(pcmFormat: format,
                                          frameCapacity: frameCapacity)

    var j = 0
    let length: AVAudioFrameCount = frameLength
    let channelCount = Int(format.channelCount)

    for i in (0 ..< Int(length)).reversed() {
      for n in 0 ..< channelCount {
        reversedBuffer?.floatChannelData?[n][j] = floatChannelData?[n][i] ?? 0.0
      }
      j += 1
    }
    reversedBuffer?.frameLength = length
    return reversedBuffer
  }
}

extension AVAudioPCMBuffer {
  var rms: Float {
    guard let data = floatChannelData else { return 0 }

    let channelCount = Int(format.channelCount)
    var rms: Float = 0.0
    for i in 0 ..< channelCount {
      var channelRms: Float = 0.0
      vDSP_rmsqv(data[i], 1, &channelRms, vDSP_Length(frameLength))
      rms += abs(channelRms)
    }
    let value = (rms / Float(channelCount))
    return value
  }
}
