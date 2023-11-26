// Created with love by Igor Klyuzhev in 2023

import Foundation

enum Logger {
  static func log(_ error: Error) {
    print("LOG: ERROR -> \(error.localizedDescription)")
  }

  static func log(_ str: String) {
    print("LOG: ERROR -> \(str)")
  }
}
