import SwiftUI

/// Sheet providing system-level audio controls, TrollStore status,
/// Headphone Accommodations Audiogram injection for wired headphones, and daemon management.
/// Designed with machined studio hardware aesthetics, double-bezel depth, and fluid tactile physics.
public struct SystemAudioSheetView: View {
    @ObservedObject var viewModel: EqualizerViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingResetAlert: Bool = false
    @State private var showingRespringAlert: Bool = false
    
    public init(viewModel: EqualizerViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                EqualizerTheme.Colors.backgroundBase
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Environment & Wired Route Card
                        environmentCard
                        
                        // System-Wide EQ for Wired Headphones
                        systemEQCard
                        
                        // Daemon & Respring Management Card
                        daemonManagementCard
                        
                        // Advanced Audio Tweaks Card
                        advancedCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Wired System Audio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        EqualizerTheme.Haptics.impactLight()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Done")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(EqualizerTheme.Colors.cyanAccent)
                    }
                }
            }
            // Reset Confirmation Alert
            .alert(isPresented: $showingResetAlert) {
                Alert(
                    title: Text("Reset Wired Headphone EQ?"),
                    message: Text("This will remove custom audiograms, turn off Headphone Accommodations for wired outputs, restore stock iOS audio settings, and restart audio daemons."),
                    primaryButton: .destructive(Text("Reset to Stock")) {
                        EqualizerTheme.Haptics.warning()
                        viewModel.resetWiredEQToStock()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    // MARK: - Environment & Wired Route Card
    private var environmentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cpu")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(EqualizerTheme.Colors.cyanAccent)
                
                Text("WIRED HARDWARE ROUTE & ENVIRONMENT")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.white)
                    .tracking(0.5)
                
                Spacer()
                
                Button(action: {
                    EqualizerTheme.Haptics.impactLight()
                    viewModel.refreshSystemStatus()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(EqualizerTheme.Colors.cyanAccent)
                        .padding(6)
                        .background(Circle().fill(EqualizerTheme.Colors.surfaceHighlight))
                }
                .pressable()
            }
            
            Divider().background(EqualizerTheme.Colors.borderHairline)
            
            // Access Level
            HStack {
                Text("Access Level:")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                Text(viewModel.environmentName)
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundColor(viewModel.isUnsandboxed ? EqualizerTheme.Colors.emerald : EqualizerTheme.Colors.tubeAmber)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(
                            (viewModel.isUnsandboxed ? EqualizerTheme.Colors.emerald : EqualizerTheme.Colors.tubeAmber).opacity(0.15)
                        )
                    )
            }
            
            // Wired Status
            HStack {
                Text("Wired Output Status:")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                HStack(spacing: 5) {
                    Circle()
                        .fill(viewModel.isWiredHeadsetConnected ? EqualizerTheme.Colors.emerald : EqualizerTheme.Colors.tubeAmber)
                        .frame(width: 7, height: 7)
                        .shadow(
                            color: (viewModel.isWiredHeadsetConnected ? EqualizerTheme.Colors.emerald : EqualizerTheme.Colors.tubeAmber).opacity(0.8),
                            radius: 3
                        )
                    Text(viewModel.isWiredHeadsetConnected ? "CONNECTED" : "NOT DETECTED")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(viewModel.isWiredHeadsetConnected ? EqualizerTheme.Colors.emerald : EqualizerTheme.Colors.tubeAmber)
                }
            }
            
            // Detected Port
            HStack {
                Text("Detected Hardware Port:")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                HStack(spacing: 5) {
                    Image(systemName: viewModel.isWiredHeadsetConnected ? "headphones" : "cable.connector.horizontal")
                        .font(.system(size: 12))
                    Text(viewModel.connectedPortName)
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(EqualizerTheme.Colors.cyanAccent)
            }
            
            // Hardware Format
            if viewModel.isWiredHeadsetConnected {
                HStack {
                    Text("Hardware Format:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(viewModel.hardwareFormatText)
                        .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(14)
        .studioCard(cornerRadius: 16)
    }
    
    // MARK: - Wired System-Wide EQ Card
    private var systemEQCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "headphones")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(EqualizerTheme.Colors.violet)
                
                Text("WIRED SYSTEM-WIDE EQUALIZER")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.white)
                    .tracking(0.5)
                
                Spacer()
                
                Toggle("", isOn: $viewModel.isSystemEQActive)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: EqualizerTheme.Colors.violet))
                    .onChange(of: viewModel.isSystemEQActive) { active in
                        EqualizerTheme.Haptics.impactMedium()
                        if active {
                            viewModel.applyToWiredOutput(restartDaemons: true)
                        } else {
                            viewModel.disableSystemWideEQ()
                        }
                    }
            }
            
            Text("Injects your custom 10-band EQ curve strictly into Apple's Headphone Accommodations & Audiogram daemon (heard) for wired routes (3.5mm Aux, Lightning, USB-C headphones & external USB DACs). Audio never leaks to built-in speaker.")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
            
            // Apply to Wired Output (Restart Audio) Button
            Button(action: {
                EqualizerTheme.Haptics.impactMedium()
                viewModel.applyToWiredOutput(restartDaemons: true)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("Apply to Wired Output (Restart Audio)")
                        .font(.system(size: 13, weight: .heavy))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(EqualizerTheme.Colors.purpleBlueGradient)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .foregroundColor(.white)
                .shadow(color: EqualizerTheme.Colors.violet.opacity(0.35), radius: 6, x: 0, y: 2)
            }
            .pressable()
            
            if !viewModel.systemStatusMessage.isEmpty {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(EqualizerTheme.Colors.emerald)
                    Text(viewModel.systemStatusMessage)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(EqualizerTheme.Colors.emerald)
                }
                .padding(.top, 2)
            }
        }
        .padding(14)
        .studioCard(cornerRadius: 16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    viewModel.isSystemEQActive ? EqualizerTheme.Colors.violet.opacity(0.4) : Color.clear,
                    lineWidth: 1
                )
        )
    }
    
    // MARK: - Daemon & Respring Management Card
    private var daemonManagementCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(EqualizerTheme.Colors.cyanAccent)
                
                Text("DAEMON & RESPRING ACTIONS")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.white)
                    .tracking(0.5)
            }
            
            Text("Forces mediaserverd & heard to reload CFPreferences without rebooting your iOS device.")
                .font(.system(size: 10.5, weight: .medium))
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                // Restart Audio Daemons Button
                Button(action: {
                    EqualizerTheme.Haptics.impactMedium()
                    viewModel.restartAudioEngine()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "speaker.wave.2.circle.fill")
                            .font(.system(size: 13))
                        Text("Restart Audio")
                            .font(.system(size: 12, weight: .heavy))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(EqualizerTheme.Colors.surfaceHighlight)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(EqualizerTheme.Colors.cyanAccent.opacity(0.4), lineWidth: 1)
                            )
                    )
                    .foregroundColor(EqualizerTheme.Colors.cyanAccent)
                }
                .pressable()
                
                // Respring Button
                Button(action: {
                    EqualizerTheme.Haptics.impactMedium()
                    viewModel.respring()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12))
                        Text("Respring")
                            .font(.system(size: 12, weight: .heavy))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(EqualizerTheme.Colors.surfaceHighlight)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(EqualizerTheme.Colors.tubeAmber.opacity(0.4), lineWidth: 1)
                            )
                    )
                    .foregroundColor(EqualizerTheme.Colors.tubeAmber)
                }
                .pressable()
            }
            
            Divider().background(EqualizerTheme.Colors.borderHairline)
            
            // Reset to Stock Default Button
            Button(action: {
                EqualizerTheme.Haptics.warning()
                showingResetAlert = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.system(size: 13))
                    Text("Reset Wired EQ to Stock Default")
                        .font(.system(size: 12, weight: .heavy))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(EqualizerTheme.Colors.peakPink.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(EqualizerTheme.Colors.peakPink.opacity(0.35), lineWidth: 1)
                        )
                )
                .foregroundColor(EqualizerTheme.Colors.peakPink)
            }
            .pressable()
        }
        .padding(14)
        .studioCard(cornerRadius: 16)
    }
    
    // MARK: - Advanced Audio Tweaks Card
    private var advancedCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "slider.horizontal.below.rectangle")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(EqualizerTheme.Colors.tubeAmber)
                
                Text("ADVANCED AUDIO TWEAKS")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.white)
                    .tracking(0.5)
            }
            
            // Bypass EU Headphone Volume Limit
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Disable EU 85dB Wired Headphone Cap")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Unlocks 100% full-scale volume on 3.5mm/Lightning/USB-C")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    EqualizerTheme.Haptics.impactLight()
                    viewModel.disableHeadphoneSafetyLimit()
                }) {
                    Text("Unlock")
                        .font(.system(size: 12, weight: .heavy))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(EqualizerTheme.Colors.tubeAmber.opacity(0.2))
                                .overlay(
                                    Capsule().stroke(EqualizerTheme.Colors.tubeAmber.opacity(0.4), lineWidth: 1)
                                )
                        )
                        .foregroundColor(EqualizerTheme.Colors.tubeAmber)
                }
                .pressable()
            }
        }
        .padding(14)
        .studioCard(cornerRadius: 16)
    }
}
