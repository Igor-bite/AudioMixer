// Copyright 2023 ZEN. All rights reserved.

import Foundation

final class WeakHolder: Hashable {
  weak var object: AnyObject?

  init(_ object: AnyObject) {
    self.object = object
  }

  func hash(into hasher: inout Hasher) {
    guard let object else { return }
    hasher.combine(ObjectIdentifier(object))
  }

  static func == (lhs: WeakHolder, rhs: WeakHolder) -> Bool {
    guard let lhsObject = lhs.object,
          let rhsObject = rhs.object
    else { return true }
    return ObjectIdentifier(lhsObject) == ObjectIdentifier(rhsObject)
  }
}
