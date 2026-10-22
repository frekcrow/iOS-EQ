import Foundation

/// Manages persistence of custom equalizer presets in UserDefaults.
public final class PresetStore {
    private let userDefaultsKey = "com.equalizer.customPresets"
    private let userDefaults: UserDefaults
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    /// Loads custom presets saved by the user.
    public func loadCustomPresets() -> [EQPreset] {
        guard let data = userDefaults.data(forKey: userDefaultsKey) else {
            return []
        }
        do {
            let presets = try JSONDecoder().decode([EQPreset].self, data)
            return presets
        } catch {
            print("[PresetStore] Error decoding presets: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Saves custom presets to UserDefaults.
    public func saveCustomPresets(_ presets: [EQPreset]) {
        do {
            let data = try JSONEncoder().encode(presets)
            userDefaults.set(data, forKey: userDefaultsKey)
        } catch {
            print("[PresetStore] Error encoding presets: \(error.localizedDescription)")
        }
    }
    
    /// Appends a new custom preset.
    public func addPreset(_ preset: EQPreset) -> [EQPreset] {
        var presets = loadCustomPresets()
        presets.append(preset)
        saveCustomPresets(presets)
        return presets
    }
    
    /// Deletes a custom preset by ID.
    public func deletePreset(id: UUID) -> [EQPreset] {
        var presets = loadCustomPresets()
        presets.removeAll { $0.id == id }
        saveCustomPresets(presets)
        return presets
    }
}
