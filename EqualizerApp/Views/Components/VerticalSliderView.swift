import SwiftUI

/// Studio-grade vertical fader knob with machined tactile grip grooves,
/// magnetic zero-detent snap, velocity-sensitive haptics, and double-tap reset.
public struct VerticalSliderView: View {
    let band: EQBand
    let onGainChanged: (Float) -> Void
    let onBypassToggled: () -> Void
    
    // Gain range: -12.0 to +12.0 dB
    private let minGain: Float = -12.0
    private let maxGain: Float = 12.0
    
    @State private var isDragging: Bool = false
    @State private var didSnapZero: Bool = false
    
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
        VStack(spacing: 7) {
            // Gain Readout Badge
            Text(formattedGain(band.gain))
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundColor(gainTextColor)
                .frame(width: 44, height: 18)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(isDragging ? EqualizerTheme.Colors.surfaceElevated : EqualizerTheme.Colors.backgroundBase)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(isDragging ? EqualizerTheme.Colors.cyanAccent.opacity(0.4) : EqualizerTheme.Colors.borderHairline, lineWidth: 1)
                        )
                )
                .shadow(color: isDragging ? EqualizerTheme.Colors.cyanAccent.opacity(0.2) : Color.clear, radius: 4)
            
            // Vertical Slider Track with HIG-compliant hit target
            GeometryReader { geometry in
                let height = geometry.size.height
                let thumbRadius: CGFloat = 13.0
                let trackHeight = max(10, height - thumbRadius * 2)
                
                // Normalized position: 0.0 at bottom (-12 dB), 1.0 at top (+12 dB), 0.5 at center (0 dB)
                let normalized = CGFloat((band.gain - minGain) / (maxGain - minGain))
                let thumbY = height - thumbRadius - (normalized * trackHeight)
                
                ZStack(alignment: .top) {
                    // Outer Recessed Trough
                    RoundedRectangle(cornerRadius: 3)
                        .fill(EqualizerTheme.Colors.backgroundBase)
                        .frame(width: 5, height: height)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.white.opacity(0.06), lineWidth: 0.75)
                        )
                    
                    // Center 0 dB Calibrated Tick Mark
                    Rectangle()
                        .fill(Color.white.opacity(0.45))
                        .frame(width: 16, height: 1.5)
                        .position(x: geometry.size.width / 2, y: height / 2)
                    
                    // Dynamic Level Fill (from center 0 dB to current thumb position)
                    let centerY = height / 2
                    let fillHeight = abs(centerY - thumbY)
                    let fillY = min(centerY, thumbY) + fillHeight / 2
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            band.bypass
                                ? LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .bottom, endPoint: .top)
                                : (band.gain >= 0
                                   ? LinearGradient(colors: [EqualizerTheme.Colors.cyanAccent, EqualizerTheme.Colors.royalBlue], startPoint: .top, endPoint: .bottom)
                                   : LinearGradient(colors: [EqualizerTheme.Colors.tubeAmber, EqualizerTheme.Colors.peakPink], startPoint: .bottom, endPoint: .top))
                        )
                        .frame(width: 3.5, height: max(1, fillHeight))
                        .position(x: geometry.size.width / 2, y: fillY)
                    
                    // Tactile Hardware Fader Knob
                    FaderKnobView(isDragging: isDragging, isBypassed: band.bypass, gain: band.gain)
                        .position(x: geometry.size.width / 2, y: thumbY)
                        .shadow(
                            color: isDragging ? EqualizerTheme.Colors.cyanAccent.opacity(0.4) : Color.black.opacity(0.5),
                            radius: isDragging ? 6 : 2.5,
                            x: 0,
                            y: 2
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle()) // Large 44pt touchable area
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if !isDragging {
                                isDragging = true
                                EqualizerTheme.Haptics.impactLight()
                            }
                            
                            let touchY = value.location.y
                            let clampedY = max(thumbRadius, min(height - thumbRadius, touchY))
                            let fraction = 1.0 - ((clampedY - thumbRadius) / trackHeight)
                            var newGain = minGain + Float(fraction) * (maxGain - minGain)
                            
                            // Magnetic 0 dB detent snap
                            if abs(newGain) < 0.45 {
                                newGain = 0.0
                                if !didSnapZero {
                                    didSnapZero = true
                                    EqualizerTheme.Haptics.selection()
                                }
                            } else {
                                didSnapZero = false
                            }
                            
                            onGainChanged(newGain)
                        }
                        .onEnded { _ in
                            isDragging = false
                            didSnapZero = false
                            EqualizerTheme.Haptics.impactLight()
                        }
                )
                .onTapGesture(count: 2) {
                    // Double tap: immediate zero reset with spring haptics
                    withAnimation(EqualizerTheme.AnimationSprings.tactile) {
                        onGainChanged(0.0)
                    }
                    EqualizerTheme.Haptics.impactMedium()
                }
            }
            .frame(width: 44) // 44pt HIG minimum hit target
            
            // Frequency Label Pill
            Button(action: {
                withAnimation(EqualizerTheme.AnimationSprings.tactile) {
                    onBypassToggled()
                }
                EqualizerTheme.Haptics.impactLight()
            }) {
                VStack(spacing: 1.5) {
                    Text(band.frequencyFormatted)
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .foregroundColor(band.bypass ? .gray : .primary)
                    
                    Text(filterTypeLabel(band.filterType))
                        .font(.system(size: 7, weight: .black))
                        .foregroundColor(band.bypass ? .gray.opacity(0.6) : EqualizerTheme.Colors.cyanAccent.opacity(0.8))
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(band.bypass ? Color.clear : EqualizerTheme.Colors.surfaceTray.opacity(0.5))
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .opacity(band.bypass ? 0.38 : 1.0)
        .animation(EqualizerTheme.AnimationSprings.tactile, value: band.bypass)
    }
    
    private var gainTextColor: Color {
        if band.bypass { return .secondary }
        if band.gain > 0 { return EqualizerTheme.Colors.cyanAccent }
        if band.gain < 0 { return EqualizerTheme.Colors.tubeAmber }
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
    
    private func filterTypeLabel(_ type: EQFilterType) -> String {
        switch type {
        case .lowShelf: return "LOW"
        case .highShelf: return "HIGH"
        case .parametric: return "PEAK"
        }
    }
}

/// Precision machined aluminum fader knob with laser-etched grip ridges.
private struct FaderKnobView: View {
    let isDragging: Bool
    let isBypassed: Bool
    let gain: Float
    
    var body: some View {
        ZStack {
            // Outer Machined Cap
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: isDragging
                            ? [Color(white: 0.38), Color(white: 0.22), Color(white: 0.28)]
                            : [Color(white: 0.30), Color(white: 0.16), Color(white: 0.22)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 29, height: 18)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(
                            isDragging
                                ? EqualizerTheme.Colors.cyanAccent.opacity(0.8)
                                : Color.white.opacity(0.25),
                            lineWidth: 1
                        )
                )
            
            // Micro tactile grip ridges
            VStack(spacing: 2) {
                Rectangle().fill(Color.black.opacity(0.4)).frame(width: 14, height: 0.75)
                
                // Luminous Center Notch Indicator
                Rectangle()
                    .fill(centerIndicatorColor)
                    .frame(width: 17, height: 2.0)
                    .shadow(color: isDragging ? centerIndicatorColor.opacity(0.8) : Color.clear, radius: 2)
                
                Rectangle().fill(Color.black.opacity(0.4)).frame(width: 14, height: 0.75)
            }
        }
        .scaleEffect(isDragging ? 1.05 : 1.0)
        .animation(EqualizerTheme.AnimationSprings.tactile, value: isDragging)
    }
    
    private var centerIndicatorColor: Color {
        if isBypassed { return Color.gray }
        if abs(gain) < 0.05 { return Color.white }
        if gain > 0 { return EqualizerTheme.Colors.cyanAccent }
        return EqualizerTheme.Colors.tubeAmber
    }
}
