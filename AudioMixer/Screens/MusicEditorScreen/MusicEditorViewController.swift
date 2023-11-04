// Created with love by Igor Klyuzhev in 2023

import SnapKit
import UIKit

final class MusicEditorViewController: UIViewController {
  override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

  private let audioMixer = AudioMixer()
  private var previewLayerPlaying: LayerModel?

  private lazy var guitarSelector = SelectorButton(model: SelectorButton.Model(
    title: "гитара",
    image: Asset.guitar.image,
    closedBackgroundColor: .white,
    openedBackgroundColor: UIColor(red: 0.66, green: 0.858, blue: 0.064, alpha: 1),
    selectedItemBackgroundColor: .white,
    itemTextColor: .black,
    items: [
      .init(title: "сэмпл 1"),
      .init(title: "сэмпл 2"),
      .init(title: "сэмпл 3"),
      .init(title: "сэмпл 4"),
      .init(title: "сэмпл 5"),
    ],
    tapAction: guitarTapped,
    hoverAction: { [weak self] index in
      self?.playSample(index: index)
    },
    selectAction: { [weak self] index in
      self?.sampleSelected(at: index)
    }
  ))

  private lazy var drumsSelector = SelectorButton(model: SelectorButton.Model(
    title: "ударные",
    image: Asset.drums.image,
    closedBackgroundColor: .white,
    openedBackgroundColor: UIColor(red: 0.66, green: 0.858, blue: 0.064, alpha: 1),
    selectedItemBackgroundColor: .white,
    itemTextColor: .black,
    items: [
      .init(title: "сэмпл 1"),
      .init(title: "сэмпл 2"),
      .init(title: "сэмпл 3"),
      .init(title: "сэмпл 4"),
      .init(title: "сэмпл 5"),
    ],
    tapAction: guitarTapped,
    hoverAction: { _ in },
    selectAction: { _ in }
  ))

  private lazy var trumpetSelector = SelectorButton(model: SelectorButton.Model(
    title: "духовые",
    image: Asset.trumpet.image,
    closedBackgroundColor: .white,
    openedBackgroundColor: UIColor(red: 0.66, green: 0.858, blue: 0.064, alpha: 1),
    selectedItemBackgroundColor: .white,
    itemTextColor: .black,
    items: [
      .init(title: "сэмпл 1"),
      .init(title: "сэмпл 2"),
      .init(title: "сэмпл 3"),
      .init(title: "сэмпл 4"),
      .init(title: "сэмпл 5"),
    ],
    tapAction: guitarTapped,
    hoverAction: { _ in },
    selectAction: { _ in }
  ))

  private lazy var layersView = LayersView(audioController: audioMixer)
  private var layersHeightConstraint: ConstraintMakerEditable?

  override func viewDidLoad() {
    super.viewDidLoad()

    setupUI()
  }

  private func setupUI() {
    let stack = UIStackView()
    stack.distribution = .equalSpacing
    view.addSubviews(stack, layersView)
    stack.snp.makeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide)
      make.leading.equalToSuperview().offset(16)
      make.trailing.equalToSuperview().inset(16)
    }
    stack.addArrangedSubviews(guitarSelector, drumsSelector, trumpetSelector)

    layersView.snp.makeConstraints { make in
      make.leading.trailing.bottom.equalToSuperview()
      layersHeightConstraint = make.height.equalTo(0)
    }

    layersView.heightDidChange = { [weak self] height in
      self?.layersHeightConstraint?.constraint.update(offset: height)
      UIView.animate(withDuration: 0.3) { [weak self] in
        self?.view.layoutSubviews()
      }
    }
  }

  private func guitarTapped() {
    guard let layer = layerModel(from: .zero) else { return }
    audioMixer.play(layer)
    layersView.addLayer(layer)
  }

  private func playSample(index: Int) {
    guard let layer = layerModel(from: index),
          previewLayerPlaying != layer
    else { return }
    if let previewLayerPlaying {
      audioMixer.stop(previewLayerPlaying)
    }
    previewLayerPlaying = layer
    audioMixer.play(layer)
  }

  private func sampleSelected(at index: Int) {
    guard let layer = previewLayerPlaying ?? layerModel(from: index) else { return }
    previewLayerPlaying = nil
    layersView.addLayer(layer)
  }

  private func layerModel(from sampleIndex: Int) -> LayerModel? {
    let sample = "sample_\(sampleIndex + 1).wav"
    guard let audioFileUrl = Bundle.main.url(forResource: sample, withExtension: nil)
    else {
      Logger.log("Audio file was not found")
      return nil
    }

    return LayerModel(
      name: sample,
      audioFileUrl: audioFileUrl,
      isMuted: false
    )
  }
}
