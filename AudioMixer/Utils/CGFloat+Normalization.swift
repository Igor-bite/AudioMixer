// Created with love by Igor Klyuzhev in 2023

import Foundation

extension BinaryFloatingPoint {
  func normalize(min: Self, max: Self, from a: Self = 0, to b: Self = 1) -> Self {
    (b - a) * ((self - min) / (max - min)) + a
  }
}
