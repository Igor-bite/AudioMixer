// Created with love by Igor Klyuzhev in 2023

import UIKit

final class PlayerCoordinator {
  private let screenRecorder: ScreenRecorder
  private let trackUrl: URL
  private let screenAssembly: ScreenAssembly
  private let navigationController: UINavigationController

  init(
    screenRecorder: ScreenRecorder,
    trackUrl: URL,
    screenAssembly: ScreenAssembly,
    navigationController: UINavigationController
  ) {
    self.screenRecorder = screenRecorder
    self.trackUrl = trackUrl
    self.screenAssembly = screenAssembly
    self.navigationController = navigationController
  }

  func start() {
    let viewModel = PlayerViewModel(
      screenRecorder: screenRecorder,
      trackUrl: trackUrl,
      coordinator: self
    )
    screenRecorder.completion = { [weak self] url in
      self?.shareFile(fileUrl: url)
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
