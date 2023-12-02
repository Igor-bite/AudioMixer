// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif
#if canImport(SwiftUI)
  import SwiftUI
#endif

// Deprecated typealiases
@available(*, deprecated, renamed: "ImageAsset.Image", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetImageTypeAlias = ImageAsset.Image

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
internal enum Asset {
  internal enum Shapes {
    internal static let circleFilled = ImageAsset(name: "Shapes/circle-filled")
    internal static let circleOutline = ImageAsset(name: "Shapes/circle-outline")
    internal static let curl1 = ImageAsset(name: "Shapes/curl-1")
    internal static let curl2 = ImageAsset(name: "Shapes/curl-2")
    internal static let curl3 = ImageAsset(name: "Shapes/curl-3")
    internal static let dots = ImageAsset(name: "Shapes/dots")
    internal static let linesDiagonal = ImageAsset(name: "Shapes/lines-diagonal")
    internal static let linesHorizontal = ImageAsset(name: "Shapes/lines-horizontal")
    internal static let linesStrange = ImageAsset(name: "Shapes/lines-strange")
    internal static let sunFilled = ImageAsset(name: "Shapes/sun-filled")
    internal static let sunOutline = ImageAsset(name: "Shapes/sun-outline")
    internal static let sun = ImageAsset(name: "Shapes/sun")
    internal static let tetraedrFilled = ImageAsset(name: "Shapes/tetraedr-filled")
    internal static let tetraedrGreen = ImageAsset(name: "Shapes/tetraedr-green")
    internal static let tetraedrWhite = ImageAsset(name: "Shapes/tetraedr-white")
  }

  internal static let chevronUp = ImageAsset(name: "chevron_up")
  internal static let cross = ImageAsset(name: "cross")
  internal static let downloadArrow = ImageAsset(name: "download_arrow")
  internal static let drums = ImageAsset(name: "drums")
  internal static let guitar = ImageAsset(name: "guitar")
  internal static let launchScreenImage = ImageAsset(name: "launch_screen_image")
  internal static let microphone = ImageAsset(name: "microphone")
  internal static let pause = ImageAsset(name: "pause")
  internal static let play = ImageAsset(name: "play")
  internal static let recordCircle = ImageAsset(name: "record_circle")
  internal static let trumpet = ImageAsset(name: "trumpet")
  internal static let volumeOff = ImageAsset(name: "volume_off")
  internal static let volumeOn = ImageAsset(name: "volume_on")
}

// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

internal struct ImageAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
    internal typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
    internal typealias Image = UIImage
  #endif

  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, macOS 10.7, *)
  internal var image: Image {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
      let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
      let name = NSImage.Name(self.name)
      let image = (bundle == .main) ? NSImage(named: name) : bundle.image(forResource: name)
    #elseif os(watchOS)
      let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }

  #if os(iOS) || os(tvOS)
    @available(iOS 8.0, tvOS 9.0, *)
    internal func image(compatibleWith traitCollection: UITraitCollection) -> Image {
      let bundle = BundleToken.bundle
      guard let result = Image(named: name, in: bundle, compatibleWith: traitCollection) else {
        fatalError("Unable to load image asset named \(name).")
      }
      return result
    }
  #endif

  #if canImport(SwiftUI)
    @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
    internal var swiftUIImage: SwiftUI.Image {
      SwiftUI.Image(asset: self)
    }
  #endif
}

extension ImageAsset.Image {
  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, *)
  @available(macOS, deprecated,
             message: "This initializer is unsafe on macOS, please use the ImageAsset.image property")
  internal convenience init?(asset: ImageAsset) {
    #if os(iOS) || os(tvOS)
      let bundle = BundleToken.bundle
      self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
      self.init(named: NSImage.Name(asset.name))
    #elseif os(watchOS)
      self.init(named: asset.name)
    #endif
  }
}

#if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  extension SwiftUI.Image {
    internal init(asset: ImageAsset) {
      let bundle = BundleToken.bundle
      self.init(asset.name, bundle: bundle)
    }

    internal init(asset: ImageAsset, label: Text) {
      let bundle = BundleToken.bundle
      self.init(asset.name, bundle: bundle, label: label)
    }

    internal init(decorative asset: ImageAsset) {
      let bundle = BundleToken.bundle
      self.init(decorative: asset.name, bundle: bundle)
    }
  }
#endif

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
      return Bundle.module
    #else
      return Bundle(for: BundleToken.self)
    #endif
  }()
}

// swiftlint:enable convenience_type
