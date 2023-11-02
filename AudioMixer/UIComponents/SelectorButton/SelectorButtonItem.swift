// Created with love by Igor Klyuzhev in 2023

import SnapKit
import UIKit

final class SelectorButtonItem: UIView {
  private let label = {
    let view = UILabel()
    view.adjustsFontSizeToFitWidth = true
    view.textAlignment = .center
    view.clipsToBounds = true
    return view
  }()

  private let backgroundGradient = CAGradientLayer()

  var itemIndex: Int?

  override init(frame: CGRect = .zero) {
    super.init(frame: frame)
    setup()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    backgroundGradient.frame = bounds
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(with text: String, textColor: UIColor, itemIndex: Int) {
    label.text = text
    label.textColor = textColor
    self.itemIndex = itemIndex
  }

  func didSelect() {
    animateGradient(to: 1)
  }

  func shouldDeselect() {
    animateGradient(to: 0)
  }

  private func setup() {
    setupGradient()
    addSubview(label)
    label.snp.makeConstraints { make in
      make.top.bottom.equalToSuperview()
      make.leading.equalToSuperview().offset(8)
      make.trailing.equalToSuperview().inset(8)
    }
    snp.makeConstraints { make in
      make.height.equalTo(Constants.height)
    }
  }

  private func animateGradient(to opacity: Float) {
    UIView.animate(
      withDuration: 0.1
    ) { [weak self] in
      self?.backgroundGradient.opacity = opacity
    }
  }

  private func setupGradient() {
    layer.addSublayer(backgroundGradient)
    backgroundGradient.colors = Constants.gradientColors.map { $0.cgColor }
    backgroundGradient.startPoint = .init(x: 0.5, y: 0)
    backgroundGradient.endPoint = .init(x: 0.5, y: 1)
    backgroundGradient.locations = [0, 0.26, 0.76, 1]

    backgroundGradient.opacity = .zero
  }
}

fileprivate enum Constants {
  static let gradientColors: [UIColor] = [
    .white.withAlphaComponent(.zero),
    .white,
    .white,
    .white.withAlphaComponent(.zero),
  ]
  static let height = 36.0
}
