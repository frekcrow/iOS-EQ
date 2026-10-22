import SwiftUI

/// Sheet providing system-level audio controls, TrollStore status,
/// Headphone Accommodations Audiogram injection, and daemon management.
public struct SystemAudioSheetView: View {
    @ObservedObject var viewModel: EqualizerViewModel
    @Environment(\.presentationMode) var presentationMode
    
    public init(viewModel: EqualizerViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.06, blue: 0.08).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Environment & Active Route Card
                        environmentCard
                        
                        // System-Wide EQ (Headphone Accommodations)
                        systemEQCard
                        
                        // Volume Limit & Audio Server Management
                        advancedCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("System Audio Control")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.cyan)
                }
            }
        }
    }
    
    // MARK: - Environment Card
    private var environmentCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "cpu")
                    .foregroundColor(.cyan)
                Text("ENVIRONMENT & HARDWARE ROUTE")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    viewModel.refreshSystemStatus()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13))
                        .foregroundColor(.cyan)
                }
            }
            
            HStack {
                Text("Access Level:")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Spacer()
                Text(viewModel.environmentName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(viewModel.isUnsandboxed ? .green : .orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(viewModel.isUnsandboxed ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                    )
            }
            
            HStack {
                Text("Active Route:")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "airpodspro")
                        .font(.system(size: 12))
                    Text(viewModel.activeAudioRoute)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.cyan)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(white: 0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    // MARK: - System-Wide EQ Card
    private var systemEQCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "headphones")
                    .foregroundColor(.purple)
                Text("SYSTEM-WIDE EQUALIZER (AIRPODS / HEADPHONES)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Toggle("", isOn: $viewModel.isSystemEQActive)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .purple))
                    .onChange(of: viewModel.isSystemEQActive) { active in
                        if active {
                            viewModel.applySystemWideEQ()
                        } else {
                            viewModel.disableSystemWideEQ()
                        }
                    }
            }
            
            Text("Applies your custom 10-band curve globally to Spotify, Apple Music, YouTube, Safari, games, and phone calls using Apple's Headphone Accommodations.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Push Current Curve Button
            Button(action: {
                viewModel.applySystemWideEQ()
            }) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Apply Current EQ Curve Globally")
                        .font(.system(size: 13, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: [Color.purple, Color.blue], startPoint: .leading, endPoint: .trailing))
                )
                .foregroundColor(.white)
            }
            
            if !viewModel.systemStatusMessage.isEmpty {
                Text(viewModel.systemStatusMessage)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.green)
                    .padding(.top, 2)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(white: 0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(viewModel.isSystemEQActive ? Color.purple.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Advanced Audio Server Card
    private var advancedCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "slider.horizontal.below.rectangle")
                    .foregroundColor(.orange)
                Text("ADVANCED AUDIO TWEAKS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Bypass EU Headphone Volume Limit
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Disable EU 85dB Volume Cap")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                    Text("Unlocks 100% volume output on headphones")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Unlock") {
                    viewModel.disableHeadphoneSafetyLimit()
                }
                .font(.system(size: 12, weight: .bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.orange.opacity(0.2)))
                .foregroundColor(.orange)
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            // Restart Audio Daemon
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Restart mediaserverd")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                    Text("Kills and restarts audio daemon to force reload")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Restart") {
                    viewModel.restartAudioDaemon()
                }
                .font(.system(size: 12, weight: .bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.red.opacity(0.2)))
                .foregroundColor(.red)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(white: 0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}
