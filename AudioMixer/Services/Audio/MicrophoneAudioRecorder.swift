// Created with love by Igor Klyuzhev in 2023

import AVFoundation
import Foundation

final class MicrophoneAudioRecorder {
  private let recordingSession = AVAudioSession.sharedInstance()
  private var voiceRecorder: AVAudioRecorder?
  private var recordingLayer: LayerModel?

  var recordingsCounter = 1

  var isRecording: Bool {
    voiceRecorder != nil && voiceRecorder?.isRecording == true
  }

  private let format: AVAudioFormat

  init(format: AVAudioFormat, notAllowedAction: @escaping () -> Void) {
    self.format = format
    do {
      try recordingSession.setCategory(.playAndRecord, mode: .default)
      try recordingSession.setActive(true)
      recordingSession.requestRecordPermission { allowed in
        DispatchQueue.main.async {
          if !allowed {
            notAllowedAction()
            Logger.log("Not allowed to use mic")
          }
        }
      }
    } catch {
      handleError(e: error)
    }
  }

  func record() -> Bool {
    if recordingSession.recordPermission != .granted {
      return false
    }
    let layer = makeVoiceMemoLayer()
    recordingLayer = layer

    do {
      voiceRecorder = try AVAudioRecorder(url: layer.audioFileUrl, format: format)
      voiceRecorder?.record()
    } catch {
      stopRecording()
      handleError(e: error)
    }
    return true
  }

  private func handleError(e: Error) {
    Logger.log(e)
  }

  @discardableResult
  func stopRecording() -> LayerModel? {
    voiceRecorder?.stop()
    voiceRecorder = nil
    guard let layer = recordingLayer else {
      assertionFailure("No layer model by the end of recording")
      return nil
    }
    recordingLayer = nil
    return layer
  }

  private func makeVoiceMemoLayer() -> LayerModel {
    let fileName = "voice_\(recordingsCounter)"
    let sampleType = SampleType.voice
    let layerName = "\(sampleType.layerPrefix) \(recordingsCounter)"
    let date = Date().description.replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: ":", with: "-")
    let fileUrl = FileManager.getDocumentsDirectory().appendingPathComponent("\(fileName)_\(date).m4a")
    recordingsCounter += 1
    return LayerModel(
      name: layerName,
      audioFileUrl: fileUrl,
      isMuted: false,
      sampleType: sampleType
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
