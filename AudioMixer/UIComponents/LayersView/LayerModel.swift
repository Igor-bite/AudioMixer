// Created with love by Igor Klyuzhev in 2023

import AVFoundation
import Foundation

enum SampleType {
  case guitar
  case trumpet
  case drums
}

final class LayerModel: Hashable {
  let id: UUID
  let name: String
  let audioFileUrl: URL
  let sampleType: SampleType
  var isMuted: Bool

  lazy var audioFile = try? AVAudioFile(forReading: audioFileUrl)
  lazy var duration: Double = {
    guard let audioFile else { return .zero }
    let length = Double(audioFile.length)
    let sampleRate = audioFile.processingFormat.sampleRate
    return length / sampleRate
  }()

  init(
    id: UUID = .init(),
    name: String,
    audioFileUrl: URL,
    isMuted: Bool
  ) {
    self.id = id
    self.name = name
    self.audioFileUrl = audioFileUrl
    self.isMuted = isMuted
    self.sampleType = .guitar
  }

  static func == (lhs: LayerModel, rhs: LayerModel) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
