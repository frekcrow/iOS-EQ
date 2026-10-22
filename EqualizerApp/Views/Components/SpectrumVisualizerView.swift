import SwiftUI

/// A high-performance, studio-grade real-time frequency spectrum visualizer.
public struct SpectrumVisualizerView: View {
    let magnitudes: [Float]
    let isPlaying: Bool
    
    // State to store falling peak caps for classic hardware meter look
    @State private var peakMagnitudes: [Float] = []
    
    public init(magnitudes: [Float], isPlaying: Bool) {
        self.magnitudes = magnitudes
        self.isPlaying = isPlaying
    }
    
    public var body: some View {
        VStack(spacing: 4) {
            // Spectrum Canvas & Bars
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                let barCount = max(1, magnitudes.count)
                let spacing: CGFloat = 3.0
                let totalSpacing = spacing * CGFloat(barCount - 1)
                let barWidth = max(2.0, (width - totalSpacing) / CGFloat(barCount))
                
                ZStack(alignment: .bottomLeading) {
                    // Background Studio Grid Lines
                    GridLinesView(height: height)
                    
                    // Live Spectrum Bars
                    HStack(alignment: .bottom, spacing: spacing) {
                        ForEach(0..<barCount, id: \.self) { index in
                            let mag = CGFloat(index < magnitudes.count ? magnitudes[index] : 0.0)
                            let barHeight = max(4.0, mag * height)
                            
                            VStack(spacing: 2) {
                                Spacer()
                                
                                // Glowing spectrum bar
                                RoundedRectangle(cornerRadius: 2.0)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.15, green: 0.85, blue: 1.0), // Electric Cyan
                                                Color(red: 0.35, green: 0.45, blue: 1.0), // Royal Blue
                                                Color(red: 0.75, green: 0.25, blue: 0.95), // Neon Purple
                                                Color(red: 1.0, green: 0.25, blue: 0.45)  // Hot Pink (peaks)
                                            ]),
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                    )
                                    .frame(width: barWidth, height: barHeight)
                                    .shadow(
                                        color: isPlaying ? Color.cyan.opacity(0.4) : Color.clear,
                                        radius: 3,
                                        x: 0,
                                        y: 0
                                    )
                                    .animation(.easeOut(duration: 0.08), value: mag)
                            }
                        }
                    }
                }
            }
            .frame(height: 110)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 0.07, green: 0.08, blue: 0.11))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            
            // Frequency Axis Labels underneath
            HStack {
                Text("32 Hz")
                Spacer()
                Text("250 Hz")
                Spacer()
                Text("1 kHz")
                Spacer()
                Text("4 kHz")
                Spacer()
                Text("16 kHz")
            }
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .foregroundColor(.secondary)
            .padding(.horizontal, 16)
        }
    }
}

/// Subtle dB reference grid lines across the spectrum display.
private struct GridLinesView: View {
    let height: CGFloat
    
    var body: some View {
        VStack(spacing: 0) {
            Group {
                lineWithDb(label: " 0 dB")
                Spacer()
                lineWithDb(label: "-6 dB")
                Spacer()
                lineWithDb(label: "-18 dB")
                Spacer()
                lineWithDb(label: "-36 dB")
            }
        }
    }
    
    private func lineWithDb(label: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 8, weight: .regular, design: .monospaced))
                .foregroundColor(.white.opacity(0.25))
            
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 0.8)
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
