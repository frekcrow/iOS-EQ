import Foundation
import AVFoundation
import Accelerate

/// Core Audio Manager orchestrating AVAudioEngine nodes, effects, playback, and real-time FFT metering.
public final class AudioEngineManager: NSObject {
    
    // MARK: - Audio Engine Nodes
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    public let eqNode = AVAudioUnitEQ(numberOfBands: 10)
    private let pitchNode = AVAudioUnitTimePitch()
    private let distortionNode = AVAudioUnitDistortion()
    private let delayNode = AVAudioUnitDelay()
    private let reverbNode = AVAudioUnitReverb()
    
    // MARK: - State & Helpers
    private let fftAnalyzer = FFTAnalyzer(fftSize: 1024, numberOfVisualBands: 20)
    private var audioFile: AVAudioFile?
    private var pcmBuffer: AVAudioPCMBuffer?
    
    private var isPlayingAudio: Bool = false
    private var isLoopingAudio: Bool = false
    private var audioDuration: TimeInterval = 0.0
    private var seekOffsetTime: TimeInterval = 0.0
    private var playbackTimer: Timer?
    
    // Closures for View Model notification
    public var onMagnitudesUpdated: (([Float]) -> Void)?
    public var onPlaybackProgress: ((TimeInterval, TimeInterval) -> Void)?
    public var onPlaybackEnded: (() -> Void)?
    
    public override init() {
        super.init()
        setupAudioSession()
        configureNodes()
        attachNodes()
        connectNodes()
        setupTap()
        startEngineIfNeeded()
    }
    
    deinit {
        stopPlaybackTimer()
        removeTap()
        engine.stop()
    }
    
    // MARK: - Audio Session
    private func setupAudioSession() {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playback,
                mode: .default,
                options: [.allowAirPlay, .allowBluetoothA2DP, .allowBluetoothHFP, .mixWithOthers]
            )
            try session.setActive(true)
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleInterruption),
                name: AVAudioSession.interruptionNotification,
                object: session
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleRouteChange),
                name: AVAudioSession.routeChangeNotification,
                object: session
            )
        } catch {
            print("[AudioEngineManager] Failed to setup AVAudioSession: \(error.localizedDescription)")
        }
        #endif
    }
    
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        
        switch type {
        case .began:
            pause()
        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    play()
                }
            }
        @unknown default:
            break
        }
    }
    
    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }
        
        if reason == .oldDeviceUnavailable {
            pause()
        }
    }
    
    // MARK: - Node Setup
    private func configureNodes() {
        let frequencies = EQBand.standardFrequencies
        for (i, freq) in frequencies.enumerated() {
            let band = eqNode.bands[i]
            band.frequency = freq
            band.gain = 0.0
            band.bandwidth = 1.0
            band.bypass = false
            
            if i == 0 {
                band.filterType = .lowShelf
            } else if i == frequencies.count - 1 {
                band.filterType = .highShelf
            } else {
                band.filterType = .parametric
            }
        }
        
        reverbNode.loadFactoryPreset(.mediumRoom)
        reverbNode.wetDryMix = 0.0
        reverbNode.bypass = true
        
        delayNode.delayTime = 0.25
        delayNode.feedback = 35.0
        delayNode.lowPassCutoff = 15000.0
        delayNode.wetDryMix = 0.0
        delayNode.bypass = true
        
        distortionNode.loadFactoryPreset(.drumsLoFi)
        distortionNode.wetDryMix = 0.0
        distortionNode.bypass = true
        
        pitchNode.pitch = 0.0
        pitchNode.rate = 1.0
        pitchNode.bypass = true
    }
    
    private func attachNodes() {
        engine.attach(playerNode)
        engine.attach(eqNode)
        engine.attach(pitchNode)
        engine.attach(distortionNode)
        engine.attach(delayNode)
        engine.attach(reverbNode)
    }
    
    public var defaultProcessingFormat: AVAudioFormat {
        let hwFormat = engine.outputNode.outputFormat(forBus: 0)
        let sampleRate = hwFormat.sampleRate > 0 ? hwFormat.sampleRate : 48000.0
        let channelCount = hwFormat.channelCount > 0 ? hwFormat.channelCount : 2
        return AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: channelCount) ?? AVAudioFormat(standardFormatWithSampleRate: 48000.0, channels: 2)!
    }
    
    private func connectNodes() {
        reconnectProcessingChain(format: defaultProcessingFormat)
        engine.prepare()
    }
    
    private func reconnectProcessingChain(format: AVAudioFormat) {
        engine.disconnectNodeOutput(playerNode)
        engine.disconnectNodeOutput(eqNode)
        engine.disconnectNodeOutput(pitchNode)
        engine.disconnectNodeOutput(distortionNode)
        engine.disconnectNodeOutput(delayNode)
        engine.disconnectNodeOutput(reverbNode)
        
        // Signal Chain:
        // playerNode -> eqNode -> pitchNode -> distortionNode -> delayNode -> reverbNode -> mainMixerNode -> outputNode
        engine.connect(playerNode, to: eqNode, format: format)
        engine.connect(eqNode, to: pitchNode, format: format)
        engine.connect(pitchNode, to: distortionNode, format: format)
        engine.connect(distortionNode, to: delayNode, format: format)
        engine.connect(delayNode, to: reverbNode, format: format)
        engine.connect(reverbNode, to: engine.mainMixerNode, format: format)
        
        let outFormat = engine.outputNode.outputFormat(forBus: 0)
        if outFormat.sampleRate > 0 && outFormat.channelCount > 0 {
            engine.connect(engine.mainMixerNode, to: engine.outputNode, format: outFormat)
        }
        engine.mainMixerNode.outputVolume = 1.0
        playerNode.volume = 1.0
    }
    
    private func setupTap() {
        let mixer = engine.mainMixerNode
        mixer.removeTap(onBus: 0)
        mixer.installTap(onBus: 0, bufferSize: 1024, format: nil) { [weak self] buffer, _ in
            guard let self = self else { return }
            let magnitudes = self.fftAnalyzer.process(buffer: buffer)
            DispatchQueue.main.async {
                self.onMagnitudesUpdated?(magnitudes)
            }
        }
    }
    
    private func removeTap() {
        engine.mainMixerNode.removeTap(onBus: 0)
    }
    
    private func startEngineIfNeeded() {
        if !engine.isRunning {
            do {
                #if os(iOS)
                try AVAudioSession.sharedInstance().setActive(true)
                #endif
                try engine.start()
            } catch {
                print("[AudioEngineManager] Engine start failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Equalizer Controls
    public func setBandGain(index: Int, gain: Float, bypass: Bool = false) {
        guard index >= 0 && index < eqNode.bands.count else { return }
        eqNode.bands[index].gain = max(-12.0, min(12.0, gain))
        eqNode.bands[index].bypass = bypass
    }
    
    public func setAllBandGains(_ gains: [Float]) {
        for (i, gain) in gains.enumerated() {
            if i < eqNode.bands.count {
                eqNode.bands[i].gain = max(-12.0, min(12.0, gain))
                eqNode.bands[i].bypass = false
            }
        }
    }
    
    public func setEQBypass(_ bypass: Bool) {
        eqNode.bypass = bypass
    }
    
    // MARK: - Audio Effects Controls
    public func updateEffects(_ settings: AudioEffectSettings) {
        reverbNode.bypass = !settings.isReverbEnabled
        reverbNode.loadFactoryPreset(settings.reverbPreset.avPreset)
        reverbNode.wetDryMix = settings.reverbWetDryMix
        
        delayNode.bypass = !settings.isDelayEnabled
        delayNode.delayTime = TimeInterval(settings.delayTime)
        delayNode.feedback = settings.delayFeedback
        delayNode.lowPassCutoff = settings.delayLowPassCutoff
        delayNode.wetDryMix = settings.delayWetDryMix
        
        distortionNode.bypass = !settings.isDistortionEnabled
        distortionNode.loadFactoryPreset(settings.distortionPreset.avPreset)
        distortionNode.wetDryMix = settings.distortionWetDryMix
        
        pitchNode.bypass = !settings.isPitchEnabled
        pitchNode.pitch = settings.pitchCents
        pitchNode.rate = settings.playbackRate
        
        engine.mainMixerNode.outputVolume = settings.masterVolume
        playerNode.pan = settings.panBalance
    }
    
    // MARK: - Loading Audio
    public func loadAudioFile(url: URL) throws -> (title: String, duration: TimeInterval, format: String) {
        stop()
        pcmBuffer = nil
        
        let file = try AVAudioFile(forReading: url)
        self.audioFile = file
        
        let sampleRate = file.processingFormat.sampleRate
        let length = Double(file.length)
        let duration = sampleRate > 0 ? length / sampleRate : 0.0
        self.audioDuration = duration
        self.seekOffsetTime = 0.0
        
        let formatDescription = "\(Int(sampleRate / 1000.0)) kHz • \(file.processingFormat.channelCount == 2 ? "Stereo" : "Mono")"
        let title = url.deletingPathExtension().lastPathComponent
        
        reconnectProcessingChain(format: file.processingFormat)
        scheduleFile(fromTime: 0.0)
        return (title: title, duration: duration, format: formatDescription)
    }
    
    public func loadDemoTone(type: DemoSoundType) -> (title: String, duration: TimeInterval, format: String) {
        stop()
        audioFile = nil
        
        let duration: Double = 8.0
        let format = defaultProcessingFormat
        guard let buffer = AudioToneGenerator.generateBuffer(type: type, duration: duration, sampleRate: format.sampleRate) else {
            return (title: type.rawValue, duration: 0.0, format: "Synth PCM")
        }
        
        self.pcmBuffer = buffer
        self.audioDuration = duration
        self.seekOffsetTime = 0.0
        
        reconnectProcessingChain(format: format)
        schedulePCMBuffer(buffer: buffer)
        return (title: type.rawValue, duration: duration, format: "\(Int(format.sampleRate / 1000.0)) kHz • Stereo Synth")
    }
    
    // MARK: - Scheduling & Playback
    private func scheduleFile(fromTime: TimeInterval) {
        guard let file = audioFile else { return }
        
        startEngineIfNeeded()
        playerNode.stop()
        
        let sampleRate = file.processingFormat.sampleRate
        let startFrame = AVAudioFramePosition(fromTime * sampleRate)
        let frameCount = AVAudioFrameCount(max(0, file.length - startFrame))
        
        guard frameCount > 0 else { return }
        
        playerNode.scheduleSegment(
            file,
            startingFrame: startFrame,
            frameCount: frameCount,
            at: nil
        ) { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if self.isLoopingAudio && self.isPlayingAudio {
                    self.seek(to: 0.0)
                    self.play()
                } else {
                    self.isPlayingAudio = false
                    self.stopPlaybackTimer()
                    self.onPlaybackEnded?()
                }
            }
        }
    }
    
    private func schedulePCMBuffer(buffer: AVAudioPCMBuffer) {
        startEngineIfNeeded()
        playerNode.stop()
        
        let options: AVAudioPlayerNodeBufferOptions = isLoopingAudio ? [.loops] : []
        playerNode.scheduleBuffer(buffer, at: nil, options: options) { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if !self.isLoopingAudio {
                    self.isPlayingAudio = false
                    self.stopPlaybackTimer()
                    self.onPlaybackEnded?()
                }
            }
        }
    }
    
    // MARK: - Transport Controls
    public func play() {
        startEngineIfNeeded()
        playerNode.play()
        isPlayingAudio = true
        startPlaybackTimer()
    }
    
    public func pause() {
        playerNode.pause()
        isPlayingAudio = false
        stopPlaybackTimer()
    }
    
    public func stop() {
        playerNode.stop()
        isPlayingAudio = false
        seekOffsetTime = 0.0
        stopPlaybackTimer()
        onPlaybackProgress?(0.0, audioDuration)
    }
    
    public func seek(to time: TimeInterval) {
        let clampedTime = max(0.0, min(time, audioDuration))
        seekOffsetTime = clampedTime
        
        if let _ = audioFile {
            let wasPlaying = isPlayingAudio
            scheduleFile(fromTime: clampedTime)
            if wasPlaying {
                playerNode.play()
            }
        } else if let buffer = pcmBuffer {
            let wasPlaying = isPlayingAudio
            schedulePCMBuffer(buffer: buffer)
            if wasPlaying {
                playerNode.play()
            }
        }
        
        onPlaybackProgress?(clampedTime, audioDuration)
    }
    
    public func setLooping(_ looping: Bool) {
        self.isLoopingAudio = looping
        if let buffer = pcmBuffer, isPlayingAudio {
            schedulePCMBuffer(buffer: buffer)
            playerNode.play()
        }
    }
    
    // MARK: - Playback Progress Timer
    private func startPlaybackTimer() {
        stopPlaybackTimer()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.updateCurrentTime()
        }
    }
    
    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    private func updateCurrentTime() {
        guard isPlayingAudio else { return }
        
        if let nodeTime = playerNode.lastRenderTime,
           let playerTime = playerNode.playerTime(forNodeTime: nodeTime) {
            let sampleRate = playerTime.sampleRate
            guard sampleRate > 0 else { return }
            let elapsed = Double(playerTime.sampleTime) / sampleRate
            let current = (seekOffsetTime + elapsed).truncatingRemainder(dividingBy: max(0.001, audioDuration))
            onPlaybackProgress?(current, audioDuration)
        }
    }
}
