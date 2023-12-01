// Created with love by Igor Klyuzhev in 2023

import Foundation

final class ProjectModel: Hashable, Codable {
  let id: UUID
  let name: String
  let creationDate: Date
  let updateDate: Date
  var layers: [LayerModel]

  init(
    id: UUID = .init(),
    name: String,
    creationDate: Date = .init(),
    updateDate: Date = .init(),
    layers: [LayerModel] = .init()
  ) {
    self.id = id
    self.name = name
    self.creationDate = creationDate
    self.updateDate = updateDate
    self.layers = layers
  }

  static func == (lhs: ProjectModel, rhs: ProjectModel) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
