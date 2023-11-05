// Created with love by Igor Klyuzhev in 2023

import UIKit

enum RulerViewType {
  case vertical
  case horizontal
}

class RulerView: UIView {
  // MARK: - Properties

  private let lineWidth: CGFloat
  private let lineColor: UIColor
  private let type: RulerViewType
  private let shouldDecrease: Bool
  private let longStickIndex: Int?

  // MARK: - View Life Cycle

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  init(
    lineWidth: CGFloat = 1,
    lineColor: UIColor = .white,
    defaultDistance: CGFloat,
    type: RulerViewType,
    shouldDecrease: Bool,
    longStickIndex: Int? = nil
  ) {
    self.lineWidth = lineWidth
    self.lineColor = lineColor
    self.type = type
    self.shouldDecrease = shouldDecrease
    self.longStickIndex = longStickIndex
    super.init(frame: .zero)
    backgroundColor = .clear
  }

  override func draw(_ rect: CGRect) {
    lineColor.setFill()
    var i = 0.0
    var count = 0
    let limit = type == .vertical ? Double(bounds.size.height) : Double(bounds.size.width)
    while Double(i) < limit {
      let isVertical = type == .vertical

      let width: CGFloat
      let height: CGFloat
      if isVertical {
        if let longStickIndex {
          let isLong = count % longStickIndex == 0
          if isLong {
            width = bounds.size.width
          } else {
            width = bounds.size.width / 2
          }
        } else {
          width = bounds.size.width
        }

        height = lineWidth
      } else {
        if let longStickIndex {
          let isLong = count % longStickIndex == 0
          if isLong {
            height = bounds.size.height
          } else {
            height = bounds.size.height / 2
          }
        } else {
          height = bounds.size.height
        }

        width = lineWidth
      }

      UIRectFill(
        CGRect(
          x: isVertical ? 0 : i,
          y: isVertical ? i : 0,
          width: width,
          height: height
        )
      )
      let dist: CGFloat
      if shouldDecrease {
        dist = 14.0 - CGFloat(count + 1) * 0.3
      } else {
        dist = 10.0
      }
      i += max(5, dist)
      count += 1
    }
  }
}
