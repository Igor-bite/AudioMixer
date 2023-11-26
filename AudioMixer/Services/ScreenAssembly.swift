// Created with love by Igor Klyuzhev in 2023

import UIKit

final class ScreenAssembly {
  let rootNavigationController = UINavigationController()

  lazy var alertPresenter: AlertPresenting = AlertPresenter(
    presentingViewController: rootNavigationController
  )

  let audioMixer = AudioMixer()
  lazy var microphoneRecorder = MicrophoneAudioRecorder(
    format: audioMixer.format,
    notAllowedAction: {} // TODO: make inside
  )

  func makeMusicEditor() -> UIViewController {
    let viewModel = MusicEditorViewModel(
      audioMixer: audioMixer,
      audioRecorder: microphoneRecorder
    )

    let viewController = MusicEditorViewController(viewModel: viewModel)
    viewModel.view = viewController

    return viewController
  }
}
