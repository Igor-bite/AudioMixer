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
  var isPlaying: CurrentValueSubject<Bool, Never> { get }
  var playedTime: CurrentValueSubject<CGFloat, Never> { get }

  func backTapped()
  func downloadTapped()
  func playPauseTapped()
  func previousTrackTapped()
  func nextTrackTapped()
  func newTimingValue(_ value: CGFloat)
}
