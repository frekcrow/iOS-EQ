import Foundation
import Accelerate
import AVFoundation

/// Analyzes real-time audio PCM buffers using Accelerate's vDSP FFT
/// to generate smooth frequency spectrum magnitudes for visualization.
public final class FFTAnalyzer {
    private let fftSize: Int
    private let log2n: vDSP_Length
    private let halfSize: Int
    private var fftSetup: vDSP_DFT_Setup?
    
    // Smooth decay values to prevent erratic visual jumping
    private var previousMagnitudes: [Float]
    private let numberOfVisualBands: Int
    private let decayRate: Float = 0.82
    private let minDb: Float = -70.0
    private let maxDb: Float = 0.0
    
    public init(fftSize: Int = 1024, numberOfVisualBands: Int = 20) {
        self.fftSize = fftSize
        self.log2n = vDSP_Length(log2(Double(fftSize)))
        self.halfSize = fftSize / 2
        self.numberOfVisualBands = numberOfVisualBands
        self.previousMagnitudes = [Float](repeating: 0.0, count: numberOfVisualBands)
        
        // Setup vDSP 1D Real forward FFT
        self.fftSetup = vDSP_DFT_zop_CreateSetup(
            nil,
            vDSP_Length(fftSize),
            vDSP_DFT_Direction.FORWARD
        )
    }
    
    deinit {
        if let setup = fftSetup {
            vDSP_DFT_DestroySetup(setup)
        }
    }
    
    /// Processes an audio buffer and returns an array of normalized band magnitudes (0.0 to 1.0).
    public func process(buffer: AVAudioPCMBuffer) -> [Float] {
        guard let channelData = buffer.floatChannelData?[0] else {
            return decayMagnitudes()
        }
        
        let frameLength = Int(buffer.frameLength)
        guard frameLength >= fftSize else {
            return decayMagnitudes()
        }
        
        // 1. Apply Hann window to reduce spectral leakage
        var window = [Float](repeating: 0.0, count: fftSize)
        vDSP_hann_window(&window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
        
        var windowedInput = [Float](repeating: 0.0, count: fftSize)
        vDSP_vmul(channelData, 1, window, 1, &windowedInput, 1, vDSP_Length(fftSize))
        
        // 2. Prepare split complex arrays
        var realIn = windowedInput
        var imagIn = [Float](repeating: 0.0, count: fftSize)
        var realOut = [Float](repeating: 0.0, count: fftSize)
        var imagOut = [Float](repeating: 0.0, count: fftSize)
        
        guard let setup = fftSetup else {
            return decayMagnitudes()
        }
        
        vDSP_DFT_Execute(setup, &realIn, &imagIn, &realOut, &imagOut)
        
        // 3. Compute magnitudes: sqrt(real^2 + imag^2)
        var magnitudes = [Float](repeating: 0.0, count: halfSize)
        realOut.withUnsafeMutableBufferPointer { realPtr in
            imagOut.withUnsafeMutableBufferPointer { imagPtr in
                guard let rBase = realPtr.baseAddress, let iBase = imagPtr.baseAddress else { return }
                var splitComplex = DSPSplitComplex(realp: rBase, imagp: iBase)
                vDSP_zvabs(&splitComplex, 1, &magnitudes, 1, vDSP_Length(halfSize))
            }
        }
        
        // 4. Group bins into logarithmic frequency bands
        let bandMagnitudes = computeLogarithmicBands(magnitudes: magnitudes, sampleRate: Float(buffer.format.sampleRate))
        
        // 5. Apply smooth decay and return
        for i in 0..<numberOfVisualBands {
            let current = bandMagnitudes[i]
            let prev = previousMagnitudes[i]
            
            if current >= prev {
                previousMagnitudes[i] = current
            } else {
                previousMagnitudes[i] = prev * decayRate + current * (1.0 - decayRate)
            }
        }
        
        return previousMagnitudes
    }
    
    private func computeLogarithmicBands(magnitudes: [Float], sampleRate: Float) -> [Float] {
        var bands = [Float](repeating: 0.0, count: numberOfVisualBands)
        
        // Bin width in Hz
        let binWidth = sampleRate / Float(fftSize)
        
        // Frequency limits (approx 20 Hz to 20,000 Hz)
        let minFreq: Float = 25.0
        let maxFreq: Float = min(sampleRate / 2.0, 18000.0)
        
        // Logarithmic spacing
        let minLog = log10(minFreq)
        let maxLog = log10(maxFreq)
        let logStep = (maxLog - minLog) / Float(numberOfVisualBands)
        
        for bandIndex in 0..<numberOfVisualBands {
            let startFreq = pow(10.0, minLog + Float(bandIndex) * logStep)
            let endFreq = pow(10.0, minLog + Float(bandIndex + 1) * logStep)
            
            let startBin = max(0, min(Int(startFreq / binWidth), halfSize - 1))
            let endBin = max(startBin + 1, min(Int(endFreq / binWidth), halfSize))
            
            var sum: Float = 0.0
            let count = endBin - startBin
            if count > 0 {
                for bin in startBin..<endBin {
                    sum += magnitudes[bin]
                }
                let avg = sum / Float(count)
                
                // Convert to decibels: 20 * log10(avg + epsilon)
                let db = 20.0 * log10(max(avg, 0.00001))
                
                // Normalize between 0.0 and 1.0 based on minDb and maxDb
                let normalized = (db - minDb) / (maxDb - minDb)
                bands[bandIndex] = max(0.0, min(1.0, normalized))
            }
        }
        
        return bands
    }
    
    private func decayMagnitudes() -> [Float] {
        for i in 0..<previousMagnitudes.count {
            previousMagnitudes[i] *= decayRate
            if previousMagnitudes[i] < 0.01 {
                previousMagnitudes[i] = 0.0
            }
        }
        return previousMagnitudes
    }
}
