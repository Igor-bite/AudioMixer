// Created with love by Igor Klyuzhev in 2023

import AVFoundation
import UIKit

final class PlayerCoordinator {
  private let screenRecorder: ScreenRecorder
  private let project: ProjectModel
  private let screenAssembly: ScreenAssembly
  private let isStreaming: Bool
  private let navigationController: UINavigationController

  init(
    screenRecorder: ScreenRecorder,
    project: ProjectModel,
    screenAssembly: ScreenAssembly,
    isStreaming: Bool,
    navigationController: UINavigationController
  ) {
    self.screenRecorder = screenRecorder
    self.project = project
    self.screenAssembly = screenAssembly
    self.isStreaming = isStreaming
    self.navigationController = navigationController
  }

  func start() {
    var audioController: MusicVisualizerAudioControlling?
    if isStreaming {
      audioController = screenAssembly.audioMixer
    } else {
      if let trackUrl = project.trackUrl {
        audioController = try? AVAudioPlayer(contentsOf: trackUrl)
      }
    }
    let viewModel = PlayerViewModel(
      screenRecorder: screenRecorder,
      project: project,
      audioController: audioController,
      coordinator: self
    )
    screenRecorder.completion = { [weak self] prev in
      self?.navigationController.present(prev, animated: true)
    }
    let viewController = PlayerViewController(viewModel: viewModel)
    viewModel.view = viewController

    navigationController.pushViewController(viewController, animated: true)
  }

  func finish() {
    navigationController.popViewController(animated: true)
  }

  func shareFile(fileUrl: URL) {
    let activityViewController = UIActivityViewController(
      activityItems: [fileUrl],
      applicationActivities: nil
    )
    activityViewController.completionWithItemsHandler = { _, _, _, _ in }
    navigationController.present(
      activityViewController,
      animated: true,
      completion: nil
    )
  }
}
