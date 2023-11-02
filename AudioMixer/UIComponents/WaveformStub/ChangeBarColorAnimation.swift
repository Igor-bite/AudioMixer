// Created with love by Igor Klyuzhev in 2023

import SwiftUI

struct ChangeBarColorAnimation: AnimatableModifier {
  private var progress: Int
  private let index: Int

  init(progress: Int, index: Int) {
    self.progress = progress
    self.index = index
  }

  var animatableData: CGFloat {
    get {
      CGFloat(progress)
    }
    set {
      progress = Int(newValue)
    }
  }

  func body(content: Content) -> some View {
    content
      .foregroundColor(getColor(from: index, and: progress))
  }

  private func getColor(from index: Int, and progress: Int) -> Color {
    if index == progress || index == progress - 4 {
      return Color.white.opacity(0.8)
    }
    if index == progress - 1 || index == progress - 3 {
      return Color.white.opacity(0.9)
    }
    if index == progress - 2 {
      return Color.white
    }

    return Color.white.opacity(0.4)
  }
}
