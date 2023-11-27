// Created with love by Igor Klyuzhev in 2023

import UIKit

final class FeedbackGenerator {
  private static let selectionFeedbackGenerator = UISelectionFeedbackGenerator()

  static func selectionChanged() {
    selectionFeedbackGenerator.prepare()
    selectionFeedbackGenerator.selectionChanged()
  }
}
