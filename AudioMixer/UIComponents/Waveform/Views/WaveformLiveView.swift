// Created with love by Igor Klyuzhev in 2023

import UIKit

public class WaveformLiveView: UIView {
  public static let defaultConfiguration = Waveform.Configuration(damping: .init(percentage: 0.125, sides: .both))

  public var shouldDrawSilencePadding: Bool = false {
    didSet {
      sampleLayer.shouldDrawSilencePadding = shouldDrawSilencePadding
    }
  }

  public var configuration: Waveform.Configuration {
    didSet {
      sampleLayer.configuration = configuration
    }
  }

  public var samples: [Float] {
    sampleLayer.samples
  }

  private var sampleLayer: WaveformLiveLayer! {
    layer as? WaveformLiveLayer
  }

  override public class var layerClass: AnyClass {
    WaveformLiveLayer.self
  }

  public var renderer: WaveformRenderer {
    didSet {
      sampleLayer.renderer = renderer
    }
  }

  public init(configuration: Waveform.Configuration = defaultConfiguration, renderer: WaveformRenderer = LinearWaveformRenderer()) {
    self.configuration = configuration
    self.renderer = renderer
    super.init(frame: .zero)
    self.contentMode = .redraw

    defer { // will call didSet to propagate to sampleLayer
      self.configuration = configuration
      self.renderer = renderer
    }
  }

  override public init(frame: CGRect) {
    self.configuration = Self.defaultConfiguration
    self.renderer = LinearWaveformRenderer()
    super.init(frame: frame)
    contentMode = .redraw

    defer { // will call didSet to propagate to sampleLayer
      self.configuration = Self.defaultConfiguration
      self.renderer = LinearWaveformRenderer()
    }
  }

  required init?(coder: NSCoder) {
    self.configuration = Self.defaultConfiguration
    self.renderer = LinearWaveformRenderer()
    super.init(coder: coder)
    contentMode = .redraw

    defer { // will call didSet to propagate to sampleLayer
      self.configuration = Self.defaultConfiguration
      self.renderer = LinearWaveformRenderer()
    }
  }

  public func add(sample: Float) {
    sampleLayer.add([sample])
  }

  public func add(samples: [Float]) {
    sampleLayer.add(samples)
  }

  public func reset() {
    sampleLayer.reset()
  }
}

class WaveformLiveLayer: CALayer {
  @NSManaged var samples: [Float]

  var configuration = WaveformLiveView.defaultConfiguration {
    didSet { contentsScale = configuration.scale }
  }

  var shouldDrawSilencePadding: Bool = false {
    didSet {
      waveformDrawer.shouldDrawSilencePadding = shouldDrawSilencePadding
      setNeedsDisplay()
    }
  }

  var renderer: WaveformRenderer = LinearWaveformRenderer() {
    didSet { setNeedsDisplay() }
  }

  private let waveformDrawer = WaveformImageDrawer()

  override class func needsDisplay(forKey key: String) -> Bool {
    if key == #keyPath(samples) {
      return true
    }
    return super.needsDisplay(forKey: key)
  }

  override func draw(in context: CGContext) {
    super.draw(in: context)

    UIGraphicsPushContext(context)
    waveformDrawer.draw(waveform: samples, on: context, with: configuration.with(size: bounds.size), renderer: renderer)
    UIGraphicsPopContext()
  }

  func add(_ newSamples: [Float]) {
    samples += newSamples
  }

  func reset() {
    samples = []
  }
}
