import SwiftUI

/// Control bar for live hardware microphone pass-through, noise gate, gain, and voice pitch modification.
/// Exclusively routes audio directly to wired headphones with low-latency DSP.
public struct MicControlBarView: View {
    @ObservedObject var viewModel: EqualizerViewModel
    
    public init(viewModel: EqualizerViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 9) {
            // Live Status & Feedback Notice
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(viewModel.isMicMonitoring ? EqualizerTheme.Colors.peakPink : Color.gray)
                        .frame(width: 8, height: 8)
                        .shadow(color: viewModel.isMicMonitoring ? EqualizerTheme.Colors.peakPink.opacity(0.8) : Color.clear, radius: 4)
                    
                    Text(viewModel.isMicMonitoring ? "MIC DSP STREAMING" : "MIC STANDBY")
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .foregroundColor(viewModel.isMicMonitoring ? EqualizerTheme.Colors.peakPink : .secondary)
                }
                
                Spacer()
                
                // Wired output confirmation / Warning
                HStack(spacing: 4) {
                    Image(systemName: viewModel.isWiredHeadsetConnected ? "headphones" : "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                    Text(viewModel.isWiredHeadsetConnected ? "Output locked to wired headset" : "Connect wired headphones")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(viewModel.isWiredHeadsetConnected ? .secondary : EqualizerTheme.Colors.tubeAmber)
            }
            .padding(.horizontal, 16)
            
            // Sliders: Mic Boost Preamp & Voice Pitch Shift
            HStack(spacing: 16) {
                // Mic Boost
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Preamp Gain")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.1fx", viewModel.micGain))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(EqualizerTheme.Colors.cyanAccent)
                    }
                    Slider(value: Binding(
                        get: { viewModel.micGain },
                        set: {
                            viewModel.setMicGain($0)
                            EqualizerTheme.Haptics.selection()
                        }
                    ), in: 0.5...3.0, step: 0.1)
                    .accentColor(EqualizerTheme.Colors.cyanAccent)
                }
                
                // Voice Pitch Shift
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Voice Pitch")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        let st = viewModel.voicePitchCents / 100.0
                        Text(String(format: "%+.0f st", st))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(EqualizerTheme.Colors.violet)
                    }
                    Slider(value: Binding(
                        get: { viewModel.voicePitchCents },
                        set: {
                            viewModel.setVoicePitch(cents: $0)
                            EqualizerTheme.Haptics.selection()
                        }
                    ), in: -1200...1200, step: 100)
                    .accentColor(EqualizerTheme.Colors.violet)
                }
            }
            .padding(.horizontal, 16)
            
            // Transport & Toggle Buttons
            HStack(spacing: 16) {
                // Noise Gate Button
                Button(action: {
                    withAnimation(EqualizerTheme.AnimationSprings.tactile) {
                        viewModel.toggleNoiseGate()
                    }
                    EqualizerTheme.Haptics.impactLight()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: viewModel.isNoiseGateEnabled ? "waveform.badge.minus" : "waveform")
                            .font(.system(size: 11, weight: .bold))
                        Text(viewModel.isNoiseGateEnabled ? "Gate ON" : "Gate OFF")
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule().fill(viewModel.isNoiseGateEnabled ? EqualizerTheme.Colors.emerald.opacity(0.18) : Color.white.opacity(0.06))
                    )
                    .overlay(
                        Capsule().stroke(viewModel.isNoiseGateEnabled ? EqualizerTheme.Colors.emerald.opacity(0.4) : EqualizerTheme.Colors.borderHairline, lineWidth: 1)
                    )
                    .foregroundColor(viewModel.isNoiseGateEnabled ? EqualizerTheme.Colors.emerald : .secondary)
                }
                .pressable()
                
                Spacer()
                
                // Big Live Mic Toggle Button
                Button(action: {
                    withAnimation(EqualizerTheme.AnimationSprings.tactile) {
                        viewModel.toggleMicMonitoring()
                    }
                    EqualizerTheme.Haptics.impactMedium()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.isMicMonitoring ? "mic.slash.fill" : "mic.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text(viewModel.isMicMonitoring ? "Stop Monitor" : "Start Live Monitor")
                            .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(
                        Capsule().fill(
                            viewModel.isMicMonitoring
                                ? EqualizerTheme.Colors.amberCoralGradient
                                : EqualizerTheme.Colors.cyanBlueGradient
                        )
                    )
                    .foregroundColor(.white)
                    .shadow(
                        color: (viewModel.isMicMonitoring ? EqualizerTheme.Colors.peakPink : EqualizerTheme.Colors.cyanAccent).opacity(0.4),
                        radius: 6,
                        x: 0,
                        y: 2
                    )
                }
                .pressable()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 2)
        }
        .padding(.vertical, 10)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(EqualizerTheme.Colors.surfaceTray)
                RoundedRectangle(cornerRadius: 18)
                    .stroke(EqualizerTheme.Colors.borderHairline, lineWidth: 1)
            }
        )
        .padding(.horizontal, 12)
    }
}
