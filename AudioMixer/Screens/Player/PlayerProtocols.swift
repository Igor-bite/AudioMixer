// Created with love by Igor Klyuzhev in 2023

import Combine
import Foundation

// View
protocol PlayerInput: AnyObject {}

// ViewModel
protocol PlayerOutput {
  var project: ProjectModel { get }
  var trackName: String { get }
  var trackDuration: CGFloat { get }
  var isStreaming: Bool { get }
  var isPlaying: CurrentValueSubject<Bool, Never> { get }
  var playedTime: CurrentValueSubject<CGFloat, Never> { get }

  func backTapped()
  func downloadTapped()
  func playPauseTapped()
  func previousTrackTapped()
  func nextTrackTapped()
  func textFieldChanged(_ text: String)
  func newTimingValue(_ value: CGFloat)
}
