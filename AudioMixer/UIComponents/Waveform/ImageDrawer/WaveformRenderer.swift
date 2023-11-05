// Created with love by Igor Klyuzhev in 2023

import CoreGraphics
import UIKit

extension WaveformRenderer {
  public func defaultStyle(context: CGContext, with configuration: Waveform.Configuration) {
    // draw pixel-perfect by default
    context.setLineWidth(1.0 / configuration.scale)

    switch configuration.style {
    case let .filled(color):
      context.setFillColor(color.cgColor)
      context.fillPath()

    case let .outlined(color, lineWidth):
      context.setStrokeColor(color.cgColor)
      context.setLineWidth(lineWidth)
      context.setLineCap(.round)
      context.strokePath()

    case let .striped(config):
      context.setLineWidth(config.width)
      context.setLineCap(config.lineCap)
      context.setStrokeColor(config.color.cgColor)
      context.strokePath()

    case let .gradient(colors):
      context.clip()
      let colors = NSArray(array: colors.map { (color: UIColor) -> CGColor in color.cgColor }) as CFArray
      let colorSpace = CGColorSpaceCreateDeviceRGB()
      let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: nil)!
      context.drawLinearGradient(gradient,
                                 start: CGPoint(x: 0, y: 0),
                                 end: CGPoint(x: 0, y: configuration.size.height),
                                 options: .drawsAfterEndLocation)

    case let .gradientOutlined(colors, lineWidth):
      context.setLineWidth(lineWidth)
      context.replacePathWithStrokedPath()
      context.setLineCap(.round)
      context.setLineJoin(.round)
      context.clip()
      let colors = NSArray(array: colors.map { (color: UIColor) -> CGColor in color.cgColor }) as CFArray
      let colorSpace = CGColorSpaceCreateDeviceRGB()
      let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: nil)!
      context.drawLinearGradient(gradient,
                                 start: CGPoint(x: 0, y: 0),
                                 end: CGPoint(x: 0, y: configuration.size.height),
                                 options: .drawsAfterEndLocation)
    }
  }
}
