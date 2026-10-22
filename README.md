# Equalizer Pro (iOS 14.0 - 15.x)
### System-Wide Audio DSP & Equalizer for TrollStore & Jailbroken Devices

**Equalizer Pro** is an unsandboxed, studio-grade 10-band graphic equalizer, digital signal processor (DSP), and hardware audio controller designed specifically for **TrollStore** and **jailbroken iOS devices (iOS 14.0 - 15.x)** (Dopamine, unc0ver, Taurine, palera1n).

Unlike standard App Store audio players, Equalizer Pro leverages **unsandboxed entitlements** (`com.apple.private.security.no-sandbox`) and private system frameworks (`Celestial.framework`) to manipulate audio at the **system level**, modify **AirPods and headphone output across all apps**, and process **live hardware microphone input**.

---

## ⚡ Core Capabilities for TrollStore & Jailbreak

### 1. 🌐 System-Wide Equalizer (All Apps & System Audio)
- **AirPods & Headphone System EQ via Apple Headphone Accommodations**:
  - Automatically translates your 10-band fader curve into a native 7-band **Audiogram loss profile** and injects it into `/var/mobile/Library/Preferences/com.apple.HearingAids.plist`.
  - Works **system-wide across all apps**: **Spotify, Apple Music, YouTube, Safari, Netflix, games, and phone calls**!
  - Fully compatible with **AirPods 2, AirPods 3, AirPods Pro, AirPods Max**, and Beats headphones.
  - No respring required — triggers instant daemon reload via Darwin notifications (`com.apple.HearingAids.SettingsChanged`).

- **`mediaserverd` IPC Hook Integration (EQE / AudioServerPlugIn compatible)**:
  - If a tweak or daemon is injected into `mediaserverd`, Equalizer Pro syncs in real-time via `/var/mobile/Library/Preferences/com.equalizer.systemeq.json` and UNIX domain socket (`/var/run/eqe.sock`).
  - Includes privileged `posix_spawn` command to cleanly restart `mediaserverd` when needed.

- **Bypass EU 85dB Headphone Volume Cap**:
  - Dynamically interfaces with `AVSystemController` to lift hardware headphone safety limits, unlocking 100% full volume power.

### 2. 🎙 Live Hardware Microphone & Voice DSP Processor
- **Low-Latency Input-to-Output Pass-Through**:
  - Captures device microphone or AirPods headset mic and streams processed audio directly to headphones with ultra-low buffer latency (~5.8ms).
- **Noise Gate**:
  - Intelligent RMS threshold muting to eliminate room background hum, PC fan noise, or hiss.
- **Hardware Mic Gain / Preamp**:
  - Boost weak microphone signals by up to +10 dB.
- **Microphone 10-Band Parametric EQ**:
  - Tailor voice presence, boost vocal warmth (250 Hz), add air/clarity (4 kHz - 8 kHz), and cut low-frequency rumble (high-pass at 32 Hz).
- **Live Voice Pitch Shifter**:
  - Shift voice pitch in real-time from -12 to +12 semitones (voice changer / pitch correction).

### 3. 🎧 Studio Media Player & Audio Lab
- Built-in `AVAudioEngine` player supporting imported audio files (`MP3`, `M4A`, `WAV`, `AIFF`, `FLAC`, `AAC`).
- 4 built-in synthesized demo audio generators (*Harmonic Synth Pad*, *Pink Noise EQ Reference*, *Drum Beat Loop*, *Frequency Sweep*).
- Real-time **vDSP FFT 20-band neon spectrum visualizer** with logarithmic frequency distribution.
- DSP rack: **Reverb, Stereo Echo / Delay, Analog Distortion, and Stereo Panning**.

---

## 🎛 System Architecture & Signal Chain

```
               ┌────────────────────────────────────────────────────────┐
               │             Equalizer Pro (Unsandboxed)                │
               │   com.apple.private.security.no-sandbox = true         │
               └───────────────┬────────────────────────┬───────────────┘
                               │                        │
       [System Audio Hook / Audiogram]        [Live Hardware Mic DSP]
                               │                        │
               ┌───────────────▼──────────────┐         │
               │  /var/mobile/Preferences/    │         ▼
               │  com.apple.HearingAids.plist │  [AVAudioEngine]
               │  com.equalizer.systemeq.json │  Mic In ──► HighPass ──► Mic EQ
               └───────────────┬──────────────┘         ──► Pitch ──► Gate ──► Out
                               │                        │
               ┌───────────────▼──────────────┐         │
               │   System Daemons & Audio     │         │
               │   (heard / mediaserverd)     │         │
               └───────────────┬──────────────┘         │
                               │                        │
               ┌───────────────▼────────────────────────▼──────────────┐
               │         Hardware Output: AirPods / Headphones          │
               │    System-Wide Frequency Response Altered in Real Time  │
               └────────────────────────────────────────────────────────┘
```

---

## 📁 Repository Structure

```
ios-eq/
├── EqualizerApp.xcodeproj/
│   ├── project.pbxproj                     # Xcode project configured for iOS 14.0+
│   └── xcshareddata/xcschemes/
│       └── EqualizerApp.xcscheme           # Xcode build & test scheme
├── EqualizerApp/
│   ├── App/
│   │   ├── EqualizerApp.swift              # SwiftUI entry point
│   │   ├── Info.plist                      # Background audio & mic permissions
│   │   └── EqualizerApp.entitlements       # TrollStore unsandboxed entitlements
│   ├── SystemAudio/                        # TrollStore & Jailbreak System Control
│   │   ├── TrollStoreEnvironment.swift    # Privilege & jailbreak environment detector
│   │   ├── SystemAudiogramManager.swift    # Headphone Accommodations & Audiogram injector
│   │   ├── AVSystemControllerBridge.swift # Private Celestial.framework dynamic bridge
│   │   └── MediaServerdIPC.swift           # IPC hook for mediaserverd & EQE
│   ├── AudioEngine/
│   │   ├── AudioEngineManager.swift        # Primary AVAudioEngine playback pipeline
│   │   ├── LiveInputMonitorEngine.swift    # Low-latency Mic & Voice DSP engine
│   │   ├── FFTAnalyzer.swift               # Accelerate vDSP FFT spectrum analyzer
│   │   └── AudioToneGenerator.swift        # Built-in PCM demo synthesizer
│   ├── ViewModels/
│   │   └── EqualizerViewModel.swift        # State manager for System, Mic & Player modes
│   ├── Views/
│   │   ├── MainView.swift                  # Multi-mode studio UI (iOS 14 & 15 compatible)
│   │   ├── DocumentPicker.swift            # iOS file importer
│   │   └── Components/
│   │       ├── SpectrumVisualizerView.swift# 20-band neon audio visualizer
│   │       ├── VerticalSliderView.swift    # Tactile fader knobs with 0 dB snap
│   │       ├── EqualizerBandsView.swift    # 10 faders + live spline curve
│   │       ├── SystemAudioSheetView.swift  # System EQ & route settings sheet
│   │       ├── MicControlBarView.swift     # Live mic & voice pitch control bar
│   │       ├── PlayerControlBarView.swift  # Media scrubber & transport buttons
│   │       ├── PresetSelectorView.swift    # Factory & custom presets sheet
│   │       └── EffectsRackView.swift       # Reverb, Delay, Distortion & Pan DSP
│   ├── Models/                             # EQBand, EQPreset, AudioTrack, Effects
│   ├── Storage/PresetStore.swift           # Custom presets persistence
│   └── Assets.xcassets/                    # Asset catalogs
├── EqualizerAppTests/                      # Automated unit test suite
├── build_trollstore.sh                     # Packaging script for .tipa (TrollStore)
├── Package.swift                           # SwiftPM package manifest (.iOS(.v14))
└── README.md
```

---

## 📦 Building & Installing on TrollStore (iOS 14.0 - 15.x)

### Option 1: Packaging as `.tipa` via script
Run the included build script:
```bash
./build_trollstore.sh
```
This generates `output/EqualizerPro.tipa` signed with the unsandboxed entitlements. You can then:
1. AirDrop or transfer `EqualizerPro.tipa` to your iOS device.
2. Open with **TrollStore** to install.

### Option 2: Building with Xcode
1. Open **`EqualizerApp.xcodeproj`** in Xcode.
2. The deployment target is set to **iOS 14.0**.
3. Select any connected device or simulator.
4. Build and archive or export `.ipa`, then install via TrollStore.
