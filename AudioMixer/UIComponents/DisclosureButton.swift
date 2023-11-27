// Created with love by Igor Klyuzhev in 2023

import SnapKit
import UIKit

final class DisclosureButton: UIControl {
  private lazy var chevronImageView = {
    let view = UIImageView()
    view.contentMode = .scaleAspectFit
    view.image = Asset.chevronUp.image
    view.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
    return view
  }()

  private lazy var title = {
    let label = UILabel()
    label.textColor = .black
    label.font = .systemFont(ofSize: 16, weight: .regular)
    return label
  }()

  var isOpened: Bool = false {
    didSet {
      guard isOpened != oldValue else { return }
      openStateChanged()
    }
  }

  var action: ((_ isOpened: Bool) -> Void)?

  init() {
    super.init(frame: .zero)
    setupUI()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setup(withText text: String) {
    title.text = text
  }

  private func setupUI() {
    smoothCornerRadius = .inset4
    backgroundColor = .white
    addTarget(self, action: #selector(handleTap), for: .touchUpInside)

    addSubviews(chevronImageView, title)

    chevronImageView.snp.makeConstraints { make in
      make.right.equalToSuperview().offset(-10)
      make.centerY.equalToSuperview()
      make.size.equalTo(CGSize(width: 12, height: 12))
    }

    title.snp.makeConstraints { make in
      make.left.top.equalToSuperview().offset(10)
      make.bottom.equalToSuperview().offset(-10)
      make.right.equalTo(chevronImageView).offset(-16)
    }
  }

  @objc
  private func handleTap() {
    isOpened.toggle()
  }

  private func openStateChanged() {
    UIView.animate(withDuration: 0.3) { [weak self] in
      guard let self else { return }
      chevronImageView.transform = isOpened ? .identity : CGAffineTransform(rotationAngle: CGFloat.pi)
      backgroundColor = isOpened ? .accentColor : .white
    }
    action?(isOpened)
  }
}
