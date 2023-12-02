// Created with love by Igor Klyuzhev in 2023

import Foundation
import ReplayKit

final class ScreenRecorder: NSObject, RPPreviewViewControllerDelegate {
  private let recorder = RPScreenRecorder.shared()

  var completion: ((UIViewController) -> Void)?

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
    recorder.stopRecording { [weak self] prev, error in
      if let error {
        Logger.log(error)
        return
      }
      guard let prev else { return }
      self?.completion?(prev)
    }
  }
}
