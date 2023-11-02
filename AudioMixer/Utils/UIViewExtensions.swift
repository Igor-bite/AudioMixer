// Created with love by Igor Klyuzhev in 2023

import UIKit

extension UIView {
  public func forceLayout() {
    setNeedsLayout()
    layoutIfNeeded()
  }

  public func addSubviews(_ views: [UIView]) {
    for view in views { addSubview(view) }
  }

  public func addSubviews(_ views: UIView...) {
    for view in views { addSubview(view) }
  }

  public var smoothCornerRadius: CGFloat {
    get {
      layer.cornerRadius
    }
    set {
      layer.cornerRadius = newValue
      layer.cornerCurve = .continuous
    }
  }
}
