import Foundation
import AVFoundation

/// The filter type for an individual equalizer band.
public enum EQFilterType: String, Codable, CaseIterable {
    case lowShelf
    case parametric
    case highShelf
    
    public var avFilterType: AVAudioUnitEQFilterType {
        switch self {
        case .lowShelf:
            return .lowShelf
        case .parametric:
            return .parametric
        case .highShelf:
            return .highShelf
        }
    }
    
    public var displayName: String {
        switch self {
        case .lowShelf:
            return "Low Shelf"
        case .parametric:
            return "Parametric"
        case .highShelf:
            return "High Shelf"
        }
    }
}

/// Represents a single frequency band in the graphic equalizer.
public struct EQBand: Identifiable, Codable, Equatable {
    public let id: UUID
    public let index: Int
    public let frequency: Float      // Center frequency in Hertz (Hz)
    public var gain: Float           // Gain in decibels (dB), typical range: -12.0 to +12.0 dB
    public var bandwidth: Float      // Bandwidth in octaves (e.g., 1.0 octave)
    public var filterType: EQFilterType
    public var bypass: Bool
    
    public init(
        id: UUID = UUID(),
        index: Int,
        frequency: Float,
        gain: Float = 0.0,
        bandwidth: Float = 1.0,
        filterType: EQFilterType = .parametric,
        bypass: Bool = false
    ) {
        self.id = id
        self.index = index
        self.frequency = frequency
        self.gain = gain
        self.bandwidth = bandwidth
        self.filterType = filterType
        self.bypass = bypass
    }
    
    /// User-friendly formatted frequency label (e.g., "32 Hz", "1 kHz", "16 kHz").
    public var frequencyFormatted: String {
        if frequency >= 1000 {
            let khz = frequency / 1000.0
            return khz.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0fk", khz)
                : String(format: "%.1fk", khz)
        } else {
            return String(format: "%.0f", frequency)
        }
    }
    
    /// User-friendly formatted gain string (e.g., "+3.2 dB", "0.0 dB", "-4.5 dB").
    public var gainFormatted: String {
        if gain > 0 {
            return String(format: "+%.1f dB", gain)
        } else {
            return String(format: "%.1f dB", gain)
        }
    }
    
    /// Default standard 10-band ISO graphic equalizer frequencies.
    public static let standardFrequencies: [Float] = [
        32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000
    ]
    
    /// Factory standard 10-band flat setup.
    public static var defaultBands: [EQBand] {
        return standardFrequencies.enumerated().map { index, freq in
            let filterType: EQFilterType
            if index == 0 {
                filterType = .lowShelf
            } else if index == standardFrequencies.count - 1 {
                filterType = .highShelf
            } else {
                filterType = .parametric
            }
            return EQBand(
                index: index,
                frequency: freq,
                gain: 0.0,
                bandwidth: 1.0,
                filterType: filterType,
                bypass: false
            )
        }
    }
}
