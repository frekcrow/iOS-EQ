import XCTest
import AVFoundation
@testable import EqualizerEngine

final class EqualizerAppTests: XCTestCase {

    // MARK: - EQBand Tests
    func testDefault10BandsConfiguration() {
        let bands = EQBand.defaultBands
        XCTAssertEqual(bands.count, 10, "Default graphic equalizer must contain exactly 10 bands")
        
        // Test first band is Low Shelf
        XCTAssertEqual(bands.first?.filterType, .lowShelf)
        XCTAssertEqual(bands.first?.frequency, 32.0)
        
        // Test middle bands are Parametric
        XCTAssertEqual(bands[4].filterType, .parametric)
        XCTAssertEqual(bands[4].frequency, 500.0)
        
        // Test last band is High Shelf
        XCTAssertEqual(bands.last?.filterType, .highShelf)
        XCTAssertEqual(bands.last?.frequency, 16000.0)
        
        // Initial gains should all be flat (0.0 dB)
        for band in bands {
            XCTAssertEqual(band.gain, 0.0, accuracy: 0.001)
            XCTAssertFalse(band.bypass)
        }
    }
    
    func testFrequencyFormatting() {
        let band32 = EQBand(index: 0, frequency: 32.0)
        XCTAssertEqual(band32.frequencyFormatted, "32")
        
        let band1k = EQBand(index: 5, frequency: 1000.0)
        XCTAssertEqual(band1k.frequencyFormatted, "1k")
        
        let band16k = EQBand(index: 9, frequency: 16000.0)
        XCTAssertEqual(band16k.frequencyFormatted, "16k")
    }
    
    func testGainFormatting() {
        var band = EQBand(index: 0, frequency: 1000.0)
        
        band.gain = 4.5
        XCTAssertEqual(band.gainFormatted, "+4.5 dB")
        
        band.gain = 0.0
        XCTAssertEqual(band.gainFormatted, "0.0 dB")
        
        band.gain = -3.2
        XCTAssertEqual(band.gainFormatted, "-3.2 dB")
    }

    // MARK: - EQPreset Tests
    func testSystemPresetsExist() {
        let presets = EQPreset.systemPresets
        XCTAssertGreaterThanOrEqual(presets.count, 10)
        
        let flat = presets.first { $0.name == "Flat" }
        XCTAssertNotNil(flat)
        XCTAssertEqual(flat?.gains, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        
        let rock = presets.first { $0.name == "Rock" }
        XCTAssertNotNil(rock)
        XCTAssertEqual(rock?.gains.count, 10)
    }
    
    func testPresetEncodingDecoding() throws {
        let original = EQPreset(
            name: "My Custom Curve",
            iconName: "slider.vertical.3",
            gains: [2, 4, 3, 1, 0, -1, 2, 4, 5, 3],
            isSystem: false,
            category: .custom
        )
        
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(EQPreset.self, data)
        
        XCTAssertEqual(original.name, decoded.name)
        XCTAssertEqual(original.gains, decoded.gains)
        XCTAssertEqual(original.category, decoded.category)
    }

    // MARK: - AudioTrack Formatting Tests
    func testTimeFormatting() {
        XCTAssertEqual(AudioTrack.formatTime(0.0), "0:00")
        XCTAssertEqual(AudioTrack.formatTime(45.0), "0:45")
        XCTAssertEqual(AudioTrack.formatTime(65.0), "1:05")
        XCTAssertEqual(AudioTrack.formatTime(215.0), "3:35")
        XCTAssertEqual(AudioTrack.formatTime(3600.0), "60:00")
        XCTAssertEqual(AudioTrack.formatTime(-5.0), "0:00")
    }

    // MARK: - AudioToneGenerator Tests
    func testSynthesizedBufferGeneration() {
        for type in DemoSoundType.allCases {
            let buffer = AudioToneGenerator.generateBuffer(type: type, duration: 1.0, sampleRate: 44100.0)
            XCTAssertNotNil(buffer, "Tone generator should produce a valid buffer for \(type.rawValue)")
            XCTAssertEqual(buffer?.format.channelCount, 2, "Buffer should be stereo")
            XCTAssertEqual(buffer?.format.sampleRate, 44100.0)
            XCTAssertEqual(buffer?.frameLength, 44100)
            XCTAssertNotNil(buffer?.floatChannelData?[0])
            XCTAssertNotNil(buffer?.floatChannelData?[1])
        }
    }

    // MARK: - System Audiogram Tests
    func testAudiogramFrequencyMapping() {
        let freqs = SystemAudiogramManager.audiogramFrequencies
        XCTAssertEqual(freqs.count, 7)
        XCTAssertEqual(freqs, [125, 250, 500, 1000, 2000, 4000, 8000])
    }

    // MARK: - TrollStore Environment Tests
    func testTrollStoreEnvironmentDetection() {
        let env = TrollStoreEnvironment.shared
        XCTAssertNotNil(env.environment)
    }
}
