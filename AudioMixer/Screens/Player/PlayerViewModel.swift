// Created with love by Igor Klyuzhev in 2023

import AVFoundation
import Combine
import Foundation

final class PlayerViewModel: PlayerOutput {
  private let screenRecorder: ScreenRecorder
  private let coordinator: PlayerCoordinator
  private lazy var player: AVAudioPlayer? = {
    Timer.scheduledTimer(
      timeInterval: 1.0,
      target: self,
      selector: #selector(updatePlayedTime),
      userInfo: nil,
      repeats: true
    )
    return try? AVAudioPlayer(contentsOf: trackUrl)
  }()

  private var trackUrl: URL {
    project.trackUrl?.currentDocumentsDirectory ?? project.trackUrl ?? URL(string: "https://ya.ru")! // TODO: fix
  }

  weak var view: PlayerInput?

  private(set) lazy var trackName: String = trackUrl.lastPathComponent.replacingOccurrences(of: ".caf", with: "")
  private(set) lazy var trackDuration: CGFloat = player?.duration ?? .zero

  var isPlaying = CurrentValueSubject<Bool, Never>(false)
  var playedTime = CurrentValueSubject<CGFloat, Never>(.zero)
  let project: ProjectModel

  init(
    screenRecorder: ScreenRecorder,
    project: ProjectModel,
    coordinator: PlayerCoordinator
  ) {
    self.screenRecorder = screenRecorder
    self.project = project
    self.coordinator = coordinator
  }

  func backTapped() {
    coordinator.finish()
  }

  func downloadTapped() {
    coordinator.shareFile(fileUrl: trackUrl)
  }

  func playPauseTapped() {
    guard let player else {
      assertionFailure("Player was not initialized")
      return
    }
    if isPlaying.value {
      player.pause()
      screenRecorder.stopRecording()
    } else {
      player.prepareToPlay()
      player.play()
      screenRecorder.startRecording()
    }
    isPlaying.send(!isPlaying.value)
  }

  func previousTrackTapped() {}

  func nextTrackTapped() {}

  func newTimingValue(_ value: CGFloat) {
    player?.play(atTime: value)
  }

  @objc
  private func updatePlayedTime() {
    playedTime.send(player?.currentTime ?? .zero)
  }
}
