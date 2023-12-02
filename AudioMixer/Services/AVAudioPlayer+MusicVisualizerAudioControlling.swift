// Created with love by Igor Klyuzhev in 2023

import AVFoundation

extension AVAudioPlayer: MusicVisualizerAudioControlling {
  var isStreaming: Bool {
    false
  }

  var audioDuration: TimeInterval? { duration }

  var currentPlayingTime: TimeInterval? {
    currentTime
  }

  func seek(to time: TimeInterval) {
    self.currentTime = time
  }
}
