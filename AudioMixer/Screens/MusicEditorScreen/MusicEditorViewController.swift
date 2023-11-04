// Created with love by Igor Klyuzhev in 2023

import SnapKit
import UIKit

final class MusicEditorViewController: UIViewController {
  override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

  private let audioMixer = AudioMixer()
  private let audioRecorder = MicrophoneAudioRecorder()
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

  private lazy var recordMicrophoneButton = {
    let view = UIButton()
    view.smoothCornerRadius = .inset4
    view.backgroundColor = .white
    view.setImage(Asset.microphone.image, for: .normal)
    view.addTarget(self, action: #selector(micRecordTapped), for: .touchUpInside)
    return view
  }()

  private lazy var recordSampleButton = {
    let view = UIButton()
    view.smoothCornerRadius = .inset4
    view.backgroundColor = .white
    view.setImage(Asset.recordCircle.image, for: .normal)
    view.addTarget(self, action: #selector(recordSampleTapped), for: .touchUpInside)
    return view
  }()

  private lazy var playPauseButton = {
    let view = UIButton()
    view.smoothCornerRadius = .inset4
    view.backgroundColor = .white
    view.setImage(Asset.play.image, for: .normal)
    view.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
    return view
  }()

  private lazy var chevronImageView = {
    let view = UIImageView()
    view.contentMode = .scaleAspectFit
    view.image = Asset.chevronUp.image
    return view
  }()

  private lazy var layersLabel = {
    let label = UILabel()
    label.text = "Слои"
    label.textColor = .black
    return label
  }()

  private lazy var layersButton = {
    let view = UIControl()
    view.smoothCornerRadius = .inset4
    view.backgroundColor = .white
    view.addTarget(self, action: #selector(layersButtonTapped), for: .touchUpInside)

    view.addSubviews(chevronImageView, layersLabel)

    chevronImageView.snp.makeConstraints { make in
      make.right.equalToSuperview().offset(-10)
      make.centerY.equalToSuperview()
      make.size.equalTo(CGSize(width: 12, height: 12))
    }

    layersLabel.snp.makeConstraints { make in
      make.left.top.equalToSuperview().offset(10)
      make.bottom.equalToSuperview().offset(-10)
      make.right.equalTo(chevronImageView).offset(-16)
    }

    return view
  }()

  override func viewDidLoad() {
    super.viewDidLoad()

    setupUI()
  }

  private func setupUI() {
    let stack = UIStackView()
    stack.distribution = .equalSpacing
    view.addSubviews(stack, layersView, recordMicrophoneButton, recordSampleButton, playPauseButton, layersButton)
    stack.snp.makeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide)
      make.leading.equalToSuperview().offset(16)
      make.trailing.equalToSuperview().inset(16)
    }
    stack.addArrangedSubviews(guitarSelector, drumsSelector, trumpetSelector)

    layersView.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-100)
      make.leading.trailing.equalToSuperview()
      layersHeightConstraint = make.height.equalTo(0)
    }

    playPauseButton.snp.makeConstraints { make in
      make.right.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
      make.size.equalTo(CGSize(width: 36, height: 36))
    }

    recordSampleButton.snp.makeConstraints { make in
      make.right.equalTo(playPauseButton.snp.left).offset(-8)
      make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
      make.size.equalTo(CGSize(width: 36, height: 36))
    }

    recordMicrophoneButton.snp.makeConstraints { make in
      make.right.equalTo(recordSampleButton.snp.left).offset(-8)
      make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
      make.size.equalTo(CGSize(width: 36, height: 36))
    }

    layersButton.snp.makeConstraints { make in
      make.height.equalTo(36)
      make.width.equalTo(84)
      make.left.equalToSuperview().offset(16)
      make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
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

  @objc
  private func micRecordTapped() {
    if audioRecorder.isRecording {
      recordMicrophoneButton.backgroundColor = .white
      guard let layer = audioRecorder.stopRecording() else { return }
      layersView.addLayer(layer)
      audioMixer.play(layer)
    } else {
      recordMicrophoneButton.backgroundColor = .red.withAlphaComponent(0.8)
      audioRecorder.record()
    }
  }

  var shouldRecord = false

  @objc
  private func recordSampleTapped() {
    shouldRecord.toggle()
    recordSampleButton.backgroundColor = shouldRecord ? .red : .white

    audioMixer.renderToFile(isStart: shouldRecord) { fileUrl in
      DispatchQueue.main.async { [weak self] in
        let activityViewController = UIActivityViewController(activityItems: [fileUrl], applicationActivities: nil)
        activityViewController.completionWithItemsHandler = { _, _, _, _ in
          print("end")
        }
        self?.present(activityViewController, animated: true, completion: nil)
      }
    }
  }

  @objc
  private func playPauseTapped() {
    if audioMixer.isRunning {
      audioMixer.pause()
    } else {
      audioMixer.start()
    }
  }

  @objc
  private func layersButtonTapped() {
    let newAlpha: CGFloat = layersView.alpha == 1 ? 0 : 1
    UIView.animate(withDuration: 0.3) { [weak self] in
      self?.layersView.alpha = newAlpha
      self?.chevronImageView.transform = newAlpha == 1 ? CGAffineTransform(rotationAngle: CGFloat.pi) : .identity
    }
  }
}
