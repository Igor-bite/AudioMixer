// Created with love by Igor Klyuzhev in 2023

import AVFoundation
import SnapKit
import UIKit

public class WaveformImageView: UIImageView {
  private let waveformImageDrawer: WaveformImageDrawer

  public var configuration: Waveform.Configuration

  public var waveformAudioURL: URL? {
    didSet { updateWaveform() }
  }

  override public var image: UIImage? {
    didSet {
      guard let image else { return }
      imageDidSet?(image)
      progressView.frame.size = image.size
      progressView.image = image.withRenderingMode(.alwaysTemplate)
      if let progress {
        updateProgress(progress)
      }
    }
  }

  public var imageDidSet: ((UIImage) -> Void)?

  public var progress: CGFloat? {
    didSet {
      progressView.frame = frame
      if let progress {
        updateProgress(progress)
      }
    }
  }

  override public var frame: CGRect {
    didSet {
      progressView.frame = frame
    }
  }

  private lazy var progressView: UIImageView = {
    let view = UIImageView()
    view.contentMode = .scaleAspectFit
    view.tintColor = .accentColor
    return view
  }()

  override public init(frame: CGRect) {
    configuration = Waveform.Configuration(size: frame.size)
    waveformImageDrawer = WaveformImageDrawer()
    super.init(frame: frame)
    progressView.frame = frame
    addSubview(progressView)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func layoutSubviews() {
    super.layoutSubviews()
//    if progress != nil {
//      progressView.frame = frame
//    }
//    updateWaveform()
  }

  public func reset() {
    waveformAudioURL = nil
    image = nil
  }

  private func updateProgress(_ progress: CGFloat) {
    let fullRect = bounds
    let newWidth = Double(fullRect.size.width) * progress

    let maskLayer = CAShapeLayer()
    let maskRect = CGRect(x: 0.0, y: 0.0, width: newWidth, height: Double(fullRect.size.height))

    let path = CGPath(rect: maskRect, transform: nil)
    maskLayer.path = path

    progressView.layer.mask = maskLayer
  }
}

extension WaveformImageView {
  fileprivate func updateWaveform() {
    guard let audioURL = waveformAudioURL else { return }

    Task {
      do {
        let image = try await waveformImageDrawer.waveformImage(
          fromAudioAt: audioURL,
          with: configuration.with(size: bounds.size),
          qos: .userInteractive
        )

        await MainActor.run {
          self.image = image
        }
      } catch {
        print("Error occurred during waveform image creation:")
        print(error)
      }
    }
  }
}
