// Created with love by Igor Klyuzhev in 2023

import AVFoundation
import Foundation

// View
protocol MusicEditorInput: AnyObject {
  func setLayerForModifications(_ layer: LayerModel?)
  func addLayerToLayersView(_ layer: LayerModel)
}

// ViewModel
protocol MusicEditorOutput {
  var settingsChangingLayer: LayerModel? { get }
  var isAllPlaying: Bool { get }
  var audioController: AudioControlling { get }
  var audioRecordingFormat: AVAudioFormat { get }

  func playPreview(for layer: LayerModel)
  func stopPreview()

  func addLayer(_ layer: LayerModel)
  func changingLayerSet(to layer: LayerModel?)
  func layerDidDelete(_ layer: LayerModel)

  func startRecordingVoice()
  func stopRecordingVoice()

  func startRecordingComposition()
  func stopRecordingComposition()

  func playAll()
  func pauseAll()
}
