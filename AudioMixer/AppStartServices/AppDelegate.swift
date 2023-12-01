// Created with love by Igor Klyuzhev in 2023

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?
  private let screenAssembly = ScreenAssembly()

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    window = UIWindow(frame: UIScreen.main.bounds)
    guard let window = window else { return false }

    let initialController = screenAssembly.rootNavigationController
    let projectsList = screenAssembly.makeProjectsList()
    projectsList.start()

    window.rootViewController = initialController
    window.makeKeyAndVisible()

    return true
  }
}
