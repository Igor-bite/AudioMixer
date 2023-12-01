// Created with love by Igor Klyuzhev in 2023

import AVFoundation
import Foundation

final class MusicEditorViewModel: MusicEditorOutput {
  weak var view: MusicEditorInput?
  private let audioMixer: AudioMixer
  private let audioRecorder: MicrophoneAudioRecorder

  private var previewLayerPlaying: LayerModel?

  var settingsChangingLayer: LayerModel?
  var isAllPlaying: Bool = false

  var audioController: AudioControlling {
    audioMixer
  }

  var audioRecordingFormat: AVAudioFormat {
    audioMixer.format
  }

  init(
    audioMixer: AudioMixer,
    audioRecorder: MicrophoneAudioRecorder
  ) {
    self.audioMixer = audioMixer
    self.audioRecorder = audioRecorder
  }

  func playPreview(for layer: LayerModel) {
    guard layer != previewLayerPlaying else { return }

    if let previewLayerPlaying {
      audioMixer.stopPreview(for: previewLayerPlaying)
    }

    previewLayerPlaying = layer
    audioMixer.playPreview(for: layer)
  }

  func stopPreview() {
    guard let previewLayerPlaying else { return }
    audioMixer.stopPreview(for: previewLayerPlaying)
    self.previewLayerPlaying = nil
  }

  func addLayer(_ layer: LayerModel) {
    audioMixer.play(layer)
    view?.addLayerToLayersView(layer)
    changingLayerSet(to: layer)
  }

  func changingLayerSet(to layer: LayerModel?) {
    settingsChangingLayer = layer
    view?.setLayerForModifications(layer)
  }

  func layerDidDelete(_ layer: LayerModel) {
    audioMixer.stop(layer)
    guard settingsChangingLayer == layer else { return }
    changingLayerSet(to: nil)
  }

  func startRecordingVoice() {}

  func stopRecordingVoice() {}

  func startRecordingComposition() {}

  func stopRecordingComposition() {}

  func playAll() {
    isAllPlaying = true
    audioMixer.playAll()
  }

  func pauseAll() {
    isAllPlaying = false
    audioMixer.pauseAll()
  }
}

enum SettingType {
  case volume
  case speed
}
