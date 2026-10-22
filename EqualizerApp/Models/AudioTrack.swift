import Foundation

/// Represents an audio track loaded into the equalizer.
public struct AudioTrack: Identifiable, Equatable {
    public let id: UUID
    public var title: String
    public var artist: String
    public var album: String
    public var duration: TimeInterval
    public var fileURL: URL?
    public var isGeneratedTone: Bool
    public var formatDescription: String
    
    public init(
        id: UUID = UUID(),
        title: String,
        artist: String = "Unknown Artist",
        album: String = "Unknown Album",
        duration: TimeInterval = 0.0,
        fileURL: URL? = nil,
        isGeneratedTone: Bool = false,
        formatDescription: String = "Stereo 44.1 kHz"
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.fileURL = fileURL
        self.isGeneratedTone = isGeneratedTone
        self.formatDescription = formatDescription
    }
    
    /// Formatted duration string (mm:ss).
    public var formattedDuration: String {
        Self.formatTime(duration)
    }
    
    public static func formatTime(_ time: TimeInterval) -> String {
        guard !time.isNaN && !time.isInfinite && time >= 0 else { return "0:00" }
        let totalSeconds = Int(time.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Default empty placeholder track
    public static let placeholder = AudioTrack(
        title: "No Audio Selected",
        artist: "Import an audio file or start demo tone",
        album: "Equalizer Studio",
        duration: 0.0,
        fileURL: nil,
        isGeneratedTone: false,
        formatDescription: "-- kHz • --"
    )
}
