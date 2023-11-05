// Created with love by Igor Klyuzhev in 2023

import AVFoundation
import CoreGraphics
import Foundation
import UIKit

/// Renders a UIImage of the waveform data calculated by the analyzer.
class WaveformImageDrawer {
  init() {}

  /// Renders a UIImage of the waveform data calculated by the analyzer.
  func waveformImage(
    fromAudioAt audioAssetURL: URL,
    with configuration: WaveformConfiguration,
    qos: DispatchQoS.QoSClass = .userInitiated,
    completionHandler: @escaping (_ waveformImage: UIImage?) -> Void
  ) {
    let scaledConfiguration = getScaledConfiguration(configuration)
    guard let waveformAnalyzer = WaveformAnalyzer(audioAssetURL: audioAssetURL) else {
      completionHandler(nil)
      return
    }
    render(from: waveformAnalyzer, with: scaledConfiguration, qos: qos, completionHandler: completionHandler)
  }

  /// Renders a UIImage of the waveform data calculated by the analyzer.
  func waveformImage(
    fromAudioAt audioAssetURL: URL,
    size: CGSize,
    color: UIColor = UIColor.black,
    accentColor: UIColor = UIColor.black,
    backgroundColor: UIColor = UIColor.clear,
    style: WaveformStyle = .gradient,
    position: WaveformPosition = .middle,
    scale: CGFloat = UIScreen.onePixel,
    paddingFactor: CGFloat? = nil,
    accentStartPoint: CGFloat? = nil,
    accentEndPoint: CGFloat? = nil,
    qos _: DispatchQoS.QoSClass = .userInitiated,
    completionHandler: @escaping (_ waveformImage: UIImage?) -> Void
  ) {
    let configuration = WaveformConfiguration(
      size: size,
      color: color,
      accentColor: accentColor,
      backgroundColor: backgroundColor,
      style: style,
      position: position,
      scale: scale,
      paddingFactor: paddingFactor,
      accentStartPoint: accentStartPoint,
      accentEndPoint: accentEndPoint
    )
    waveformImage(fromAudioAt: audioAssetURL, with: configuration, completionHandler: completionHandler)
  }

  func waveformImage(
    fromAudio audio: AVAsset,
    with configuration: WaveformConfiguration,
    qos: DispatchQoS.QoSClass = .userInitiated,
    completionHandler: @escaping (_ waveformImage: UIImage?) -> Void
  ) {
    let scaledConfiguration = getScaledConfiguration(configuration)
    guard let waveformAnalyzer = WaveformAnalyzer(asset: audio) else {
      completionHandler(nil)
      return
    }
    render(from: waveformAnalyzer, with: scaledConfiguration, qos: qos, completionHandler: completionHandler)
  }

  func waveformImage(
    fromAudio audio: AVAsset,
    size: CGSize,
    color: UIColor = UIColor.black,
    accentColor: UIColor = UIColor.black,
    backgroundColor: UIColor = UIColor.clear,
    style: WaveformStyle = .gradient,
    position: WaveformPosition = .middle,
    scale: CGFloat = UIScreen.onePixel,
    paddingFactor: CGFloat? = nil,
    accentStartPoint: CGFloat? = nil,
    accentEndPoint: CGFloat? = nil,
    qos _: DispatchQoS.QoSClass = .userInitiated,
    completionHandler: @escaping (_ waveformImage: UIImage?) -> Void
  ) {
    let configuration = WaveformConfiguration(
      size: size,
      color: color,
      accentColor: accentColor,
      backgroundColor: backgroundColor,
      style: style,
      position: position,
      scale: scale,
      paddingFactor: paddingFactor,
      accentStartPoint: accentStartPoint,
      accentEndPoint: accentEndPoint
    )
    waveformImage(fromAudio: audio, with: configuration, completionHandler: completionHandler)
  }

  // swiftlint:enable function_parameter_count
}

// MARK: Image generation

extension WaveformImageDrawer {
  private func getScaledConfiguration(_ configuration: WaveformConfiguration) -> WaveformConfiguration {
    let scaledSize = CGSize(width: configuration.size.width * configuration.scale,
                            height: configuration.size.height * configuration.scale)
    return WaveformConfiguration(
      size: scaledSize,
      color: configuration.color,
      accentColor: configuration.accentColor,
      backgroundColor: configuration.backgroundColor,
      style: configuration.style,
      position: configuration.position,
      scale: configuration.scale,
      paddingFactor: configuration.paddingFactor,
      accentStartPoint: configuration.accentStartPoint,
      accentEndPoint: configuration.accentEndPoint
    )
  }

  fileprivate func render(
    from waveformAnalyzer: WaveformAnalyzer,
    with configuration: WaveformConfiguration,
    qos: DispatchQoS.QoSClass,
    completionHandler: @escaping (_ waveformImage: UIImage?) -> Void
  ) {
    let sampleCount = Int(configuration.size.width * configuration.scale)
    waveformAnalyzer.samples(count: sampleCount, qos: qos) { samples in
      guard let samples = samples else {
        completionHandler(nil)
        return
      }
      completionHandler(self.graphImage(from: samples, with: configuration))
    }
  }

  private func graphImage(from samples: [Float], with configuration: WaveformConfiguration) -> UIImage? {
    let format = UIGraphicsImageRendererFormat()
    format.scale = configuration.scale
    let renderer = UIGraphicsImageRenderer(size: configuration.size, format: format)
    return renderer.image { renderContext in
      draw(on: renderContext.cgContext, from: samples, with: configuration)
    }
  }

  private func draw(on context: CGContext, from samples: [Float], with configuration: WaveformConfiguration) {
    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)

    drawBackground(on: context, with: configuration)
    drawGraph(from: samples, on: context, with: configuration)
  }

  private func drawBackground(on context: CGContext, with configuration: WaveformConfiguration) {
    context.setFillColor(configuration.backgroundColor.cgColor)
    context.fill(CGRect(origin: CGPoint.zero, size: configuration.size))
  }

  private func drawGraph(
    from samples: [Float],
    on context: CGContext,
    with configuration: WaveformConfiguration
  ) {
    var maxAmplitude: CGFloat = 0.0 // we know 1 is our max in normalized data, but we keep it 'generic'

    context.setLineWidth(2.0 / configuration.scale)

    let path = getPath(samples: samples, configuration: configuration, maxAmplitude: &maxAmplitude)
    context.addPath(path)

    switch configuration.style {
    case .filled, .striped:
      context.setStrokeColor(configuration.color.cgColor)
      context.strokePath()
    case .gradient:
      let graphRect = CGRect(origin: CGPoint.zero, size: configuration.size)
      let positionAdjustedGraphCenter = CGFloat(configuration.position.value()) * graphRect.size.height
      context.replacePathWithStrokedPath()
      context.clip()
      let colors = NSArray(array: [
        configuration.color.cgColor,
        configuration.color.highlighted(brightnessAdjustment: 0.5).cgColor,
      ]) as CFArray
      let colorSpace = CGColorSpaceCreateDeviceRGB()
      let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: nil)!
      context.drawLinearGradient(gradient,
                                 start: CGPoint(x: 0, y: positionAdjustedGraphCenter - maxAmplitude),
                                 end: CGPoint(x: 0, y: positionAdjustedGraphCenter + maxAmplitude),
                                 options: .drawsAfterEndLocation)
    }

    if let accentStartPoint = configuration.accentStartPoint, let accentEndPoint = configuration.accentEndPoint {
      let accentPath = getPath(
        samples: samples,
        configuration: configuration,
        maxAmplitude: &maxAmplitude,
        accentStartPoint: accentStartPoint,
        accentEndPoint: accentEndPoint
      )
      context.addPath(accentPath)
      context.setStrokeColor(configuration.accentColor.cgColor)
      context.strokePath()
    }
  }

  func getPath(
    samples: [Float],
    configuration: WaveformConfiguration,
    maxAmplitude: inout CGFloat,
    accentStartPoint: Double? = nil,
    accentEndPoint: Double? = nil
  ) -> CGPath {
    let graphRect = CGRect(origin: CGPoint.zero, size: configuration.size)
    let positionAdjustedGraphCenter = CGFloat(configuration.position.value()) * graphRect.size.height
    let verticalPaddingDivisor = configuration.paddingFactor ?? CGFloat(configuration.position.value() == 0.5 ? 2.5 : 1.5)
    let drawMappingFactor = graphRect.size.height / verticalPaddingDivisor
    let minimumGraphAmplitude: CGFloat = 1 // we want to see at least a 1pt line for silence

    let path = CGMutablePath()
    for (x, sample) in samples.enumerated() {
      let xPos = CGFloat(x) / configuration.scale

      if let startPoint = accentStartPoint, let endPoint = accentEndPoint {
        if xPos < startPoint || xPos > endPoint { continue }
      }

      let invertedDbSample = 1 - CGFloat(sample) // sample is in dB, linearly normalized to [0, 1] (1 -> -50 dB)
      let drawingAmplitude = max(minimumGraphAmplitude, invertedDbSample * drawMappingFactor)
      let drawingAmplitudeUp = positionAdjustedGraphCenter - drawingAmplitude
      let drawingAmplitudeDown = positionAdjustedGraphCenter + drawingAmplitude
      maxAmplitude = max(drawingAmplitude, maxAmplitude)

      if configuration.style == .striped, Int(xPos) % 5 != 0 { continue }

      path.move(to: CGPoint(x: xPos, y: drawingAmplitudeUp))
      path.addLine(to: CGPoint(x: xPos, y: drawingAmplitudeDown))
    }
    return path
  }
}

/**
 Position of the drawn waveform:
 - **top**: Draws the waveform at the top of the image, such that only the bottom 50% are visible.
 - **top**: Draws the waveform in the middle the image, such that the entire waveform is visible.
 - **bottom**: Draws the waveform at the bottom of the image, such that only the top 50% are visible.
 */
enum WaveformPosition {
  case top
  case middle
  case bottom
  case custom(Double)

  func value() -> Double {
    switch self {
    case .top: return 0.0
    case .middle: return 0.5
    case .bottom: return 1.0
    case let .custom(value): return min(1.0, max(0.0, value))
    }
  }
}

/**
 Style of the waveform which is used during drawing:
 - **filled**: Use solid color for the waveform.
 - **gradient**: Use gradient based on color for the waveform.
 - **striped**: Use striped filling based on color for the waveform.
 */
enum WaveformStyle: Int {
  case filled = 0
  case gradient
  case striped
}

/// Allows customization of the waveform output image.
struct WaveformConfiguration {
  /// Desired output size of the waveform image, works together with scale.
  let size: CGSize

  /// Color of the waveform, defaults to black.
  let color: UIColor

  /// Additional color of the waveform, defaults to black.
  let accentColor: UIColor

  /// Background color of the waveform, defaults to clear.
  let backgroundColor: UIColor

  /// Waveform drawing style, defaults to .gradient.
  let style: WaveformStyle

  /// Waveform drawing position, defaults to .middle.
  let position: WaveformPosition

  /// Scale to be applied to the image, defaults to main screen's scale.
  let scale: CGFloat

  /// Optional padding or vertical shrinking factor for the waveform.
  let paddingFactor: CGFloat?

  /// Borders of a different color waveform segment
  let accentStartPoint: CGFloat?
  let accentEndPoint: CGFloat?

  init(
    size: CGSize,
    color: UIColor = UIColor.black,
    accentColor: UIColor = UIColor.black,
    backgroundColor: UIColor = UIColor.clear,
    style: WaveformStyle = .gradient,
    position: WaveformPosition = .middle,
    scale: CGFloat = UIScreen.onePixel,
    paddingFactor: CGFloat? = nil,
    accentStartPoint: CGFloat? = nil,
    accentEndPoint: CGFloat? = nil
  ) {
    self.color = color
    self.accentColor = accentColor
    self.backgroundColor = backgroundColor
    self.style = style
    self.position = position
    self.size = size
    self.scale = scale
    self.paddingFactor = paddingFactor
    self.accentStartPoint = accentStartPoint
    self.accentEndPoint = accentEndPoint
  }
}

extension UIColor {
  func highlighted(brightnessAdjustment: CGFloat) -> UIColor {
    var hue: CGFloat = 0.0, saturation: CGFloat = 0.0, brightness: CGFloat = 0.0, alpha: CGFloat = 0.0
    getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

    let brightnessAdjustment: CGFloat = brightnessAdjustment
    let adjustmentModifier: CGFloat = brightness < brightnessAdjustment ? 1 : -1
    let newBrightness = brightness + brightnessAdjustment * adjustmentModifier
    return UIColor(hue: hue, saturation: saturation, brightness: newBrightness, alpha: alpha)
  }
}
