import SwiftUI

/// Control bar for live hardware microphone pass-through, noise gate, gain, and voice pitch modification.
public struct MicControlBarView: View {
    @ObservedObject var viewModel: EqualizerViewModel
    
    public init(viewModel: EqualizerViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // Live Status & Feedback Notice
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(viewModel.isMicMonitoring ? Color.red : Color.gray)
                        .frame(width: 8, height: 8)
                        .shadow(color: viewModel.isMicMonitoring ? Color.red : Color.clear, radius: 4)
                    
                    Text(viewModel.isMicMonitoring ? "MIC LIVE MONITORING" : "MIC STANDBY")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(viewModel.isMicMonitoring ? .red : .secondary)
                }
                
                Spacer()
                
                // Headphone warning
                HStack(spacing: 4) {
                    Image(systemName: "headphones")
                        .font(.system(size: 10))
                    Text("Use headphones to prevent feedback")
                        .font(.system(size: 10))
                }
                .foregroundColor(.orange.opacity(0.9))
            }
            .padding(.horizontal, 16)
            
            // Sliders: Mic Boost & Voice Pitch
            HStack(spacing: 16) {
                // Mic Boost
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Mic Gain")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.1fx", viewModel.micGain))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                    Slider(value: Binding(
                        get: { viewModel.micGain },
                        set: { viewModel.setMicGain($0) }
                    ), in: 0.5...3.0, step: 0.1)
                    .accentColor(.cyan)
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
                            .foregroundColor(.purple)
                    }
                    Slider(value: Binding(
                        get: { viewModel.voicePitchCents },
                        set: { viewModel.setVoicePitch(cents: $0) }
                    ), in: -1200...1200, step: 100)
                    .accentColor(.purple)
                }
            }
            .padding(.horizontal, 16)
            
            // Transport / Toggle Buttons
            HStack(spacing: 24) {
                // Noise Gate Button
                Button(action: {
                    viewModel.toggleNoiseGate()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.isNoiseGateEnabled ? "waveform.badge.minus" : "waveform")
                        Text(viewModel.isNoiseGateEnabled ? "Gate ON" : "Gate OFF")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(viewModel.isNoiseGateEnabled ? Color.green.opacity(0.2) : Color.white.opacity(0.08)))
                    .foregroundColor(viewModel.isNoiseGateEnabled ? .green : .secondary)
                }
                
                Spacer()
                
                // Big Live Mic Toggle Button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        viewModel.toggleMicMonitoring()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.isMicMonitoring ? "mic.slash.fill" : "mic.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text(viewModel.isMicMonitoring ? "Stop Mic Monitor" : "Start Live Monitor")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule().fill(
                            viewModel.isMicMonitoring
                                ? LinearGradient(colors: [Color.red, Color.orange], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [Color.cyan, Color.blue], startPoint: .leading, endPoint: .trailing)
                        )
                    )
                    .foregroundColor(.white)
                    .shadow(color: viewModel.isMicMonitoring ? Color.red.opacity(0.4) : Color.cyan.opacity(0.4), radius: 6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 4)
        }
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .padding(.horizontal, 12)
    }
}
