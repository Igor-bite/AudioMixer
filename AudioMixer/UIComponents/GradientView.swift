// Created with love by Igor Klyuzhev in 2023

import QuartzCore
import UIKit

public class GradientView: UIView {
  override public class var layerClass: Swift.AnyClass {
    CAGradientLayer.self
  }

  public init(
    frame: CGRect = .zero,
    direction: Direction = .vertical,
    colors: [UIColor],
    locations: [Float]? = nil
  ) {
    super.init(frame: frame)

    guard let gradientLayer = layer as? CAGradientLayer else {
      return
    }

    switch direction {
    case .vertical:
      gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
      gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)

    case .horizontal:
      gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
      gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
    }

    gradientLayer.colors = colors.map { $0.cgColor }

    if let locations = locations {
      gradientLayer.locations = locations.map { NSNumber(value: $0) }
    }
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init?(coder:) has not been implemented")
  }

  public func updateGradientColors(
    _ color: [UIColor],
    colorLocations: [Float]? = nil
  ) {
    guard let gradientLayer = layer as? CAGradientLayer else {
      return
    }

    gradientLayer.colors = color.map { $0.cgColor }
    if let colorLocations = colorLocations {
      gradientLayer.locations = colorLocations.map { NSNumber(value: $0) }
    }
  }
}

// MARK: - Direction

extension GradientView {
  public enum Direction {
    case vertical
    case horizontal
  }
}
