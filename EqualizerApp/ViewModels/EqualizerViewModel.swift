import Foundation
import Combine
import SwiftUI

/// Main ViewModel coordinating Equalizer audio processing, presets, spectrum metering, and transport controls.
public final class EqualizerViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var bands: [EQBand]
    @Published public var activePreset: EQPreset
    @Published public var systemPresets: [EQPreset]
    @Published public var customPresets: [EQPreset]
    @Published public var currentTrack: AudioTrack
    
    @Published public var isPlaying: Bool = false
    @Published public var currentTime: TimeInterval = 0.0
    @Published public var duration: TimeInterval = 0.0
    @Published public var isLooping: Bool = true
    
    @Published public var spectrumMagnitudes: [Float] = Array(repeating: 0.0, count: 20)
    @Published public var isEQBypassed: Bool = false
    @Published public var preampGain: Float = 0.0 // dB (-12 to +12)
    @Published public var effects: AudioEffectSettings = AudioEffectSettings()
    
    @Published public var errorMessage: String? = nil
    @Published public var showErrorAlert: Bool = false
    @Published public var isFilePickerPresented: Bool = false
    @Published public var isPresetsSheetPresented: Bool = false
    @Published public var isEffectsSheetPresented: Bool = false
    @Published public var isSavePresetDialogPresented: Bool = false
    
    // MARK: - Private Engine & Services
    private let audioEngine: AudioEngineManager
    private let presetStore: PresetStore
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        audioEngine: AudioEngineManager = AudioEngineManager(),
        presetStore: PresetStore = PresetStore()
    ) {
        self.audioEngine = audioEngine
        self.presetStore = presetStore
        
        self.bands = EQBand.defaultBands
        self.activePreset = .flat
        self.systemPresets = EQPreset.systemPresets
        self.customPresets = presetStore.loadCustomPresets()
        self.currentTrack = .placeholder
        
        setupEngineCallbacks()
        loadInitialDemoAudio()
    }
    
    // MARK: - Engine Callbacks
    private func setupEngineCallbacks() {
        audioEngine.onMagnitudesUpdated = { [weak self] magnitudes in
            self?.spectrumMagnitudes = magnitudes
        }
        
        audioEngine.onPlaybackProgress = { [weak self] current, total in
            self?.currentTime = current
            self?.duration = total
        }
        
        audioEngine.onPlaybackEnded = { [weak self] in
            self?.isPlaying = false
        }
    }
    
    private func loadInitialDemoAudio() {
        // Load default synthesized harmonic sound so the user can immediately hit Play
        loadDemoTone(.synthChord)
    }
    
    // MARK: - Transport Controls
    public func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    public func play() {
        audioEngine.play()
        isPlaying = true
    }
    
    public func pause() {
        audioEngine.pause()
        isPlaying = false
    }
    
    public func stop() {
        audioEngine.stop()
        isPlaying = false
        currentTime = 0.0
    }
    
    public func seek(to time: TimeInterval) {
        audioEngine.seek(to: time)
        currentTime = time
    }
    
    public func toggleLoop() {
        isLooping.toggle()
        audioEngine.setLooping(isLooping)
    }
    
    // MARK: - Equalizer Band Operations
    public func setBandGain(index: Int, gain: Float) {
        guard index >= 0 && index < bands.count else { return }
        bands[index].gain = max(-12.0, min(12.0, gain))
        audioEngine.setBandGain(index: index, gain: bands[index].gain, bypass: bands[index].bypass)
        
        // If modified away from preset, indicate custom configuration
        if activePreset.isSystem {
            activePreset = EQPreset(
                name: "Custom",
                iconName: "slider.vertical.3",
                gains: bands.map { $0.gain },
                isSystem: false,
                category: .custom
            )
        }
    }
    
    public func toggleBandBypass(index: Int) {
        guard index >= 0 && index < bands.count else { return }
        bands[index].bypass.toggle()
        audioEngine.setBandGain(index: index, gain: bands[index].gain, bypass: bands[index].bypass)
    }
    
    public func toggleMasterEQBypass() {
        isEQBypassed.toggle()
        audioEngine.setEQBypass(isEQBypassed)
    }
    
    public func setPreampGain(_ gain: Float) {
        preampGain = max(-12.0, min(12.0, gain))
        // Apply linear scale to main mixer or effects preamp
        let linearMultiplier = pow(10.0, preampGain / 20.0)
        effects.masterVolume = min(1.0, linearMultiplier)
        audioEngine.updateEffects(effects)
    }
    
    public func resetToFlat() {
        applyPreset(.flat)
    }
    
    // MARK: - Preset Management
    public func applyPreset(_ preset: EQPreset) {
        activePreset = preset
        for (i, gain) in preset.gains.enumerated() {
            if i < bands.count {
                bands[i].gain = gain
                bands[i].bypass = false
            }
        }
        audioEngine.setAllBandGains(preset.gains)
    }
    
    public func saveCustomPreset(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let newPreset = EQPreset(
            name: trimmed,
            iconName: "slider.vertical.3",
            gains: bands.map { $0.gain },
            isSystem: false,
            category: .custom
        )
        
        customPresets = presetStore.addPreset(newPreset)
        activePreset = newPreset
    }
    
    public func deleteCustomPreset(_ preset: EQPreset) {
        customPresets = presetStore.deletePreset(id: preset.id)
        if activePreset.id == preset.id {
            applyPreset(.flat)
        }
    }
    
    // MARK: - Audio Effects Rack
    public func updateEffects() {
        audioEngine.updateEffects(effects)
    }
    
    // MARK: - Audio Loading
    public func loadAudioFile(url: URL) {
        do {
            let info = try audioEngine.loadAudioFile(url: url)
            currentTrack = AudioTrack(
                title: info.title,
                artist: "Imported File",
                album: "User Library",
                duration: info.duration,
                fileURL: url,
                isGeneratedTone: false,
                formatDescription: info.format
            )
            duration = info.duration
            currentTime = 0.0
            play()
        } catch {
            errorMessage = "Failed to load audio: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
    
    public func loadDemoTone(_ type: DemoSoundType) {
        let info = audioEngine.loadDemoTone(type: type)
        currentTrack = AudioTrack(
            title: info.title,
            artist: "Studio Synthesizer",
            album: "Built-in Tones",
            duration: info.duration,
            fileURL: nil,
            isGeneratedTone: true,
            formatDescription: info.format
        )
        duration = info.duration
        currentTime = 0.0
        audioEngine.setLooping(isLooping)
    }
}
