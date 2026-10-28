import Foundation
#if os(iOS)
import UIKit
#endif

/// Dynamic wrapper around Apple's private Celestial.framework and AVSystemController.
/// Exclusively targets Wired Headphone audio categories and routes ("Headphones" / "Wired")
/// for volume control and safety limit bypass on jailbroken & TrollStore iOS 14.0-15.x devices.
public final class AVSystemControllerBridge: NSObject {
    public static let shared = AVSystemControllerBridge()
    
    private var avSystemController: AnyObject?
    
    public override init() {
        super.init()
        loadCelestialFramework()
    }
    
    private func loadCelestialFramework() {
        let frameworkPath = "/System/Library/PrivateFrameworks/Celestial.framework/Celestial"
        guard dlopen(frameworkPath, RTLD_NOW) != nil else {
            print("[AVSystemControllerBridge] Unable to dlopen Celestial framework")
            return
        }
        
        if let controllerClass = NSClassFromString("AVSystemController") as? NSObject.Type {
            let sharedSelector = NSSelectorFromString("sharedAVSystemController")
            if controllerClass.responds(to: sharedSelector) {
                avSystemController = controllerClass.perform(sharedSelector)?.takeUnretainedValue()
            }
        }
    }
    
    /// Reads the current system volume for the wired "Headphones" audio category (0.0 to 1.0).
    public func getSystemVolume() -> Float {
        guard let controller = avSystemController else { return 0.5 }
        
        var volume: Float = 0.0
        let selector = NSSelectorFromString("getVolume:forCategory:")
        if controller.responds(to: selector) {
            typealias GetVolumeFunc = @convention(c) (AnyObject, Selector, UnsafeMutablePointer<Float>, NSString) -> Bool
            let method = class_getMethodImplementation(type(of: controller), selector)
            let fn = unsafeBitCast(method, to: GetVolumeFunc.self)
            
            // First check dedicated "Headphones" category
            if !fn(controller, selector, &volume, "Headphones" as NSString) {
                // Fallback to "Audio/Video"
                _ = fn(controller, selector, &volume, "Audio/Video" as NSString)
            }
        }
        return volume
    }
    
    /// Sets the headphone volume without displaying the system volume HUD.
    @discardableResult
    public func setSystemVolume(_ volume: Float) -> Bool {
        guard let controller = avSystemController else { return false }
        
        let clamped = max(0.0, min(1.0, volume))
        let selector = NSSelectorFromString("setVolumeTo:forCategory:")
        if controller.responds(to: selector) {
            typealias SetVolumeFunc = @convention(c) (AnyObject, Selector, Float, NSString) -> Bool
            let method = class_getMethodImplementation(type(of: controller), selector)
            let fn = unsafeBitCast(method, to: SetVolumeFunc.self)
            
            // Apply to "Headphones" and "Audio/Video"
            let hpSuccess = fn(controller, selector, clamped, "Headphones" as NSString)
            let avSuccess = fn(controller, selector, clamped, "Audio/Video" as NSString)
            return hpSuccess || avSuccess
        }
        return false
    }
    
    /// Returns the currently active audio output route name.
    public func getActiveAudioRoute() -> String {
        guard let controller = avSystemController else { return "Headphones" }
        
        let selector = NSSelectorFromString("getActiveAudioRouteDescription")
        if controller.responds(to: selector) {
            if let desc = controller.perform(selector)?.takeUnretainedValue() as? [String: Any] {
                if let routeName = desc["AVSystemController_AudioRouteNameAttribute"] as? String {
                    return routeName
                }
            }
        }
        
        // Fallback to route selector
        let altSelector = NSSelectorFromString("activeAudioRoute")
        if controller.responds(to: altSelector) {
            if let route = controller.perform(altSelector)?.takeUnretainedValue() as? String {
                return route
            }
        }
        
        return "Wired Headphones"
    }
    
    /// Checks if the active route is a wired headphone or USB DAC.
    public func isWiredHeadphoneActive() -> Bool {
        let route = getActiveAudioRoute().lowercased()
        return route.contains("headphone") ||
               route.contains("headset") ||
               route.contains("wired") ||
               route.contains("usb") ||
               route.contains("dac") ||
               route.contains("lightning")
    }
    
    /// Disables EU / iOS Headphone Safety Volume Limit (85 dB volume cap) targeting wired headphones.
    @discardableResult
    public func disableHeadphoneVolumeLimit() -> Bool {
        guard let controller = avSystemController else { return false }
        
        let selector = NSSelectorFromString("setHeadphoneVolumeLimit:forCategory:")
        if controller.responds(to: selector) {
            typealias LimitFunc = @convention(c) (AnyObject, Selector, Float, NSString) -> Bool
            let method = class_getMethodImplementation(type(of: controller), selector)
            let fn = unsafeBitCast(method, to: LimitFunc.self)
            
            // 1.0 = 100% unrestricted limit for both Headphones and Audio/Video
            let hp = fn(controller, selector, 1.0, "Headphones" as NSString)
            let av = fn(controller, selector, 1.0, "Audio/Video" as NSString)
            return hp || av
        }
        return false
    }
}
