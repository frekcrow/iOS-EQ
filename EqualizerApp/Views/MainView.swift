import SwiftUI

/// Main container screen supporting iOS 14.0 - 15.x with Wired System Audio,
/// Microphone DSP Monitoring, and Studio Media Player modes.
/// Designed according to Apple HIG, tactile hardware depth, and fluid physics.
public struct MainView: View {
    @StateObject private var viewModel = EqualizerViewModel()
    @Namespace private var modeAnimation
    @State private var isPulsing: Bool = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Studio hardware machined background with subtle radial ambiance
            EqualizerTheme.Colors.backgroundBase
                .ignoresSafeArea()
            
            RadialGradient(
                colors: [
                    EqualizerTheme.Colors.cyanAccent.opacity(0.04),
                    Color.clear
                ],
                center: .top,
                startRadius: 20,
                endRadius: 380
            )
            .ignoresSafeArea()
            
            VStack(spacing: 8) {
                // Top Header Bar
                headerBar
                
                // Wired Headphone Status Banner
                wiredHeadphoneStatusBanner
                
                // Physical Segmented Mode Selector Bar
                modeSelectorBar
                
                // Real-Time Spectrum Visualizer
                SpectrumVisualizerView(
                    magnitudes: viewModel.spectrumMagnitudes,
                    isPlaying: viewModel.isPlaying || viewModel.isMicMonitoring
                )
                .padding(.horizontal, 12)
                
                // 10-Band Equalizer Section
                EqualizerBandsView(viewModel: viewModel)
                
                Spacer(minLength: 4)
                
                // Bottom Control Bar based on Active Mode
                bottomControlBar
            }
            .padding(.top, 4)
            .padding(.bottom, 6)
        }
        .preferredColorScheme(.dark)
        // Sheets
        .sheet(isPresented: $viewModel.isPresetsSheetPresented) {
            PresetSelectorView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.isEffectsSheetPresented) {
            EffectsRackView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.isSystemSettingsPresented) {
            SystemAudioSheetView(viewModel: viewModel)
        }
        #if os(iOS)
        .sheet(isPresented: $viewModel.isFilePickerPresented) {
            DocumentPicker { url in
                viewModel.loadAudioFile(url: url)
            }
        }
        #endif
        // iOS 14.0 compatible Alert presentation
        .alert(isPresented: $viewModel.showErrorAlert) {
            Alert(
                title: Text("Audio Notice"),
                message: Text(viewModel.errorMessage ?? "An audio error occurred."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(spacing: 8) {
            // Branding & Environment Pill
            HStack(spacing: 7) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(EqualizerTheme.Colors.cyanAccent.opacity(0.12))
                        .frame(width: 30, height: 30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(EqualizerTheme.Colors.cyanAccent.opacity(0.35), lineWidth: 1)
                        )
                    
                    Image(systemName: "slider.vertical.3")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(EqualizerTheme.Colors.cyanAccent)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("EQ PRO")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(0.5)
                    
                    HStack(spacing: 3) {
                        Circle()
                            .fill(viewModel.isUnsandboxed ? EqualizerTheme.Colors.emerald : EqualizerTheme.Colors.tubeAmber)
                            .frame(width: 5, height: 5)
                        Text(viewModel.isUnsandboxed ? "TROLLSTORE" : "JAILBREAK")
                            .font(.system(size: 7.5, weight: .heavy, design: .monospaced))
                            .foregroundColor(viewModel.isUnsandboxed ? EqualizerTheme.Colors.emerald : EqualizerTheme.Colors.tubeAmber)
                    }
                }
            }
            
            Spacer()
            
            // Active Wired Audio Route Pill
            Button(action: {
                EqualizerTheme.Haptics.impactLight()
                viewModel.isSystemSettingsPresented = true
            }) {
                HStack(spacing: 5) {
                    Image(systemName: viewModel.isWiredHeadsetConnected ? "headphones" : "cable.connector.horizontal")
                        .font(.system(size: 11, weight: .semibold))
                    Text(viewModel.connectedPortName)
                        .font(.system(size: 11, weight: .semibold))
                        .lineLimit(1)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(EqualizerTheme.Colors.surfaceTray)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(viewModel.isWiredHeadsetConnected ? EqualizerTheme.Colors.emerald.opacity(0.3) : EqualizerTheme.Colors.borderHairline, lineWidth: 1)
                        )
                )
                .foregroundColor(viewModel.isWiredHeadsetConnected ? EqualizerTheme.Colors.emerald : .secondary)
            }
            .pressable()
            
            // Preset Selector Button
            Button(action: {
                EqualizerTheme.Haptics.impactLight()
                viewModel.isPresetsSheetPresented = true
            }) {
                HStack(spacing: 5) {
                    Image(systemName: viewModel.activePreset.iconName)
                        .font(.system(size: 11, weight: .semibold))
                    Text(viewModel.activePreset.name)
                        .font(.system(size: 11, weight: .bold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .heavy))
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(EqualizerTheme.Colors.surfaceTray)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(EqualizerTheme.Colors.borderHairline, lineWidth: 1)
                        )
                )
                .foregroundColor(.white)
            }
            .pressable()
            
            // System Settings Button
            Button(action: {
                EqualizerTheme.Haptics.impactLight()
                viewModel.isSystemSettingsPresented = true
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(viewModel.isSystemEQActive ? EqualizerTheme.Colors.violet : .white)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle()
                            .fill(EqualizerTheme.Colors.surfaceTray)
                            .overlay(
                                Circle()
                                    .stroke(viewModel.isSystemEQActive ? EqualizerTheme.Colors.violet.opacity(0.4) : EqualizerTheme.Colors.borderHairline, lineWidth: 1)
                            )
                    )
            }
            .pressable()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 2)
    }
    
    // MARK: - Wired Headphone Status Banner
    private var wiredHeadphoneStatusBanner: some View {
        Button(action: {
            EqualizerTheme.Haptics.impactLight()
            viewModel.isSystemSettingsPresented = true
        }) {
            HStack(spacing: 10) {
                // Breathing status indicator dot
                ZStack {
                    Circle()
                        .fill(viewModel.isWiredHeadsetConnected ? EqualizerTheme.Colors.emerald : EqualizerTheme.Colors.tubeAmber)
                        .frame(width: 8, height: 8)
                        .shadow(
                            color: (viewModel.isWiredHeadsetConnected ? EqualizerTheme.Colors.emerald : EqualizerTheme.Colors.tubeAmber).opacity(0.8),
                            radius: 3
                        )
                    
                    if viewModel.isWiredHeadsetConnected {
                        Circle()
                            .stroke(EqualizerTheme.Colors.emerald.opacity(isPulsing ? 0.6 : 0.15), lineWidth: 1.5)
                            .frame(width: isPulsing ? 18 : 12, height: isPulsing ? 18 : 12)
                            .animation(Animation.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: isPulsing)
                    }
                }
                .frame(width: 18, height: 18)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(viewModel.isWiredHeadsetConnected ? "WIRED OUTPUT ACTIVE" : "NO WIRED HEADPHONES DETECTED")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundColor(viewModel.isWiredHeadsetConnected ? EqualizerTheme.Colors.emerald : EqualizerTheme.Colors.tubeAmber)
                        
                        if viewModel.isWiredHeadsetConnected {
                            Text(viewModel.portTypeDescription)
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(EqualizerTheme.Colors.cyanAccent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1.5)
                                .background(Capsule().fill(EqualizerTheme.Colors.cyanAccent.opacity(0.15)))
                        }
                    }
                    
                    Text(viewModel.isWiredHeadsetConnected
                         ? "\(viewModel.connectedPortName) • \(viewModel.hardwareFormatText)"
                         : "Connect 3.5mm Aux, Lightning, or USB-C Audio / DAC")
                        .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: viewModel.isWiredHeadsetConnected ? "headphones" : "cable.connector.horizontal")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(viewModel.isWiredHeadsetConnected ? EqualizerTheme.Colors.cyanAccent : .secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .studioCard(cornerRadius: 12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        viewModel.isWiredHeadsetConnected
                            ? EqualizerTheme.Colors.emerald.opacity(0.25)
                            : EqualizerTheme.Colors.tubeAmber.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
        .pressable()
        .padding(.horizontal, 12)
        .onAppear {
            isPulsing = true
        }
    }
    
    // MARK: - Operating Mode Switcher Bar
    private var modeSelectorBar: some View {
        HStack(spacing: 4) {
            ForEach(AppAudioMode.allCases) { mode in
                let isSelected = viewModel.audioMode == mode
                
                Button(action: {
                    EqualizerTheme.Haptics.selection()
                    withAnimation(EqualizerTheme.AnimationSprings.tactile) {
                        viewModel.audioMode = mode
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: mode.iconName)
                            .font(.system(size: 11, weight: .bold))
                        Text(mode.rawValue)
                            .font(.system(size: 11, weight: .bold))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                    .foregroundColor(isSelected ? .white : .secondary)
                    .background(
                        ZStack {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 9)
                                    .fill(EqualizerTheme.Colors.surfaceHighlight)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 9)
                                            .stroke(EqualizerTheme.Colors.cyanAccent.opacity(0.4), lineWidth: 1)
                                    )
                                    .matchedGeometryEffect(id: "activeModeIndicator", in: modeAnimation)
                                    .shadow(color: EqualizerTheme.Colors.cyanAccent.opacity(0.2), radius: 6, x: 0, y: 1)
                            }
                        }
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(EqualizerTheme.Colors.surfaceTray)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(EqualizerTheme.Colors.borderHairline, lineWidth: 1)
                )
        )
        .padding(.horizontal, 12)
    }
    
    // MARK: - Dynamic Bottom Bar
    @ViewBuilder
    private var bottomControlBar: some View {
        switch viewModel.audioMode {
        case .systemWide:
            systemWideBar
        case .microphoneDSP:
            MicControlBarView(viewModel: viewModel)
        case .mediaPlayer:
            PlayerControlBarView(viewModel: viewModel)
        }
    }
    
    // System-Wide Quick Push Bar
    private var systemWideBar: some View {
        HStack(spacing: 12) {
            // Status LED and Description
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(viewModel.isSystemEQActive ? EqualizerTheme.Colors.violet : EqualizerTheme.Colors.tubeAmber)
                        .frame(width: 8, height: 8)
                        .shadow(
                            color: (viewModel.isSystemEQActive ? EqualizerTheme.Colors.violet : EqualizerTheme.Colors.tubeAmber).opacity(0.7),
                            radius: 3
                        )
                    
                    Text(viewModel.isSystemEQActive ? "WIRED EQ ACTIVE" : "WIRED EQ BYPASSED")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(viewModel.isSystemEQActive ? EqualizerTheme.Colors.violet : EqualizerTheme.Colors.tubeAmber)
                }
                
                Text("Audiogram daemon injection (heard) • Zero speaker leak")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Apply to Wired Output & Restart Audio Daemon Button
            Button(action: {
                EqualizerTheme.Haptics.impactMedium()
                withAnimation(EqualizerTheme.AnimationSprings.fluidDefault) {
                    viewModel.applyToWiredOutput(restartDaemons: true)
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text("Apply to Wired")
                        .font(.system(size: 11, weight: .heavy))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(EqualizerTheme.Colors.purpleBlueGradient)
                        .overlay(
                            Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .foregroundColor(.white)
                .shadow(color: EqualizerTheme.Colors.violet.opacity(0.4), radius: 6, x: 0, y: 2)
            }
            .pressable()
            
            // Effects Rack Button
            Button(action: {
                EqualizerTheme.Haptics.impactLight()
                viewModel.isEffectsSheetPresented = true
            }) {
                Image(systemName: "dial.low.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(EqualizerTheme.Colors.cyanAccent)
                    .frame(width: 34, height: 34)
                    .background(
                        Circle()
                            .fill(EqualizerTheme.Colors.surfaceHighlight)
                            .overlay(
                                Circle().stroke(EqualizerTheme.Colors.borderHairline, lineWidth: 1)
                            )
                    )
            }
            .pressable()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .studioCard(cornerRadius: 16)
        .padding(.horizontal, 12)
    }
}

#if DEBUG
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .preferredColorScheme(.dark)
    }
}
#endif
