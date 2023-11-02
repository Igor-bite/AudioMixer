// Created with love by Igor Klyuzhev in 2023

import SwiftUI

struct WaveformStubView: View {
  let count = UIScreen.main.bounds.width / 48 // 48 = barsPerCycleCount * (barWidth + barsSpacing)
  let animationDuration: Double = 0.5
  let barsPerCycleCount: Int = 8
  let animationStep: Int = 2
  let barWidth: CGFloat = 2
  let barHeight: CGFloat = 34
  let barsSpacing: CGFloat = 4

  var body: some View {
    VStack {
      HStack(spacing: barsSpacing) {
        ForEach(0 ..< Int(count), id: \.self) {
          BarsCycleView(
            cycleIndex: $0,
            animationDuration: animationDuration,
            barsPerCycleCount: barsPerCycleCount,
            animationStep: animationStep,
            barWidth: barWidth,
            barHeight: barHeight,
            barsSpacing: barsSpacing
          )
        }
      }
    }
  }
}
