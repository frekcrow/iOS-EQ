import SwiftUI

/// Studio DSP Effects Rack modal presenting Reverb, Delay, Pitch, Distortion,
/// Stereo Pan, and Master Volume controls in a double-bezel modular rack design.
public struct EffectsRackView: View {
    @ObservedObject var viewModel: EqualizerViewModel
    @Environment(\.presentationMode) var presentationMode
    
    public init(viewModel: EqualizerViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                EqualizerTheme.Colors.backgroundBase.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 14) {
                        // Reverb Module
                        reverbCard
                        
                        // Stereo Delay / Echo Module
                        delayCard
                        
                        // Pitch Shifter & Playback Speed
                        pitchCard
                        
                        // Distortion / Tube Saturation
                        distortionCard
                        
                        // Master Output & Stereo Panning
                        masterRoutingCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("DSP Effects Studio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(EqualizerTheme.Colors.cyanAccent)
                }
            }
        }
    }
    
    // MARK: - Reverb Card
    private var reverbCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "skew")
                    .foregroundColor(EqualizerTheme.Colors.violet)
                    .font(.system(size: 14, weight: .bold))
                Text("REVERBERATION")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(0.5)
                
                Spacer()
                
                Toggle("", isOn: $viewModel.effects.isReverbEnabled)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: EqualizerTheme.Colors.violet))
                    .onChange(of: viewModel.effects.isReverbEnabled) { _ in
                        withAnimation(EqualizerTheme.AnimationSprings.tactile) {
                            viewModel.updateEffects()
                        }
                        EqualizerTheme.Haptics.impactLight()
                    }
            }
            
            if viewModel.effects.isReverbEnabled {
                VStack(spacing: 12) {
                    // Preset Picker
                    HStack {
                        Text("Room Preset")
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        Picker("Preset", selection: $viewModel.effects.reverbPreset) {
                            ForEach(ReverbPresetOption.allCases) { opt in
                                Text(opt.displayName).tag(opt)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: viewModel.effects.reverbPreset) { _ in
                            viewModel.updateEffects()
                            EqualizerTheme.Haptics.selection()
                        }
                    }
                    
                    // Wet/Dry Mix
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Wet / Dry Mix")
                                .font(.system(size: 11.5))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.0f %%", viewModel.effects.reverbWetDryMix))
                                .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                                .foregroundColor(EqualizerTheme.Colors.violet)
                        }
                        
                        Slider(value: $viewModel.effects.reverbWetDryMix, in: 0...100, step: 1)
                            .accentColor(EqualizerTheme.Colors.violet)
                            .onChange(of: viewModel.effects.reverbWetDryMix) { _ in
                                viewModel.updateEffects()
                            }
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(EqualizerTheme.Colors.surfaceTray)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(viewModel.effects.isReverbEnabled ? EqualizerTheme.Colors.violet.opacity(0.4) : EqualizerTheme.Colors.borderHairline, lineWidth: 1)
                )
        )
    }
    
    // MARK: - Delay Card
    private var delayCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "repeat.1")
                    .foregroundColor(EqualizerTheme.Colors.royalBlue)
                    .font(.system(size: 14, weight: .bold))
                Text("STEREO DELAY / ECHO")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(0.5)
                
                Spacer()
                
                Toggle("", isOn: $viewModel.effects.isDelayEnabled)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: EqualizerTheme.Colors.royalBlue))
                    .onChange(of: viewModel.effects.isDelayEnabled) { _ in
                        withAnimation(EqualizerTheme.AnimationSprings.tactile) {
                            viewModel.updateEffects()
                        }
                        EqualizerTheme.Haptics.impactLight()
                    }
            }
            
            if viewModel.effects.isDelayEnabled {
                VStack(spacing: 12) {
                    // Delay Time
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Delay Time")
                                .font(.system(size: 11.5))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.2f s", viewModel.effects.delayTime))
                                .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                                .foregroundColor(EqualizerTheme.Colors.royalBlue)
                        }
                        
                        Slider(value: $viewModel.effects.delayTime, in: 0.05...1.0, step: 0.01)
                            .accentColor(EqualizerTheme.Colors.royalBlue)
                            .onChange(of: viewModel.effects.delayTime) { _ in
                                viewModel.updateEffects()
                            }
                    }
                    
                    // Feedback
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Feedback")
                                .font(.system(size: 11.5))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.0f %%", viewModel.effects.delayFeedback))
                                .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                                .foregroundColor(EqualizerTheme.Colors.royalBlue)
                        }
                        
                        Slider(value: $viewModel.effects.delayFeedback, in: 0...90, step: 1)
                            .accentColor(EqualizerTheme.Colors.royalBlue)
                            .onChange(of: viewModel.effects.delayFeedback) { _ in
                                viewModel.updateEffects()
                            }
                    }
                    
                    // Wet/Dry Mix
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Wet / Dry Mix")
                                .font(.system(size: 11.5))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.0f %%", viewModel.effects.delayWetDryMix))
                                .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                                .foregroundColor(EqualizerTheme.Colors.royalBlue)
                        }
                        
                        Slider(value: $viewModel.effects.delayWetDryMix, in: 0...100, step: 1)
                            .accentColor(EqualizerTheme.Colors.royalBlue)
                            .onChange(of: viewModel.effects.delayWetDryMix) { _ in
                                viewModel.updateEffects()
                            }
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(EqualizerTheme.Colors.surfaceTray)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(viewModel.effects.isDelayEnabled ? EqualizerTheme.Colors.royalBlue.opacity(0.4) : EqualizerTheme.Colors.borderHairline, lineWidth: 1)
                )
        )
    }
    
    // MARK: - Pitch & Speed Card
    private var pitchCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tuningfork")
                    .foregroundColor(EqualizerTheme.Colors.cyanAccent)
                    .font(.system(size: 14, weight: .bold))
                Text("PITCH & PLAYBACK SPEED")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(0.5)
                
                Spacer()
                
                Toggle("", isOn: $viewModel.effects.isPitchEnabled)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: EqualizerTheme.Colors.cyanAccent))
                    .onChange(of: viewModel.effects.isPitchEnabled) { _ in
                        withAnimation(EqualizerTheme.AnimationSprings.tactile) {
                            viewModel.updateEffects()
                        }
                        EqualizerTheme.Haptics.impactLight()
                    }
            }
            
            if viewModel.effects.isPitchEnabled {
                VStack(spacing: 12) {
                    // Pitch Shift
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Pitch Shift")
                                .font(.system(size: 11.5))
                                .foregroundColor(.secondary)
                            Spacer()
                            let semitones = viewModel.effects.pitchCents / 100.0
                            Text(String(format: "%+.1f semitones", semitones))
                                .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                                .foregroundColor(EqualizerTheme.Colors.cyanAccent)
                        }
                        
                        Slider(value: $viewModel.effects.pitchCents, in: -1200...1200, step: 100)
                            .accentColor(EqualizerTheme.Colors.cyanAccent)
                            .onChange(of: viewModel.effects.pitchCents) { _ in
                                viewModel.updateEffects()
                            }
                    }
                    
                    // Rate (Speed)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Playback Speed")
                                .font(.system(size: 11.5))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.2fx", viewModel.effects.playbackRate))
                                .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                                .foregroundColor(EqualizerTheme.Colors.cyanAccent)
                        }
                        
                        Slider(value: $viewModel.effects.playbackRate, in: 0.5...2.0, step: 0.05)
                            .accentColor(EqualizerTheme.Colors.cyanAccent)
                            .onChange(of: viewModel.effects.playbackRate) { _ in
                                viewModel.updateEffects()
                            }
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(EqualizerTheme.Colors.surfaceTray)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(viewModel.effects.isPitchEnabled ? EqualizerTheme.Colors.cyanAccent.opacity(0.4) : EqualizerTheme.Colors.borderHairline, lineWidth: 1)
                )
        )
    }
    
    // MARK: - Distortion Card
    private var distortionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(EqualizerTheme.Colors.tubeAmber)
                    .font(.system(size: 14, weight: .bold))
                Text("DISTORTION & TUBE DRIVE")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(0.5)
                
                Spacer()
                
                Toggle("", isOn: $viewModel.effects.isDistortionEnabled)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: EqualizerTheme.Colors.tubeAmber))
                    .onChange(of: viewModel.effects.isDistortionEnabled) { _ in
                        withAnimation(EqualizerTheme.AnimationSprings.tactile) {
                            viewModel.updateEffects()
                        }
                        EqualizerTheme.Haptics.impactLight()
                    }
            }
            
            if viewModel.effects.isDistortionEnabled {
                VStack(spacing: 12) {
                    HStack {
                        Text("Drive Flavor")
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        Picker("Distortion Type", selection: $viewModel.effects.distortionPreset) {
                            ForEach(DistortionPresetOption.allCases) { opt in
                                Text(opt.displayName).tag(opt)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: viewModel.effects.distortionPreset) { _ in
                            viewModel.updateEffects()
                            EqualizerTheme.Haptics.selection()
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Drive Amount")
                                .font(.system(size: 11.5))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.0f %%", viewModel.effects.distortionWetDryMix))
                                .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                                .foregroundColor(EqualizerTheme.Colors.tubeAmber)
                        }
                        
                        Slider(value: $viewModel.effects.distortionWetDryMix, in: 0...100, step: 1)
                            .accentColor(EqualizerTheme.Colors.tubeAmber)
                            .onChange(of: viewModel.effects.distortionWetDryMix) { _ in
                                viewModel.updateEffects()
                            }
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(EqualizerTheme.Colors.surfaceTray)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(viewModel.effects.isDistortionEnabled ? EqualizerTheme.Colors.tubeAmber.opacity(0.4) : EqualizerTheme.Colors.borderHairline, lineWidth: 1)
                )
        )
    }
    
    // MARK: - Master Routing & Pan
    private var masterRoutingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "headphones")
                    .foregroundColor(EqualizerTheme.Colors.emerald)
                    .font(.system(size: 14, weight: .bold))
                Text("PANNING & MASTER OUTPUT")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(0.5)
            }
            
            // Stereo Pan
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("L")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Stereo Balance")
                        .font(.system(size: 11.5))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("R")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $viewModel.effects.panBalance, in: -1.0...1.0, step: 0.05)
                    .accentColor(EqualizerTheme.Colors.emerald)
                    .onChange(of: viewModel.effects.panBalance) { _ in
                        viewModel.updateEffects()
                    }
            }
            
            // Master Volume
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Master Volume")
                        .font(.system(size: 11.5))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.0f %%", viewModel.effects.masterVolume * 100))
                        .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                        .foregroundColor(EqualizerTheme.Colors.emerald)
                }
                
                Slider(value: $viewModel.effects.masterVolume, in: 0.0...1.0, step: 0.01)
                    .accentColor(EqualizerTheme.Colors.emerald)
                    .onChange(of: viewModel.effects.masterVolume) { _ in
                        viewModel.updateEffects()
                    }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(EqualizerTheme.Colors.surfaceTray)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(EqualizerTheme.Colors.borderHairline, lineWidth: 1)
                )
        )
    }
}
