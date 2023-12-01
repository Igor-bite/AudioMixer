// Created with love by Igor Klyuzhev in 2023

import UIKit

final class MusicEditorCoordinator {
  private let project: ProjectModel
  private let alertPresenter: AlertPresenting
  private let audioMixer: AudioMixer
  private let microphoneRecorder: MicrophoneAudioRecorder
  private let screenAssembly: ScreenAssembly
  private let projectSaver: ProjectsSaving
  private let navigationController: UINavigationController

  init(
    project: ProjectModel,
    alertPresenter: AlertPresenting,
    audioMixer: AudioMixer,
    microphoneRecorder: MicrophoneAudioRecorder,
    screenAssembly: ScreenAssembly,
    projectSaver: ProjectsSaving,
    navigationController: UINavigationController
  ) {
    self.project = project
    self.alertPresenter = alertPresenter
    self.audioMixer = audioMixer
    self.microphoneRecorder = microphoneRecorder
    self.screenAssembly = screenAssembly
    self.projectSaver = projectSaver
    self.navigationController = navigationController
  }

  func start() {
    let viewModel = MusicEditorViewModel(
      project: project,
      projectSaver: projectSaver,
      audioMixer: audioMixer,
      audioRecorder: microphoneRecorder
    )

    let viewController = MusicEditorViewController(
      viewModel: viewModel,
      alertPresenter: alertPresenter
    )
    viewModel.view = viewController

    navigationController.pushViewController(viewController, animated: true)
  }
}
