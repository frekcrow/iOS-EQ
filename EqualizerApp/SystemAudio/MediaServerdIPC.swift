import Foundation

/// Inter-Process Communication (IPC) manager for interacting with mediaserverd tweaks
/// (such as EQE, AudioServerPlugIn, or custom system audio hooks) on jailbroken iOS 14.0-15.x.
public final class MediaServerdIPC {
    public static let shared = MediaServerdIPC()
    
    private let sharedConfigPath = "/var/mobile/Library/Preferences/com.equalizer.systemeq.json"
    private let eqeSocketPath = "/var/run/eqe.sock"
    
    private init() {}
    
    /// Checks if a system audio hook or daemon (e.g., EQE or AudioServerPlugIn) is active.
    public func isDaemonActive() -> Bool {
        return FileManager.default.fileExists(atPath: eqeSocketPath)
    }
    
    /// Syncs current 10-band equalizer settings to system shared preferences JSON.
    @discardableResult
    public func syncSettings(
        bands: [Float],
        preamp: Float,
        isBypassed: Bool,
        limiterEnabled: Bool
    ) -> Bool {
        let payload: [String: Any] = [
            "version": 1,
            "bypassed": isBypassed,
            "preamp_db": preamp,
            "limiter_enabled": limiterEnabled,
            "bands": bands,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
            try data.write(to: URL(fileURLWithPath: sharedConfigPath))
            
            // Post Darwin notification for hook to re-read settings
            let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
            let name = CFNotificationName("com.equalizer.systemeq.reload" as CFString)
            CFNotificationCenterPostNotification(notificationCenter, name, nil, nil, true)
            
            // Also attempt UNIX domain socket push if socket exists
            if isDaemonActive() {
                sendSocketCommand("set_bands \(bands.map { String($0) }.joined(separator: " "))")
            }
            
            return true
        } catch {
            print("[MediaServerdIPC] Failed to write shared settings: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Sends a low-level command through UNIX domain socket to EQE/mediaserverd hook.
    @discardableResult
    private func sendSocketCommand(_ command: String) -> Bool {
        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { return false }
        defer { close(fd) }
        
        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        
        let pathBytes = eqeSocketPath.utf8CString
        let maxPathLen = MemoryLayout.size(ofValue: addr.sun_path)
        guard pathBytes.count <= maxPathLen else { return false }
        
        withUnsafeMutableBytes(of: &addr.sun_path) { rawBuffer in
            if let baseAddress = rawBuffer.baseAddress?.assumingMemoryBound(to: CChar.self) {
                eqeSocketPath.withCString { cstr in
                    strncpy(baseAddress, cstr, maxPathLen)
                }
            }
        }
        
        let addrLen = socklen_t(MemoryLayout<sockaddr_un>.size)
        let connectResult = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                connect(fd, sa, addrLen)
            }
        }
        
        guard connectResult == 0 else { return false }
        
        let message = command + "\n"
        let bytesWritten = message.withCString { cstr in
            write(fd, cstr, strlen(cstr))
        }
        return bytesWritten > 0
    }
}
