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
    alertPresenter: alertPresenter
  )

  lazy var projectsSaver: ProjectsSaving = ProjectsSaver()

  func makeMusicEditor(for project: ProjectModel) -> MusicEditorCoordinator {
    MusicEditorCoordinator(
      project: project,
      alertPresenter: alertPresenter,
      audioMixer: audioMixer,
      microphoneRecorder: microphoneRecorder,
      screenAssembly: self,
      projectSaver: projectsSaver,
      navigationController: rootNavigationController
    )
  }

  func makeProjectsList() -> ProjectsListViewCoordinator {
    ProjectsListViewCoordinator(
      projectsSaver: projectsSaver,
      screenAssembly: self,
      navigationController: rootNavigationController
    )
  }
}
