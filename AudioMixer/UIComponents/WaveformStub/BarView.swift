// Created with love by Igor Klyuzhev in 2023

import SwiftUI

struct BarView: View {
  private let progress: Int
  private let index: Int
  private let height: CGFloat
  private let width: CGFloat

  private var percent: CGFloat {
    switch index {
    case 1:
      return 0.1
    case 2, 8:
      return 0.25
    case 3, 7:
      return 0.5
    case 4, 6:
      return 0.75
    default:
      return 1
    }
  }

  init(progress: Int, index: Int, height: CGFloat, width: CGFloat) {
    self.progress = progress
    self.index = index
    self.height = height
    self.width = width
  }

  var body: some View {
    Rectangle()
      .modifier(ChangeBarColorAnimation(progress: progress, index: index))
      .frame(width: width, height: percent * height)
      .cornerRadius(2)
  }
}
