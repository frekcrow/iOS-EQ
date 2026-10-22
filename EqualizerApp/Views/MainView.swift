import SwiftUI

/// Main container screen supporting iOS 14.0 - 15.x with System-Wide Audio,
/// Microphone DSP Monitoring, and Studio Media Player modes.
public struct MainView: View {
    @StateObject private var viewModel = EqualizerViewModel()
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Dark hardware studio background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.06, blue: 0.08),
                    Color(red: 0.08, green: 0.09, blue: 0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 8) {
                // Top Header Bar
                headerBar
                
                // Mode Selector Bar (System EQ / Mic DSP / Studio Player)
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
        HStack {
            // Branding & Environment Pill
            HStack(spacing: 6) {
                Image(systemName: "slider.vertical.3")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.cyan)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("EQ PRO")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(viewModel.isUnsandboxed ? "TROLLSTORE" : "JAILBREAK")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(viewModel.isUnsandboxed ? .green : .orange)
                }
            }
            
            Spacer()
            
            // Active Audio Route Pill
            Button(action: {
                viewModel.isSystemSettingsPresented = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "airpodspro")
                        .font(.system(size: 11))
                    Text(viewModel.activeAudioRoute)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.08))
                .cornerRadius(8)
                .foregroundColor(.cyan)
            }
            
            // Preset Selector Button
            Button(action: {
                viewModel.isPresetsSheetPresented = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.activePreset.iconName)
                        .font(.system(size: 11))
                    Text(viewModel.activePreset.name)
                        .font(.system(size: 11, weight: .semibold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.08))
                )
                .foregroundColor(.white)
            }
            
            // System Settings Button
            Button(action: {
                viewModel.isSystemSettingsPresented = true
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(viewModel.isSystemEQActive ? .green : .white)
                    .padding(7)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 2)
    }
    
    // MARK: - Operating Mode Switcher Bar
    private var modeSelectorBar: some View {
        HStack(spacing: 6) {
            ForEach(AppAudioMode.allCases) { mode in
                let isSelected = viewModel.audioMode == mode
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.audioMode = mode
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: mode.iconName)
                            .font(.system(size: 11, weight: .bold))
                        Text(mode.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected ? Color.cyan.opacity(0.2) : Color.white.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? Color.cyan : Color.clear, lineWidth: 1)
                            )
                    )
                    .foregroundColor(isSelected ? .cyan : .secondary)
                }
            }
        }
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
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(viewModel.isSystemEQActive ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(viewModel.isSystemEQActive ? "SYSTEM EQ ACTIVE" : "SYSTEM EQ BYPASSED")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(viewModel.isSystemEQActive ? .green : .orange)
                }
                Text("All apps (Spotify, Music, Calls)")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Push / Sync Button
            Button(action: {
                withAnimation {
                    viewModel.applySystemWideEQ()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12))
                    Text("Apply to System")
                        .font(.system(size: 12, weight: .bold))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(LinearGradient(colors: [Color.purple, Color.blue], startPoint: .leading, endPoint: .trailing))
                )
                .foregroundColor(.white)
                .shadow(color: Color.purple.opacity(0.4), radius: 4)
            }
            
            // Effects Rack Button
            Button(action: {
                viewModel.isEffectsSheetPresented = true
            }) {
                Image(systemName: "dial.low.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.cyan)
                    .padding(8)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
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

#if DEBUG
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .preferredColorScheme(.dark)
    }
}
#endif
