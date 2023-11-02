// Created with love by Igor Klyuzhev in 2023

import UIKit
import SwiftUI
import AVFoundation

final class ExampleController: UIViewController {

  private lazy var imageView = UIImageView()
  private lazy var waveformStubView = makeWaveformStubView()
  private let imageDrawer = WaveformImageDrawer()
  
  override func viewDidLoad() {
    super.viewDidLoad()

    view.addSubview(imageView)
    view.addSubview(waveformStubView)

    imageView.translatesAutoresizingMaskIntoConstraints = false
    waveformStubView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      imageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1),
      imageView.heightAnchor.constraint(equalToConstant: 100),
      imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),

      waveformStubView.topAnchor.constraint(equalTo: view.topAnchor, constant: 40),
      waveformStubView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      waveformStubView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      waveformStubView.heightAnchor.constraint(equalToConstant: 100)
    ])

    guard let fileUrl = Bundle.main.url(forResource: "sample_2.wav", withExtension: nil),
          let audioFile = try? AVAudioFile(forReading: fileUrl)
    else {
      Logger.log("Audio file not found")
      return
    }

    let currentAsset = AVURLAsset(url: fileUrl, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])

    imageView.contentMode = .scaleAspectFill
    imageDrawer.waveformImage(
      fromAudioAt: fileUrl,
      with: .init(
        size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height / 10),
        color: .white,
        accentColor: .red,
        backgroundColor: .clear,
        style: .striped,
        position: .middle,
        scale: 1,
        paddingFactor: 2,
        accentStartPoint: nil,
        accentEndPoint: nil
      )) { waveformImage in
        DispatchQueue.main.async {
          self.imageView.image = waveformImage
        }
      }
  }

  private func makeWaveformStubView() -> UIView {
    var view = UIView()
    let stubWaveformView = WaveformStubView()
    let host = UIHostingController(rootView: stubWaveformView)
    if let hostView = host.view {
      hostView.backgroundColor = .clear
      view = hostView
    }
    return view
  }
}
