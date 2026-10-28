import SwiftUI

/// Studio Transport control bar containing interactive waveform scrubber,
/// tactile playback buttons, synthesized demo sound picker, and file importer.
public struct PlayerControlBarView: View {
    @ObservedObject var viewModel: EqualizerViewModel
    @State private var isScrubbing: Bool = false
    
    public init(viewModel: EqualizerViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // Track Info & Source Menu
            HStack(spacing: 10) {
                // Audio Waveform Glyphs Badge
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(EqualizerTheme.Colors.cyanAccent.opacity(0.12))
                        .frame(width: 34, height: 34)
                    
                    Image(systemName: viewModel.isPlaying ? "waveform" : "music.note")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(EqualizerTheme.Colors.cyanAccent)
                }
                
                VStack(alignment: .leading, spacing: 1.5) {
                    Text(viewModel.currentTrack.title)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text("\(viewModel.currentTrack.artist) • \(viewModel.currentTrack.formatDescription)")
                        .font(.system(size: 10.5, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Demo Synthesizer Audio Menu
                Menu {
                    ForEach(DemoSoundType.allCases) { type in
                        Button(action: {
                            viewModel.loadDemoTone(type)
                            EqualizerTheme.Haptics.selection()
                        }) {
                            Label(type.rawValue, systemImage: type.iconName)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "waveform.badge.plus")
                            .font(.system(size: 10.5))
                        Text("Demo Audio")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4.5)
                    .background(EqualizerTheme.Colors.surfaceElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(EqualizerTheme.Colors.borderHairline, lineWidth: 1)
                    )
                    .cornerRadius(7)
                    .foregroundColor(EqualizerTheme.Colors.cyanAccent)
                }
                
                // Import Audio File Button
                Button(action: {
                    viewModel.isFilePickerPresented = true
                    EqualizerTheme.Haptics.impactLight()
                }) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(7)
                        .background(EqualizerTheme.Colors.surfaceElevated)
                        .overlay(
                            Circle().stroke(EqualizerTheme.Colors.borderHairline, lineWidth: 1)
                        )
                        .clipShape(Circle())
                }
                .pressable()
            }
            .padding(.horizontal, 16)
            
            // Progress Bar / Interactive Scrubber
            VStack(spacing: 3) {
                GeometryReader { geo in
                    let width = geo.size.width
                    let progress = viewModel.duration > 0 ? CGFloat(viewModel.currentTime / viewModel.duration) : 0.0
                    
                    ZStack(alignment: .leading) {
                        // Recessed Track Trough
                        Capsule()
                            .fill(EqualizerTheme.Colors.backgroundBase)
                            .frame(height: 5.5)
                            .overlay(
                                Capsule().stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                            )
                        
                        // Active Elapsed Gradient Fill
                        Capsule()
                            .fill(EqualizerTheme.Colors.cyanBlueGradient)
                            .frame(width: max(0, min(width, width * progress)), height: 5.5)
                            .shadow(color: EqualizerTheme.Colors.cyanAccent.opacity(0.3), radius: 3)
                        
                        // Scrubber Thumb Tick
                        if isScrubbing || viewModel.isPlaying {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 12, height: 12)
                                .shadow(color: Color.black.opacity(0.4), radius: 2)
                                .offset(x: max(0, min(width - 12, width * progress - 6)))
                        }
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { val in
                                isScrubbing = true
                                let fraction = max(0.0, min(1.0, val.location.x / width))
                                let targetTime = Double(fraction) * viewModel.duration
                                viewModel.seek(to: targetTime)
                            }
                            .onEnded { _ in
                                isScrubbing = false
                                EqualizerTheme.Haptics.impactLight()
                            }
                    )
                }
                .frame(height: 14)
                
                // Optical Timestamps (Elapsed vs Remaining)
                HStack {
                    Text(AudioTrack.formatTime(viewModel.currentTime))
                        .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    let remaining = max(0.0, viewModel.duration - viewModel.currentTime)
                    Text("-" + AudioTrack.formatTime(remaining))
                        .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            
            // Transport Action Buttons
            HStack(spacing: 28) {
                // Loop toggle
                Button(action: {
                    withAnimation(EqualizerTheme.AnimationSprings.tactile) {
                        viewModel.toggleLoop()
                    }
                    EqualizerTheme.Haptics.impactLight()
                }) {
                    Image(systemName: "repeat")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(viewModel.isLooping ? EqualizerTheme.Colors.cyanAccent : .secondary)
                        .padding(8)
                        .background(viewModel.isLooping ? EqualizerTheme.Colors.cyanAccent.opacity(0.12) : Color.clear)
                        .clipShape(Circle())
                }
                .pressable()
                
                // Restart / Seek to Start
                Button(action: {
                    withAnimation(EqualizerTheme.AnimationSprings.tactile) {
                        viewModel.seek(to: 0.0)
                    }
                    EqualizerTheme.Haptics.impactLight()
                }) {
                    Image(systemName: "backward.end.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                .pressable()
                
                // Central Island Play / Pause Button
                Button(action: {
                    withAnimation(EqualizerTheme.AnimationSprings.tactile) {
                        viewModel.togglePlayPause()
                    }
                    EqualizerTheme.Haptics.impactMedium()
                }) {
                    ZStack {
                        Circle()
                            .fill(EqualizerTheme.Colors.cyanBlueGradient)
                            .frame(width: 52, height: 52)
                            .shadow(color: EqualizerTheme.Colors.cyanAccent.opacity(0.35), radius: 8, x: 0, y: 3)
                        
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                            .offset(x: viewModel.isPlaying ? 0 : 1.5)
                    }
                }
                .pressable()
                
                // Stop Button
                Button(action: {
                    withAnimation(EqualizerTheme.AnimationSprings.tactile) {
                        viewModel.stop()
                    }
                    EqualizerTheme.Haptics.impactLight()
                }) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                .pressable()
                
                // DSP Effects Rack button
                Button(action: {
                    viewModel.isEffectsSheetPresented = true
                    EqualizerTheme.Haptics.impactLight()
                }) {
                    Image(systemName: "dial.low.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(viewModel.effects.isReverbEnabled || viewModel.effects.isDelayEnabled ? EqualizerTheme.Colors.cyanAccent : .secondary)
                        .padding(8)
                        .background((viewModel.effects.isReverbEnabled || viewModel.effects.isDelayEnabled) ? EqualizerTheme.Colors.cyanAccent.opacity(0.12) : Color.clear)
                        .clipShape(Circle())
                }
                .pressable()
            }
            .padding(.bottom, 4)
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
