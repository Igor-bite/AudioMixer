// Created with love by Igor Klyuzhev in 2023

import SwiftUI

struct BarsCycleView: View {
  @State private var progress = Int.zero

  private let cycleIndex: Int
  private let animationDuration: Double
  private let barsPerCycleCount: Int
  private let animationStep: Int
  private let barWidth: CGFloat
  private let barHeight: CGFloat
  private let barsSpacing: CGFloat

  init(
    cycleIndex: Int,
    animationDuration: Double,
    barsPerCycleCount: Int,
    animationStep: Int,
    barWidth: CGFloat,
    barHeight: CGFloat,
    barsSpacing: CGFloat
  ) {
    self.cycleIndex = cycleIndex
    self.animationDuration = animationDuration
    self.barsPerCycleCount = barsPerCycleCount
    self.animationStep = animationStep
    self.barWidth = barWidth
    self.barHeight = barHeight
    self.barsSpacing = barsSpacing
  }

  var body: some View {
    HStack(spacing: barsSpacing) {
      ForEach(1 ..< 9) { index in
        BarView(progress: progress, index: index, height: barHeight, width: barWidth)
      }
    }
    .onAppear {
      DispatchQueue.main.asyncAfter(deadline: .now() + (Double(cycleIndex) * animationDuration / Double(animationStep))) {
        withAnimation(.linear(duration: animationDuration).repeatForever(autoreverses: false)) {
          progress = barsPerCycleCount * animationStep
        }
      }
    }
  }
}
