import SwiftUI

/// Transport control bar containing scrubber, playback buttons, demo generator menu, and file importer.
public struct PlayerControlBarView: View {
    @ObservedObject var viewModel: EqualizerViewModel
    
    public init(viewModel: EqualizerViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // Track Info Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.currentTrack.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text("\(viewModel.currentTrack.artist) • \(viewModel.currentTrack.formatDescription)")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Demo Audio Selector Menu
                Menu {
                    ForEach(DemoSoundType.allCases) { type in
                        Button(action: {
                            viewModel.loadDemoTone(type)
                        }) {
                            Label(type.rawValue, systemImage: type.iconName)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "waveform.badge.magnifyingglass")
                            .font(.system(size: 11))
                        Text("Demo Audio")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(8)
                    .foregroundColor(.cyan)
                }
                
                // Import Audio File Button
                Button(action: {
                    viewModel.isFilePickerPresented = true
                }) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            
            // Progress Bar / Scrubber
            VStack(spacing: 4) {
                GeometryReader { geo in
                    let width = geo.size.width
                    let progress = viewModel.duration > 0 ? CGFloat(viewModel.currentTime / viewModel.duration) : 0.0
                    
                    ZStack(alignment: .leading) {
                        // Track trough
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 5)
                        
                        // Active elapsed fill
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.cyan, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, min(width, width * progress)), height: 5)
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { val in
                                let fraction = max(0.0, min(1.0, val.location.x / width))
                                let targetTime = Double(fraction) * viewModel.duration
                                viewModel.seek(to: targetTime)
                            }
                    )
                }
                .frame(height: 12)
                
                // Timestamps (Elapsed vs Remaining)
                HStack {
                    Text(AudioTrack.formatTime(viewModel.currentTime))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    let remaining = max(0.0, viewModel.duration - viewModel.currentTime)
                    Text("-" + AudioTrack.formatTime(remaining))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            
            // Transport Action Buttons
            HStack(spacing: 32) {
                // Loop toggle
                Button(action: {
                    viewModel.toggleLoop()
                }) {
                    Image(systemName: "repeat")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(viewModel.isLooping ? .cyan : .secondary)
                }
                
                // Restart / Seek to Start
                Button(action: {
                    viewModel.seek(to: 0.0)
                }) {
                    Image(systemName: "backward.end.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                
                // Main Play / Pause Button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        viewModel.togglePlayPause()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.cyan, Color.blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 54, height: 54)
                            .shadow(color: Color.cyan.opacity(0.4), radius: 8, x: 0, y: 3)
                        
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.black)
                            .offset(x: viewModel.isPlaying ? 0 : 1.5)
                    }
                }
                
                // Stop Button
                Button(action: {
                    viewModel.stop()
                }) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                
                // Effects Rack button
                Button(action: {
                    viewModel.isEffectsSheetPresented = true
                }) {
                    Image(systemName: "dial.low.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(viewModel.effects.isReverbEnabled || viewModel.effects.isDelayEnabled ? .cyan : .secondary)
                }
            }
            .padding(.bottom, 6)
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
