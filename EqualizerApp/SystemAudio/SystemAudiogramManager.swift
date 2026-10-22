import Foundation
import CoreFoundation

/// Controls system-wide Headphone Accommodations and Audiogram EQ curves on iOS 14.0 - 15.x.
/// Applies frequency curves system-wide across all apps (Spotify, Apple Music, YouTube, Phone Calls)
/// for AirPods, EarPods, and supported headphones using CFPreferences and unsandboxed TrollStore/jailbreak access.
public final class SystemAudiogramManager {
    public static let shared = SystemAudiogramManager()
    
    private let hearingAidsDomain = "com.apple.HearingAids" as CFString
    private let accessibilityDomain = "com.apple.Accessibility" as CFString
    
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
    
    // MARK: - Query Status
    
    /// Reads whether system Headphone Accommodations is currently enabled.
    public func isHeadphoneAccommodationsEnabled() -> Bool {
        // First check CFPreferences cache
        if let val = CFPreferencesCopyAppValue("HearingAidsAccommodationsEnabled" as CFString, hearingAidsDomain) {
            if let boolVal = val as? Bool {
                return boolVal
            }
        }
        // Fallback to disk read
        guard let dict = NSDictionary(contentsOfFile: preferencesPath) as? [String: Any] else {
            return false
        }
        return (dict["HearingAidsAccommodationsEnabled"] as? Bool) ?? false
    }
    
    // MARK: - CFPreferences Write Helper
    
    private func setPreference(key: String, value: Any?, domain: CFString) {
        let cfKey = key as CFString
        let cfValue = value as CFPropertyList?
        
        // 1. Write for current user
        CFPreferencesSetValue(cfKey, cfValue, domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        CFPreferencesSynchronize(domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        
        // 2. Also write explicitly for "mobile" user (daemons like heard read from mobile)
        let mobileUser = "mobile" as CFString
        CFPreferencesSetValue(cfKey, cfValue, domain, mobileUser, kCFPreferencesAnyHost)
        CFPreferencesSynchronize(domain, mobileUser, kCFPreferencesAnyHost)
    }
    
    // MARK: - Apply System Audiogram EQ
    
    /// Converts a 10-band EQ curve into an Apple 7-band Audiogram profile and injects it system-wide.
    @discardableResult
    public func applyCustomAudiogramEQ(bandGains: [Float], restartDaemons: Bool = false) -> Bool {
        // Map 10-band fader gains to 7 standard audiogram test frequencies:
        // [125, 250, 500, 1000, 2000, 4000, 8000]
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
        
        let audiogramDict: [String: Any] = [
            "Frequencies": Self.audiogramFrequencies.map { Double($0) },
            "LeftEarLoss": lossValues,
            "RightEarLoss": lossValues,
            "DateCreated": Date().timeIntervalSince1970,
            "ProfileName": "Equalizer Pro System Profile"
        ]
        
        // 1. Write via CFPreferences (targeting both current user and 'mobile')
        setPreference(key: "HearingAidsAccommodationsEnabled", value: true, domain: hearingAidsDomain)
        setPreference(key: "HearingAidsAccommodationsAppliesToPhone", value: true, domain: hearingAidsDomain)
        setPreference(key: "HearingAidsAccommodationsAppliesToMedia", value: true, domain: hearingAidsDomain)
        setPreference(key: "HearingAidsAccommodationsTuning", value: TuningType.customAudiogram.rawValue, domain: hearingAidsDomain)
        setPreference(key: "HearingAidsCustomAudiogram", value: audiogramDict, domain: hearingAidsDomain)
        
        // Also mirror in Accessibility domain
        setPreference(key: "AXHeadphoneAccommodationsEnabled", value: true, domain: accessibilityDomain)
        setPreference(key: "AXHeadphoneAccommodationsCustomAudiogram", value: audiogramDict, domain: accessibilityDomain)
        
        // 2. Write direct to disk plists as backup
        var hearingDict = (NSDictionary(contentsOfFile: preferencesPath) as? [String: Any]) ?? [:]
        hearingDict["HearingAidsAccommodationsEnabled"] = true
        hearingDict["HearingAidsAccommodationsAppliesToPhone"] = true
        hearingDict["HearingAidsAccommodationsAppliesToMedia"] = true
        hearingDict["HearingAidsAccommodationsTuning"] = TuningType.customAudiogram.rawValue
        hearingDict["HearingAidsCustomAudiogram"] = audiogramDict
        (hearingDict as NSDictionary).write(toFile: preferencesPath, atomically: true)
        
        var accessDict = (NSDictionary(contentsOfFile: accessibilityPath) as? [String: Any]) ?? [:]
        accessDict["AXHeadphoneAccommodationsEnabled"] = true
        accessDict["AXHeadphoneAccommodationsCustomAudiogram"] = audiogramDict
        (accessDict as NSDictionary).write(toFile: accessibilityPath, atomically: true)
        
        // 3. Post Darwin notifications
        postSettingsChangedNotification()
        
        // 4. Optionally restart audio daemons immediately
        if restartDaemons {
            TrollStoreEnvironment.shared.restartAudioEngine()
        }
        
        return true
    }
    
    // MARK: - Enable / Disable Accommodations
    
    @discardableResult
    public func setHeadphoneAccommodationsEnabled(_ enabled: Bool, restartDaemons: Bool = false) -> Bool {
        setPreference(key: "HearingAidsAccommodationsEnabled", value: enabled, domain: hearingAidsDomain)
        setPreference(key: "HearingAidsAccommodationsAppliesToPhone", value: enabled, domain: hearingAidsDomain)
        setPreference(key: "HearingAidsAccommodationsAppliesToMedia", value: enabled, domain: hearingAidsDomain)
        setPreference(key: "AXHeadphoneAccommodationsEnabled", value: enabled, domain: accessibilityDomain)
        
        var dict = (NSDictionary(contentsOfFile: preferencesPath) as? [String: Any]) ?? [:]
        dict["HearingAidsAccommodationsEnabled"] = enabled
        (dict as NSDictionary).write(toFile: preferencesPath, atomically: true)
        
        postSettingsChangedNotification()
        
        if restartDaemons {
            TrollStoreEnvironment.shared.restartAudioEngine()
        }
        return true
    }
    
    // MARK: - Reset to Stock Default
    
    /// Resets all system audio accommodations and audiograms back to default un-equalized iOS state.
    @discardableResult
    public func resetToDefaultSystemAudio() -> Bool {
        // Clear HearingAids preferences
        setPreference(key: "HearingAidsAccommodationsEnabled", value: false, domain: hearingAidsDomain)
        setPreference(key: "HearingAidsCustomAudiogram", value: nil, domain: hearingAidsDomain)
        setPreference(key: "HearingAidsAccommodationsTuning", value: nil, domain: hearingAidsDomain)
        setPreference(key: "HearingAidsAccommodationsStrength", value: nil, domain: hearingAidsDomain)
        
        // Clear Accessibility preferences
        setPreference(key: "AXHeadphoneAccommodationsEnabled", value: false, domain: accessibilityDomain)
        setPreference(key: "AXHeadphoneAccommodationsCustomAudiogram", value: nil, domain: accessibilityDomain)
        
        // Clear disk plists
        if var hearingDict = NSDictionary(contentsOfFile: preferencesPath) as? [String: Any] {
            hearingDict.removeValue(forKey: "HearingAidsAccommodationsEnabled")
            hearingDict.removeValue(forKey: "HearingAidsCustomAudiogram")
            hearingDict.removeValue(forKey: "HearingAidsAccommodationsTuning")
            hearingDict.removeValue(forKey: "HearingAidsAccommodationsStrength")
            (hearingDict as NSDictionary).write(toFile: preferencesPath, atomically: true)
        }
        
        if var accessDict = NSDictionary(contentsOfFile: accessibilityPath) as? [String: Any] {
            accessDict.removeValue(forKey: "AXHeadphoneAccommodationsEnabled")
            accessDict.removeValue(forKey: "AXHeadphoneAccommodationsCustomAudiogram")
            (accessDict as NSDictionary).write(toFile: accessibilityPath, atomically: true)
        }
        
        // Reset MediaServerd IPC shared configuration
        MediaServerdIPC.shared.syncSettings(
            bands: [Float](repeating: 0.0, count: 10),
            preamp: 0.0,
            isBypassed: true,
            limiterEnabled: false
        )
        
        postSettingsChangedNotification()
        
        // Restart daemons so stock sound is restored immediately
        TrollStoreEnvironment.shared.restartAudioEngine()
        return true
    }
    
    /// Broadcasts Darwin notifications to trigger immediate system daemon reload.
    public func postSettingsChangedNotification() {
        let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
        let names = [
            "com.apple.HearingAids.SettingsChanged",
            "com.apple.accessibility.heard.settings-changed",
            "com.apple.Accessibility.PreferenceChanged"
        ]
        
        for name in names {
            CFNotificationCenterPostNotification(
                notificationCenter,
                CFNotificationName(name as CFString),
                nil,
                nil,
                true
            )
        }
    }
}
