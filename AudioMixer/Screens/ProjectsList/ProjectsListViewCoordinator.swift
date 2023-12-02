// Created with love by Igor Klyuzhev in 2023

import UIKit

final class ProjectsListViewCoordinator {
  private let projectsSaver: ProjectsSaving
  private let screenAssembly: ScreenAssembly
  private let navigationController: UINavigationController

  init(
    projectsSaver: ProjectsSaving,
    screenAssembly: ScreenAssembly,
    navigationController: UINavigationController
  ) {
    self.projectsSaver = projectsSaver
    self.screenAssembly = screenAssembly
    self.navigationController = navigationController
  }

  func start() {
    let viewModel = ProjectsListViewModel(
      coordinator: self,
      projectsSaver: projectsSaver
    )

    let viewController = ProjectsListViewController(
      viewModel: viewModel
    )
    viewModel.view = viewController

    navigationController.setViewControllers([viewController], animated: false)
  }

  func openEditor(for project: ProjectModel) {
    screenAssembly.makeMusicEditor(for: project).start()
  }
}
