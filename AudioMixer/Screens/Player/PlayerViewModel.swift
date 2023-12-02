// Created with love by Igor Klyuzhev in 2023

import AVFoundation
import Combine
import Foundation

final class PlayerViewModel: PlayerOutput {
  private let screenRecorder: ScreenRecorder
  private let coordinator: PlayerCoordinator
  private var player: MusicVisualizerAudioControlling?

  private var trackUrl: URL {
    project.trackUrl?.currentDocumentsDirectory ?? project.trackUrl ?? URL(string: "https://ya.ru")! // TODO: fix
  }

  weak var view: PlayerInput?

  let isStreaming: Bool
  private(set) lazy var trackName: String = player?.isStreaming == true ? project.name : trackUrl.lastPathComponent.replacingOccurrences(of: ".caf", with: "")
  private(set) lazy var trackDuration: CGFloat = player?.audioDuration ?? .zero

  var isPlaying = CurrentValueSubject<Bool, Never>(false)
  var playedTime = CurrentValueSubject<CGFloat, Never>(.zero)
  let project: ProjectModel

  init(
    screenRecorder: ScreenRecorder,
    project: ProjectModel,
    audioController: MusicVisualizerAudioControlling?,
    coordinator: PlayerCoordinator
  ) {
    self.screenRecorder = screenRecorder
    self.project = project
    self.coordinator = coordinator
    self.player = audioController
    self.isStreaming = audioController?.isStreaming ?? false
    setupTimer()
    if let isSomethingPlaying = audioController?.isSomethingPlaying {
      isPlaying.send(isSomethingPlaying)
    }
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
      if !player.isStreaming {
        screenRecorder.stopRecording()
      }
    } else {
      _ = player.play()
      if !player.isStreaming {
        screenRecorder.startRecording()
      }
    }
    isPlaying.send(!isPlaying.value)
  }

  func previousTrackTapped() {
    player?.seek(to: .zero)
  }

  func nextTrackTapped() {
    player?.seek(to: trackDuration)
  }

  func textFieldChanged(_ text: String) {
    guard player?.isStreaming == true else { return }
    project.name = text
  }

  func newTimingValue(_ value: CGFloat) {
    player?.seek(to: 0)
  }

  private func setupTimer() {
    guard player?.isStreaming == false else { return }
    Timer.scheduledTimer(
      timeInterval: 1.0,
      target: self,
      selector: #selector(updatePlayedTime),
      userInfo: nil,
      repeats: true
    )
  }

  @objc
  private func updatePlayedTime() {
    playedTime.send(player?.currentPlayingTime ?? .zero)
  }
}
