// Created with love by Igor Klyuzhev in 2023

import Foundation
import ReplayKit

final class ScreenRecorder: NSObject, RPPreviewViewControllerDelegate {
  private let recorder = RPScreenRecorder.shared()

  var completion: ((URL) -> Void)?

  func toggleRecording() {
    guard recorder.isAvailable else {
      Logger.log("ReplayKit unavailable")
      return
    }
    if recorder.isRecording {
      self.stopRecording()
    } else {
      self.startRecording()
    }
  }

  func startRecording() {
    recorder.startRecording { (error: Error?) in
      if let error {
        Logger.log(error)
      }
    }
  }

  func stopRecording() {
    let url = FileManager.getDocumentsDirectory().appending(path: "\(UUID().uuidString).mov")
    recorder.stopRecording(withOutput: url) { [weak self] error in
      if let error {
        Logger.log(error)
        return
      }
      self?.completion?(url)
    }
  }
}
