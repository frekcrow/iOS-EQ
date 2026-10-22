import Foundation
import AVFoundation

/// Factory reverb presets.
public enum ReverbPresetOption: Int, CaseIterable, Identifiable {
    case smallRoom = 0
    case mediumRoom = 1
    case largeRoom = 2
    case mediumHall = 3
    case largeHall = 4
    case plate = 5
    case cathedral = 6
    
    public var id: Int { rawValue }
    
    public var avPreset: AVAudioUnitReverbPreset {
        switch self {
        case .smallRoom: return .smallRoom
        case .mediumRoom: return .mediumRoom
        case .largeRoom: return .largeRoom
        case .mediumHall: return .mediumHall
        case .largeHall: return .largeHall
        case .plate: return .plate
        case .cathedral: return .cathedral
        }
    }
    
    public var displayName: String {
        switch self {
        case .smallRoom: return "Small Room"
        case .mediumRoom: return "Medium Room"
        case .largeRoom: return "Large Room"
        case .mediumHall: return "Medium Hall"
        case .largeHall: return "Large Hall"
        case .plate: return "Plate"
        case .cathedral: return "Cathedral"
        }
    }
}

/// Factory distortion presets.
public enum DistortionPresetOption: Int, CaseIterable, Identifiable {
    case drumsLoFi = 0
    case multiBrokenSpeaker = 1
    case speechRadio = 2
    case electricGuitar = 3
    case multiEcho1 = 4
    
    public var id: Int { rawValue }
    
    public var avPreset: AVAudioUnitDistortionPreset {
        switch self {
        case .drumsLoFi: return .drumsLoFi
        case .multiBrokenSpeaker: return .multiBrokenSpeaker
        case .speechRadioTower: return .speechRadioTower
        case .electricGuitar: return .multiEchoTight1
        case .multiEcho1: return .multiEcho2
        }
    }
    
    public var displayName: String {
        switch self {
        case .drumsLoFi: return "Lo-Fi Drums"
        case .multiBrokenSpeaker: return "Broken Speaker"
        case .speechRadioTower: return "Vintage Radio"
        case .electricGuitar: return "Warm Overdrive"
        case .multiEcho1: return "Echo Chamber"
        }
    }
}

/// Represents the audio processor rack settings.
public struct AudioEffectSettings: Equatable {
    // Reverb
    public var isReverbEnabled: Bool = false
    public var reverbPreset: ReverbPresetOption = .mediumRoom
    public var reverbWetDryMix: Float = 30.0 // 0 to 100%
    
    // Delay / Echo
    public var isDelayEnabled: Bool = false
    public var delayTime: Float = 0.25 // seconds (0.01 to 2.0)
    public var delayFeedback: Float = 35.0 // percent (-100 to 100)
    public var delayLowPassCutoff: Float = 15000.0 // Hz
    public var delayWetDryMix: Float = 25.0 // 0 to 100%
    
    // Pitch & Tempo
    public var isPitchEnabled: Bool = false
    public var pitchCents: Float = 0.0 // -2400 to +2400 cents (-2 to +2 octaves)
    public var playbackRate: Float = 1.0 // 0.5 to 2.0x
    
    // Distortion
    public var isDistortionEnabled: Bool = false
    public var distortionPreset: DistortionPresetOption = .drumsLoFi
    public var distortionWetDryMix: Float = 20.0 // 0 to 100%
    
    // Master Output & Balance
    public var masterVolume: Float = 1.0 // 0.0 to 1.0
    public var panBalance: Float = 0.0 // -1.0 (Left) to +1.0 (Right)
    public var preampGain: Float = 0.0 // -12.0 to +12.0 dB
    
    public init() {}
}
