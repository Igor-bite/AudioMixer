// Created with love by Igor Klyuzhev in 2023

import AVFoundation
import Foundation

final class MicrophoneAudioRecorder {
  private let recordingSession = AVAudioSession.sharedInstance()
  private var whistleRecorder: AVAudioRecorder?
  private var recordingLayer: LayerModel?

  private var recordingsCounter = 1

  var isRecording: Bool {
    whistleRecorder != nil && whistleRecorder?.isRecording == true
  }

  init() {
    do {
      try recordingSession.setCategory(.playAndRecord, mode: .default)
      try recordingSession.setActive(true)
      recordingSession.requestRecordPermission { [weak self] allowed in
        DispatchQueue.main.async {
          if !allowed {
            Logger.log("Not allowed to use mic")
          }
        }
      }
    } catch {
      handleError(e: error)
    }
  }

  func record() {
    let layer = makeVoiceMemoLayer()
    recordingLayer = layer
    print(layer.audioFileUrl.absoluteString)

    let settings = [
      AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
      AVNumberOfChannelsKey: 1,
      AVSampleRateKey: 4410,
      AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
    ]

    do {
      whistleRecorder = try AVAudioRecorder(url: layer.audioFileUrl, settings: settings)
      whistleRecorder?.record()
    } catch {
      stopRecording()
      handleError(e: error)
    }
  }

  private func handleError(e: Error) {
    Logger.log(e)
  }

  @discardableResult
  func stopRecording() -> LayerModel? {
    whistleRecorder?.stop()
    whistleRecorder = nil
    guard let layer = recordingLayer else {
      assertionFailure("No layer model by the end of recording")
      return nil
    }
    recordingLayer = nil
    return layer
  }

  private func makeVoiceMemoLayer() -> LayerModel {
    let name = "voice_\(recordingsCounter)"
    let date = Date().description.replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: ":", with: "-")
    let fileUrl = FileManager.getDocumentsDirectory().appendingPathComponent("\(name)_\(date).m4a")
    recordingsCounter += 1
    return LayerModel(
      name: name,
      audioFileUrl: fileUrl,
      isMuted: false,
      sampleType: .voice
    )
  }
}

extension FileManager {
  static func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory
  }
}
