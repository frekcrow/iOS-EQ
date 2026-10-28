import Foundation
import AVFoundation
import Combine

/// Dedicated Hardware Monitor for Wired Audio Outputs.
/// Detects and route-locks strictly to:
/// 1. Standard 3.5mm Aux / Lightning-to-3.5mm dongles / Lightning EarPods (.headphones)
/// 2. USB-C digital headphones / Lightning USB adapters / External USB DACs (.usbAudio)
public final class WiredHeadphoneMonitor: ObservableObject {
    public static let shared = WiredHeadphoneMonitor()
    
    // MARK: - Published Properties
    @Published public private(set) var isWiredHeadsetConnected: Bool = false
    @Published public private(set) var connectedPortName: String = "No Wired Headphones"
    @Published public private(set) var portTypeDescription: String = "Disconnected"
    @Published public private(set) var sampleRate: Double = 44100.0
    @Published public private(set) var channelCount: Int = 2
    @Published public private(set) var hardwareFormatDescription: String = "-- kHz • --"
    
    // Callback for ViewModels or AudioEngines when wired route changes
    public var onWiredRouteChanged: ((Bool, String) -> Void)?
    
    // For unit testing / simulation
    private var isSimulated: Bool = false
    
    public init() {
        setupRouteObserver()
        refresh()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Route Monitoring
    private func setupRouteObserver() {
        #if os(iOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        #endif
    }
    
    #if os(iOS)
    @objc private func handleAudioRouteChange(notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.refresh()
        }
    }
    #endif
    
    /// Queries the current audio session outputs and updates state for wired headphones.
    public func refresh() {
        if isSimulated { return }
        
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        let outputs = session.currentRoute.outputs
        
        var foundWired = false
        var detectedName = "No Wired Headphones"
        var detectedType = "Disconnected"
        
        for output in outputs {
            switch output.portType {
            case .headphones:
                // 3.5mm Aux, Lightning-to-3.5mm dongle, or native Lightning headphones
                foundWired = true
                detectedName = output.portName.isEmpty ? "Lightning / 3.5mm Headphones" : output.portName
                detectedType = "Lightning / 3.5mm Aux"
                break
                
            case .usbAudio:
                // USB-C digital headphones, Apple USB-C dongle, external USB DAC
                foundWired = true
                detectedName = output.portName.isEmpty ? "USB-C Audio / DAC" : output.portName
                detectedType = "USB-C Digital / DAC"
                break
                
            default:
                break
            }
            if foundWired { break }
        }
        
        let currentRate = session.sampleRate > 0 ? session.sampleRate : 48000.0
        let currentChannels = session.outputNumberOfChannels > 0 ? session.outputNumberOfChannels : 2
        
        let rateKhz = String(format: "%.1f kHz", currentRate / 1000.0)
        let chText = currentChannels == 2 ? "Stereo" : (currentChannels == 1 ? "Mono" : "\(currentChannels)ch")
        let formatText = "\(rateKhz) • \(chText)"
        
        let previousStatus = self.isWiredHeadsetConnected
        
        self.isWiredHeadsetConnected = foundWired
        self.connectedPortName = detectedName
        self.portTypeDescription = detectedType
        self.sampleRate = currentRate
        self.channelCount = currentChannels
        self.hardwareFormatDescription = foundWired ? formatText : "-- kHz • Disconnected"
        
        if previousStatus != foundWired {
            self.onWiredRouteChanged?(foundWired, detectedName)
        }
        #else
        // macOS / Simulator Fallback
        self.isWiredHeadsetConnected = false
        self.connectedPortName = "No Wired Headphones"
        self.portTypeDescription = "Disconnected"
        self.sampleRate = 48000.0
        self.channelCount = 2
        self.hardwareFormatDescription = "-- kHz • Disconnected"
        #endif
    }
    
    // MARK: - Testing & Simulation Support
    public func simulateWiredConnection(isConnected: Bool, portName: String, portType: String, sampleRate: Double = 48000.0, channels: Int = 2) {
        self.isSimulated = true
        self.isWiredHeadsetConnected = isConnected
        self.connectedPortName = portName
        self.portTypeDescription = portType
        self.sampleRate = sampleRate
        self.channelCount = channels
        
        let rateKhz = String(format: "%.1f kHz", sampleRate / 1000.0)
        let chText = channels == 2 ? "Stereo" : "\(channels)ch"
        self.hardwareFormatDescription = isConnected ? "\(rateKhz) • \(chText)" : "-- kHz • Disconnected"
        
        self.onWiredRouteChanged?(isConnected, portName)
    }
    
    public func resetSimulation() {
        self.isSimulated = false
        refresh()
    }
}
