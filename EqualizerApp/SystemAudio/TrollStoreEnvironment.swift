import Foundation

/// Detection and privileged execution utilities for TrollStore and jailbroken iOS 14.0-15.x environments.
public final class TrollStoreEnvironment {
    public static let shared = TrollStoreEnvironment()
    
    public enum EnvironmentType: String {
        case trollStore = "TrollStore (Unsandboxed)"
        case jailbrokenRootless = "Jailbroken (Rootless)"
        case jailbrokenRootful = "Jailbroken (Rootful)"
        case jailed = "Standard Sandbox (Restricted)"
    }
    
    public private(set) var environment: EnvironmentType = .jailed
    public private(set) var isUnsandboxed: Bool = false
    public private(set) var canWriteSystemPreferences: Bool = false
    
    private init() {
        checkEnvironment()
    }
    
    public func refresh() {
        checkEnvironment()
    }
    
    private func checkEnvironment() {
        // 1. Test Unsandboxed access by reading /var/mobile
        let testPath = "/var/mobile/Library/Preferences"
        let fileManager = FileManager.default
        let canRead = fileManager.isReadableFile(atPath: testPath)
        
        let writeTestFile = "/var/mobile/Library/Preferences/.eq_test_write"
        var canWrite = false
        if let testData = "test".data(using: .utf8) {
            canWrite = fileManager.createFile(atPath: writeTestFile, contents: testData)
            try? fileManager.removeItem(atPath: writeTestFile)
        }
        
        self.isUnsandboxed = canRead
        self.canWriteSystemPreferences = canWrite
        
        // 2. Check for Jailbreak paths (Dopamine, unc0ver, Taurine, palera1n)
        let rootlessJBPaths = [
            "/var/jb/usr/bin",
            "/var/jb/Library/MobileSubstrate",
            "/var/jb/basebin"
        ]
        let rootfulJBPaths = [
            "/usr/lib/libsubstitute.dylib",
            "/Library/MobileSubstrate",
            "/usr/bin/sileo",
            "/Applications/Cydia.app"
        ]
        
        var isRootless = false
        for path in rootlessJBPaths {
            if fileManager.fileExists(atPath: path) {
                isRootless = true
                break
            }
        }
        
        var isRootful = false
        for path in rootfulJBPaths {
            if fileManager.fileExists(atPath: path) {
                isRootful = true
                break
            }
        }
        
        if isRootless {
            environment = .jailbrokenRootless
        } else if isRootful {
            environment = .jailbrokenRootful
        } else if canWrite || canRead {
            environment = .trollStore
        } else {
            environment = .jailed
        }
    }
    
    /// Spawns a process with posix_spawn for root actions (e.g. restarting audio daemon).
    @discardableResult
    public func executePrivilegedCommand(executable: String, arguments: [String]) -> (exitCode: Int32, output: String) {
        var pid: pid_t = 0
        var pipeFD: [Int32] = [0, 0]
        pipe(&pipeFD)
        
        var fileActions: posix_spawn_file_actions_t?
        posix_spawn_file_actions_init(&fileActions)
        posix_spawn_file_actions_adddup2(&fileActions, pipeFD[1], STDOUT_FILENO)
        posix_spawn_file_actions_adddup2(&fileActions, pipeFD[1], STDERR_FILENO)
        posix_spawn_file_actions_addclose(&fileActions, pipeFD[0])
        
        let args = [executable] + arguments
        let cArgs = args.map { strdup($0) } + [nil]
        
        defer {
            for ptr in cArgs where ptr != nil {
                free(ptr)
            }
            posix_spawn_file_actions_destroy(&fileActions)
        }
        
        let env: [UnsafeMutablePointer<CChar>?] = [
            strdup("PATH=/var/jb/usr/bin:/var/jb/bin:/usr/bin:/bin:/usr/sbin:/sbin"),
            nil
        ]
        defer {
            for ptr in env where ptr != nil {
                free(ptr)
            }
        }
        
        let status = posix_spawnp(&pid, executable, &fileActions, nil, cArgs, env)
        close(pipeFD[1])
        
        var output = ""
        if status == 0 {
            let handle = FileHandle(fileDescriptor: pipeFD[0])
            let data = handle.readDataToEndOfFile()
            output = String(data: data, encoding: .utf8) ?? ""
            
            var exitStatus: Int32 = 0
            waitpid(pid, &exitStatus, 0)
            return (exitStatus, output)
        } else {
            close(pipeFD[0])
            return (status, "Failed to spawn process (code: \(status))")
        }
    }
    
    /// Restarts mediaserverd so system audio daemon immediately picks up modified audio parameters.
    public func restartMediaServerd() {
        if environment == .jailbrokenRootless {
            executePrivilegedCommand(executable: "/var/jb/usr/bin/killall", arguments: ["-9", "mediaserverd"])
        } else if environment == .jailbrokenRootful {
            executePrivilegedCommand(executable: "/usr/bin/killall", arguments: ["-9", "mediaserverd"])
        } else {
            // TrollStore mode fallback
            executePrivilegedCommand(executable: "killall", arguments: ["-9", "mediaserverd"])
        }
    }
}
