import SwiftUI

/// Container view for the 10-band graphic equalizer faders and curve response graph.
public struct EqualizerBandsView: View {
    @ObservedObject var viewModel: EqualizerViewModel
    
    public init(viewModel: EqualizerViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            // Header Bar: EQ Bypass, Curve Mode, Reset & Quick Preset buttons
            HStack {
                // Master Bypass Toggle
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.toggleMasterEQBypass()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.isEQBypassed ? "bolt.slash.fill" : "bolt.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text(viewModel.isEQBypassed ? "BYPASS" : "EQ ACTIVE")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(viewModel.isEQBypassed ? Color.red.opacity(0.2) : Color.green.opacity(0.2))
                    )
                    .overlay(
                        Capsule()
                            .stroke(viewModel.isEQBypassed ? Color.red.opacity(0.5) : Color.green.opacity(0.5), lineWidth: 1)
                    )
                    .foregroundColor(viewModel.isEQBypassed ? .red : .green)
                }
                
                Spacer()
                
                // Quick Zero / Reset Button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.resetToFlat()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Flat")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                    )
                    .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            
            // Interactive Smooth Response Curve Visualization
            EQCurveView(bands: viewModel.bands, isBypassed: viewModel.isEQBypassed)
                .frame(height: 54)
                .padding(.horizontal, 16)
            
            // Sliders Container (Scrollable or Fit-to-Width)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // Preamp Trim Slider
                    PreampSliderView(
                        gain: viewModel.preampGain,
                        onGainChanged: { newGain in
                            viewModel.setPreampGain(newGain)
                        }
                    )
                    .frame(height: 200)
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                        .frame(height: 160)
                        .padding(.horizontal, 2)
                    
                    // 10 Frequency Band Sliders
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
                        .frame(height: 200)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.09, green: 0.10, blue: 0.13))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 12)
        }
    }
}

/// Dynamic Spline / Bezier curve visualizing the frequency response of all 10 bands.
private struct EQCurveView: View {
    let bands: [EQBand]
    let isBypassed: Bool
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let centerY = height / 2.0
            
            ZStack {
                // Background curve box
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 0.05, green: 0.06, blue: 0.08))
                
                // Zero dB center baseline
                Path { path in
                    path.move(to: CGPoint(x: 0, y: centerY))
                    path.addLine(to: CGPoint(x: width, y: centerY))
                }
                .stroke(Color.white.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                
                // Filled curve area
                Path { path in
                    let points = curvePoints(width: width, height: height, centerY: centerY)
                    guard points.count > 1 else { return }
                    
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
                            Color.cyan.opacity(isBypassed ? 0.05 : 0.30),
                            Color.blue.opacity(isBypassed ? 0.02 : 0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Stroke Curve Line
                Path { path in
                    let points = curvePoints(width: width, height: height, centerY: centerY)
                    guard points.count > 1 else { return }
                    
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
                    isBypassed ? Color.gray.opacity(0.5) : Color.cyan,
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                )
                .shadow(color: isBypassed ? Color.clear : Color.cyan.opacity(0.6), radius: 3)
            }
        }
    }
    
    private func curvePoints(width: CGFloat, height: CGFloat, centerY: CGFloat) -> [CGPoint] {
        guard !bands.isEmpty else { return [] }
        let count = bands.count
        let step = width / CGFloat(count + 1)
        
        var points: [CGPoint] = []
        // Start anchor at left edge
        let firstGain = isBypassed ? 0.0 : CGFloat(bands[0].gain)
        points.append(CGPoint(x: 0, y: centerY - (firstGain / 12.0) * (height / 2.2)))
        
        for (i, band) in bands.enumerated() {
            let x = step * CGFloat(i + 1)
            let effectiveGain = (isBypassed || band.bypass) ? 0.0 : CGFloat(band.gain)
            let y = centerY - (effectiveGain / 12.0) * (height / 2.2)
            points.append(CGPoint(x: x, y: y))
        }
        
        // End anchor at right edge
        let lastGain = isBypassed ? 0.0 : CGFloat(bands[count - 1].gain)
        points.append(CGPoint(x: width, y: centerY - (lastGain / 12.0) * (height / 2.2)))
        return points
    }
}

/// Preamp master gain vertical fader
private struct PreampSliderView: View {
    let gain: Float
    let onGainChanged: (Float) -> Void
    
    var body: some View {
        VStack(spacing: 6) {
            Text(gain > 0 ? String(format: "+%.1f", gain) : String(format: "%.1f", gain))
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.yellow)
                .frame(width: 44, height: 16)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.yellow.opacity(0.12)))
            
            GeometryReader { geometry in
                let height = geometry.size.height
                let thumbRadius: CGFloat = 13.0
                let trackHeight = max(10, height - thumbRadius * 2)
                let normalized = CGFloat((gain - (-12.0)) / 24.0)
                let thumbY = height - thumbRadius - (normalized * trackHeight)
                
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 6, height: height)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.35))
                        .frame(width: 14, height: 1.5)
                        .position(x: geometry.size.width / 2, y: height / 2)
                    
                    // Thumb
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.yellow)
                        .frame(width: 26, height: 16)
                        .overlay(Rectangle().fill(Color.black).frame(width: 14, height: 2))
                        .position(x: geometry.size.width / 2, y: thumbY)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { val in
                            let clampedY = max(thumbRadius, min(height - thumbRadius, val.location.y))
                            let fraction = 1.0 - ((clampedY - thumbRadius) / trackHeight)
                            var newGain = -12.0 + Float(fraction) * 24.0
                            if abs(newGain) < 0.4 { newGain = 0.0 }
                            onGainChanged(newGain)
                        }
                )
            }
            .frame(width: 32)
            
            VStack(spacing: 2) {
                Text("PRE")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.yellow)
                Text("AMP")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .frame(width: 36)
        }
    }
}
