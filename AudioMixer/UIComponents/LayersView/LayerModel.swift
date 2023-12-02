// Created with love by Igor Klyuzhev in 2023

import AVFoundation
import UIKit

enum SampleType: String, Codable {
  case guitar
  case trumpet
  case drum
  case voice

  var layerPrefix: String {
    switch self {
    case .guitar:
      return "Гитара"
    case .trumpet:
      return "Духовые"
    case .drum:
      return "Ударные"
    case .voice:
      return "Вокал"
    }
  }

  var shapeImage: UIImage {
    switch self {
    case .guitar:
      let images = [
        Asset.Shapes.linesStrange.image,
        Asset.Shapes.linesDiagonal.image,
        Asset.Shapes.linesHorizontal.image,
        Asset.Shapes.tetraedrFilled.image,
        Asset.Shapes.tetraedrWhite.image,
      ]
      return images.randomElement() ?? images[0]
    case .trumpet:
      let images = [
        Asset.Shapes.sun.image,
        Asset.Shapes.sunFilled.image,
        Asset.Shapes.sunOutline.image,
      ]
      return images.randomElement() ?? images[0]
    case .drum:
      let images = [
        Asset.Shapes.circleFilled.image,
        Asset.Shapes.circleOutline.image,
        Asset.Shapes.dots.image,
        Asset.Shapes.tetraedrGreen.image,
      ]
      return images.randomElement() ?? images[0]
    case .voice:
      let images = [
        Asset.Shapes.curl1.image,
        Asset.Shapes.curl2.image,
        Asset.Shapes.curl3.image,
      ]
      return images.randomElement() ?? images[0]
    }
  }
}

final class LayerModel: Hashable, Codable {
  let id: UUID
  let name: String
  let audioFileUrl: URL
  let sampleType: SampleType
  var isMuted: Bool
  var volume: CGFloat = 0.5
  var rate: CGFloat = 1

  lazy var audioFile = try? AVAudioFile(forReading: audioFileUrl)
  lazy var duration: Double = {
    guard let audioFile else { return .zero }
    let length = Double(audioFile.length)
    let sampleRate = audioFile.processingFormat.sampleRate
    return length / sampleRate
  }()

  lazy var waveformWidth: Double = duration * 60 * 2

  init(
    id: UUID = .init(),
    name: String,
    audioFileUrl: URL,
    isMuted: Bool,
    sampleType: SampleType
  ) {
    self.id = id
    self.name = name
    self.audioFileUrl = audioFileUrl
    self.isMuted = isMuted
    self.sampleType = sampleType
  }

  convenience init?(
    sampleType: SampleType,
    postfix: String
  ) {
    let fileName = "\(sampleType.rawValue)_\(postfix)"
    let layerName = "\(sampleType.layerPrefix) \(postfix)"
    guard let audioFileUrl = Bundle.main.url(forResource: fileName, withExtension: "wav")
    else {
      Logger.log("Audio file was not found")
      return nil
    }

    self.init(
      name: layerName,
      audioFileUrl: audioFileUrl,
      isMuted: false,
      sampleType: sampleType
    )
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decode(UUID.self, forKey: .id)
    self.name = try container.decode(String.self, forKey: .name)
    let audioFileUrl = try container.decode(URL.self, forKey: .audioFileUrl)
    self.audioFileUrl = audioFileUrl.currentBundleUrl ?? audioFileUrl.currentDocumentsDirectory ?? audioFileUrl
    self.sampleType = try container.decode(SampleType.self, forKey: .sampleType)
    self.isMuted = try container.decode(Bool.self, forKey: .isMuted)
  }

  static func == (lhs: LayerModel, rhs: LayerModel) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

extension URL {
  var currentBundleUrl: URL? {
    Bundle.main.url(forResource: lastPathComponent, withExtension: nil)
  }

  var currentDocumentsDirectory: URL {
    FileManager.getDocumentsDirectory().appendingPathComponent(lastPathComponent)
  }
}
