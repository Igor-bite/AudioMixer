// Created with love by Igor Klyuzhev in 2023

import AVFoundation
import Combine
import Foundation

final class MusicEditorViewModel: MusicEditorOutput {
  weak var view: MusicEditorInput?
  private let audioMixer: AudioMixer
  private let audioRecorder: MicrophoneAudioRecorder
  private let project: ProjectModel
  private let projectSaver: ProjectsSaving

  private var previewLayerPlaying: LayerModel?
  private var recordCompositionWorkItem: DispatchWorkItem?

  var settingsChangingLayer: LayerModel?
  var isAllPlaying = false
  var isCompositionRecording = false
  var isRecordingVoice = CurrentValueSubject<Bool, Never>(false)

  var audioController: AudioMixer {
    audioMixer
  }

  init(
    project: ProjectModel,
    projectSaver: ProjectsSaving,
    audioMixer: AudioMixer,
    audioRecorder: MicrophoneAudioRecorder
  ) {
    self.project = project
    self.projectSaver = projectSaver
    self.audioMixer = audioMixer
    self.audioRecorder = audioRecorder
  }

  func viewDidAppear() {
    view?.configureWithLayers(
      project.layers,
      shouldOpenLayers: !project.layers.isEmpty
    )
  }

  func viewDidDisappear() {
    projectSaver.save(project: project)
    audioMixer.reset()
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
    project.layers.append(layer)
    audioMixer.play(layer)
    view?.addLayerToLayersView(layer)
    changingLayerSet(to: layer)
  }

  func changingLayerSet(to layer: LayerModel?) {
    settingsChangingLayer = layer
    view?.setLayerForModifications(layer)
  }

  func layerDidDelete(_ layer: LayerModel) {
    if let layerIndex = project.layers.firstIndex(of: layer) {
      project.layers.remove(at: layerIndex)
    } else {
      assertionFailure("Invalid project state")
    }
    audioMixer.stop(layer)
    guard settingsChangingLayer == layer else { return }
    changingLayerSet(to: nil)
  }

  func micRecordTapped() {
    if audioRecorder.isRecording {
      isRecordingVoice.send(false)
      guard let layer = audioRecorder.stopRecording() else { return }
      addLayer(layer)
    } else {
      isRecordingVoice.send(true)
      pauseAll()
      audioRecorder.record { [weak self] in
        self?.isRecordingVoice.send(false)
      }
    }
  }

  func recordSampleTapped() {
    isCompositionRecording.toggle()
    let recordCompositionWorkItem = DispatchWorkItem { [weak self] in
      guard let self else { return }
      audioMixer.renderToFile(isStart: isCompositionRecording) { fileUrl in
        DispatchQueue.main.async { [weak self] in
          self?.recordCompositionWorkItem = nil
          self?.view?.showSharing(for: fileUrl)
        }
      }
    }
    self.recordCompositionWorkItem = recordCompositionWorkItem
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: recordCompositionWorkItem)
    return isCompositionRecording ? playAll() : pauseAll()
  }

  func playAll() {
    isAllPlaying = true
    for layer in project.layers {
      if audioMixer.isLayerPlaying(layer) {
        audioMixer.stop(layer)
      }
      audioMixer.play(layer)
    }
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
