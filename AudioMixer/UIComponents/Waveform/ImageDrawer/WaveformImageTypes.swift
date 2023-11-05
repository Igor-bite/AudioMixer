// Created with love by Igor Klyuzhev in 2023

import AVFoundation
import UIKit

public protocol WaveformRenderer: Sendable {
  func path(samples: [Float], with configuration: Waveform.Configuration, lastOffset: Int, position: Waveform.Position) -> CGPath

  func render(samples: [Float], on context: CGContext, with configuration: Waveform.Configuration, lastOffset: Int, position: Waveform.Position)
}

extension WaveformRenderer {
  public func path(samples: [Float], with configuration: Waveform.Configuration, lastOffset: Int, position: Waveform.Position = .middle) -> CGPath {
    path(samples: samples, with: configuration, lastOffset: lastOffset, position: position)
  }

  public func render(
    samples: [Float],
    on context: CGContext,
    with configuration: Waveform.Configuration,
    lastOffset: Int,
    position: Waveform.Position = .middle
  ) {
    render(samples: samples, on: context, with: configuration, lastOffset: lastOffset, position: position)
  }
}

public enum Waveform {
  public enum Position: Equatable {
    case top

    case middle

    case bottom

    case custom(CGFloat)

    func offset() -> CGFloat {
      switch self {
      case .top: return 0.0
      case .middle: return 0.5
      case .bottom: return 1.0
      case let .custom(offset): return min(1, max(0, offset))
      }
    }
  }

  public enum Style: Equatable, Sendable {
    public struct StripeConfig: Equatable, Sendable {
      public let color: UIColor

      public let width: CGFloat

      public let spacing: CGFloat

      public let lineCap: CGLineCap

      public init(color: UIColor, width: CGFloat = 1, spacing: CGFloat = 5, lineCap: CGLineCap = .round) {
        self.color = color
        self.width = width
        self.spacing = spacing
        self.lineCap = lineCap
      }
    }

    case filled(UIColor)
    case outlined(UIColor, CGFloat)
    case gradient([UIColor])
    case gradientOutlined([UIColor], CGFloat)
    case striped(StripeConfig)
  }

  public struct Damping: Equatable, Sendable {
    public enum Sides: Equatable, Sendable {
      case left
      case right
      case both
    }

    public let percentage: Float

    public let sides: Sides

    public let easing: @Sendable (Float)
      -> Float

    public init(percentage: Float = 0.125, sides: Sides = .both, easing: @escaping @Sendable (Float) -> Float = { x in pow(x, 2) }) {
      guard (0 ... 0.5).contains(percentage) else {
        preconditionFailure("dampingPercentage must be within (0..<0.5)")
      }

      self.percentage = percentage
      self.sides = sides
      self.easing = easing
    }

    public func with(percentage: Float? = nil, sides: Sides? = nil, easing: (@Sendable (Float) -> Float)? = nil) -> Damping {
      .init(percentage: percentage ?? self.percentage, sides: sides ?? self.sides, easing: easing ?? self.easing)
    }

    public static func == (lhs: Waveform.Damping, rhs: Waveform.Damping) -> Bool {
      // poor-man's way to make two closures Equatable w/o too much hassle
      let randomEqualitySample = Float.random(in: 0 ..< Float.greatestFiniteMagnitude)
      return lhs.percentage == rhs.percentage && lhs.sides == rhs.sides && lhs.easing(randomEqualitySample) == rhs.easing(randomEqualitySample)
    }
  }

  public struct Configuration: Equatable, Sendable {
    public let size: CGSize

    public let backgroundColor: UIColor

    public let style: Style

    public let damping: Damping?

    public let scale: CGFloat

    public let verticalScalingFactor: CGFloat

    public let shouldAntialias: Bool

    public var shouldDamp: Bool {
      damping != nil
    }

    public init(size: CGSize = .zero,
                backgroundColor: UIColor = UIColor.clear,
                style: Style = .gradient([UIColor.black, UIColor.gray]),
                damping: Damping? = nil,
                scale: CGFloat = UIScreen.main.scale,
                verticalScalingFactor: CGFloat = 0.95,
                shouldAntialias: Bool = false)
    {
      guard verticalScalingFactor > 0 else {
        preconditionFailure("verticalScalingFactor must be greater 0")
      }

      self.backgroundColor = backgroundColor
      self.style = style
      self.damping = damping
      self.size = size
      self.scale = scale
      self.verticalScalingFactor = verticalScalingFactor
      self.shouldAntialias = shouldAntialias
    }

    public func with(size: CGSize? = nil,
                     backgroundColor: UIColor? = nil,
                     style: Style? = nil,
                     damping: Damping? = nil,
                     scale: CGFloat? = nil,
                     verticalScalingFactor: CGFloat? = nil,
                     shouldAntialias: Bool? = nil) -> Configuration
    {
      Configuration(
        size: size ?? self.size,
        backgroundColor: backgroundColor ?? self.backgroundColor,
        style: style ?? self.style,
        damping: damping ?? self.damping,
        scale: scale ?? self.scale,
        verticalScalingFactor: verticalScalingFactor ?? self.verticalScalingFactor,
        shouldAntialias: shouldAntialias ?? self.shouldAntialias
      )
    }
  }
}
