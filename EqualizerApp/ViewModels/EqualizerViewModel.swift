import Foundation
import Combine
import SwiftUI

/// Operational Mode of Equalizer Pro.
public enum AppAudioMode: String, CaseIterable, Identifiable {
    case systemWide = "Wired System EQ"
    case microphoneDSP = "Wired Mic / Voice"
    case mediaPlayer = "Studio Player"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .systemWide: return "headphones"
        case .microphoneDSP: return "mic.fill"
        case .mediaPlayer: return "music.note"
        }
    }
}

/// Main ViewModel coordinating Equalizer audio processing, system-wide Audiograms for Wired Headphones,
/// live microphone hardware monitoring, and media playback on iOS 14.0-15.x.
public final class EqualizerViewModel: ObservableObject {
    
    // MARK: - App Operating Mode
    @Published public var audioMode: AppAudioMode = .systemWide
    
    // MARK: - Jailbreak & Environment Status
    @Published public var environmentName: String = ""
    @Published public var isUnsandboxed: Bool = false
    @Published public var activeAudioRoute: String = "No Wired Headphones"
    
    // MARK: - Wired Headphone Monitor Properties
    @Published public var isWiredHeadsetConnected: Bool = false
    @Published public var connectedPortName: String = "No Wired Headphones"
    @Published public var portTypeDescription: String = "Disconnected"
    @Published public var wiredSampleRate: Double = 44100.0
    @Published public var wiredChannelCount: Int = 2
    @Published public var hardwareFormatText: String = "-- kHz • --"
    
    // MARK: - System-Wide Headphone Accommodations & Audiogram
    @Published public var isSystemEQActive: Bool = false
    @Published public var systemTuning: SystemAudiogramManager.TuningType = .customAudiogram
    @Published public var systemStrength: SystemAudiogramManager.BoostStrength = .moderate
    @Published public var isHeadphoneLimitDisabled: Bool = false
    @Published public var systemStatusMessage: String = ""
    
    // MARK: - Live Hardware Microphone & Voice DSP
    @Published public var isMicMonitoring: Bool = false
    @Published public var micGain: Float = 1.0 // 1.0 = normal, up to 3.0 (+10 dB)
    @Published public var isNoiseGateEnabled: Bool = true
    @Published public var voicePitchCents: Float = 0.0 // -1200 to +1200
    
    // MARK: - Equalizer Bands & Presets
    @Published public var bands: [EQBand]
    @Published public var activePreset: EQPreset
    @Published public var systemPresets: [EQPreset]
    @Published public var customPresets: [EQPreset]
    @Published public var isEQBypassed: Bool = false
    @Published public var preampGain: Float = 0.0 // dB (-12 to +12)
    @Published public var spectrumMagnitudes: [Float] = Array(repeating: 0.0, count: 20)
    
    // MARK: - Built-in Studio Media Player
    @Published public var currentTrack: AudioTrack
    @Published public var isPlaying: Bool = false
    @Published public var currentTime: TimeInterval = 0.0
    @Published public var duration: TimeInterval = 0.0
    @Published public var isLooping: Bool = true
    @Published public var effects: AudioEffectSettings = AudioEffectSettings()
    
    // MARK: - Sheet & Alert Presentation Flags
    @Published public var errorMessage: String? = nil
    @Published public var showErrorAlert: Bool = false
    @Published public var isFilePickerPresented: Bool = false
    @Published public var isPresetsSheetPresented: Bool = false
    @Published public var isEffectsSheetPresented: Bool = false
    @Published public var isSystemSettingsPresented: Bool = false
    
    // MARK: - Engines & Managers
    private let audioEngine: AudioEngineManager
    private let micEngine: LiveInputMonitorEngine
    private let wiredMonitor: WiredHeadphoneMonitor
    private let presetStore: PresetStore
    private let audiogramManager: SystemAudiogramManager
    private let systemController: AVSystemControllerBridge
    private let trollStoreEnv: TrollStoreEnvironment
    private let mediaServerdIPC: MediaServerdIPC
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        audioEngine: AudioEngineManager = AudioEngineManager(),
        micEngine: LiveInputMonitorEngine = LiveInputMonitorEngine(),
        wiredMonitor: WiredHeadphoneMonitor = WiredHeadphoneMonitor.shared,
        presetStore: PresetStore = PresetStore()
    ) {
        self.audioEngine = audioEngine
        self.micEngine = micEngine
        self.wiredMonitor = wiredMonitor
        self.presetStore = presetStore
        self.audiogramManager = SystemAudiogramManager.shared
        self.systemController = AVSystemControllerBridge.shared
        self.trollStoreEnv = TrollStoreEnvironment.shared
        self.mediaServerdIPC = MediaServerdIPC.shared
        
        self.bands = EQBand.defaultBands
        self.activePreset = .flat
        self.systemPresets = EQPreset.systemPresets
        self.customPresets = presetStore.loadCustomPresets()
        self.currentTrack = .placeholder
        
        setupEngineCallbacks()
        setupWiredMonitorSubscriptions()
        refreshSystemStatus()
        loadInitialDemoAudio()
    }
    
    // MARK: - Wired Headphone Subscriptions
    private func setupWiredMonitorSubscriptions() {
        wiredMonitor.$isWiredHeadsetConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected in
                guard let self = self else { return }
                self.isWiredHeadsetConnected = connected
                if !connected {
                    if self.isPlaying {
                        self.pause()
                        self.systemStatusMessage = "Wired headphones disconnected. Playback paused."
                    }
                    if self.isMicMonitoring {
                        self.micEngine.stopMonitoring()
                        self.isMicMonitoring = false
                        self.systemStatusMessage = "Wired headphones disconnected. Mic monitor stopped."
                    }
                }
            }
            .store(in: &cancellables)
        
        wiredMonitor.$connectedPortName
            .receive(on: DispatchQueue.main)
            .assign(to: &$connectedPortName)
        
        wiredMonitor.$portTypeDescription
            .receive(on: DispatchQueue.main)
            .assign(to: &$portTypeDescription)
        
        wiredMonitor.$sampleRate
            .receive(on: DispatchQueue.main)
            .assign(to: &$wiredSampleRate)
        
        wiredMonitor.$channelCount
            .receive(on: DispatchQueue.main)
            .assign(to: &$wiredChannelCount)
        
        wiredMonitor.$hardwareFormatDescription
            .receive(on: DispatchQueue.main)
            .assign(to: &$hardwareFormatText)
    }
    
    // MARK: - System Audio Status Refresh
    public func refreshSystemStatus() {
        trollStoreEnv.refresh()
        wiredMonitor.refresh()
        self.environmentName = trollStoreEnv.environment.rawValue
        self.isUnsandboxed = trollStoreEnv.isUnsandboxed
        self.isWiredHeadsetConnected = wiredMonitor.isWiredHeadsetConnected
        self.connectedPortName = wiredMonitor.connectedPortName
        self.portTypeDescription = wiredMonitor.portTypeDescription
        self.wiredSampleRate = wiredMonitor.sampleRate
        self.wiredChannelCount = wiredMonitor.channelCount
        self.hardwareFormatText = wiredMonitor.hardwareFormatDescription
        self.activeAudioRoute = wiredMonitor.isWiredHeadsetConnected ? wiredMonitor.connectedPortName : systemController.getActiveAudioRoute()
        self.isSystemEQActive = audiogramManager.isHeadphoneAccommodationsEnabled()
    }
    
    // MARK: - Wired Headphone System-Wide EQ Operations
    
    /// Applies 10-band curve as a 7-band Audiogram targeting Wired Headphones exclusively.
    public func applyToWiredOutput(restartDaemons: Bool = true) {
        let gains = bands.map { $0.gain }
        
        // 1. Inject Audiogram into iOS Headphone Accommodations targeting wired headphones
        let audiogramSuccess = audiogramManager.applyCustomAudiogramEQ(bandGains: gains, restartDaemons: restartDaemons)
        
        // 2. Sync with mediaserverd tweak / hook IPC
        let ipcSuccess = mediaServerdIPC.syncSettings(
            bands: gains,
            preamp: preampGain,
            isBypassed: isEQBypassed,
            limiterEnabled: true
        )
        
        if audiogramSuccess || ipcSuccess {
            isSystemEQActive = true
            systemStatusMessage = restartDaemons
                ? "Wired EQ synced & audio daemons (mediaserverd & heard) restarted!"
                : "Wired EQ curve synced to CFPreferences (tap Restart Audio to apply)."
        } else {
            systemStatusMessage = "Could not write system preferences. Ensure TrollStore or Jailbreak is active."
        }
    }
    
    /// Alias for backwards compatibility
    public func applySystemWideEQ(restartDaemons: Bool = false) {
        applyToWiredOutput(restartDaemons: restartDaemons)
    }
    
    public func disableSystemWideEQ() {
        audiogramManager.setHeadphoneAccommodationsEnabled(false, restartDaemons: true)
        mediaServerdIPC.syncSettings(
            bands: bands.map { _ in 0.0 },
            preamp: 0.0,
            isBypassed: true,
            limiterEnabled: false
        )
        isSystemEQActive = false
        systemStatusMessage = "Wired Headphone EQ bypassed."
    }
    
    /// Resets Wired Headphone EQ and audiograms back to default un-equalized iOS state.
    public func resetWiredEQToStock() {
        audiogramManager.resetWiredEQToStock()
        isSystemEQActive = false
        resetToFlat()
        systemStatusMessage = "Wired headphone audio & audiograms successfully reset to stock iOS default."
    }
    
    /// Alias for backwards compatibility
    public func resetSystemAudioToDefault() {
        resetWiredEQToStock()
    }
    
    public func disableHeadphoneSafetyLimit() {
        let success = systemController.disableHeadphoneVolumeLimit()
        isHeadphoneLimitDisabled = success
        systemStatusMessage = success ? "EU 85dB wired headphone cap removed." : "Unable to override limit."
    }
    
    public func restartAudioEngine() {
        let _ = trollStoreEnv.restartAudioEngine()
        systemStatusMessage = "Audio daemons (mediaserverd & heard) restarted."
        refreshSystemStatus()
    }
    
    public func respring() {
        systemStatusMessage = "Respringing device..."
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.trollStoreEnv.respring()
        }
    }
    
    // MARK: - Live Microphone Monitoring
    public func toggleMicMonitoring() {
        if isMicMonitoring {
            micEngine.stopMonitoring()
            isMicMonitoring = false
        } else {
            do {
                if isPlaying { pause() }
                try micEngine.startMonitoring()
                isMicMonitoring = true
            } catch {
                errorMessage = "Microphone error: \(error.localizedDescription)"
                showErrorAlert = true
            }
        }
    }
    
    public func setMicGain(_ gain: Float) {
        micGain = gain
        micEngine.micGain = gain
    }
    
    public func setVoicePitch(cents: Float) {
        voicePitchCents = cents
        micEngine.setVoicePitch(cents: cents)
    }
    
    public func toggleNoiseGate() {
        isNoiseGateEnabled.toggle()
        micEngine.isNoiseGateEnabled = isNoiseGateEnabled
    }
    
    // MARK: - Engine Callbacks
    private func setupEngineCallbacks() {
        audioEngine.onMagnitudesUpdated = { [weak self] magnitudes in
            guard let self = self, self.audioMode == .mediaPlayer else { return }
            self.spectrumMagnitudes = magnitudes
        }
        
        audioEngine.onPlaybackProgress = { [weak self] current, total in
            self?.currentTime = current
            self?.duration = total
        }
        
        audioEngine.onPlaybackEnded = { [weak self] in
            self?.isPlaying = false
        }
        
        micEngine.onMicMagnitudesUpdated = { [weak self] magnitudes in
            guard let self = self, self.audioMode == .microphoneDSP else { return }
            self.spectrumMagnitudes = magnitudes
        }
    }
    
    private func loadInitialDemoAudio() {
        loadDemoTone(.synthChord)
    }
    
    // MARK: - Equalizer Band Operations
    public func setBandGain(index: Int, gain: Float) {
        guard index >= 0 && index < bands.count else { return }
        bands[index].gain = max(-12.0, min(12.0, gain))
        
        // Update audio engine
        audioEngine.setBandGain(index: index, gain: bands[index].gain, bypass: bands[index].bypass)
        
        // Update mic engine if in mic mode
        micEngine.setMicBandGain(index: index, gain: bands[index].gain)
        
        // Auto-sync if system-wide EQ is currently active
        if isSystemEQActive && audioMode == .systemWide {
            applyToWiredOutput(restartDaemons: false)
        }
        
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
        if isSystemEQActive {
            if isEQBypassed {
                disableSystemWideEQ()
            } else {
                applyToWiredOutput(restartDaemons: true)
            }
        }
    }
    
    public func setPreampGain(_ gain: Float) {
        preampGain = max(-12.0, min(12.0, gain))
        let linearMultiplier = pow(10.0, preampGain / 20.0)
        effects.masterVolume = min(1.0, linearMultiplier)
        audioEngine.updateEffects(effects)
        
        if isSystemEQActive {
            applyToWiredOutput(restartDaemons: false)
        }
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
                micEngine.setMicBandGain(index: i, gain: gain)
            }
        }
        audioEngine.setAllBandGains(preset.gains)
        
        if isSystemEQActive {
            applyToWiredOutput(restartDaemons: false)
        }
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
    
    // MARK: - Transport Controls
    public func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    public func play() {
        if isMicMonitoring {
            micEngine.stopMonitoring()
            isMicMonitoring = false
        }
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
    
    public func updateEffects() {
        audioEngine.updateEffects(effects)
    }
    
    public func loadAudioFile(url: URL) {
        do {
            let info = try audioEngine.loadAudioFile(url: url)
            currentTrack = AudioTrack(
                title: info.title,
                artist: "Imported Audio",
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
