import Foundation

/// Controls system-wide Headphone Accommodations and Audiogram EQ curves on iOS 14.0 - 15.x.
/// Applies frequency curves system-wide across all apps (Spotify, Apple Music, YouTube, Phone Calls)
/// for AirPods, EarPods, and supported headphones using unsandboxed TrollStore/jailbreak access.
public final class SystemAudiogramManager {
    public static let shared = SystemAudiogramManager()
    
    private let preferencesPath = "/var/mobile/Library/Preferences/com.apple.HearingAids.plist"
    private let accessibilityPath = "/var/mobile/Library/Preferences/com.apple.Accessibility.plist"
    
    // Standard audiogram frequency test points supported natively by iOS 14/15
    public static let audiogramFrequencies: [Float] = [125, 250, 500, 1000, 2000, 4000, 8000]
    
    public enum TuningType: Int, CaseIterable, Identifiable {
        case balanced = 1
        case vocalRange = 2
        case brightness = 3
        case customAudiogram = 4
        
        public var id: Int { rawValue }
        
        public var title: String {
            switch self {
            case .balanced: return "Balanced Tone"
            case .vocalRange: return "Vocal Range"
            case .brightness: return "Brightness Boost"
            case .customAudiogram: return "Custom 7-Band Audiogram"
            }
        }
    }
    
    public enum BoostStrength: Int, CaseIterable, Identifiable {
        case slight = 1
        case moderate = 2
        case strong = 3
        
        public var id: Int { rawValue }
        
        public var title: String {
            switch self {
            case .slight: return "Slight (+3 dB)"
            case .moderate: return "Moderate (+6 dB)"
            case .strong: return "Strong (+9 dB)"
            }
        }
    }
    
    private init() {}
    
    /// Reads whether system Headphone Accommodations is currently enabled.
    public func isHeadphoneAccommodationsEnabled() -> Bool {
        guard let dict = NSDictionary(contentsOfFile: preferencesPath) as? [String: Any] else {
            return false
        }
        return (dict["HearingAidsAccommodationsEnabled"] as? Bool) ?? false
    }
    
    /// Enables or disables system-wide Headphone Accommodations.
    @discardableResult
    public func setHeadphoneAccommodationsEnabled(_ enabled: Bool) -> Bool {
        var dict = (NSDictionary(contentsOfFile: preferencesPath) as? [String: Any]) ?? [:]
        dict["HearingAidsAccommodationsEnabled"] = enabled
        dict["HearingAidsAccommodationsAppliesToPhone"] = true
        dict["HearingAidsAccommodationsAppliesToMedia"] = true
        
        let success = (dict as NSDictionary).write(toFile: preferencesPath, atomically: true)
        postSettingsChangedNotification()
        return success
    }
    
    /// Applies tuning mode and strength system-wide.
    @discardableResult
    public func applySystemTuning(tuning: TuningType, strength: BoostStrength) -> Bool {
        var dict = (NSDictionary(contentsOfFile: preferencesPath) as? [String: Any]) ?? [:]
        
        dict["HearingAidsAccommodationsEnabled"] = true
        dict["HearingAidsAccommodationsAppliesToPhone"] = true
        dict["HearingAidsAccommodationsAppliesToMedia"] = true
        dict["HearingAidsAccommodationsTuning"] = tuning.rawValue
        dict["HearingAidsAccommodationsStrength"] = strength.rawValue
        
        let success = (dict as NSDictionary).write(toFile: preferencesPath, atomically: true)
        postSettingsChangedNotification()
        return success
    }
    
    /// Converts a 10-band EQ curve into an Apple 7-band Audiogram profile and injects it system-wide.
    @discardableResult
    public func applyCustomAudiogramEQ(bandGains: [Float]) -> Bool {
        // Map 10-band fader gains to 7 standard audiogram test frequencies:
        // [125, 250, 500, 1000, 2000, 4000, 8000]
        // Standard baseline hearing is ~15 dB HL. A loss of +25 dB HL triggers iOS to boost that frequency!
        var audiogramGains: [Float] = []
        if bandGains.count >= 10 {
            audiogramGains = [
                bandGains[2], // 125 Hz
                bandGains[3], // 250 Hz
                bandGains[4], // 500 Hz
                bandGains[5], // 1000 Hz
                bandGains[6], // 2000 Hz
                bandGains[7], // 4000 Hz
                bandGains[8]  // 8000 Hz
            ]
        } else {
            audiogramGains = [Float](repeating: 0.0, count: 7)
        }
        
        // Invert EQ gains to Audiogram Hearing Loss values:
        // +12 dB gain -> 45 dB HL (strong compensation boost by system)
        // 0 dB gain -> 15 dB HL (normal hearing, flat)
        // -12 dB gain -> 0 dB HL (no boost / cut)
        var lossValues: [Double] = []
        for gain in audiogramGains {
            let baseline: Double = 15.0
            let compensation = Double(gain) * 2.5
            let calculatedLoss = max(0.0, min(80.0, baseline + compensation))
            lossValues.append(calculatedLoss)
        }
        
        var dict = (NSDictionary(contentsOfFile: preferencesPath) as? [String: Any]) ?? [:]
        dict["HearingAidsAccommodationsEnabled"] = true
        dict["HearingAidsAccommodationsAppliesToPhone"] = true
        dict["HearingAidsAccommodationsAppliesToMedia"] = true
        dict["HearingAidsAccommodationsTuning"] = TuningType.customAudiogram.rawValue
        
        // Inject Custom Audiogram Dictionary structure expected by iOS 14 / 15
        let audiogramDict: [String: Any] = [
            "Frequencies": Self.audiogramFrequencies.map { Double($0) },
            "LeftEarLoss": lossValues,
            "RightEarLoss": lossValues,
            "DateCreated": Date().timeIntervalSince1970,
            "ProfileName": "Equalizer Pro System Profile"
        ]
        dict["HearingAidsCustomAudiogram"] = audiogramDict
        
        let success = (dict as NSDictionary).write(toFile: preferencesPath, atomically: true)
        postSettingsChangedNotification()
        return success
    }
    
    /// Broadcasts Darwin notifications to trigger immediate system daemon reload.
    private func postSettingsChangedNotification() {
        let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
        let name1 = CFNotificationName("com.apple.HearingAids.SettingsChanged" as CFString)
        let name2 = CFNotificationName("com.apple.accessibility.heard.settings-changed" as CFString)
        
        CFNotificationCenterPostNotification(notificationCenter, name1, nil, nil, true)
        CFNotificationCenterPostNotification(notificationCenter, name2, nil, nil, true)
    }
}
