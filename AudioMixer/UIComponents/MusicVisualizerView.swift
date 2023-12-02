// Created with love by Igor Klyuzhev in 2023

import SnapKit
import UIKit

final class MusicVisualizerView: UIView {
  private var animatingViews = [AnimatingView]()
  private let project: ProjectModel

  var shouldAnimate: Bool = false {
    didSet {
      if oldValue != shouldAnimate,
         shouldAnimate
      {
        updateAnimations()
      }
    }
  }

  init(project: ProjectModel) {
    self.project = project
    super.init(frame: .zero)
    setupUI()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupUI() {
    animatingViews = project.layers.map(AnimatingView.init)

    for view in animatingViews.map(\.view) {
      addSubview(view)

      view.snp.makeConstraints { make in
        make.size.equalTo(CGSize(width: 100, height: 100))
        make.center.equalToSuperview()
      }
      view.alpha = .zero
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
      self.updateAnimations()
    }
  }

  private func updateAnimations() {
    guard shouldAnimate else { return }
    for view in animatingViews {
      updateAnimation(for: view)
    }
  }

  private func translationValue(for size: CGSize) -> CGPoint {
    let screenBounds = UIScreen.main.bounds
    let activeHeight = screenBounds.height - safeAreaInsets.top - safeAreaInsets.bottom
    let activeWidth = screenBounds.width
    let maxX = activeWidth / 2 - size.width / 2
    let maxY = activeHeight / 2 - size.height / 2
    return CGPoint(
      x: CGFloat.random(in: -maxX ... maxX),
      y: CGFloat.random(in: -maxY ... maxY)
    )
  }

  private var scaleValue: CGPoint {
    let v = CGFloat.random(in: 0 ... 2)
    return CGPoint(
      x: v,
      y: v
    )
  }

  private var rotationValue: CGFloat {
    CGFloat.random(in: -CGFloat.pi ... CGFloat.pi)
  }

  private var alphaValue: CGFloat {
    CGFloat.random(in: 0 ... 1)
  }

  private var animationDurationValue: CGFloat {
    CGFloat.random(in: 2 ... 5)
  }

  private func updateAnimation(for view: AnimatingView) {
    guard shouldAnimate else { return }
    UIView.animate(
      withDuration: animationDurationValue,
      delay: .zero,
      options: .curveEaseInOut
    ) { [weak self] in
      guard let self else { return }
      let scale = scaleValue
      var size = view.size
      size.width *= scale.x
      size.height *= scale.y
      let translation = translationValue(for: size)
      view.view.transform = CGAffineTransform(
        translationX: translation.x,
        y: translation.y
      ).scaledBy(
        x: scale.x,
        y: scale.y
      ).rotated(
        by: rotationValue
      )

      view.view.alpha = alphaValue
    } completion: { [weak self] _ in
      self?.updateAnimation(for: view)
    }
  }
}

struct AnimatingView {
  let view: UIView
  let layer: LayerModel
  let size: CGSize

  init(view: UIView, layer: LayerModel, size: CGSize) {
    self.view = view
    self.layer = layer
    self.size = size
  }

  init(layer: LayerModel) {
    let view = UIImageView()
    let image = layer.sampleType.shapeImage
    view.image = image
    view.contentMode = .scaleAspectFit
    self.init(view: view, layer: layer, size: image.size)
  }
}

protocol MusicVisualizerAudioControlling {
  var isStreaming: Bool { get }

  func play()
  func pause()
  func seek(to time: CGFloat)
}
