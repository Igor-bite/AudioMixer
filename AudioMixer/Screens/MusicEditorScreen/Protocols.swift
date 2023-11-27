// Created with love by Igor Klyuzhev in 2023

import Foundation

// View
protocol MusicEditorInput: AnyObject {}

// ViewModel
protocol MusicEditorOutput {
  func playPreview(for layer: LayerModel)
  func stopPreview()

  func addLayer(_ layer: LayerModel)
  func changingLayerSet(to layer: LayerModel)
  func changeLayerSetting(setting: SettingType, value: Double)

  func startRecordingVoice()
  func stopRecordingVoice()

  func startRecordingComposition()
  func stopRecordingComposition()

  func playAll()
  func pauseAll()
}
