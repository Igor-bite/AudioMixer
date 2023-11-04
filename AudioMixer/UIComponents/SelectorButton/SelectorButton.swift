// Created with love by Igor Klyuzhev in 2023

import SnapKit
import UIKit

final class SelectorButton: UIView {
  struct Model {
    struct Item {
      let title: String
    }

    let title: String
    let image: UIImage
    let closedBackgroundColor: UIColor
    let openedBackgroundColor: UIColor
    let selectedItemBackgroundColor: UIColor
    let itemTextColor: UIColor
    let items: [Item]
    let tapAction: Action
    let closeWithoutSelectionAction: Action
    let hoverAction: (_ itemIndex: Int?) -> Void
    let selectAction: (_ itemIndex: Int) -> Void
  }

  private let iconView = {
    let view = UIImageView()
    view.contentMode = .scaleAspectFit
    view.clipsToBounds = false
    return view
  }()

  private let title = {
    let view = UILabel()
    view.textAlignment = .center
    view.clipsToBounds = false
    return view
  }()

  private let backgroundView = {
    let view = UIView()
    view.layer.cornerRadius = Constants.cornerRadius
    return view
  }()

  private let itemsStackContainer = {
    let view = UIView()
    view.clipsToBounds = true
    view.isUserInteractionEnabled = true
    return view
  }()

  private let itemsStack = {
    let view = UIStackView()
    view.axis = .vertical
    view.spacing = .zero
    view.distribution = .equalSpacing
    view.isUserInteractionEnabled = true
    return view
  }()

  private var selectedItem: SelectorButtonItem?
  private let model: Model
  private var heightConstraint: ConstraintMakerEditable?

  init(model: Model) {
    self.model = model
    super.init(frame: .zero)
    setupUI()
    setupColors()
    setupGestures()
    setupModelData()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupModelData() {
    iconView.image = model.image
    title.text = model.title
    for (index, item) in model.items.enumerated() {
      addItem(item, index: index)
    }
  }

  private func addItem(_ item: Model.Item, index: Int) {
    let selectorItem = SelectorButtonItem()
    selectorItem.alpha = .zero
    selectorItem.configure(with: item.title, textColor: model.itemTextColor, itemIndex: index)
    selectorItem.isUserInteractionEnabled = true
    itemsStack.addArrangedSubview(selectorItem)
    selectorItem.snp.makeConstraints { make in
      make.width.equalToSuperview()
    }
  }

  private func setupUI() {
    addSubviews(title, backgroundView)
    backgroundView.addSubviews(iconView, itemsStackContainer)
    itemsStackContainer.addSubview(itemsStack)

    iconView.snp.makeConstraints { make in
      make.top.leading.trailing.equalToSuperview()
      make.height.equalTo(backgroundView.snp.width)
    }

    itemsStackContainer.snp.makeConstraints { make in
      make.leading.trailing.equalToSuperview()
      make.bottom.equalToSuperview().inset(Constants.size.height / 2)
      make.top.equalTo(iconView.snp.bottom).offset(8)
    }

    itemsStack.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }

    backgroundView.snp.makeConstraints { make in
      make.width.equalTo(Constants.size.width)
      self.heightConstraint = make.height.equalTo(Constants.size.height)
      make.leading.trailing.top.equalToSuperview()
    }

    title.snp.makeConstraints { make in
      make.top.equalTo(iconView.snp.bottom).offset(8)
      make.bottom.equalToSuperview()
      make.leading.equalToSuperview().offset(-12)
      make.trailing.equalToSuperview().offset(12)
    }
  }

  private func setupColors() {
    backgroundView.backgroundColor = model.closedBackgroundColor
    iconView.tintColor = .black
    title.textColor = .white
  }

  private func setupGestures() {
    isUserInteractionEnabled = true

    let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongTap))
    longPressGestureRecognizer.cancelsTouchesInView = false
    addGestureRecognizer(longPressGestureRecognizer)

    let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
    tapGestureRecognizer.cancelsTouchesInView = false
    addGestureRecognizer(tapGestureRecognizer)
  }

  @objc
  private func handleLongTap(sender: UILongPressGestureRecognizer) {
    switch sender.state {
    case .began:
      setState(true)
    case .ended, .cancelled, .failed:
      let point = sender.location(in: self)
      if let view = itemsStack.hitTest(convert(point, to: itemsStack), with: nil) as? SelectorButtonItem {
        guard let itemIndex = view.itemIndex else { return }
        model.selectAction(itemIndex)
        selectedItem?.shouldDeselect()
      } else {
        model.closeWithoutSelectionAction()
      }
      setState(false)
    case .changed:
      let point = sender.location(in: self)
      if !self.point(inside: point, with: nil) {
        setState(false)
        model.closeWithoutSelectionAction()
      }
      if let view = itemsStack.hitTest(convert(point, to: itemsStack), with: nil) as? SelectorButtonItem {
        guard selectedItem != view else { return }
        selectedItem?.shouldDeselect()
        view.didSelect()
        selectedItem = view
        guard let itemIndex = view.itemIndex else { return }
        model.hoverAction(itemIndex)
      } else {
        selectedItem?.shouldDeselect()
        selectedItem = nil
        model.hoverAction(nil)
      }
    default:
      break
    }
  }

  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    backgroundView.point(inside: point, with: event)
  }

  @objc
  private func handleTap() {
    model.tapAction()
    showOpening()
  }

  private func setState(_ isOpened: Bool) {
    if isOpened {
      open()
    } else {
      close()
    }
    animateItems(isOpened)
  }

  private func open() {
    UIView.animate(
      withDuration: 0.3,
      delay: .zero,
      options: .curveEaseInOut
    ) { [weak self] in
      guard let self else { return }
      title.alpha = 0
      backgroundView.backgroundColor = model.openedBackgroundColor
      let itemsHeight = CGFloat(model.items.count) * 36.0
      heightConstraint?.constraint.update(
        offset: Constants.size.height + itemsHeight + Constants.size.height / 2 + 8
      )
      layoutSubviews()
    } completion: { _ in }
  }

  private func close() {
    UIView.animate(
      withDuration: 0.3,
      delay: .zero,
      options: .curveEaseInOut
    ) { [weak self] in
      guard let self else { return }
      title.alpha = 1
      backgroundView.backgroundColor = model.closedBackgroundColor
      heightConstraint?.constraint.update(offset: Constants.size.height)
      layoutSubviews()
    } completion: { _ in }
  }

  private func animateItems(_ isShowing: Bool) {
    guard isShowing else {
      itemsStack.arrangedSubviews.forEach { $0.alpha = .zero }
      return
    }
    var delay = 0.0
    for itemView in itemsStack.arrangedSubviews {
      UIView.animate(
        withDuration: 0.15,
        delay: delay,
        options: .curveEaseIn,
        animations: {
          itemView.alpha = 1
        },
        completion: nil
      )
      delay += 0.1
    }
  }

  private func showOpening() {
    UIView.animate(
      withDuration: 0.15,
      delay: .zero,
      options: .curveEaseInOut
    ) { [weak self] in
      guard let self else { return }
      backgroundView.backgroundColor = model.openedBackgroundColor
      heightConstraint?.constraint.update(offset: Constants.size.height + Constants.openingOffset)
      layoutSubviews()
    } completion: { [weak self] _ in
      UIView.animate(
        withDuration: 0.15,
        delay: .zero,
        options: .curveEaseInOut
      ) {
        guard let self else { return }
        self.backgroundView.backgroundColor = self.model.closedBackgroundColor
        self.heightConstraint?.constraint.update(offset: Constants.size.height)
        self.layoutSubviews()
      }
    }
  }
}

fileprivate enum Constants {
  static let size = CGSize(width: 64, height: 64)
  static let cornerRadius = size.width / 2
  static let openingOffset: CGFloat = .inset24
}
