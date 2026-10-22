import SwiftUI

/// Custom studio-styled vertical slider for graphic equalizer frequency bands.
public struct VerticalSliderView: View {
    let band: EQBand
    let onGainChanged: (Float) -> Void
    let onBypassToggled: () -> Void
    
    // Gain range: -12.0 to +12.0 dB
    private let minGain: Float = -12.0
    private let maxGain: Float = 12.0
    
    @State private var isDragging: Bool = false
    
    public init(
        band: EQBand,
        onGainChanged: @escaping (Float) -> Void,
        onBypassToggled: @escaping () -> Void
    ) {
        self.band = band
        self.onGainChanged = onGainChanged
        self.onBypassToggled = onBypassToggled
    }
    
    public var body: some View {
        VStack(spacing: 6) {
            // Gain readout label
            Text(formattedGain(band.gain))
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(gainTextColor)
                .frame(width: 44, height: 16)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isDragging ? Color.cyan.opacity(0.2) : Color.white.opacity(0.05))
                )
            
            // Vertical Slider Track
            GeometryReader { geometry in
                let height = geometry.size.height
                let thumbRadius: CGFloat = 13.0
                let trackHeight = max(10, height - thumbRadius * 2)
                
                // Normalized position: 0.0 at bottom (-12 dB), 1.0 at top (+12 dB), 0.5 at center (0 dB)
                let normalized = CGFloat((band.gain - minGain) / (maxGain - minGain))
                let thumbY = height - thumbRadius - (normalized * trackHeight)
                
                ZStack(alignment: .top) {
                    // Outer track trough
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 6, height: height)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                    
                    // Center 0 dB marker tick
                    Rectangle()
                        .fill(Color.white.opacity(0.35))
                        .frame(width: 14, height: 1.5)
                        .position(x: geometry.size.width / 2, y: height / 2)
                    
                    // Boost / Cut colored indicator line from center (0 dB) to current thumb position
                    let centerY = height / 2
                    let fillHeight = abs(centerY - thumbY)
                    let fillY = min(centerY, thumbY) + fillHeight / 2
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            band.bypass
                                ? Color.gray.opacity(0.3)
                                : (band.gain >= 0
                                   ? LinearGradient(colors: [Color.cyan, Color.blue], startPoint: .top, endPoint: .bottom)
                                   : LinearGradient(colors: [Color.orange, Color.red], startPoint: .bottom, endPoint: .top))
                        )
                        .frame(width: 4, height: fillHeight)
                        .position(x: geometry.size.width / 2, y: fillY)
                    
                    // Slider Thumb (Hardware Fader Knob style)
                    FaderKnobView(isDragging: isDragging, isBypassed: band.bypass)
                        .position(x: geometry.size.width / 2, y: thumbY)
                        .shadow(color: isDragging ? Color.cyan.opacity(0.5) : Color.black.opacity(0.4), radius: isDragging ? 5 : 2)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            let touchY = value.location.y
                            let clampedY = max(thumbRadius, min(height - thumbRadius, touchY))
                            let fraction = 1.0 - ((clampedY - thumbRadius) / trackHeight)
                            var newGain = minGain + Float(fraction) * (maxGain - minGain)
                            
                            // Snap to 0 dB when close to center for tactile precision
                            if abs(newGain) < 0.4 {
                                newGain = 0.0
                            }
                            
                            onGainChanged(newGain)
                        }
                        .onEnded { _ in
                            isDragging = false
                            triggerHapticFeedback()
                        }
                )
                .onTapGesture(count: 2) {
                    // Double tap quickly resets this band to 0.0 dB
                    onGainChanged(0.0)
                    triggerHapticFeedback()
                }
            }
            .frame(width: 32)
            
            // Frequency label badge
            VStack(spacing: 2) {
                Text(band.frequencyFormatted)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(band.bypass ? .gray : .primary)
                
                Text(band.filterType == .lowShelf ? "LOW" : (band.filterType == .highShelf ? "HIGH" : "PEAK"))
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .frame(width: 36)
            .contentShape(Rectangle())
            .onTapGesture {
                // Tapping label toggles band bypass
                onBypassToggled()
                triggerHapticFeedback()
            }
        }
        .opacity(band.bypass ? 0.4 : 1.0)
    }
    
    private var gainTextColor: Color {
        if band.bypass { return .secondary }
        if band.gain > 0 { return Color.cyan }
        if band.gain < 0 { return Color.orange }
        return .secondary
    }
    
    private func formattedGain(_ gain: Float) -> String {
        if abs(gain) < 0.05 {
            return "0.0"
        } else if gain > 0 {
            return String(format: "+%.1f", gain)
        } else {
            return String(format: "%.1f", gain)
        }
    }
    
    private func triggerHapticFeedback() {
        #if os(iOS)
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        #endif
    }
}

/// Tactile hardware-styled fader knob.
private struct FaderKnobView: View {
    let isDragging: Bool
    let isBypassed: Bool
    
    var body: some View {
        ZStack {
            // Knob body
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(white: 0.35),
                            Color(white: 0.18),
                            Color(white: 0.25)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 28, height: 18)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isDragging ? Color.cyan : Color.white.opacity(0.3), lineWidth: 1)
                )
            
            // Center notch indicator line
            Rectangle()
                .fill(isBypassed ? Color.gray : (isDragging ? Color.cyan : Color.white))
                .frame(width: 16, height: 2)
                .shadow(color: isDragging ? Color.cyan : Color.clear, radius: 2)
        }
    }
}
