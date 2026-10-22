import Foundation
import AVFoundation
import Accelerate

/// Real-time Hardware Microphone & Headphone DSP Engine.
/// Captures mic audio, applies low-cut noise filters, 10-band mic EQ, pitch shifting,
/// and streams directly to AirPods/Headphones with ultra-low latency.
public final class LiveInputMonitorEngine: NSObject {
    private let engine = AVAudioEngine()
    private let micEQ = AVAudioUnitEQ(numberOfBands: 10)
    private let pitchShifter = AVAudioUnitTimePitch()
    private let fftAnalyzer = FFTAnalyzer(fftSize: 1024, numberOfVisualBands: 20)
    
    public private(set) var isRunning: Bool = false
    public var micGain: Float = 1.0 // 0.0 to 3.0 (+10 dB boost)
    public var noiseGateThreshold: Float = -45.0 // dB
    public var isNoiseGateEnabled: Bool = true
    
    public var onMicMagnitudesUpdated: (([Float]) -> Void)?
    
    public override init() {
        super.init()
        configureMicNodes()
        attachNodes()
    }
    
    deinit {
        stopMonitoring()
    }
    
    private func configureMicNodes() {
        let freqs = EQBand.standardFrequencies
        for (i, freq) in freqs.enumerated() {
            let band = micEQ.bands[i]
            band.frequency = freq
            band.gain = 0.0
            band.bandwidth = 1.0
            band.bypass = false
            band.filterType = (i == 0) ? .highPass : .parametric
        }
        
        pitchShifter.pitch = 0.0
        pitchShifter.rate = 1.0
        pitchShifter.bypass = true
    }
    
    private func attachNodes() {
        engine.attach(micEQ)
        engine.attach(pitchShifter)
    }
    
    public func startMonitoring() throws {
        guard !isRunning else { return }
        
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playAndRecord,
            mode: .default,
            options: [.allowBluetoothHFP, .allowBluetoothA2DP, .defaultToSpeaker]
        )
        try session.setPreferredIOBufferDuration(0.005)
        try session.setActive(true)
        #endif
        
        let inputNode = engine.inputNode
        let rawFormat = inputNode.inputFormat(forBus: 0)
        let sampleRate = rawFormat.sampleRate > 0 ? rawFormat.sampleRate : 48000.0
        let channelCount = rawFormat.channelCount > 0 ? rawFormat.channelCount : 1
        guard let inputFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: channelCount) else {
            throw NSError(domain: "LiveInputMonitorEngine", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to configure microphone format"])
        }
        
        engine.disconnectNodeOutput(inputNode)
        engine.disconnectNodeOutput(micEQ)
        engine.disconnectNodeOutput(pitchShifter)
        
        // Connect mic graph: InputNode -> micEQ -> pitchShifter -> mainMixer -> outputNode
        engine.connect(inputNode, to: micEQ, format: inputFormat)
        engine.connect(micEQ, to: pitchShifter, format: inputFormat)
        engine.connect(pitchShifter, to: engine.mainMixerNode, format: inputFormat)
        
        let outputFormat = engine.outputNode.outputFormat(forBus: 0)
        if outputFormat.sampleRate > 0 && outputFormat.channelCount > 0 {
            engine.connect(engine.mainMixerNode, to: engine.outputNode, format: outputFormat)
        }
        engine.mainMixerNode.outputVolume = 1.0
        
        // Tap on mainMixerNode for real-time visualizer
        engine.mainMixerNode.removeTap(onBus: 0)
        engine.mainMixerNode.installTap(onBus: 0, bufferSize: 512, format: nil) { [weak self] buffer, _ in
            guard let self = self else { return }
            let mags = self.fftAnalyzer.process(buffer: buffer)
            DispatchQueue.main.async {
                self.onMicMagnitudesUpdated?(mags)
            }
        }
        
        engine.prepare()
        try engine.start()
        isRunning = true
    }
    
    public func stopMonitoring() {
        guard isRunning else { return }
        engine.mainMixerNode.removeTap(onBus: 0)
        engine.stop()
        isRunning = false
    }
    
    public func setMicBandGain(index: Int, gain: Float) {
        guard index >= 0 && index < micEQ.bands.count else { return }
        micEQ.bands[index].gain = max(-12.0, min(12.0, gain))
    }
    
    public func setVoicePitch(cents: Float) {
        pitchShifter.pitch = cents
        pitchShifter.bypass = (cents == 0.0)
    }
}
