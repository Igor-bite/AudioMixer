// Created with love by Igor Klyuzhev in 2023

import SnapKit
import UIKit

final class MusicEditorViewController: UIViewController, MusicEditorInput {
  override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

  private lazy var guitarSelector = makeGuitarSelector()
  private lazy var drumsSelector = makeDrumsSelector()
  private lazy var trumpetSelector = makeTrumpetSelector()
  private lazy var layersView = makeLayersView()

  private lazy var recordMicrophoneButton = makeButton(
    image: Asset.microphone.image,
    action: #selector(micRecordTapped)
  )

  private lazy var recordSampleButton = makeButton(
    image: Asset.recordCircle.image,
    action: #selector(recordSampleTapped)
  )

  private lazy var playPauseButton = makeButton(
    image: Asset.play.image,
    action: #selector(playPauseTapped)
  )

  private lazy var layersButton = {
    let button = DisclosureButton()
    button.action = layersButtonTapped
    button.setup(withText: "Слои")
    return button
  }()

  private lazy var settingsControlAreaView = {
    let view = SettingsControlView(audioController: viewModel.audioController)
    view.layer.borderColor = UIColor.gray.cgColor
    view.layer.borderWidth = UIScreen.onePixel
    return view
  }()

  private lazy var waveFormView = {
    let view = WaveformImageView(frame: .zero)
    view.imageDidSet = { [weak self] image in
      view.frame.size = image.size
      self?.waveFormScrollView.contentSize = image.size
    }
    return view
  }()

  private lazy var waveFormScrollView = {
    let view = UIScrollView()
    view.contentInset = Constants.waveformScrollInsets
    view.showsHorizontalScrollIndicator = false
    view.showsVerticalScrollIndicator = false
    return view
  }()

  private lazy var audioMixer = AudioMixer()
  private lazy var audioRecorder = MicrophoneAudioRecorder(
    format: viewModel.audioRecordingFormat,
    alertPresenter: alertPresenter
  )

  private var shouldRecord = false
  private lazy var displayLink = createDisplayLink(.common)
  private var previousProgress: Double = -1
  private var layersHeightConstraint: ConstraintMakerEditable?
  private var waveformWidthConstraint: ConstraintMakerEditable?

  private let waveformImageDrawer = WaveformImageDrawer()
  private let viewModel: MusicEditorOutput
  private let alertPresenter: AlertPresenting

  init(
    viewModel: MusicEditorOutput,
    alertPresenter: AlertPresenting
  ) {
    self.viewModel = viewModel
    self.alertPresenter = alertPresenter
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    setupUI()

    navigationController?.navigationBar.isHidden = true
  }

  func setLayerForModifications(_ layer: LayerModel?) {
    settingsControlAreaView.configure(with: layer)
    if let layer {
      showWaveform(for: layer)
    } else {
      hideWaveform()
    }
  }

  func addLayerToLayersView(_ layer: LayerModel) {
    layersView.addLayer(layer)
  }

  private func setupUI() {
    let stack = UIStackView()
    stack.distribution = .equalSpacing
    view.addSubviews(
      settingsControlAreaView,
      stack,
      waveFormScrollView,
      layersView,
      recordMicrophoneButton,
      recordSampleButton,
      playPauseButton,
      layersButton
    )
    waveFormScrollView.addSubview(waveFormView)

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

    waveFormScrollView.snp.makeConstraints { make in
      make.leading.trailing.equalToSuperview()
      make.bottom.equalTo(layersButton.snp.top).offset(-32)
      make.height.equalTo(Constants.waveformHeight)
    }

    layersView.snp.makeConstraints { make in
      make.bottom.equalTo(waveFormScrollView.snp.top).offset(-12)
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
  }

  private func playSample(index: Int, type: SampleType) {
    guard let layer = LayerModel(
      sampleType: type,
      postfix: "\(index + 1)"
    ) else { return }
    viewModel.playPreview(for: layer)
  }

  private func sampleSelected(at index: Int, type: SampleType) {
    guard let layer = LayerModel(
      sampleType: type,
      postfix: "\(index + 1)"
    )
    else { return }

    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      viewModel.stopPreview()
      viewModel.addLayer(layer)
      if layersView.isEmpty {
        layersButton.isOpened = true
      }
    }
  }

  private func showWaveform(for layer: LayerModel) {
    previousProgress = -1
    let displayLink = displayLink
    displayLink.isPaused = false
    let waveformWidth = layer.waveformWidth
    let size = CGSize(width: waveformWidth, height: Constants.waveformHeight)
    waveFormView.frame.size = size
    waveFormView.configuration = Waveform.Configuration(
      size: size,
      backgroundColor: .clear,
      style: .striped(
        Waveform.Style.StripeConfig(
          color: .white,
          width: 2,
          spacing: 2,
          lineCap: .round
        )
      ),
      verticalScalingFactor: Constants.koeff,
      shouldAntialias: true
    )
    waveFormView.reset()
    waveFormView.waveformAudioURL = layer.audioFileUrl
  }

  private func hideWaveform() {
    waveFormView.reset()
    displayLink.isPaused = true
  }

  @objc
  private func updateWaveformProgress() {
    guard let settingsChangingLayer = viewModel.settingsChangingLayer,
          audioMixer.isLayerPlaying(settingsChangingLayer)
    else { return }
    let duration = audioMixer.playedTime(settingsChangingLayer)
    let progress = duration / settingsChangingLayer.duration
    guard previousProgress != progress else { return }
    previousProgress = progress
    waveFormView.progress = progress
    let contentSize = waveFormScrollView.contentSize
    guard contentSize.width > UIScreen.main.bounds.width - 32 else {
      waveFormScrollView.contentInset.left = UIScreen.main.bounds.width / 2 - contentSize.width / 2
      return
    }
    waveFormScrollView.contentInset.left = 16
    let offset = contentSize.width * progress
    waveFormScrollView.contentOffset.x = max(-16, offset - UIScreen.main.bounds.width / 2)
  }

  private func createDisplayLink(_ mode: RunLoop.Mode) -> CADisplayLink {
    let displayLink = CADisplayLink(target: self, selector: #selector(updateWaveformProgress))
    displayLink.preferredFrameRateRange = CAFrameRateRange(
      minimum: 60,
      maximum: Float(UIScreen.main.maximumFramesPerSecond),
      preferred: Float(UIScreen.main.maximumFramesPerSecond)
    )
    displayLink.add(to: .current, forMode: mode)
    displayLink.isPaused = true
    return displayLink
  }

  @objc
  private func micRecordTapped() {
    FeedbackGenerator.selectionChanged()

    if audioRecorder.isRecording {
      recordMicrophoneButton.backgroundColor = .white
      guard let layer = audioRecorder.stopRecording() else { return }
      viewModel.addLayer(layer)
    } else {
      viewModel.pauseAll()
      recordMicrophoneButton.backgroundColor = .red
      audioRecorder.record { [weak self] in
        self?.recordMicrophoneButton.backgroundColor = .white
      }
    }
  }

  @objc
  private func recordSampleTapped() {
    guard !layersView.isEmpty else {
      showNoLayersAlert()
      return
    }
    FeedbackGenerator.selectionChanged()
    shouldRecord.toggle()
    recordSampleButton.backgroundColor = shouldRecord ? .red : .white
    viewModel.playAll()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
      guard let self else { return }
      audioMixer.renderToFile(isStart: shouldRecord) { fileUrl in
        DispatchQueue.main.async { [weak self] in
          let activityViewController = UIActivityViewController(activityItems: [fileUrl], applicationActivities: nil)
          activityViewController.completionWithItemsHandler = { _, _, _, _ in }
          self?.present(activityViewController, animated: true, completion: nil)
        }
      }
    }
  }

  @objc
  private func playPauseTapped() {
    FeedbackGenerator.selectionChanged()
    let isAllPlaying = viewModel.isAllPlaying
    playPauseButton.setImage(
      isAllPlaying ? Asset.play.image : Asset.pause.image,
      for: .normal
    )
    return isAllPlaying ? viewModel.pauseAll() : viewModel.playAll()
  }

  private func layersButtonTapped(_ isLayersViewHidden: Bool) {
    FeedbackGenerator.selectionChanged()
    UIView.animate(withDuration: 0.3) { [weak self] in
      guard let self else { return }
      layersView.alpha = isLayersViewHidden ? 1 : 0
    }
  }

  private func showNoLayersAlert() {
    let okAction = UIAlertAction(title: "Ок", style: .default, handler: nil)
    alertPresenter.showAlert(
      title: "Пока что записывать нечего",
      message: "Добавьте слои используя кнопки сверху",
      style: .alert,
      actions: [okAction]
    )
  }

  // MARK: - View factory

  private func makeGuitarSelector() -> SelectorButton {
    SelectorButton(model: SelectorButton.Model(
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
        .init(title: "сэмпл 6"),
        .init(title: "сэмпл 7"),
        .init(title: "сэмпл 8"),
      ],
      tapAction: { [weak self] in
        self?.sampleSelected(at: .zero, type: .guitar)
      },
      closeWithoutSelectionAction: { [weak self] in
        self?.viewModel.stopPreview()
      },
      hoverAction: { [weak self] index in
        guard let index else {
          self?.viewModel.stopPreview()
          return
        }
        self?.playSample(index: index, type: .guitar)
      },
      selectAction: { [weak self] index in
        self?.sampleSelected(at: index, type: .guitar)
      }
    ))
  }

  private func makeDrumsSelector() -> SelectorButton {
    SelectorButton(model: SelectorButton.Model(
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
        .init(title: "сэмпл 5"),
        .init(title: "сэмпл 6"),
        .init(title: "сэмпл 7"),
        .init(title: "сэмпл 8"),
      ],
      tapAction: { [weak self] in
        self?.sampleSelected(at: .zero, type: .drum)
      },
      closeWithoutSelectionAction: { [weak self] in
        self?.viewModel.stopPreview()
      },
      hoverAction: { [weak self] index in
        guard let index else {
          self?.viewModel.stopPreview()
          return
        }
        self?.playSample(index: index, type: .drum)
      },
      selectAction: { [weak self] index in
        self?.sampleSelected(at: index, type: .drum)
      }
    ))
  }

  private func makeTrumpetSelector() -> SelectorButton {
    SelectorButton(model: SelectorButton.Model(
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
        .init(title: "сэмпл 5"),
        .init(title: "сэмпл 6"),
        .init(title: "сэмпл 7"),
        .init(title: "сэмпл 8"),
      ],
      tapAction: { [weak self] in
        self?.sampleSelected(at: .zero, type: .trumpet)
      },
      closeWithoutSelectionAction: { [weak self] in
        self?.viewModel.stopPreview()
      },
      hoverAction: { [weak self] index in
        guard let index else {
          self?.viewModel.stopPreview()
          return
        }
        self?.playSample(index: index, type: .trumpet)
      },
      selectAction: { [weak self] index in
        self?.sampleSelected(at: index, type: .trumpet)
      }
    ))
  }

  private func makeLayersView() -> LayersView {
    let view = LayersView(audioController: viewModel.audioController) { [weak self] layer in
      self?.layersButton.isOpened = false
      self?.viewModel.changingLayerSet(to: layer)
    } heightDidChange: { [weak self] height in
      self?.layersHeightConstraint?.constraint.update(offset: height)
      UIView.animate(withDuration: 0.3) { [weak self] in
        self?.view.layoutSubviews()
      }
    } didDeleteLayer: { [weak self] layer in
      self?.viewModel.layerDidDelete(layer)
    }
    view.alpha = .zero
    return view
  }

  private func makeButton(image: UIImage, action: Selector) -> UIButton {
    let button = UIButton()
    button.smoothCornerRadius = .inset4
    button.backgroundColor = .white
    button.setImage(image, for: .normal)
    button.addTarget(self, action: action, for: .touchUpInside)
    return button
  }
}

fileprivate enum Constants {
  static let waveformHeight = 48 * koeff
  static let koeff = 0.8
  static let waveformScrollInsets = UIEdgeInsets(
    top: .zero,
    left: 16,
    bottom: .zero,
    right: 16
  )
}
