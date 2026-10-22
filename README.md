# Equalizer Pro (iOS)

A studio-grade 10-band graphic equalizer and digital signal processor (DSP) app built natively for iOS with **Swift**, **SwiftUI**, and **AVFoundation**.

---

## 🎧 Highlights & Features

- **10-Band Graphic Equalizer**:
  - ISO Standard frequencies: **32 Hz, 64 Hz, 125 Hz, 250 Hz, 500 Hz, 1 kHz, 2 kHz, 4 kHz, 8 kHz, 16 kHz**.
  - High-precision tactile hardware faders with -12.0 dB to +12.0 dB range.
  - Zero-center detent snapping and double-tap to reset.
  - Interactive smooth spline curve visualization displaying the exact frequency response.
  - Per-band bypass switches and Master EQ bypass switch.
  - Preamp input trim slider (-12 dB to +12 dB).

- **Real-Time FFT Spectrum Visualizer**:
  - Accelerated Fast Fourier Transform (vDSP) processing using Apple's **Accelerate framework**.
  - Dynamic glowing 20-band neon spectrum bars with logarithmic frequency spacing.
  - Calibrated decibel reference grid (-36 dB, -18 dB, -6 dB, 0 dB) and smooth falloff decay.

- **Audio Engine & DSP Rack (`AVAudioEngine`)**:
  - **Reverb Unit**: Factory room models (Small Room, Medium Room, Large Room, Medium Hall, Large Hall, Plate, Cathedral) with wet/dry balance.
  - **Stereo Delay / Echo**: Delay time (0.05s to 1.0s), feedback control, and wet/dry mix.
  - **Pitch Shifter & Speed**: Pitch shift (-12 to +12 semitones) and variable playback rate (0.5x to 2.0x).
  - **Distortion / Overdrive**: Analog character options (Warm Overdrive, Lo-Fi Drums, Broken Speaker, Vintage Radio, Echo Chamber).
  - **Stereo Pan & Master Output**: Left/Right balance control and master output volume.

- **Preset Engine**:
  - 14 built-in factory presets (Flat, Bass Booster, Bass Reducer, Vocal Booster, Treble Booster, Rock, Pop, Jazz, Electronic, Classical, Hip-Hop, Acoustic, Podcast, Club).
  - Full custom preset creation, editing, and deletion with persistent storage via `UserDefaults`.
  - Graphical mini-curve badges for each preset in the selector sheet.

- **Audio File Importer & Built-in Demo Synthesizer**:
  - Import any audio file directly from Files, iCloud Drive, or local storage (`MP3`, `M4A`, `WAV`, `AIFF`, `FLAC`, `AAC`).
  - Integrated zero-file-needed PCM sound generator for immediate testing:
    - *Harmonic Synth Pad* (lush multi-harmonic organ pad)
    - *Pink Noise EQ Reference* (Paul Kellet's algorithm: 3dB/octave slope)
    - *Rhythmic Beat Loop* (synthesized drum machine pattern)
    - *Logarithmic Frequency Sweep* (30 Hz to 16 kHz sweep)
  - Full transport controls: Scrub bar, elapsed & remaining time, Play/Pause, Stop, and Loop toggle.

---

## 🏗 Audio Signal Processing Chain

```
[Audio File / PCM Synth]
          │
          ▼
  [AVAudioPlayerNode]
          │
          ▼
   [AVAudioUnitEQ]  (10-Band Graphic Equalizer)
          │
          ▼
[AVAudioUnitTimePitch] (Pitch Shifter & Speed)
          │
          ▼
[AVAudioUnitDistortion] (Saturation & Overdrive)
          │
          ▼
  [AVAudioUnitDelay] (Stereo Echo & Feedback)
          │
          ▼
 [AVAudioUnitReverb] (Room & Hall Ambience)
          │
          ▼
   [Main Mixer Node] ──► [vDSP FFT Real-Time Tap] ──► [Spectrum Visualizer View]
          │
          ▼
     [Output Node] (Headphones / Speakers / AirPlay)
```

---

## 📁 Project Directory Structure

```
ios-eq/
├── EqualizerApp.xcodeproj/
│   ├── project.pbxproj                     # Standard Xcode project file
│   └── xcshareddata/xcschemes/
│       └── EqualizerApp.xcscheme           # Xcode scheme (build, test, run)
├── EqualizerApp/
│   ├── App/
│   │   ├── EqualizerApp.swift              # App entry point (@main)
│   │   └── Info.plist                      # Background audio and app permissions
│   ├── Models/
│   │   ├── EQBand.swift                    # Frequency band data model
│   │   ├── EQPreset.swift                  # Presets & factory configurations
│   │   ├── AudioTrack.swift                # Track metadata & time helpers
│   │   └── AudioEffectSettings.swift       # Reverb, Delay, Pitch, Distortion models
│   ├── AudioEngine/
│   │   ├── AudioEngineManager.swift        # AVAudioEngine graph & transport
│   │   ├── FFTAnalyzer.swift               # Accelerate vDSP FFT processor
│   │   └── AudioToneGenerator.swift        # Real-time PCM audio synthesizer
│   ├── ViewModels/
│   │   └── EqualizerViewModel.swift        # ObservableObject state manager
│   ├── Views/
│   │   ├── MainView.swift                  # Studio root view
│   │   ├── DocumentPicker.swift            # iOS file importer
│   │   └── Components/
│   │       ├── SpectrumVisualizerView.swift# Neon real-time spectrum visualizer
│   │       ├── VerticalSliderView.swift    # Tactile hardware slider fader
│   │       ├── EqualizerBandsView.swift    # 10 faders + response curve view
│   │       ├── PlayerControlBarView.swift  # Scrubber & transport buttons
│   │       ├── PresetSelectorView.swift    # Preset browser & saver
│   │       └── EffectsRackView.swift       # DSP studio rack
│   ├── Storage/
│   │   └── PresetStore.swift               # Custom preset persistence
│   ├── Assets.xcassets/                    # Icons and accent color catalog
│   └── Preview Content/                    # SwiftUI previews catalog
├── EqualizerAppTests/
│   └── EqualizerAppTests.swift             # Unit tests for bands, presets & synthesis
├── Package.swift                           # Swift Package Manager manifest
├── .gitignore                              # Standard iOS git exclusions
└── README.md                               # Project documentation
```

---

## 🚀 How to Build and Run

### Requirements
- **macOS** 12.0 or later
- **Xcode** 14.0 or later
- **iOS Deployment Target**: iOS 15.0+ (supports iOS 15, 16, 17, and 18)
- **Supported Devices**: iPhone & iPad

### Steps
1. Clone or copy the `ios-eq` folder to your Mac.
2. Double-click **`EqualizerApp.xcodeproj`** to open the project in Xcode.
3. Select your target device or simulator (e.g. *iPhone 15 Pro* or *iPad Pro*).
4. Press **`Cmd + R`** (or click the **Play** button) to build and run.
5. Select a built-in demo sound (*Harmonic Synth Pad* is preloaded) or tap the folder icon to import your favorite MP3/WAV/FLAC track!

### Running Unit Tests
- Press **`Cmd + U`** in Xcode to run all automated unit tests in `EqualizerAppTests`.
- Or run `swift test` from the terminal.
