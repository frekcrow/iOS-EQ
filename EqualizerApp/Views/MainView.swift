import SwiftUI

/// Main container screen providing the complete Equalizer Studio experience.
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
                // Top App Bar
                headerBar
                
                // Real-Time Spectrum Visualizer
                SpectrumVisualizerView(
                    magnitudes: viewModel.spectrumMagnitudes,
                    isPlaying: viewModel.isPlaying
                )
                .padding(.horizontal, 12)
                
                // 10-Band Equalizer Section
                EqualizerBandsView(viewModel: viewModel)
                
                Spacer(minLength: 4)
                
                // Bottom Transport & Audio Player Bar
                PlayerControlBarView(viewModel: viewModel)
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
        #if os(iOS)
        .sheet(isPresented: $viewModel.isFilePickerPresented) {
            DocumentPicker { url in
                viewModel.loadAudioFile(url: url)
            }
        }
        #endif
        .alert("Audio Error", isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An unknown audio error occurred.")
        }
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        HStack {
            // App Title & Branding
            HStack(spacing: 8) {
                Image(systemName: "slider.vertical.3")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.cyan)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("EQ STUDIO")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("10-BAND GRAPHIC EQUALIZER")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.cyan.opacity(0.8))
                }
            }
            
            Spacer()
            
            // Active Preset Quick Button
            Button(action: {
                viewModel.isPresetsSheetPresented = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.activePreset.iconName)
                        .font(.system(size: 12))
                    Text(viewModel.activePreset.name)
                        .font(.system(size: 12, weight: .semibold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                )
                .foregroundColor(.white)
            }
            
            // Effects Rack Button
            Button(action: {
                viewModel.isEffectsSheetPresented = true
            }) {
                Image(systemName: "dial.low.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(viewModel.effects.isReverbEnabled || viewModel.effects.isDelayEnabled ? .cyan : .white)
                    .padding(8)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
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
