import SwiftUI

/// Container view for the 10-band graphic equalizer faders, dynamic response curve,
/// and preamp gain trim stage.
public struct EqualizerBandsView: View {
    @ObservedObject var viewModel: EqualizerViewModel
    
    public init(viewModel: EqualizerViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 10) {
            // Header Bar: EQ Bypass status & Flat reset button
            HStack {
                // Master Bypass Toggle Pill
                Button(action: {
                    withAnimation(EqualizerTheme.AnimationSprings.tactile) {
                        viewModel.toggleMasterEQBypass()
                    }
                    EqualizerTheme.Haptics.impactMedium()
                }) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(viewModel.isEQBypassed ? Color.red : EqualizerTheme.Colors.emerald)
                            .frame(width: 7, height: 7)
                            .shadow(color: viewModel.isEQBypassed ? Color.red : EqualizerTheme.Colors.emerald.opacity(0.8), radius: 3)
                        
                        Text(viewModel.isEQBypassed ? "BYPASS" : "EQ ACTIVE")
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .tracking(0.5)
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5.5)
                    .background(
                        Capsule()
                            .fill(viewModel.isEQBypassed ? Color.red.opacity(0.15) : EqualizerTheme.Colors.emerald.opacity(0.15))
                    )
                    .overlay(
                        Capsule()
                            .stroke(viewModel.isEQBypassed ? Color.red.opacity(0.4) : EqualizerTheme.Colors.emerald.opacity(0.4), lineWidth: 1)
                    )
                    .foregroundColor(viewModel.isEQBypassed ? .red : EqualizerTheme.Colors.emerald)
                }
                .pressable()
                
                Spacer()
                
                // Zero / Flat Reset Button
                Button(action: {
                    withAnimation(EqualizerTheme.AnimationSprings.fluidDefault) {
                        viewModel.resetToFlat()
                    }
                    EqualizerTheme.Haptics.impactLight()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 9.5, weight: .bold))
                        Text("Flat")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5.5)
                    .background(
                        Capsule()
                            .fill(EqualizerTheme.Colors.surfaceTray)
                    )
                    .overlay(
                        Capsule()
                            .stroke(EqualizerTheme.Colors.borderHairline, lineWidth: 1)
                    )
                    .foregroundColor(.white)
                }
                .pressable()
            }
            .padding(.horizontal, 16)
            
            // Dynamic Spline Response Curve Enclosure
            EQCurveView(bands: viewModel.bands, isBypassed: viewModel.isEQBypassed)
                .frame(height: 58)
                .padding(.horizontal, 12)
            
            // Sliders Machine Rack (Scrollable)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Preamp Trim Slider
                    PreampSliderView(
                        gain: viewModel.preampGain,
                        onGainChanged: { newGain in
                            viewModel.setPreampGain(newGain)
                        }
                    )
                    .frame(height: 202)
                    
                    // Separator Hairline
                    Rectangle()
                        .fill(EqualizerTheme.Colors.borderSubtle)
                        .frame(width: 1, height: 160)
                        .padding(.horizontal, 4)
                    
                    // 10 Standard ISO Frequency Bands
                    ForEach(viewModel.bands.indices, id: \.self) { index in
                        VerticalSliderView(
                            band: viewModel.bands[index],
                            onGainChanged: { gain in
                                viewModel.setBandGain(index: index, gain: gain)
                            },
                            onBypassToggled: {
                                viewModel.toggleBandBypass(index: index)
                            }
                        )
                        .frame(height: 202)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
            .background(
                // Double-bezel machined fader tray
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(EqualizerTheme.Colors.surfaceTray)
                    
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.12), Color.white.opacity(0.04)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 12)
        }
    }
}

/// Dynamic Spline / Bezier curve visualizing frequency response across all 10 bands.
private struct EQCurveView: View {
    let bands: [EQBand]
    let isBypassed: Bool
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let centerY = height / 2.0
            let points = curvePoints(width: width, height: height, centerY: centerY)
            
            ZStack {
                // Background Enclosure with double-bezel
                RoundedRectangle(cornerRadius: 12)
                    .fill(EqualizerTheme.Colors.backgroundBase)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(EqualizerTheme.Colors.borderHairline, lineWidth: 1)
                    )
                
                // Zero dB Center Baseline
                Path { path in
                    path.move(to: CGPoint(x: 10, y: centerY))
                    path.addLine(to: CGPoint(x: width - 10, y: centerY))
                }
                .stroke(Color.white.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                
                // Gradient Filled Area Under Curve
                if points.count > 1 {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: centerY))
                        for p in points {
                            path.addLine(to: p)
                        }
                        path.addLine(to: CGPoint(x: width, y: centerY))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [
                                EqualizerTheme.Colors.cyanAccent.opacity(isBypassed ? 0.04 : 0.28),
                                EqualizerTheme.Colors.royalBlue.opacity(isBypassed ? 0.02 : 0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Main Spline Stroke
                    Path { path in
                        path.move(to: points[0])
                        for i in 1..<points.count {
                            let prev = points[i - 1]
                            let curr = points[i]
                            let midX = (prev.x + curr.x) / 2
                            path.addCurve(
                                to: curr,
                                control1: CGPoint(x: midX, y: prev.y),
                                control2: CGPoint(x: midX, y: curr.y)
                            )
                        }
                    }
                    .stroke(
                        isBypassed ? Color.gray.opacity(0.4) : EqualizerTheme.Colors.cyanAccent,
                        style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round)
                    )
                    .shadow(
                        color: isBypassed ? Color.clear : EqualizerTheme.Colors.cyanAccent.opacity(0.55),
                        radius: 4,
                        x: 0,
                        y: 0
                    )
                    
                    // Band Anchor Nodes
                    ForEach(1..<max(1, points.count - 1), id: \.self) { i in
                        let pt = points[i]
                        Circle()
                            .fill(isBypassed ? Color.gray : EqualizerTheme.Colors.cyanAccent)
                            .frame(width: 3.5, height: 3.5)
                            .position(pt)
                    }
                }
            }
        }
    }
    
    private func curvePoints(width: CGFloat, height: CGFloat, centerY: CGFloat) -> [CGPoint] {
        guard !bands.isEmpty else { return [] }
        let count = bands.count
        let step = width / CGFloat(count + 1)
        
        var points: [CGPoint] = []
        let firstGain = isBypassed ? 0.0 : CGFloat(bands[0].gain)
        points.append(CGPoint(x: 0, y: centerY - (firstGain / 12.0) * (height / 2.3)))
        
        for (i, band) in bands.enumerated() {
            let x = step * CGFloat(i + 1)
            let effectiveGain = (isBypassed || band.bypass) ? 0.0 : CGFloat(band.gain)
            let y = centerY - (effectiveGain / 12.0) * (height / 2.3)
            points.append(CGPoint(x: x, y: y))
        }
        
        let lastGain = isBypassed ? 0.0 : CGFloat(bands[count - 1].gain)
        points.append(CGPoint(x: width, y: centerY - (lastGain / 12.0) * (height / 2.3)))
        return points
    }
}

/// Preamp master gain trim fader with warm vacuum-tube amber styling.
private struct PreampSliderView: View {
    let gain: Float
    let onGainChanged: (Float) -> Void
    
    @State private var isDragging: Bool = false
    
    var body: some View {
        VStack(spacing: 7) {
            // Readout Badge
            Text(gain > 0 ? String(format: "+%.1f", gain) : String(format: "%.1f", gain))
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundColor(EqualizerTheme.Colors.tubeAmber)
                .frame(width: 44, height: 18)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(EqualizerTheme.Colors.backgroundBase)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(EqualizerTheme.Colors.tubeAmber.opacity(0.35), lineWidth: 1)
                        )
                )
                .shadow(color: isDragging ? EqualizerTheme.Colors.tubeAmber.opacity(0.2) : Color.clear, radius: 4)
            
            // Fader Track
            GeometryReader { geometry in
                let height = geometry.size.height
                let thumbRadius: CGFloat = 13.0
                let trackHeight = max(10, height - thumbRadius * 2)
                let normalized = CGFloat((gain - (-12.0)) / 24.0)
                let thumbY = height - thumbRadius - (normalized * trackHeight)
                
                ZStack(alignment: .top) {
                    // Outer Recessed Trough
                    RoundedRectangle(cornerRadius: 3)
                        .fill(EqualizerTheme.Colors.backgroundBase)
                        .frame(width: 5, height: height)
                    
                    // Center 0 dB Tick
                    Rectangle()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 16, height: 1.5)
                        .position(x: geometry.size.width / 2, y: height / 2)
                    
                    // Amber Level Indicator
                    let centerY = height / 2
                    let fillHeight = abs(centerY - thumbY)
                    let fillY = min(centerY, thumbY) + fillHeight / 2
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(EqualizerTheme.Colors.tubeAmber)
                        .frame(width: 3.5, height: max(1, fillHeight))
                        .position(x: geometry.size.width / 2, y: fillY)
                    
                    // Tactile Amber Fader Cap
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color(white: 0.32), Color(white: 0.18)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 29, height: 18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(EqualizerTheme.Colors.tubeAmber.opacity(0.7), lineWidth: 1)
                            )
                        
                        Rectangle()
                            .fill(EqualizerTheme.Colors.tubeAmber)
                            .frame(width: 17, height: 2.0)
                            .shadow(color: EqualizerTheme.Colors.tubeAmber.opacity(0.7), radius: 2)
                    }
                    .position(x: geometry.size.width / 2, y: thumbY)
                    .shadow(color: Color.black.opacity(0.5), radius: 3)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { val in
                            if !isDragging {
                                isDragging = true
                                EqualizerTheme.Haptics.impactLight()
                            }
                            let clampedY = max(thumbRadius, min(height - thumbRadius, val.location.y))
                            let fraction = 1.0 - ((clampedY - thumbRadius) / trackHeight)
                            var newGain = -12.0 + Float(fraction) * 24.0
                            if abs(newGain) < 0.4 { newGain = 0.0 }
                            onGainChanged(newGain)
                        }
                        .onEnded { _ in
                            isDragging = false
                            EqualizerTheme.Haptics.impactLight()
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation(EqualizerTheme.AnimationSprings.tactile) {
                        onGainChanged(0.0)
                    }
                    EqualizerTheme.Haptics.impactMedium()
                }
            }
            .frame(width: 44)
            
            // Label
            VStack(spacing: 1.5) {
                Text("PRE")
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .foregroundColor(EqualizerTheme.Colors.tubeAmber)
                Text("AMP")
                    .font(.system(size: 7, weight: .black))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 3)
        }
    }
}
