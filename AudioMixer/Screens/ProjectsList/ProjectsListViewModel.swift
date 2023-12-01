// Created with love by Igor Klyuzhev in 2023

import Foundation

final class ProjectsListViewModel {
  private let projectsSaver: ProjectsSaving
  private let coordinator: ProjectsListViewCoordinator
  weak var view: ProjectsListViewController?
  var projects = [ProjectModel]() {
    didSet {
      view?.updateCollectionView()
    }
  }

  init(
    coordinator: ProjectsListViewCoordinator,
    projectsSaver: ProjectsSaving
  ) {
    self.coordinator = coordinator
    self.projectsSaver = projectsSaver

    projectsSaver.loadProjects(completion: { [weak self] projects in
      self?.projects = projects
    })
  }

  func viewDidLoad() {
    view?.updateCollectionView()
  }

  func createProjectTapped() {
    coordinator.openEditor(for: ProjectModel(name: "Новый проект"))
  }

  func didSelectProject(at indexPath: IndexPath) {
    guard let project = projects[safe: indexPath.item] else {
      assertionFailure("Project not found")
      return
    }
    coordinator.openEditor(for: project)
  }
}
