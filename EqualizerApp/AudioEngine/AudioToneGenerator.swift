import Foundation
import AVFoundation

/// Types of demo audio synthesis available for testing the equalizer without loading external files.
public enum DemoSoundType: String, CaseIterable, Identifiable {
    case synthChord = "Harmonic Synth Pad"
    case pinkNoise = "Pink Noise (EQ Reference)"
    case drumGroove = "Rhythmic Beat Loop"
    case sineSweep = "Frequency Sine Sweep"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .synthChord: return "pianokeys"
        case .pinkNoise: return "waveform"
        case .drumGroove: return "music.note.list"
        case .sineSweep: return "waveform.path.badge.plus"
        }
    }
}

/// Synthesizes high quality PCM audio buffers for instant equalizer testing and demonstration.
public final class AudioToneGenerator {
    
    /// Generates an AVAudioPCMBuffer containing high quality synthesized audio.
    public static func generateBuffer(
        type: DemoSoundType,
        duration: Double = 6.0,
        sampleRate: Double = 48000.0
    ) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2) else {
            return nil
        }
        
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        
        buffer.frameLength = frameCount
        guard let leftChannel = buffer.floatChannelData?[0],
              let rightChannel = buffer.floatChannelData?[1] else {
            return nil
        }
        
        switch type {
        case .synthChord:
            generateHarmonicPad(left: leftChannel, right: rightChannel, count: Int(frameCount), sampleRate: sampleRate)
        case .pinkNoise:
            generatePinkNoise(left: leftChannel, right: rightChannel, count: Int(frameCount))
        case .drumGroove:
            generateDrumGroove(left: leftChannel, right: rightChannel, count: Int(frameCount), sampleRate: sampleRate)
        case .sineSweep:
            generateFrequencySweep(left: leftChannel, right: rightChannel, count: Int(frameCount), sampleRate: sampleRate, duration: duration)
        }
        
        return buffer
    }
    
    // MARK: - Harmonic Synth Pad
    private static func generateHarmonicPad(
        left: UnsafeMutablePointer<Float>,
        right: UnsafeMutablePointer<Float>,
        count: Int,
        sampleRate: Double
    ) {
        // Chord: C3 (130.81 Hz), G3 (196.00 Hz), C4 (261.63 Hz), E4 (329.63 Hz), G4 (392.00 Hz), B4 (493.88 Hz)
        let freqs: [Double] = [65.41, 130.81, 196.0, 261.63, 329.63, 392.0, 493.88, 659.25, 1046.5]
        let weights: [Float] = [0.25, 0.20, 0.18, 0.16, 0.14, 0.12, 0.08, 0.05, 0.03]
        
        for frame in 0..<count {
            let t = Double(frame) / sampleRate
            
            // Envelope with smooth fade in / fade out for seamless looping
            let attack = min(1.0, Float(frame) / Float(sampleRate * 0.4))
            let release = min(1.0, Float(count - frame) / Float(sampleRate * 0.4))
            let envelope = attack * release
            
            var sampleLeft: Float = 0.0
            var sampleRight: Float = 0.0
            
            for (idx, freq) in freqs.enumerated() {
                // Slight stereo detuning for rich chorus effect
                let detuneL = sin(2.0 * .pi * (freq * 0.998) * t)
                let detuneR = sin(2.0 * .pi * (freq * 1.002) * t)
                
                // Add soft sub-harmonics and shimmer
                let lfo = Float(0.85 + 0.15 * sin(2.0 * .pi * 0.3 * t + Double(idx)))
                sampleLeft += Float(detuneL) * weights[idx] * lfo
                sampleRight += Float(detuneR) * weights[idx] * lfo
            }
            
            left[frame] = sampleLeft * envelope * 0.75
            right[frame] = sampleRight * envelope * 0.75
        }
    }
    
    // MARK: - Pink Noise
    private static func generatePinkNoise(
        left: UnsafeMutablePointer<Float>,
        right: UnsafeMutablePointer<Float>,
        count: Int
    ) {
        // Paul Kellet's filtered pink noise algorithm
        var b0_L: Float = 0, b1_L: Float = 0, b2_L: Float = 0, b3_L: Float = 0, b4_L: Float = 0, b5_L: Float = 0, b6_L: Float = 0
        var b0_R: Float = 0, b1_R: Float = 0, b2_R: Float = 0, b3_R: Float = 0, b4_R: Float = 0, b5_R: Float = 0, b6_R: Float = 0
        
        for frame in 0..<count {
            let whiteL = (Float.random(in: -1.0...1.0)) * 0.12
            b0_L = 0.99886 * b0_L + whiteL * 0.0555179
            b1_L = 0.99332 * b1_L + whiteL * 0.0750759
            b2_L = 0.96900 * b2_L + whiteL * 0.1538520
            b3_L = 0.86650 * b3_L + whiteL * 0.3104856
            b4_L = 0.55000 * b4_L + whiteL * 0.5329522
            b5_L = -0.7616 * b5_L - whiteL * 0.0168980
            let pinkL = (b0_L + b1_L + b2_L + b3_L + b4_L + b5_L + b6_L + whiteL * 0.5362) * 0.12
            b6_L = whiteL * 0.115926
            
            let whiteR = (Float.random(in: -1.0...1.0)) * 0.12
            b0_R = 0.99886 * b0_R + whiteR * 0.0555179
            b1_R = 0.99332 * b1_R + whiteR * 0.0750759
            b2_R = 0.96900 * b2_R + whiteR * 0.1538520
            b3_R = 0.86650 * b3_R + whiteR * 0.3104856
            b4_R = 0.55000 * b4_R + whiteR * 0.5329522
            b5_R = -0.7616 * b5_R - whiteR * 0.0168980
            let pinkR = (b0_R + b1_R + b2_R + b3_R + b4_R + b5_R + b6_R + whiteR * 0.5362) * 0.12
            b6_R = whiteR * 0.115926
            
            // Loop envelope
            let env = min(1.0, Float(frame) / 2000.0) * min(1.0, Float(count - frame) / 2000.0)
            left[frame] = pinkL * env
            right[frame] = pinkR * env
        }
    }
    
    // MARK: - Rhythmic Beat Loop
    private static func generateDrumGroove(
        left: UnsafeMutablePointer<Float>,
        right: UnsafeMutablePointer<Float>,
        count: Int,
        sampleRate: Double
    ) {
        let bpm = 120.0
        let secondsPerBeat = 60.0 / bpm
        let samplesPerBeat = Int(secondsPerBeat * sampleRate)
        
        for frame in 0..<count {
            let beatIndex = frame / samplesPerBeat
            let beatFraction = Double(frame % samplesPerBeat) / sampleRate
            
            var sample: Float = 0.0
            
            // Kick on beats 0, 2 (or 1st and 3rd in 4/4)
            if beatIndex % 2 == 0 {
                let kickTime = beatFraction
                if kickTime < 0.25 {
                    let freq = max(40.0, 160.0 * exp(-kickTime * 28.0))
                    let amp = Float(exp(-kickTime * 14.0))
                    sample += Float(sin(2.0 * .pi * freq * kickTime)) * amp * 0.65
                }
            }
            
            // Snare on beats 1, 3
            if beatIndex % 2 == 1 {
                let snareTime = beatFraction
                if snareTime < 0.20 {
                    let noise = Float.random(in: -1.0...1.0) * Float(exp(-snareTime * 20.0))
                    let tone = Float(sin(2.0 * .pi * 185.0 * snareTime)) * Float(exp(-snareTime * 25.0))
                    sample += (noise * 0.45 + tone * 0.35)
                }
            }
            
            // Hi-hat on every 8th note (half-beat)
            let halfBeatFraction = (Double(frame % (samplesPerBeat / 2))) / sampleRate
            if halfBeatFraction < 0.05 {
                let hhNoise = Float.random(in: -1.0...1.0) * Float(exp(-halfBeatFraction * 90.0))
                sample += hhNoise * 0.18
            }
            
            // Bassline pulse
            let bassFreq = (beatIndex % 4 < 2) ? 65.41 : 49.00 // C2 or G1
            let bass = Float(sin(2.0 * .pi * bassFreq * Double(frame) / sampleRate)) * 0.2
            sample += bass
            
            let env = min(1.0, Float(frame) / 2000.0) * min(1.0, Float(count - frame) / 2000.0)
            left[frame] = sample * env * 0.8
            right[frame] = sample * env * 0.8
        }
    }
    
    // MARK: - Frequency Sweep
    private static func generateFrequencySweep(
        left: UnsafeMutablePointer<Float>,
        right: UnsafeMutablePointer<Float>,
        count: Int,
        sampleRate: Double,
        duration: Double
    ) {
        let f0 = 30.0
        let f1 = 16000.0
        
        for frame in 0..<count {
            let t = Double(frame) / sampleRate
            let normalizedTime = t / duration
            let phase = 2.0 * .pi * f0 * (pow(f1 / f0, normalizedTime) - 1.0) / log(f1 / f0) * duration
            
            let sample = Float(sin(phase)) * 0.4
            let env = min(1.0, Float(frame) / 2000.0) * min(1.0, Float(count - frame) / 2000.0)
            
            left[frame] = sample * env
            right[frame] = sample * env
        }
    }
}
