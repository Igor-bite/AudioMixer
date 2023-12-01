// Created with love by Igor Klyuzhev in 2023

import SnapKit
import UIKit

final class WaveformScrollingView: UIView {
  private lazy var waveFormView = {
    let view = WaveformImageView(frame: .zero)
    view.imageDidSet = { [weak self] image in
      view.frame.size = image.size
      self?.waveFormScrollView.contentSize = image.size
    }
    return view
  }()

  private lazy var waveFormScrollView = {
    let view = UIScrollView()
    view.contentInset = Constants.waveformScrollInsets
    view.showsHorizontalScrollIndicator = false
    view.showsVerticalScrollIndicator = false
    return view
  }()

  private lazy var displayLink = createDisplayLink(.common)
  private var previousProgress: Double = -1
  private var showingLayer: LayerModel?

  private let audioMixer: AudioMixer
  private let waveformImageDrawer = WaveformImageDrawer()

  init(
    audioMixer: AudioMixer
  ) {
    self.audioMixer = audioMixer
    super.init(frame: .zero)
    setupUI()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupUI() {
    addSubview(waveFormScrollView)
    waveFormScrollView.addSubview(waveFormView)

    waveFormScrollView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }

  func showWaveform(for layer: LayerModel) {
    showingLayer = layer
    previousProgress = -1
    let displayLink = displayLink
    displayLink.isPaused = false
    let waveformWidth = layer.waveformWidth
    let size = CGSize(width: waveformWidth, height: Constants.waveformHeight)
    waveFormView.frame.size = size
    waveFormView.configuration = Waveform.Configuration(
      size: size,
      backgroundColor: .clear,
      style: .striped(
        Waveform.Style.StripeConfig(
          color: .white,
          width: 2,
          spacing: 2,
          lineCap: .round
        )
      ),
      verticalScalingFactor: Constants.koeff,
      shouldAntialias: true
    )
    waveFormView.reset()
    waveFormView.waveformAudioURL = layer.audioFileUrl
  }

  func hideWaveform() {
    showingLayer = nil
    waveFormView.reset()
    displayLink.isPaused = true
  }

  @objc
  private func updateWaveformProgress(_ progress: CGFloat) {
    guard let settingsChangingLayer = showingLayer,
          audioMixer.isLayerPlaying(settingsChangingLayer)
    else { return }
    let duration = audioMixer.playedTime(settingsChangingLayer)
    let progress = duration / settingsChangingLayer.duration
    guard previousProgress != progress else { return }
    previousProgress = progress
    waveFormView.progress = progress
    let contentSize = waveFormScrollView.contentSize
    guard contentSize.width > UIScreen.main.bounds.width - 32 else {
      waveFormScrollView.contentInset.left = UIScreen.main.bounds.width / 2 - contentSize.width / 2
      return
    }
    waveFormScrollView.contentInset.left = 16
    let offset = contentSize.width * progress
    waveFormScrollView.contentOffset.x = max(-16, offset - UIScreen.main.bounds.width / 2)
  }

  private func createDisplayLink(_ mode: RunLoop.Mode) -> CADisplayLink {
    let displayLink = CADisplayLink(target: self, selector: #selector(updateWaveformProgress))
    displayLink.preferredFrameRateRange = CAFrameRateRange(
      minimum: 60,
      maximum: Float(UIScreen.main.maximumFramesPerSecond),
      preferred: Float(UIScreen.main.maximumFramesPerSecond)
    )
    displayLink.add(to: .current, forMode: mode)
    displayLink.isPaused = true
    return displayLink
  }
}

fileprivate enum Constants {
  static let waveformHeight = 48 * koeff
  static let koeff = 0.8
  static let waveformScrollInsets = UIEdgeInsets(
    top: .zero,
    left: 16,
    bottom: .zero,
    right: 16
  )
}
