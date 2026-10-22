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
    private let distortion = AVAudioUnitDistortion()
    private let fftAnalyzer = FFTAnalyzer(fftSize: 1024, numberOfVisualBands: 20)
    
    public private(set) var isRunning: Bool = false
    public var micGain: Float = 1.0 // 0.0 to 4.0 (+12 dB boost)
    public var noiseGateThreshold: Float = -45.0 // dB
    public var isNoiseGateEnabled: Bool = true
    
    public var onMicMagnitudesUpdated: (([Float]) -> Void)?
    
    public override init() {
        super.init()
        configureMicNodes()
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
    
    public func startMonitoring() throws {
        guard !isRunning else { return }
        
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playAndRecord,
            mode: .measurement,
            options: [.allowBluetoothHFP, .allowBluetoothA2DP, .defaultToSpeaker]
        )
        // Request ultra-low I/O buffer duration for real-time monitoring (approx 5.8ms)
        try session.setPreferredIOBufferDuration(0.005)
        try session.setActive(true)
        #endif
        
        let inputNode = engine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        
        engine.attach(micEQ)
        engine.attach(pitchShifter)
        
        // Connect: InputNode -> micEQ -> pitchShifter -> mainMixer -> OutputNode
        engine.connect(inputNode, to: micEQ, format: inputFormat)
        engine.connect(micEQ, to: pitchShifter, format: inputFormat)
        engine.connect(pitchShifter, to: engine.mainMixerNode, format: inputFormat)
        
        // Install tap on input for FFT visualizer and software noise gate / mic gain
        engine.mainMixerNode.installTap(onBus: 0, bufferSize: 512, format: inputFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            
            // Apply software mic boost & noise gate
            if let channelData = buffer.floatChannelData?[0] {
                let frameCount = Int(buffer.frameLength)
                var rms: Float = 0.0
                vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(frameCount))
                let db = 20.0 * log10(max(0.00001, rms))
                
                if self.isNoiseGateEnabled && db < self.noiseGateThreshold {
                    // Mute silent noise floor
                    vDSP_vclr(channelData, 1, vDSP_Length(frameCount))
                } else if self.micGain != 1.0 {
                    var gain = self.micGain
                    vDSP_vsmul(channelData, 1, &gain, channelData, 1, vDSP_Length(frameCount))
                }
            }
            
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
