// Created with love by Igor Klyuzhev in 2023

import Combine
import Foundation

public final class CancellableBag {
  private var cancellables = [AnyCancellable]()

  public init() {}

  deinit {
    drain()
  }

  public func add(_ cancellable: AnyCancellable) {
    cancellables.append(cancellable)
  }

  public func drain() {
    for cancellable in cancellables {
      cancellable.cancel()
    }
    cancellables.removeAll()
  }
}

extension AnyCancellable {
  @discardableResult
  public func store(in bag: CancellableBag) -> AnyCancellable {
    bag.add(self)
    return self
  }
}
