// Created with love by Igor Klyuzhev in 2023

import SnapKit
import UIKit

final class LayerCell: UICollectionViewCell {
  static let reuseIdentifier = "LayerCell"

  private lazy var titleLabel = {
    let view = UILabel()
    return view
  }()

  private lazy var playPauseButton = {
    let view = UIButton()
    view.setImage(Asset.play.image, for: .normal)
    view.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
    return view
  }()

  private lazy var muteButton = {
    let view = UIButton()
    view.setImage(Asset.volumeOn.image, for: .normal)
    view.addTarget(self, action: #selector(muteTapped), for: .touchUpInside)
    return view
  }()

  private lazy var deleteButton = {
    let view = UIButton()
    view.smoothCornerRadius = .inset4
    view.backgroundColor = UIColor(red: 0.896, green: 0.896, blue: 0.896, alpha: 1)
    view.setImage(Asset.cross.image, for: .normal)
    view.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
    return view
  }()

  private lazy var progressView = {
    let view = UIView()
    view.backgroundColor = .accentColor
    view.isUserInteractionEnabled = false
    view.clipsToBounds = true
    return view
  }()

  private var progressWidthConstraint: ConstraintMakerEditable?

  private var layerModel: LayerModel?
  private var deleteAction: ((LayerModel) -> Void)?
  private var audioController: AudioControlling?

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(
    with model: LayerModel,
    audioController: AudioControlling,
    deleteAction: @escaping (LayerModel) -> Void
  ) {
    self.layerModel = model
    self.audioController = audioController
    self.deleteAction = deleteAction
    audioController.observeChanges(self)
    titleLabel.text = model.name
    updateMuteState()
    updatePlayingState()
    progressView.transform = CGAffineTransform(
      translationX: -progressView.bounds.width,
      y: .zero
    )
  }

  @objc
  private func playPauseTapped() {
    guard let layerModel else { return }
    audioController?.togglePlayingState(for: layerModel)
    updatePlayingState()
  }

  @objc
  private func deleteTapped() {
    guard let layerModel else { return }
    audioController?.stop(layerModel, shouldRemove: true)
    deleteAction?(layerModel)
  }

  @objc
  private func muteTapped() {
    layerModel?.isMuted.toggle()
    updateMuteState()
  }

  private func updateMuteState() {
    guard let layerModel else { return }
    let newVolume: Float = layerModel.isMuted ? 0 : 1
    audioController?.setVolume(for: layerModel, volume: newVolume)
    let muteImage = layerModel.isMuted ? Asset.volumeOff.image : Asset.volumeOn.image
    muteButton.setImage(muteImage, for: .normal)
  }

  private func updatePlayingState() {
    guard let layerModel,
          let audioController
    else { return }

    let isPlaying = audioController.isLayerPlaying(layerModel)
    let playPauseImage = isPlaying ? Asset.pause.image : Asset.play.image
    playPauseButton.setImage(playPauseImage, for: .normal)
    displayLink.isPaused = !isPlaying
  }

  private lazy var displayLink = createDisplayLink()

  @objc
  private func updatePlayingProgress() {
    guard let layerModel,
          let audioController,
          audioController.isLayerPlaying(layerModel)
    else { return }

    let duration = audioController.playedTime(layerModel)
    let progress = duration / layerModel.duration

    UIView.animate(withDuration: progress == 0 ? 0 : 0.1) { [weak self] in
      guard let self else { return }
      let offset = -progressView.bounds.width * (1 - progress)
      progressView.transform = CGAffineTransform(translationX: offset, y: .zero)
    }
  }

  private func createDisplayLink() -> CADisplayLink {
    let displayLink = CADisplayLink(target: self, selector: #selector(updatePlayingProgress))
    displayLink.add(to: .current, forMode: .default)
    displayLink.isPaused = true
    return displayLink
  }

  private func setupUI() {
    backgroundColor = .white
    clipsToBounds = true
    smoothCornerRadius = .inset4

    addSubviews(progressView, titleLabel, playPauseButton, muteButton, deleteButton)

    progressView.snp.makeConstraints { make in
      make.left.top.bottom.equalToSuperview()
      make.right.equalTo(playPauseButton.snp.left).offset(-10)
    }

    titleLabel.snp.makeConstraints { make in
      make.top.bottom.equalToSuperview()
      make.left.equalToSuperview().offset(10)
    }

    deleteButton.snp.makeConstraints { make in
      make.top.right.bottom.equalToSuperview()
      make.width.equalTo(deleteButton.snp.height)
    }

    muteButton.snp.makeConstraints { make in
      make.top.bottom.equalToSuperview()
      make.right.equalTo(deleteButton.snp.left).offset(-4)
      make.width.equalTo(24)
    }

    playPauseButton.snp.makeConstraints { make in
      make.top.bottom.equalToSuperview()
      make.right.equalTo(muteButton.snp.left)
      make.width.equalTo(24)
    }
  }
}

extension LayerCell: AudioChangesObserver {
  func playingStateChanged() {
    DispatchQueue.main.async {
      self.displayLink.isPaused = true
      self.updatePlayingState()
    }
  }
}
