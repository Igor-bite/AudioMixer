// Created with love by Igor Klyuzhev in 2023

import AVFoundation
import Foundation

protocol AudioControlling {
  func play(_ layer: LayerModel)
  func stop(_ layer: LayerModel, shouldRemove: Bool)
  func stop(_ layer: LayerModel)
  func pause(_ layer: LayerModel)
  func togglePlayingState(for layer: LayerModel)
  func setVolume(for layer: LayerModel, volume: Float)
  func isLayerPlaying(_ layer: LayerModel) -> Bool
}

extension AudioControlling {
  func stop(_ layer: LayerModel) {
    stop(layer, shouldRemove: false)
  }

  func togglePlayingState(for layer: LayerModel) {
    if isLayerPlaying(layer) {
      pause(layer)
    } else {
      play(layer)
    }
  }
}

final class AudioMixer: AudioControlling {
  private let audioEngine = AVAudioEngine()
  private var mixerNodeInputBus = AVAudioNodeBus.min
  private var playerNodes = [LayerModel: AVAudioPlayerNode]()
  private var mixerNodeInputBusCache = [LayerModel: AVAudioNodeBus]()

  init() {
    setupAudioSession()
    setupAudioEngine()
  }

  func play(_ layer: LayerModel) {
    let player = getPlayerNode(for: layer)
    player.play(layer: layer)
  }

  func stop(_ layer: LayerModel, shouldRemove: Bool = false) {
    guard let player = playerNodes[layer] else { return }
    if player.isPlaying {
      player.stop()
    }
    guard shouldRemove else { return }
    detachPlayerNode(playerNode: player)
    playerNodes[layer] = nil
  }

  func pause(_ layer: LayerModel) {
    guard let player = playerNodes[layer] else { return }
    player.pause()
  }

  func setVolume(for layer: LayerModel, volume: Float) {
    guard let node = playerNodes[layer] else { return }
    node.volume = volume
  }

  func isLayerPlaying(_ layer: LayerModel) -> Bool {
    guard let node = playerNodes[layer] else { return false }
    return node.isPlaying
  }

  private func getPlayerNode(for layer: LayerModel) -> AVAudioPlayerNode {
    if let node = playerNodes[layer] {
      return node
    }
    return makeAndAttachPlayerNode(for: layer)
  }

  private func makeAndAttachPlayerNode(for layer: LayerModel) -> AVAudioPlayerNode {
    let node = AVAudioPlayerNode()
    playerNodes[layer] = node
    audioEngine.attach(node)
    let mixerNodeInputBus = mixerNodeInputBus(for: layer)
    audioEngine.connect(
      node,
      to: audioEngine.mainMixerNode,
      fromBus: .zero,
      toBus: mixerNodeInputBus,
      format: nil
    )
    audioEngine.prepare()
    return node
  }

  private func mixerNodeInputBus(for layer: LayerModel) -> AVAudioNodeBus {
    if let bus = mixerNodeInputBusCache[layer] {
      return bus
    }
    let bus = mixerNodeInputBus
    mixerNodeInputBusCache[layer] = bus
    mixerNodeInputBus += 1
    return bus
  }

  private func detachPlayerNode(playerNode: AVAudioPlayerNode) {
    audioEngine.disconnectNodeOutput(playerNode, bus: 0)
    audioEngine.detach(playerNode)
  }

  private func setupAudioSession() {
    do {
      try AVAudioSession.sharedInstance().setCategory(.playAndRecord)
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      Logger.log(error)
    }
  }

  private func setupAudioEngine() {
    audioEngine.connect(audioEngine.mainMixerNode, to: audioEngine.outputNode, format: nil)
    audioEngine.prepare()

    if !audioEngine.isRunning {
      do {
        try audioEngine.start()
      } catch {
        Logger.log(error)
      }
    }
  }
}

extension AVAudioPlayerNode {
  func play(layer: LayerModel) {
    play(fileUrl: layer.audioFileUrl)
  }

  func play(fileUrl: URL) {
    guard let audioFile = try? AVAudioFile(forReading: fileUrl)
    else {
      Logger.log("Audio file not found")
      return
    }

    play(file: audioFile)
  }

  func play(file: AVAudioFile) {
    scheduleFile(file, at: AVAudioTime(hostTime: .zero)) { [weak self] in
      self?.play(file: file)
    }
    play()
  }
}
