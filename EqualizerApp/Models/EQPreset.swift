import Foundation

/// Categories for organizing equalizer presets.
public enum PresetCategory: String, Codable, CaseIterable {
    case general = "General"
    case genre = "Music Genre"
    case enhancement = "Enhancement"
    case custom = "Custom"
}

/// Represents an equalizer preset configuration with gains for all bands.
public struct EQPreset: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var iconName: String
    public var gains: [Float] // 10 gain values in dB matching 32Hz -> 16kHz
    public var isSystem: Bool
    public var category: PresetCategory
    
    public init(
        id: UUID = UUID(),
        name: String,
        iconName: String = "slider.vertical.3",
        gains: [Float],
        isSystem: Bool = false,
        category: PresetCategory = .general
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.gains = gains
        self.isSystem = isSystem
        self.category = category
    }
    
    // MARK: - Factory Presets
    public static let flat = EQPreset(
        name: "Flat",
        iconName: "waveform.path",
        gains: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        isSystem: true,
        category: .general
    )
    
    public static let bassBooster = EQPreset(
        name: "Bass Booster",
        iconName: "speaker.wave.3.fill",
        gains: [6.0, 5.5, 4.0, 2.5, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0],
        isSystem: true,
        category: .enhancement
    )
    
    public static let bassReducer = EQPreset(
        name: "Bass Reducer",
        iconName: "speaker.wave.1.fill",
        gains: [-6.0, -5.0, -3.5, -2.0, -1.0, 0.0, 0.0, 0.0, 0.0, 0.0],
        isSystem: true,
        category: .enhancement
    )
    
    public static let vocalBooster = EQPreset(
        name: "Vocal Booster",
        iconName: "mic.fill",
        gains: [-2.0, -1.0, 0.0, 1.5, 3.5, 4.0, 3.0, 1.5, 0.0, -1.0],
        isSystem: true,
        category: .enhancement
    )
    
    public static let trebleBooster = EQPreset(
        name: "Treble Booster",
        iconName: "bell.fill",
        gains: [0.0, 0.0, 0.0, 0.0, 0.5, 1.5, 3.0, 4.5, 6.0, 6.5],
        isSystem: true,
        category: .enhancement
    )
    
    public static let rock = EQPreset(
        name: "Rock",
        iconName: "guitars.fill",
        gains: [4.5, 3.5, 2.0, 0.0, -1.0, -0.5, 1.5, 2.5, 3.5, 4.5],
        isSystem: true,
        category: .genre
    )
    
    public static let pop = EQPreset(
        name: "Pop",
        iconName: "music.mic",
        gains: [-1.5, 1.0, 3.0, 4.0, 3.0, 0.0, -1.0, -1.0, 1.5, 2.5],
        isSystem: true,
        category: .genre
    )
    
    public static let jazz = EQPreset(
        name: "Jazz",
        iconName: "music.quarternote.3",
        gains: [3.5, 2.5, 0.0, 1.5, -1.5, -1.0, 0.0, 1.5, 2.5, 3.5],
        isSystem: true,
        category: .genre
    )
    
    public static let electronic = EQPreset(
        name: "Electronic",
        iconName: "sparkles",
        gains: [5.5, 4.5, 1.5, 0.0, -2.0, 1.5, 2.0, 3.0, 4.5, 4.0],
        isSystem: true,
        category: .genre
    )
    
    public static let classical = EQPreset(
        name: "Classical",
        iconName: "theatermasks.fill",
        gains: [4.0, 3.0, 2.0, 1.0, -1.0, -1.0, 0.0, 1.5, 2.5, 3.0],
        isSystem: true,
        category: .genre
    )
    
    public static let hipHop = EQPreset(
        name: "Hip-Hop",
        iconName: "headphones",
        gains: [6.0, 5.0, 2.5, 1.0, -1.0, 0.0, 1.5, 1.0, 2.0, 3.0],
        isSystem: true,
        category: .genre
    )
    
    public static let acoustic = EQPreset(
        name: "Acoustic",
        iconName: "music.note",
        gains: [3.0, 2.5, 1.5, 1.0, 2.0, 2.0, 2.5, 3.0, 2.0, 1.5],
        isSystem: true,
        category: .genre
    )
    
    public static let podcast = EQPreset(
        name: "Podcast / Speech",
        iconName: "waveform.and.mic",
        gains: [-3.0, -2.0, -1.0, 1.0, 3.0, 3.5, 2.0, 0.0, -1.5, -3.0],
        isSystem: true,
        category: .enhancement
    )
    
    public static let club = EQPreset(
        name: "Club / Loudness",
        iconName: "speaker.wave.3",
        gains: [5.0, 4.0, 2.0, 0.0, -1.0, -1.0, 0.0, 2.0, 3.5, 5.0],
        isSystem: true,
        category: .genre
    )

    /// Full list of factory presets.
    public static let systemPresets: [EQPreset] = [
        .flat,
        .bassBooster,
        .bassReducer,
        .vocalBooster,
        .trebleBooster,
        .rock,
        .pop,
        .jazz,
        .electronic,
        .classical,
        .hipHop,
        .acoustic,
        .podcast,
        .club
    ]
}
