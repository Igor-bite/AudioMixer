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
  func volume(for layer: LayerModel) -> Float
  func setRate(for layer: LayerModel, rate: Float)
  func rate(for layer: LayerModel) -> Float
  func isLayerPlaying(_ layer: LayerModel) -> Bool
  func playedTime(_ layer: LayerModel) -> Double
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
  private let audioSession = AVAudioSession.sharedInstance()
  private var mixerNodeInputBus = AVAudioNodeBus.min
  private var playerNodes = [LayerModel: AVAudioPlayerNode]()
  private var pitchNodes = [LayerModel: AVAudioUnitTimePitch]()
  private var mixerNodeInputBusCache = [LayerModel: AVAudioNodeBus]()

  private lazy var previewPlayerNode = makePreviewPlayerNode()
  private lazy var layersMixerNode = AVAudioMixerNode()

  var isRunning: Bool {
    audioEngine.isRunning
  }

  var format: AVAudioFormat {
    audioEngine.outputNode.outputFormat(forBus: .zero)
  }

  init() {
    setupAudioSession()
    setupAudioEngine()
    installTap()

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleConfigurationChange),
      name: NSNotification.Name.AVAudioEngineConfigurationChange,
      object: nil
    )
  }

  func play(_ layer: LayerModel) {
    if !isRunning {
      setupAudioEngine()
    }
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

  func setPan(for layer: LayerModel, pan: Float) {
    guard let node = playerNodes[layer] else { return }
    node.pan = pan
  }

  func setPitch(for layer: LayerModel, pitch: Float) {
    guard let node = pitchNodes[layer] else { return }
    node.pitch = pitch
  }

  func setRate(for layer: LayerModel, rate: Float) {
    guard let node = pitchNodes[layer] else { return }
    node.rate = rate
  }

  func volume(for layer: LayerModel) -> Float {
    guard let node = playerNodes[layer] else { return .zero }
    return node.volume
  }

  func rate(for layer: LayerModel) -> Float {
    guard let node = pitchNodes[layer] else { return .zero }
    return node.rate
  }

  func isLayerPlaying(_ layer: LayerModel) -> Bool {
    guard let node = playerNodes[layer] else { return false }
    return node.isPlaying
  }

  func playedTime(_ layer: LayerModel) -> Double {
    guard let node = playerNodes[layer],
          let lastRenderTime = node.lastRenderTime,
          let playerTime = node.playerTime(forNodeTime: lastRenderTime)
    else { return .zero }

    let sampleTime = playerTime.sampleTime
    let sampleRate = playerTime.sampleRate
    let currentTime = Double(sampleTime) / sampleRate
    let duration = layer.duration
    let fullLoops = (currentTime / duration).rounded(.down)
    let currentDuration = currentTime - fullLoops * duration
    return currentDuration
  }

  func pauseAll() {
    for layer in playerNodes.keys {
      pause(layer)
    }
  }

  func playAll() {
    for layer in playerNodes.keys {
      play(layer)
    }
  }

  var outputFile: AVAudioFile?
  let writingQueue = DispatchQueue(label: "sample_recording.queue")

  func installTap() {
    let maxFrameCount: AVAudioFrameCount = 48000
    layersMixerNode.installTap(
      onBus: .zero,
      bufferSize: maxFrameCount,
      format: format
    ) { buffer, _ in
      self.writingQueue.async { [weak self] in
        guard let outputFile = self?.outputFile else { return }
        do {
          try outputFile.write(from: buffer)
        } catch {
          Logger.log(error)
        }
      }
    }
  }

  func renderToFile(isStart: Bool, shareAction: @escaping (URL) -> Void) {
    if isStart {
      writingQueue.async { [weak self] in
        guard let self else { return }

        let date = Date().description.replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: ":", with: "-")
        let fileUrl = FileManager.getDocumentsDirectory().appendingPathComponent("RECORDING_\(date).caf")
        let outputFile: AVAudioFile
        do {
          outputFile = try AVAudioFile(
            forWriting: fileUrl,
            settings: audioEngine.mainMixerNode.outputFormat(forBus: .zero).settings
          )
        } catch {
          Logger.log(error)
          return
        }

        self.outputFile = outputFile
      }
    } else {
      pauseAll()
      writingQueue.async { [weak self] in
        guard let self,
              let file = outputFile
        else { return }
        shareAction(file.url)
        outputFile = nil
      }
    }
  }

  func playPreview(for layer: LayerModel) {
    if previewPlayerNode.isPlaying {
      previewPlayerNode.stop()
    }
    previewPlayerNode.play(layer: layer)
  }

  func stopPreview(for layer: LayerModel) {
    if previewPlayerNode.isPlaying {
      previewPlayerNode.stop()
    }
  }

  private func makePreviewPlayerNode() -> AVAudioPlayerNode {
    let node = AVAudioPlayerNode()
    audioEngine.attach(node)
    audioEngine.connect(
      node,
      to: audioEngine.mainMixerNode,
      fromBus: .zero,
      toBus: 1,
      format: nil
    )
    audioEngine.prepare()
    return node
  }

  private func getPlayerNode(for layer: LayerModel) -> AVAudioPlayerNode {
    if let node = playerNodes[layer] {
      return node
    }
    return makeAndAttachPlayerNode(for: layer)
  }

  private func makeAndAttachPlayerNode(for layer: LayerModel) -> AVAudioPlayerNode {
    let playerNode = AVAudioPlayerNode()
    playerNodes[layer] = playerNode
    audioEngine.attach(playerNode)

    let pitchNode = AVAudioUnitTimePitch()
    pitchNodes[layer] = pitchNode
    audioEngine.attach(pitchNode)

    audioEngine.connect(playerNode, to: pitchNode, format: nil)

    let mixerNodeInputBus = mixerNodeInputBus(for: layer)
    audioEngine.connect(
      pitchNode,
      to: layersMixerNode,
      fromBus: .zero,
      toBus: mixerNodeInputBus,
      format: nil
    )
    audioEngine.prepare()
    return playerNode
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
      try audioSession.setCategory(.playAndRecord)
      try audioSession.setActive(true)
    } catch {
      Logger.log(error)
    }
  }

  private func changeOutputToSpeaker() {
    do {
      try audioSession.overrideOutputAudioPort(.speaker)
    } catch {
      Logger.log(error)
    }
  }

  private func setupAudioEngine() {
    changeOutputToSpeaker()

    audioEngine.attach(layersMixerNode)
    audioEngine.connect(layersMixerNode, to: audioEngine.mainMixerNode, fromBus: .zero, toBus: .zero, format: nil)
    audioEngine.connect(audioEngine.mainMixerNode, to: audioEngine.outputNode, fromBus: .zero, toBus: .zero, format: nil)
    audioEngine.prepare()

    if !isRunning {
      do {
        try audioEngine.start()
      } catch {
        Logger.log(error)
      }
    }
  }

  @objc
  private func handleConfigurationChange(notification: Notification) {
    setupAudioEngine()
  }
}

extension AVAudioPlayerNode {
  func play(layer: LayerModel) {
    guard !isPlaying else { return }
    play(file: layer.audioFile)
  }

  func play(file: AVAudioFile?) {
    guard let audioFile = file,
          let buffer = try? AVAudioPCMBuffer(file: audioFile)
    else { return }

    scheduleBuffer(buffer, at: nil, options: .loops)
    play()
  }
}
