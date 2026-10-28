import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Design System & Styling Tokens for Equalizer Pro.
/// Implements Apple HIG, machined studio hardware aesthetics, double-bezel depth,
/// and responsive fluid physics.
public enum EqualizerTheme {
    
    // MARK: - Color Palette
    public enum Colors {
        // Backgrounds & Surfaces
        public static let backgroundBase = Color(red: 0.04, green: 0.04, blue: 0.06)
        public static let backgroundSecondary = Color(red: 0.065, green: 0.075, blue: 0.095)
        public static let surfaceTray = Color(red: 0.09, green: 0.10, blue: 0.13)
        public static let surfaceElevated = Color(red: 0.12, green: 0.13, blue: 0.17)
        public static let surfaceHighlight = Color(red: 0.16, green: 0.18, blue: 0.23)
        
        // Hairline Borders
        public static let borderHairline = Color.white.opacity(0.08)
        public static let borderSubtle = Color.white.opacity(0.12)
        public static let borderFocused = Color.cyan.opacity(0.5)
        
        // Brand & DSP Tints
        public static let cyanAccent = Color(red: 0.0, green: 0.82, blue: 0.95) // Primary Audio Spectrum
        public static let royalBlue = Color(red: 0.25, green: 0.45, blue: 0.98) // Low-Mids
        public static let violet = Color(red: 0.65, green: 0.35, blue: 0.98) // Reverb / System EQ
        public static let emerald = Color(red: 0.20, green: 0.85, blue: 0.45) // Active / Connected
        public static let tubeAmber = Color(red: 1.0, green: 0.65, blue: 0.15) // Preamp / Warning
        public static let peakPink = Color(red: 1.0, green: 0.28, blue: 0.45) // Limiter / High Peak
        
        // Dynamic Gradients
        public static let cyanBlueGradient = LinearGradient(
            colors: [cyanAccent, royalBlue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        public static let purpleBlueGradient = LinearGradient(
            colors: [violet, royalBlue],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        public static let amberCoralGradient = LinearGradient(
            colors: [tubeAmber, peakPink],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Spring Motion Constants (Designing Fluid Interfaces)
    public enum AnimationSprings {
        // Critically damped default for UI cards & modes (response 0.35s, damping 0.85)
        public static let fluidDefault = Animation.spring(response: 0.35, dampingFraction: 0.85)
        
        // Snappy tactile response for buttons and faders
        public static let tactile = Animation.spring(response: 0.28, dampingFraction: 0.8)
        
        // Bouncy spring for modal reveals & peak bounces
        public static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.72)
        
        // Smooth interpolation for spline curves
        public static let smoothSpline = Animation.interactiveSpring(response: 0.3, dampingFraction: 0.85)
    }
    
    // MARK: - Haptic Multimodal Feedback
    public enum Haptics {
        public static func selection() {
            #if os(iOS)
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            #endif
        }
        
        public static func impactLight() {
            #if os(iOS)
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            #endif
        }
        
        public static func impactMedium() {
            #if os(iOS)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            #endif
        }
        
        public static func success() {
            #if os(iOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            #endif
        }
        
        public static func warning() {
            #if os(iOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            #endif
        }
    }
}

// MARK: - View Modifiers

public struct StudioCardModifier: ViewModifier {
    var cornerRadius: CGFloat
    var outerPadding: CGFloat
    
    public init(cornerRadius: CGFloat = 16, outerPadding: CGFloat = 0) {
        self.cornerRadius = cornerRadius
        self.outerPadding = outerPadding
    }
    
    public func body(content: Content) -> some View {
        content
            .background(
                // Double-bezel hardware tray architecture
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(EqualizerTheme.Colors.surfaceTray)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(EqualizerTheme.Colors.borderHairline, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal, outerPadding)
    }
}

public struct PressableButtonStyle: ButtonStyle {
    var haptic: Bool = true
    
    public init(haptic: Bool = true) {
        self.haptic = haptic
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(EqualizerTheme.AnimationSprings.tactile, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { pressed in
                if pressed && haptic {
                    EqualizerTheme.Haptics.impactLight()
                }
            }
    }
}

public extension View {
    func studioCard(cornerRadius: CGFloat = 16, outerPadding: CGFloat = 0) -> some View {
        self.modifier(StudioCardModifier(cornerRadius: cornerRadius, outerPadding: outerPadding))
    }
    
    func pressable(haptic: Bool = true) -> some View {
        self.buttonStyle(PressableButtonStyle(haptic: haptic))
    }
}
