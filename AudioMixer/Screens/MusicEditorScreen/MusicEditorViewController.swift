// Created with love by Igor Klyuzhev in 2023

import SnapKit
import UIKit

final class MusicEditorViewController: UIViewController {
  override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

  private lazy var audioMixer = AudioMixer()
  private lazy var audioRecorder = MicrophoneAudioRecorder(format: audioMixer.format)
  private var previewLayerPlaying: LayerModel?

  private var shouldRecord = false
  private var isAllPlaying = false

  private lazy var guitarSelector = SelectorButton(model: SelectorButton.Model(
    title: "гитара",
    image: Asset.guitar.image,
    closedBackgroundColor: .white,
    openedBackgroundColor: .accentColor,
    selectedItemBackgroundColor: .white,
    itemTextColor: .black,
    items: [
      .init(title: "сэмпл 1"),
      .init(title: "сэмпл 2"),
      .init(title: "сэмпл 3"),
      .init(title: "сэмпл 4"),
      .init(title: "сэмпл 5"),
    ],
    tapAction: { [weak self] in
      self?.selectorTapped(type: .guitar)
    },
    closeWithoutSelectionAction: { [weak self] in
      guard let self,
            let previewLayerPlaying
      else { return }
      audioMixer.stopPreview(for: previewLayerPlaying)
    },
    hoverAction: { [weak self] index in
      guard let index else {
        guard let self,
              let previewLayerPlaying
        else { return }
        audioMixer.stopPreview(for: previewLayerPlaying)
        self.previewLayerPlaying = nil
        return
      }
      self?.playSample(index: index, type: .guitar)
    },
    selectAction: { [weak self] index in
      self?.sampleSelected(at: index, type: .guitar)
    }
  ))

  private lazy var drumsSelector = SelectorButton(model: SelectorButton.Model(
    title: "ударные",
    image: Asset.drums.image,
    closedBackgroundColor: .white,
    openedBackgroundColor: .accentColor,
    selectedItemBackgroundColor: .white,
    itemTextColor: .black,
    items: [
      .init(title: "сэмпл 1"),
      .init(title: "сэмпл 2"),
      .init(title: "сэмпл 3"),
      .init(title: "сэмпл 4"),
    ],
    tapAction: { [weak self] in
      self?.selectorTapped(type: .drum)
    },
    closeWithoutSelectionAction: { [weak self] in
      guard let self,
            let previewLayerPlaying
      else { return }
      audioMixer.stopPreview(for: previewLayerPlaying)
    },
    hoverAction: { [weak self] index in
      guard let index else {
        guard let self,
              let previewLayerPlaying
        else { return }
        audioMixer.stopPreview(for: previewLayerPlaying)
        self.previewLayerPlaying = nil
        return
      }
      self?.playSample(index: index, type: .drum)
    },
    selectAction: { [weak self] index in
      self?.sampleSelected(at: index, type: .drum)
    }
  ))

  private lazy var trumpetSelector = SelectorButton(model: SelectorButton.Model(
    title: "духовые",
    image: Asset.trumpet.image,
    closedBackgroundColor: .white,
    openedBackgroundColor: .accentColor,
    selectedItemBackgroundColor: .white,
    itemTextColor: .black,
    items: [
      .init(title: "сэмпл 1"),
      .init(title: "сэмпл 2"),
      .init(title: "сэмпл 3"),
      .init(title: "сэмпл 4"),
    ],
    tapAction: { [weak self] in
      self?.selectorTapped(type: .trumpet)
    },
    closeWithoutSelectionAction: { [weak self] in
      guard let self,
            let previewLayerPlaying
      else { return }
      audioMixer.stopPreview(for: previewLayerPlaying)
    },
    hoverAction: { [weak self] index in
      guard let index else {
        guard let self,
              let previewLayerPlaying
        else { return }
        audioMixer.stopPreview(for: previewLayerPlaying)
        self.previewLayerPlaying = nil
        return
      }
      self?.playSample(index: index, type: .trumpet)
    },
    selectAction: { [weak self] index in
      self?.sampleSelected(at: index, type: .trumpet)
    }
  ))

  private lazy var layersView = {
    let view = LayersView(audioController: audioMixer)
    view.alpha = .zero
    return view
  }()

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
    view.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
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

  private lazy var settingsControlAreaView = {
    let view = SettingsControlView(audioController: audioMixer)
    view.layer.borderColor = UIColor.gray.cgColor
    view.layer.borderWidth = 1 / UIScreen.main.scale
    return view
  }()

  override func viewDidLoad() {
    super.viewDidLoad()

    setupUI()

    navigationController?.navigationBar.isHidden = true
  }

  private func setupUI() {
    let stack = UIStackView()
    stack.distribution = .equalSpacing
    view.addSubviews(
      settingsControlAreaView,
      stack,
      layersView,
      recordMicrophoneButton,
      recordSampleButton,
      playPauseButton,
      layersButton
    )

    stack.snp.makeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide)
      make.leading.equalToSuperview().offset(16)
      make.trailing.equalToSuperview().inset(16)
    }
    stack.addArrangedSubviews(guitarSelector, drumsSelector, trumpetSelector)

    settingsControlAreaView.snp.makeConstraints { make in
      make.leading.equalToSuperview().offset(16)
      make.trailing.equalToSuperview().offset(-16)
      make.top.equalTo(stack.snp.bottom).offset(36)
      make.height.equalTo(settingsControlAreaView.snp.width)
      make.bottom.lessThanOrEqualTo(layersView.snp.bottom).priority(.high)
    }

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

  private func selectorTapped(type: SampleType) {
    guard let layer = layerModel(from: .zero, type: type) else { return }
    audioMixer.play(layer)
    layersView.addLayer(layer)
  }

  private func playSample(index: Int, type: SampleType) {
    guard let layer = layerModel(from: index, type: type),
          previewLayerPlaying != layer
    else { return }
    if let previewLayerPlaying {
      audioMixer.stopPreview(for: previewLayerPlaying)
    }
    previewLayerPlaying = layer
    audioMixer.playPreview(for: layer)
  }

  private func sampleSelected(at index: Int, type: SampleType) {
    guard let layer = layerModel(from: index, type: type) else { return }
    if let previewLayerPlaying {
      audioMixer.stopPreview(for: previewLayerPlaying)
      self.previewLayerPlaying = nil
    }
    audioMixer.play(layer)
    settingsControlAreaView.configure(with: layer)
    layersView.addLayer(layer)
  }

  private func layerModel(from sampleIndex: Int, type: SampleType) -> LayerModel? {
    let sample = "\(type.rawValue)_\(sampleIndex + 1)"
    guard let audioFileUrl = Bundle.main.url(forResource: sample, withExtension: "wav")
    else {
      Logger.log("Audio file was not found")
      return nil
    }

    return LayerModel(
      name: sample,
      audioFileUrl: audioFileUrl,
      isMuted: false,
      sampleType: type
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
      recordMicrophoneButton.backgroundColor = .red
      audioRecorder.record()
    }
  }

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
    if isAllPlaying {
      audioMixer.pauseAll()
      isAllPlaying = false
      playPauseButton.setImage(Asset.play.image, for: .normal)
    } else {
      audioMixer.playAll()
      isAllPlaying = true
      playPauseButton.setImage(Asset.pause.image, for: .normal)
    }
  }

  @objc
  private func layersButtonTapped() {
    let newAlpha: CGFloat = layersView.alpha == 1 ? 0 : 1
    let isHidden = newAlpha == 0
    UIView.animate(withDuration: 0.3) { [weak self] in
      self?.layersView.alpha = newAlpha
      self?.chevronImageView.transform = isHidden ? CGAffineTransform(rotationAngle: CGFloat.pi) : .identity
      self?.layersButton.backgroundColor = isHidden ? .white : .accentColor
    }
  }
}
