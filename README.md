# Equalizer Pro (iOS 14.0 - 15.x)
### System-Wide Audio DSP & Equalizer Exclusively for Wired Headphones & DACs (TrollStore & Jailbreak)

**Equalizer Pro** is an unsandboxed, studio-grade 10-band graphic equalizer, digital signal processor (DSP), and hardware audio controller designed specifically for **TrollStore** and **jailbroken iOS devices (iOS 14.0 - 15.x)** (Dopamine, unc0ver, Taurine, palera1n).

This edition is **strictly and exclusively dedicated to Wired Headphones of all types**:
- **3.5mm Aux Headphones** (built-in 3.5mm jacks or Lightning-to-3.5mm dongles)
- **Apple Lightning EarPods / Headphones**
- **USB-C Digital Headphones** (e.g., Apple USB-C EarPods)
- **External USB DACs & Headphone Amplifiers** (via Apple Camera Adapter or USB-C, e.g., AudioQuest DragonFly, FiiO, Schiit, iFi, Apple USB-C Dongle)

Unlike standard App Store audio players, Equalizer Pro leverages **unsandboxed entitlements** (`com.apple.private.security.no-sandbox`) and private system frameworks (`Celestial.framework`) to manipulate audio at the **system level**, modify **wired headphone output across all apps**, lock audio strictly to wired routes (preventing audio leakage to built-in speaker or Bluetooth), and process **live hardware microphone input**.

---

## ⚡ Core Capabilities

### 1. 🌐 Wired System-Wide Equalizer (All Apps & System Audio)
- **System EQ via Apple Headphone Accommodations & Audiograms**:
  - Automatically translates your 10-band fader curve into a native 7-band **Audiogram loss profile** targeting the wired `"Headphones"` route and injects it into `/var/mobile/Library/Preferences/com.apple.HearingAids.plist` and `com.apple.Accessibility.plist`.
  - Works **system-wide across all apps**: **Spotify, Apple Music, YouTube, Safari, Netflix, Tidal, games, and phone calls**!
  - Targets **Wired Headphones only** — leaving the internal speaker completely untouched.
  - No respring required — triggers instant daemon reload via Darwin notifications (`com.apple.HearingAids.SettingsChanged`).

- **Wired Headphone Detection & Route Locking (`WiredHeadphoneMonitor`)**:
  - Automatically listens to `AVAudioSession.routeChangeNotification` and locks output to `.headphones` and `.usbAudio`.
  - Removed all `.allowBluetooth`, `.allowBluetoothA2DP`, and `.defaultToSpeaker` session options so audio never accidentally redirects to Bluetooth or blasts through the built-in speaker.
  - Real-time status banner in UI displaying connection state, detected port type, and hardware sample rate (e.g. 48.0 kHz • Stereo).
  - Automatically pauses playback or mic monitoring if wired headphones are unplugged.

- **`mediaserverd` IPC Hook Integration (EQE / AudioServerPlugIn compatible)**:
  - If a tweak or daemon is injected into `mediaserverd`, Equalizer Pro syncs in real-time via `/var/mobile/Library/Preferences/com.equalizer.systemeq.json` and UNIX domain socket (`/var/run/eqe.sock`).
  - Includes privileged `posix_spawn` / `sysctl` command to cleanly restart `mediaserverd` and `heard`.

- **Bypass EU 85dB Wired Headphone Volume Cap**:
  - Dynamically interfaces with `AVSystemController` to lift hardware headphone safety limits on the `"Headphones"` category, unlocking 100% full volume power.

### 2. 🎙 Live Hardware Microphone & Voice DSP Processor
- **Low-Latency Input-to-Output Pass-Through**:
  - Captures wired headset mic or device mic and streams processed audio directly to wired headphones with ultra-low buffer latency (~5.8ms).
  - Immediate auto-shutoff if wired headphones are unplugged to prevent acoustic feedback screaming.
- **Noise Gate**:
  - Intelligent RMS threshold muting to eliminate background hum, fan noise, or hiss.
- **Hardware Mic Gain / Preamp**:
  - Boost weak microphone signals by up to +10 dB (3.0x).
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
       (Locked to Wired Route: "Headphones")            │
                               │                        ▼
               ┌───────────────▼──────────────┐  [AVAudioEngine]
               │  /var/mobile/Preferences/    │  Mic In ──► HighPass ──► Mic EQ
               │  com.apple.HearingAids.plist │  ──► Pitch ──► Gate ──► Out
               │  com.equalizer.systemeq.json │         │
               └───────────────┬──────────────┘         │
                               │                        │
               ┌───────────────▼──────────────┐         │
               │   System Daemons & Audio     │         │
               │   (heard / mediaserverd)     │         │
               └───────────────┬──────────────┘         │
                               │                        │
               ┌───────────────▼────────────────────────▼──────────────┐
               │      Hardware Output: 3.5mm Aux / Lightning / USB-C    │
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
│   │   ├── SystemAudiogramManager.swift    # Headphone Accommodations & Audiogram injector (Wired)
│   │   ├── AVSystemControllerBridge.swift # Private Celestial.framework dynamic bridge (Headphones)
│   │   └── MediaServerdIPC.swift           # IPC hook for mediaserverd & EQE
│   ├── AudioEngine/
│   │   ├── WiredHeadphoneMonitor.swift     # Route detection & locking for .headphones / .usbAudio
│   │   ├── AudioEngineManager.swift        # Primary AVAudioEngine playback pipeline
│   │   ├── LiveInputMonitorEngine.swift    # Low-latency Mic & Voice DSP engine
│   │   ├── FFTAnalyzer.swift               # Accelerate vDSP FFT spectrum analyzer
│   │   └── AudioToneGenerator.swift        # Built-in PCM demo synthesizer
│   ├── ViewModels/
│   │   └── EqualizerViewModel.swift        # State manager for Wired System, Mic & Player modes
│   ├── Views/
│   │   ├── MainView.swift                  # Multi-mode studio UI with Wired Status Banner
│   │   ├── DocumentPicker.swift            # iOS file importer
│   │   └── Components/
│   │       ├── SpectrumVisualizerView.swift# 20-band neon audio visualizer
│   │       ├── VerticalSliderView.swift    # Tactile fader knobs with 0 dB snap
│   │       ├── EqualizerBandsView.swift    # 10 faders + live spline curve
│   │       ├── SystemAudioSheetView.swift  # Wired System EQ, daemons & route settings sheet
│   │       ├── MicControlBarView.swift     # Live mic & voice pitch control bar
│   │       ├── PlayerControlBarView.swift  # Media scrubber & transport buttons
│   │       ├── PresetSelectorView.swift    # Factory & custom presets sheet
│   │       └── EffectsRackView.swift       # Reverb, Delay, Distortion & Pan DSP
│   ├── Models/                             # EQBand, EQPreset, AudioTrack, Effects
│   ├── Storage/PresetStore.swift           # Custom presets persistence
│   └── Assets.xcassets/                    # Asset catalogs
├── EqualizerAppTests/                      # Automated unit test suite (with Wired tests)
├── build_trollstore.sh                     # Packaging script for .tipa (TrollStore)
├── Package.swift                           # SwiftPM package manifest (.iOS(.v15))
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
2. The deployment target is set to **iOS 15.0** (compatible with iOS 14.0+).
3. Select any connected device or simulator.
4. Build and archive or export `.ipa`, then install via TrollStore.
