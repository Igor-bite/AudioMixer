// Created with love by Igor Klyuzhev in 2023

import AVFoundation
import Combine
import Foundation

// View
protocol MusicEditorInput: AnyObject {
  func setLayerForModifications(_ layer: LayerModel?)
  func addLayerToLayersView(_ layer: LayerModel)
  func showSharing(for file: URL)
}

// ViewModel
protocol MusicEditorOutput {
  var settingsChangingLayer: LayerModel? { get }
  var isAllPlaying: Bool { get }
  var audioController: AudioMixer { get }
  var isCompositionRecording: Bool { get }
  var isRecordingVoice: CurrentValueSubject<Bool, Never> { get }

  func playPreview(for layer: LayerModel)
  func stopPreview()

  func addLayer(_ layer: LayerModel)
  func changingLayerSet(to layer: LayerModel?)
  func layerDidDelete(_ layer: LayerModel)

  func micRecordTapped()
  func recordSampleTapped()

  func playAll()
  func pauseAll()
}
