// Created with love by Igor Klyuzhev in 2023

import AVFoundation
import UIKit

final class MicrophoneAudioRecorder {
  private let format: AVAudioFormat
  private let alertPresenter: AlertPresenting
  private let recordingSession = AVAudioSession.sharedInstance()

  private var isSetupNeeded = true
  private var voiceRecorder: AVAudioRecorder?
  private var recordingLayer: LayerModel?
  var recordingsCounter = 1
  var isRecording: Bool {
    voiceRecorder != nil && voiceRecorder?.isRecording == true
  }

  init(format: AVAudioFormat, alertPresenter: AlertPresenting) {
    self.format = format
    self.alertPresenter = alertPresenter
  }

  func record(failureAction: @escaping () -> Void) {
    if isSetupNeeded {
      setup { [weak self] isSuccess in
        guard isSuccess else {
          failureAction()
          return
        }
        self?.startRecording(failureAction: failureAction)
      }
    } else {
      startRecording(failureAction: failureAction)
    }
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

  private func startRecording(failureAction: @escaping () -> Void) {
    guard recordingSession.recordPermission == .granted else {
      showMicPrivacyAlert()
      failureAction()
      return
    }

    let layer = makeVoiceMemoLayer()
    recordingLayer = layer

    do {
      voiceRecorder = try AVAudioRecorder(url: layer.audioFileUrl, format: format)
      voiceRecorder?.record()
    } catch {
      stopRecording()
      failureAction()
      handleError(e: error)
    }
  }

  private func setup(completion: @escaping (Bool) -> Void) {
    isSetupNeeded = false
    do {
      try recordingSession.setCategory(.playAndRecord, mode: .default)
      try recordingSession.setActive(true)
      recordingSession.requestRecordPermission { allowed in
        DispatchQueue.main.async { [weak self] in
          if !allowed {
            self?.showMicPrivacyAlert()
            Logger.log("Not allowed to use mic")
          }
          completion(allowed)
        }
      }
    } catch {
      handleError(e: error)
      completion(false)
    }
  }

  private func showMicPrivacyAlert() {
    let settingsAction = UIAlertAction(title: "Настройки", style: .default) { _ in
      guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
      if UIApplication.shared.canOpenURL(settingsUrl) {
        UIApplication.shared.open(settingsUrl) { _ in }
      }
    }
    let cancelAction = UIAlertAction(title: "Отменить", style: .default, handler: nil)

    alertPresenter.showAlert(
      title: "Нет доступа к микрофону",
      message: "Чтобы использовать запись с микрофона нужно дать разрешение в настройках",
      style: .alert,
      actions: [settingsAction, cancelAction]
    )
  }

  private func handleError(e: Error) {
    Logger.log(e)
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
