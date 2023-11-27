// Created with love by Igor Klyuzhev in 2023

import Foundation

final class MusicEditorViewModel: MusicEditorOutput {
  weak var view: MusicEditorInput?
  private let audioMixer: AudioMixer
  private let audioRecorder: MicrophoneAudioRecorder

  init(
    audioMixer: AudioMixer,
    audioRecorder: MicrophoneAudioRecorder
  ) {
    self.audioMixer = audioMixer
    self.audioRecorder = audioRecorder
  }

  func addLayer(_ layer: LayerModel) {}

  func changingLayerSet(to layer: LayerModel) {}

  func changeLayerSetting(setting: SettingType, value: Double) {}

  func startRecordingVoice() {}

  func stopRecordingVoice() {}

  func startRecordingComposition() {}

  func stopRecordingComposition() {}

  func playAll() {
    audioMixer.playAll()
  }

  func pauseAll() {
    audioMixer.pauseAll()
  }
}

enum SettingType {
  case volume
  case speed
}
