import SwiftUI

/// Studio-grade real-time frequency spectrum visualizer with hardware peak hold caps,
/// optical frequency grid lines, and smooth dynamic spring ballistics.
public struct SpectrumVisualizerView: View {
    let magnitudes: [Float]
    let isPlaying: Bool
    
    // Falling peak caps for physical analog hardware meter experience
    @State private var peakMagnitudes: [Float] = Array(repeating: 0.0, count: 20)
    @State private var peakHoldTimers: [Double] = Array(repeating: 0.0, count: 20)
    
    public init(magnitudes: [Float], isPlaying: Bool) {
        self.magnitudes = magnitudes
        self.isPlaying = isPlaying
    }
    
    public var body: some View {
        VStack(spacing: 6) {
            // Spectrum Display Enclosure
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                let barCount = max(1, magnitudes.count)
                let spacing: CGFloat = 3.5
                let totalSpacing = spacing * CGFloat(barCount - 1)
                let barWidth = max(2.5, (width - totalSpacing) / CGFloat(barCount))
                
                ZStack(alignment: .bottomLeading) {
                    // Studio dB Reference Lines
                    GridLinesView(height: height)
                    
                    // Live Spectrum Bars & Peak Caps
                    HStack(alignment: .bottom, spacing: spacing) {
                        ForEach(0..<barCount, id: \.self) { index in
                            let rawMag = index < magnitudes.count ? magnitudes[index] : 0.0
                            let currentMag = CGFloat(isPlaying ? rawMag : 0.0)
                            let barHeight = max(3.0, currentMag * (height - 8))
                            
                            // Peak calculation
                            let peakVal = CGFloat(index < peakMagnitudes.count ? peakMagnitudes[index] : 0.0)
                            let peakY = max(4.0, isPlaying ? peakVal * (height - 8) : 3.0)
                            
                            VStack(spacing: 0) {
                                Spacer()
                                
                                ZStack(alignment: .bottom) {
                                    // Main Glowing Spectrum Bar
                                    RoundedRectangle(cornerRadius: 2.0)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    EqualizerTheme.Colors.cyanAccent,
                                                    EqualizerTheme.Colors.royalBlue,
                                                    EqualizerTheme.Colors.violet,
                                                    EqualizerTheme.Colors.tubeAmber,
                                                    EqualizerTheme.Colors.peakPink
                                                ]),
                                                startPoint: .bottom,
                                                endPoint: .top
                                            )
                                        )
                                        .frame(width: barWidth, height: barHeight)
                                        .shadow(
                                            color: isPlaying ? EqualizerTheme.Colors.cyanAccent.opacity(0.35) : Color.clear,
                                            radius: 3,
                                            x: 0,
                                            y: -1
                                        )
                                    
                                    // Peak Hold Cap Tick (floating LED tick)
                                    if isPlaying && peakY > 6 {
                                        RoundedRectangle(cornerRadius: 1.0)
                                            .fill(peakY > height * 0.8 ? EqualizerTheme.Colors.peakPink : EqualizerTheme.Colors.tubeAmber)
                                            .frame(width: barWidth, height: 2.0)
                                            .offset(y: -peakY)
                                            .shadow(color: EqualizerTheme.Colors.tubeAmber.opacity(0.6), radius: 2)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .frame(height: 108)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                // Double-bezel machined screen with subtle top edge specular reflection
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(EqualizerTheme.Colors.backgroundBase)
                    
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.14), Color.white.opacity(0.04)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 3)
            
            // Optical Frequency Legend with Monospaced Tracking
            HStack {
                Text("32")
                Spacer()
                Text("125")
                Spacer()
                Text("500")
                Spacer()
                Text("2k")
                Spacer()
                Text("8k")
                Spacer()
                Text("16k Hz")
            }
            .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
            .foregroundColor(.secondary.opacity(0.8))
            .padding(.horizontal, 16)
        }
        .onReceive(Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()) { _ in
            guard isPlaying else {
                if !peakMagnitudes.isEmpty {
                    peakMagnitudes = Array(repeating: 0.0, count: 20)
                }
                return
            }
            updatePeaks()
        }
    }
    
    private func updatePeaks() {
        if peakMagnitudes.count != magnitudes.count {
            peakMagnitudes = Array(repeating: 0.0, count: magnitudes.count)
        }
        for i in 0..<magnitudes.count {
            let current = magnitudes[i]
            let prevPeak = peakMagnitudes[i]
            if current >= prevPeak {
                peakMagnitudes[i] = current
            } else {
                // Decay peak downward smoothly
                peakMagnitudes[i] = max(0.0, prevPeak * 0.94 - 0.01)
            }
        }
    }
}

/// Precise studio dB reference grid lines with negative tracking.
private struct GridLinesView: View {
    let height: CGFloat
    
    var body: some View {
        VStack(spacing: 0) {
            lineWithDb(label: " 0 dB")
            Spacer()
            lineWithDb(label: "-6 dB")
            Spacer()
            lineWithDb(label: "-12 dB")
            Spacer()
            lineWithDb(label: "-24 dB")
            Spacer()
            lineWithDb(label: "-48 dB")
        }
        .padding(.vertical, 2)
    }
    
    private func lineWithDb(label: String) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 7.5, weight: .regular, design: .monospaced))
                .foregroundColor(.white.opacity(0.20))
                .frame(width: 32, alignment: .leading)
            
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 0.75)
        }
    }
}

#if DEBUG
struct SpectrumVisualizerView_Previews: PreviewProvider {
    static var previews: some View {
        SpectrumVisualizerView(
            magnitudes: [0.1, 0.3, 0.6, 0.9, 0.7, 0.5, 0.8, 0.4, 0.3, 0.5, 0.7, 0.85, 0.6, 0.4, 0.3, 0.2, 0.1, 0.15, 0.1, 0.05],
            isPlaying: true
        )
        .padding()
        .preferredColorScheme(.dark)
    }
}
#endif
