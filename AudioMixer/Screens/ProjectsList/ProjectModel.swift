// Created with love by Igor Klyuzhev in 2023

import Foundation

final class ProjectModel: Hashable, Codable {
  let id: UUID
  var name: String
  let creationDate: Date
  let updateDate: Date
  var layers: [LayerModel]
  var savedFileUrls: [URL]

  var trackUrl: URL? {
    savedFileUrls.last
  }

  init(
    id: UUID = .init(),
    name: String,
    creationDate: Date = .init(),
    updateDate: Date = .init(),
    layers: [LayerModel] = .init(),
    savedFileUrls: [URL] = .init()
  ) {
    self.id = id
    self.name = name
    self.creationDate = creationDate
    self.updateDate = updateDate
    self.layers = layers
    self.savedFileUrls = savedFileUrls
  }

  static func == (lhs: ProjectModel, rhs: ProjectModel) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
