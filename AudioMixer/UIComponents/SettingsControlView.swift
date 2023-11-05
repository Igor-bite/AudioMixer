// Created with love by Igor Klyuzhev in 2023

import SnapKit
import UIKit

final class SettingsControlView: UIView {
  private var layerModel: LayerModel?
  private let audioController: AudioControlling
  private let feedbackGenerator = UISelectionFeedbackGenerator()

  var touchLocation: CGPoint = .zero

  private lazy var gradient = GradientView(colors: [
    Constants.gradientColor.withAlphaComponent(0),
    Constants.gradientColor,
  ])

  private lazy var hRuler = RulerView(
    defaultDistance: Constants.hRulerDefaultDistance,
    type: .horizontal,
    shouldDecrease: true
  )
  private lazy var vRuler = RulerView(
    defaultDistance: Constants.vRulerDefaultDistance,
    type: .vertical,
    shouldDecrease: false,
    longStickIndex: Constants.longStickIndex
  )

  private lazy var vButton = makeButton(
    with: "громкость",
    rotation: Constants.verticalButtonRotation
  )
  private lazy var hButton = makeButton(with: "скорость")

  private var width: CGFloat {
    bounds.width
  }

  private var halfWidth: CGFloat {
    width / 2
  }

  private var height: CGFloat {
    bounds.height
  }

  private var halfHeight: CGFloat {
    height / 2
  }

  init(audioController: AudioControlling) {
    self.audioController = audioController
    super.init(frame: .zero)
    setupUI()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(with layer: LayerModel) {
    self.layerModel = layer
    convertSettingsToLocation()
  }

  private func setupUI() {
    addSubviews(gradient, hRuler, vRuler, hButton, vButton)

    gradient.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }

    hRuler.snp.makeConstraints { make in
      make.right.bottom.equalToSuperview()
      make.left.equalToSuperview().offset(Constants.rulerEdgeInset)
      make.height.equalTo(Constants.rulerHeight)
    }

    vRuler.snp.makeConstraints { make in
      make.left.top.equalToSuperview()
      make.bottom.equalToSuperview().offset(-Constants.rulerEdgeInset)
      make.width.equalTo(Constants.rulerHeight)
    }

    hButton.snp.makeConstraints { make in
      make.width.equalTo(Constants.controlButtonWidth)
      make.height.equalTo(Constants.controlButtonHeight)
      make.centerX.bottom.equalToSuperview()
    }

    vButton.snp.makeConstraints { make in
      make.width.equalTo(Constants.controlButtonWidth)
      make.height.equalTo(Constants.controlButtonHeight)
      make.centerX.equalTo(snp.left).offset(Constants.controlButtonHeight / 2)
      make.centerY.equalToSuperview()
    }
  }

  private func makeButton(
    with title: String,
    rotation: CGFloat? = nil
  ) -> UIButton {
    let button = UIButton()
    button.clipsToBounds = true
    self.clipsToBounds = true
    let title = NSAttributedString(
      string: title,
      attributes: [
        .foregroundColor: UIColor.black,
        .font: UIFont.systemFont(ofSize: Constants.controlButtonFontSize),
      ]
    )
    button.setAttributedTitle(title, for: .normal)
    button.backgroundColor = .accentColor
    button.smoothCornerRadius = .inset4
    if let rotation {
      button.transform = CGAffineTransform(rotationAngle: rotation)
    }
    return button
  }

  private func convertSettingsToLocation() {
    guard let layerModel else { return }

    let volume = audioController.volume(for: layerModel)
    let touchLocaionY = touchY(for: CGFloat(volume))

    let rate = audioController.rate(for: layerModel)
    let touchLocationX = touchX(for: CGFloat(rate))

    touchLocation = CGPoint(x: touchLocationX, y: touchLocaionY)
    updateButtonsLocation(animated: true)
  }

  private func touchY(for verticalValue: CGFloat) -> CGFloat {
    let isTouchBelowCenter = verticalValue <= Constants.Volume.centerValue
    let maxValue: CGFloat
    let minValue: CGFloat

    let fromValue: CGFloat
    let toValue: CGFloat

    if isTouchBelowCenter {
      maxValue = halfHeight
      minValue = Constants.rulerEdgeInset

      fromValue = Constants.Volume.minValue
      toValue = Constants.Volume.centerValue
    } else {
      maxValue = height
      minValue = halfHeight

      fromValue = Constants.Volume.centerValue
      toValue = Constants.Volume.maxValue
    }

    return CGFloat(
      verticalValue.normalize(
        min: fromValue,
        max: toValue,
        from: minValue,
        to: maxValue
      )
    )
  }

  private func touchX(for horizontalValue: CGFloat) -> CGFloat {
    let isTouchOnRight = horizontalValue >= Constants.Rate.centerValue
    let maxValue: CGFloat
    let minValue: CGFloat

    let fromValue: CGFloat
    let toValue: CGFloat

    if isTouchOnRight {
      maxValue = width
      minValue = halfWidth
      fromValue = Constants.Rate.centerValue
      toValue = Constants.Rate.maxValue
    } else {
      maxValue = halfWidth
      minValue = Constants.rulerEdgeInset
      fromValue = Constants.Rate.minValue
      toValue = Constants.Rate.centerValue
    }

    return CGFloat(
      horizontalValue.normalize(
        min: fromValue,
        max: toValue,
        from: minValue,
        to: maxValue
      )
    )
  }

  private func updateButtonsLocation(animated: Bool = false) {
    let hButtonX = clamp(
      touchLocation.x - halfWidth,
      min: -halfWidth + Constants.controlButtonWidth / 2 + Constants.controlButtonHeight,
      max: halfWidth - Constants.controlButtonWidth / 2
    )
    let vButtonY = clamp(
      height - touchLocation.y - halfHeight,
      min: -halfHeight + Constants.controlButtonWidth / 2 + Constants.controlButtonHeight,
      max: halfHeight - Constants.controlButtonWidth / 2
    )

    let applyTransform = { [weak self] in
      self?.hButton.transform = CGAffineTransform(
        translationX: hButtonX,
        y: .zero
      )

      self?.vButton.transform = CGAffineTransform(
        translationX: .zero,
        y: -vButtonY
      ).rotated(by: Constants.verticalButtonRotation)
    }

    if animated {
      UIView.animate(withDuration: 0.2) {
        applyTransform()
      }
    } else {
      applyTransform()
    }
  }

  private func updateSettings() {
    updateVolume()
    updateSpeed()
  }

  private func updateVolume() {
    let touchLocationY: CGFloat = height - touchLocation.y
    let isTouchBelowCenter = touchLocationY <= halfHeight
    let maxValue: CGFloat
    let minValue: CGFloat

    let fromValue: CGFloat
    let toValue: CGFloat

    if isTouchBelowCenter {
      maxValue = halfHeight
      minValue = Constants.rulerEdgeInset

      fromValue = Constants.Volume.minValue
      toValue = Constants.Volume.centerValue
    } else {
      maxValue = height
      minValue = halfHeight

      fromValue = Constants.Volume.centerValue
      toValue = Constants.Volume.maxValue
    }

    var volume = max(minValue, touchLocationY)
    volume = volume.normalize(
      min: minValue,
      max: maxValue,
      from: fromValue,
      to: toValue
    )
    guard let layerModel else { return }
    audioController.setVolume(
      for: layerModel,
      volume: Float(volume)
    )
  }

  private func updateSpeed() {
    let isTouchOnRight = touchLocation.x >= halfWidth
    let touchLocationX: CGFloat = touchLocation.x
    let maxValue: CGFloat
    let minValue: CGFloat

    let fromValue: CGFloat
    let toValue: CGFloat

    if isTouchOnRight {
      maxValue = width
      minValue = halfWidth
      fromValue = Constants.Rate.centerValue
      toValue = Constants.Rate.maxValue
    } else {
      maxValue = halfWidth
      minValue = Constants.rulerEdgeInset
      fromValue = Constants.Rate.minValue
      toValue = Constants.Rate.centerValue
    }

    var rate = max(minValue, touchLocationX)
    rate = rate.normalize(min: minValue, max: maxValue, from: fromValue, to: toValue)
    guard let layerModel else { return }
    audioController.setRate(for: layerModel, rate: Float(rate))
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    let location = touches.first?.location(in: self) ?? .zero
    if point(inside: location, with: event) {
      feedbackGenerator.selectionChanged()
      touchLocation = location
      updateSettings()
      updateButtonsLocation()
    }
  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    let location = touches.first?.location(in: self) ?? .zero
    if point(inside: location, with: event) {
      touchLocation = location
      updateSettings()
      updateButtonsLocation()
    }
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    let location = touches.first?.location(in: self) ?? .zero
    if point(inside: location, with: event) {
      feedbackGenerator.selectionChanged()
    }
  }
}

fileprivate enum Constants {
  static let gradientColor = UIColor(red: 0.353, green: 0.314, blue: 0.886, alpha: 1)
  static let hRulerDefaultDistance = 9.0
  static let vRulerDefaultDistance = 11.0
  static let longStickIndex = 6
  static let verticalButtonRotation = -CGFloat.pi / 2
  static let rulerEdgeInset = 32.0
  static let rulerHeight = 14.0
  static let controlButtonWidth = 60.0
  static let controlButtonHeight = rulerHeight
  static let controlButtonFontSize = 11.0

  enum Volume {
    static let minValue = 0.0
    static let centerValue = 1.0
    static let maxValue = 10.0
  }

  enum Rate {
    static let minValue: CGFloat = 1 / 32
    static let centerValue = 1.0
    static let maxValue = 32.0
  }

  enum Pan {
    static let minValue = -1.0
    static let centerValue = 0.0
    static let maxValue = 1.0
  }

  enum Pitch {
    static let minValue = -2400.0
    static let centerValue = 0.0
    static let maxValue = 2400.0
  }
}
