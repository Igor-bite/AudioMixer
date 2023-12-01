// Created with love by Igor Klyuzhev in 2023

import Foundation

protocol ProjectsSaving {
  func save(project: ProjectModel)
  func loadProjects(completion: ([ProjectModel]) -> Void)
}

final class ProjectsSaver: ProjectsSaving {
  func save(project: ProjectModel) {}

  func loadProjects(completion: ([ProjectModel]) -> Void) {
    completion(projectsMock)
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
