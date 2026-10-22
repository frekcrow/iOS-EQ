import SwiftUI

/// Studio Effects Rack modal presenting Reverb, Delay, Pitch, Distortion, and Pan controls.
public struct EffectsRackView: View {
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
                        // Reverb Unit
                        reverbCard
                        
                        // Delay / Echo Unit
                        delayCard
                        
                        // Pitch Shifter & Speed
                        pitchCard
                        
                        // Distortion / Saturation
                        distortionCard
                        
                        // Stereo Pan & Master Volume
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
                    .foregroundColor(.cyan)
                }
            }
        }
    }
    
    // MARK: - Reverb Card
    private var reverbCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "skew")
                    .foregroundColor(.purple)
                Text("REVERBERATION")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Toggle("", isOn: $viewModel.effects.isReverbEnabled)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .purple))
                    .onChange(of: viewModel.effects.isReverbEnabled) { _ in
                        viewModel.updateEffects()
                    }
            }
            
            if viewModel.effects.isReverbEnabled {
                VStack(spacing: 12) {
                    // Preset Picker
                    HStack {
                        Text("Room Preset")
                            .font(.system(size: 13))
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
                        }
                    }
                    
                    // Wet/Dry Mix
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Wet / Dry Mix")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.0f %%", viewModel.effects.reverbWetDryMix))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.purple)
                        }
                        
                        Slider(value: $viewModel.effects.reverbWetDryMix, in: 0...100, step: 1) {
                            Text("Mix")
                        }
                        .accentColor(.purple)
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
                .fill(Color(white: 0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(viewModel.effects.isReverbEnabled ? Color.purple.opacity(0.5) : Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Delay Card
    private var delayCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "repeat.1")
                    .foregroundColor(.blue)
                Text("STEREO DELAY / ECHO")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Toggle("", isOn: $viewModel.effects.isDelayEnabled)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .onChange(of: viewModel.effects.isDelayEnabled) { _ in
                        viewModel.updateEffects()
                    }
            }
            
            if viewModel.effects.isDelayEnabled {
                VStack(spacing: 12) {
                    // Delay Time
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Delay Time")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.2f s", viewModel.effects.delayTime))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.blue)
                        }
                        
                        Slider(value: $viewModel.effects.delayTime, in: 0.05...1.0, step: 0.01) {
                            Text("Time")
                        }
                        .accentColor(.blue)
                        .onChange(of: viewModel.effects.delayTime) { _ in
                            viewModel.updateEffects()
                        }
                    }
                    
                    // Feedback
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Feedback")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.0f %%", viewModel.effects.delayFeedback))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.blue)
                        }
                        
                        Slider(value: $viewModel.effects.delayFeedback, in: 0...90, step: 1) {
                            Text("Feedback")
                        }
                        .accentColor(.blue)
                        .onChange(of: viewModel.effects.delayFeedback) { _ in
                            viewModel.updateEffects()
                        }
                    }
                    
                    // Wet/Dry Mix
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Wet / Dry Mix")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.0f %%", viewModel.effects.delayWetDryMix))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.blue)
                        }
                        
                        Slider(value: $viewModel.effects.delayWetDryMix, in: 0...100, step: 1) {
                            Text("Mix")
                        }
                        .accentColor(.blue)
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
                .fill(Color(white: 0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(viewModel.effects.isDelayEnabled ? Color.blue.opacity(0.5) : Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Pitch & Speed Card
    private var pitchCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tuningfork")
                    .foregroundColor(.cyan)
                Text("PITCH & PLAYBACK RATE")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Toggle("", isOn: $viewModel.effects.isPitchEnabled)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .cyan))
                    .onChange(of: viewModel.effects.isPitchEnabled) { _ in
                        viewModel.updateEffects()
                    }
            }
            
            if viewModel.effects.isPitchEnabled {
                VStack(spacing: 12) {
                    // Pitch Shift
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Pitch Shift")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Spacer()
                            let semitones = viewModel.effects.pitchCents / 100.0
                            Text(String(format: "%+.1f semitones", semitones))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan)
                        }
                        
                        Slider(value: $viewModel.effects.pitchCents, in: -1200...1200, step: 100) {
                            Text("Pitch")
                        }
                        .accentColor(.cyan)
                        .onChange(of: viewModel.effects.pitchCents) { _ in
                            viewModel.updateEffects()
                        }
                    }
                    
                    // Rate (Speed)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Playback Speed")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.2fx", viewModel.effects.playbackRate))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan)
                        }
                        
                        Slider(value: $viewModel.effects.playbackRate, in: 0.5...2.0, step: 0.05) {
                            Text("Speed")
                        }
                        .accentColor(.cyan)
                        .onChange(of: viewModel.effects.playbackRate) { _ in
                            viewModel.updateEffects()
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(white: 0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(viewModel.effects.isPitchEnabled ? Color.cyan.opacity(0.5) : Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Distortion Card
    private var distortionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.orange)
                Text("DISTORTION & OVERDRIVE")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Toggle("", isOn: $viewModel.effects.isDistortionEnabled)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .orange))
                    .onChange(of: viewModel.effects.isDistortionEnabled) { _ in
                        viewModel.updateEffects()
                    }
            }
            
            if viewModel.effects.isDistortionEnabled {
                VStack(spacing: 12) {
                    HStack {
                        Text("Flavor")
                            .font(.system(size: 13))
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
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Amount")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.0f %%", viewModel.effects.distortionWetDryMix))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.orange)
                        }
                        
                        Slider(value: $viewModel.effects.distortionWetDryMix, in: 0...100, step: 1) {
                            Text("Mix")
                        }
                        .accentColor(.orange)
                        .onChange(of: viewModel.effects.distortionWetDryMix) { _ in
                            viewModel.updateEffects()
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(white: 0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(viewModel.effects.isDistortionEnabled ? Color.orange.opacity(0.5) : Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Master Routing & Pan
    private var masterRoutingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "headphones")
                    .foregroundColor(.green)
                Text("PANNING & MASTER VOLUME")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Stereo Pan
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("L")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Stereo Balance")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("R")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $viewModel.effects.panBalance, in: -1.0...1.0, step: 0.05) {
                    Text("Pan")
                }
                .accentColor(.green)
                .onChange(of: viewModel.effects.panBalance) { _ in
                    viewModel.updateEffects()
                }
            }
            
            // Master Volume
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Master Output")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.0f %%", viewModel.effects.masterVolume * 100))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                }
                
                Slider(value: $viewModel.effects.masterVolume, in: 0.0...1.0, step: 0.01) {
                    Text("Volume")
                }
                .accentColor(.green)
                .onChange(of: viewModel.effects.masterVolume) { _ in
                    viewModel.updateEffects()
                }
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
