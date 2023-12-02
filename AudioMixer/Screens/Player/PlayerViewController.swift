// Created with love by Igor Klyuzhev in 2023

import Combine
import SnapKit
import UIKit

final class PlayerViewController: UIViewController, PlayerInput {
  private let viewModel: PlayerOutput

  private lazy var backButton = makeButton(
    image: UIImage(systemName: "arrow.left"),
    action: #selector(backTapped),
    backgroundColor: .secondaryAccentColor,
    tintColor: .white
  )

  private lazy var downloadButton = {
    let b = makeButton(
      image: Asset.downloadArrow.image,
      action: #selector(downloadTapped),
      backgroundColor: .accentColor,
      tintColor: .black
    )
    b.alpha = viewModel.isStreaming ? 0.5 : 1
    b.isUserInteractionEnabled = !viewModel.isStreaming
    return b
  }()

  private lazy var trackNameTextField = {
    let field = UITextField(frame: .zero)
    field.textColor = .white
    field.text = viewModel.trackName
    field.font = .systemFont(ofSize: 16)
    field.tintColor = .white
    field.addTarget(self, action: #selector(textFieldChanged), for: .allEditingEvents)
    return field
  }()

  private lazy var playPauseButton = makeButton(
    image: UIImage(systemName: "play.fill"),
    action: #selector(playPauseTapped),
    backgroundColor: .clear,
    tintColor: .accentColor
  )

  private lazy var previousTrackButton = {
    let b = makeButton(
      image: UIImage(systemName: "backward.fill"),
      action: #selector(previousTrackTapped),
      backgroundColor: .clear,
      tintColor: .accentColor
    )
    b.alpha = viewModel.isStreaming ? 0.5 : 1
    b.isUserInteractionEnabled = !viewModel.isStreaming
    return b
  }()

  private lazy var nextTrackButton = {
    let b = makeButton(
      image: UIImage(systemName: "forward.fill"),
      action: #selector(nextTrackTapped),
      backgroundColor: .clear,
      tintColor: .accentColor
    )
    b.alpha = viewModel.isStreaming ? 0.5 : 1
    b.isUserInteractionEnabled = !viewModel.isStreaming
    return b
  }()

  private lazy var currentTimeLabel = {
    let label = UILabel()
    label.textColor = .white
    label.font = .systemFont(ofSize: 14)
    return label
  }()

  private lazy var trackDurationLabel = {
    let label = UILabel()
    label.textColor = .white
    let duration = Int(viewModel.trackDuration.rounded())
    if duration > 0 {
      label.text = duration.toTimeString
    }
    label.font = .systemFont(ofSize: 14)
    return label
  }()

  private lazy var musicVisualizer = MusicVisualizerView(project: viewModel.project)

  private var bag = CancellableBag()

  init(
    viewModel: PlayerOutput
  ) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    setupUI()
    bindViewModel()

    let gr = UITapGestureRecognizer(target: self, action: #selector(endEditingTrackName))
    view.addGestureRecognizer(gr)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    endEditingTrackName()
  }

  @objc
  private func endEditingTrackName() {
    trackNameTextField.endEditing(true)
  }

  private func setupUI() {
    view.backgroundColor = .black
    view.addSubviews([
      musicVisualizer,
      backButton,
      trackNameTextField,
      downloadButton,
      currentTimeLabel,
      previousTrackButton,
      playPauseButton,
      nextTrackButton,
      trackDurationLabel,
    ])

    backButton.snp.makeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide).offset(12)
      make.left.equalTo(view.safeAreaLayoutGuide).offset(16)
      make.size.equalTo(CGSize(width: 36, height: 36))
    }

    downloadButton.snp.makeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide).offset(12)
      make.right.equalToSuperview().offset(-16)
      make.size.equalTo(CGSize(width: 36, height: 36))
    }

    trackNameTextField.snp.makeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide).offset(12)
      make.height.equalTo(36)
      make.left.equalTo(backButton.snp.right).offset(16)
      make.right.equalTo(downloadButton.snp.left).offset(-8)
    }

    currentTimeLabel.snp.makeConstraints { make in
      make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-28)
      make.left.equalToSuperview().offset(16)
      make.size.equalTo(CGSize(width: 36, height: 16))
    }

    trackDurationLabel.snp.makeConstraints { make in
      make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-28)
      make.right.equalToSuperview().offset(-16)
      make.size.equalTo(CGSize(width: 36, height: 16))
    }

    playPauseButton.snp.makeConstraints { make in
      make.size.equalTo(CGSize(width: 36, height: 36))
      make.centerY.equalTo(currentTimeLabel)
      make.centerX.equalToSuperview()
    }

    previousTrackButton.snp.makeConstraints { make in
      make.size.equalTo(CGSize(width: 36, height: 36))
      make.centerY.equalTo(currentTimeLabel)
      make.right.equalTo(playPauseButton.snp.left)
    }

    nextTrackButton.snp.makeConstraints { make in
      make.size.equalTo(CGSize(width: 36, height: 36))
      make.centerY.equalTo(currentTimeLabel)
      make.left.equalTo(playPauseButton.snp.right)
    }

    musicVisualizer.snp.makeConstraints { make in
      make.left.right.equalToSuperview()
      make.top.bottom.equalTo(view.safeAreaLayoutGuide)
    }
  }

  private func bindViewModel() {
    viewModel.isPlaying.sink { [weak self] isPlaying in
      let image = isPlaying ? UIImage(systemName: "pause.fill") : UIImage(systemName: "play.fill")
      self?.playPauseButton.setImage(image, for: .normal)
      self?.musicVisualizer.shouldAnimate = isPlaying
    }.store(in: bag)

    viewModel.playedTime.sink { [weak self] playedTime in
      guard let self else { return }
      let playedTime = Int(playedTime.rounded())
      if playedTime > 0 {
        currentTimeLabel.text = playedTime.toTimeString
      }
    }.store(in: bag)
  }

  @objc
  private func backTapped() {
    viewModel.backTapped()
  }

  @objc
  private func downloadTapped() {
    viewModel.downloadTapped()
  }

  @objc
  private func previousTrackTapped() {
    viewModel.previousTrackTapped()
  }

  @objc
  private func nextTrackTapped() {
    viewModel.nextTrackTapped()
  }

  @objc
  private func playPauseTapped() {
    viewModel.playPauseTapped()
  }

  @objc
  private func textFieldChanged() {
    viewModel.textFieldChanged(trackNameTextField.text ?? "")
  }

  private func makeButton(
    image: UIImage?,
    action: Selector,
    backgroundColor: UIColor,
    tintColor: UIColor
  ) -> UIButton {
    let button = UIButton()
    button.smoothCornerRadius = .inset4
    button.backgroundColor = backgroundColor
    button.tintColor = tintColor
    button.setImage(image, for: .normal)
    button.addTarget(self, action: action, for: .touchUpInside)
    return button
  }
}

extension Int {
  var toTimeString: String {
    let (m, s) = secondsToMinutesSeconds(self)
    let shouldAddZero = s > 0 && s < 10
    return "\(m):\(shouldAddZero ? "0" : "")\(s)"
  }

  private func secondsToMinutesSeconds(_ seconds: Int) -> (Int, Int) {
    return (seconds / 60, seconds % 60)
  }
}
