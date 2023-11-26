// Created with love by Igor Klyuzhev in 2023

import UIKit

protocol AlertPresenting {
  func showAlert(
    title: String,
    message: String,
    style: UIAlertController.Style,
    actions: [UIAlertAction]
  )

  func showAlert(
    title: String,
    message: String,
    style: UIAlertController.Style,
    actions: [UIAlertAction],
    animated: Bool
  )

  func showAlert(
    title: String,
    message: String,
    style: UIAlertController.Style,
    actions: [UIAlertAction],
    completion: (() -> Void)?
  )

  func showAlert(
    title: String,
    message: String,
    style: UIAlertController.Style,
    actions: [UIAlertAction],
    animated: Bool,
    completion: (() -> Void)?
  )
}

extension AlertPresenting {
  func showAlert(
    title: String,
    message: String,
    style: UIAlertController.Style,
    actions: [UIAlertAction]
  ) {
    self.showAlert(
      title: title,
      message: message,
      style: style,
      actions: actions,
      animated: true,
      completion: nil
    )
  }

  func showAlert(
    title: String,
    message: String,
    style: UIAlertController.Style,
    actions: [UIAlertAction],
    animated: Bool
  ) {
    self.showAlert(
      title: title,
      message: message,
      style: style,
      actions: actions,
      animated: animated,
      completion: nil
    )
  }

  func showAlert(
    title: String,
    message: String,
    style: UIAlertController.Style,
    actions: [UIAlertAction],
    completion: (() -> Void)?
  ) {
    self.showAlert(
      title: title,
      message: message,
      style: style,
      actions: actions,
      animated: true,
      completion: completion
    )
  }
}

final class AlertPresenter: AlertPresenting {
  private let presentingViewController: UIViewController

  init(presentingViewController: UIViewController) {
    self.presentingViewController = presentingViewController
  }

  func showAlert(
    title: String,
    message: String,
    style: UIAlertController.Style,
    actions: [UIAlertAction],
    animated: Bool,
    completion: (() -> Void)?
  ) {
    let alertController = UIAlertController(
      title: title,
      message: message,
      preferredStyle: style
    )

    actions.forEach(alertController.addAction)

    presentingViewController.present(
      alertController,
      animated: animated,
      completion: completion
    )
  }
}
