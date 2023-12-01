// Created with love by Igor Klyuzhev in 2023

import Foundation

protocol ProjectsSaving {
  func save(project: ProjectModel)
  func getProjects() -> [ProjectModel]
}

final class ProjectsSaver: ProjectsSaving {
  private let defaults = UserDefaults.standard
  private lazy var projects: [ProjectModel] = {
    guard let data = defaults.data(forKey: "saved-projects") else { return [] }
    return (try? JSONDecoder().decode([ProjectModel].self, from: data)) ?? []
  }()

  func save(project: ProjectModel) {
    if !projects.contains(project) {
      projects.append(project)
    }

    if let encoded = try? JSONEncoder().encode(projects) {
      defaults.set(encoded, forKey: "saved-projects")
    } else {
      assertionFailure("Encoding projects failed")
    }
  }

  func getProjects() -> [ProjectModel] {
    projects
  }
}

fileprivate let projectsMock: [ProjectModel] = {
  guard let guitarLayer = LayerModel(
    sampleType: .guitar,
    postfix: "1"
  ),
    let drumLayer = LayerModel(
      sampleType: .drum,
      postfix: "1"
    ),
    let trumpetLayer = LayerModel(
      sampleType: .trumpet,
      postfix: "1"
    )
  else { return [] }
  return [
    ProjectModel(
      name: "hello world 1",
      layers: [
        guitarLayer,
        drumLayer,
        trumpetLayer,
      ]
    ),
    ProjectModel(name: "hello world 2"),
    ProjectModel(name: "hello world 3"),
    ProjectModel(name: "hello world 4"),
    ProjectModel(name: "hello world 5"),
    ProjectModel(name: "hello world 5"),
    ProjectModel(name: "hello world 5"),
    ProjectModel(name: "hello world 5"),
    ProjectModel(name: "hello world 5"),
    ProjectModel(name: "hello world 5"),
    ProjectModel(name: "hello world 5"),
    ProjectModel(name: "hello world 5"),
    ProjectModel(name: "hello world 5"),
    ProjectModel(name: "hello world 5"),
    ProjectModel(name: "hello world 5"),
    ProjectModel(name: "hello world 5"),
    ProjectModel(name: "hello world 5"),
    ProjectModel(name: "hello world 5"),
    ProjectModel(name: "hello world 5"),
    ProjectModel(name: "hello world 5"),
    ProjectModel(name: "hello world 5"),
    ProjectModel(name: "hello world 6"),
  ]
}()
