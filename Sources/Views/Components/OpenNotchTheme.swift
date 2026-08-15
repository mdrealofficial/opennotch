import SwiftUI
import AppKit

public struct OpenNotchTheme {
    // Dynamic Adaptive Colors based on ColorScheme (.dark vs .light)
    public static func containerFill(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 16/255, green: 16/255, blue: 18/255).opacity(0.92)
            : Color(red: 248/255, green: 248/255, blue: 250/255).opacity(0.92)
    }
    
    public static func cardFill(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 30/255, green: 30/255, blue: 34/255).opacity(0.85)
            : Color.white.opacity(0.90)
    }
    
    public static func inputFill(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 22/255, green: 22/255, blue: 26/255)
            : Color(red: 238/255, green: 238/255, blue: 242/255)
    }
    
    public static func cardBorder(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.10)
            : Color.black.opacity(0.07)
    }
    
    public static func containerBorder(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.16)
            : Color.black.opacity(0.10)
    }
    
    public static func tabSelectedFill(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 50/255, green: 50/255, blue: 56/255)
            : Color(red: 220/255, green: 220/255, blue: 226/255)
    }
    
    public static func tabUnselectedText(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.55)
            : Color.black.opacity(0.55)
    }
    
    public static func shadowColor(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.black.opacity(0.55)
            : Color.black.opacity(0.15)
    }
    
    public static func dividerColor(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.10)
            : Color.black.opacity(0.08)
    }
    
    // Universal Colors
    public static let accentGreen = Color(red: 52/255, green: 199/255, blue: 89/255)
    public static let accentOrange = Color(red: 255/255, green: 149/255, blue: 0/255)
    public static let accentRed = Color(red: 255/255, green: 59/255, blue: 48/255)
    public static let accentBlue = Color(red: 0/255, green: 122/255, blue: 255/255)
    public static let accentPurple = Color(red: 175/255, green: 82/255, blue: 222/255)
    
    public static func iconGradient(for scheme: ColorScheme) -> LinearGradient {
        scheme == .dark
            ? LinearGradient(colors: [Color.white, Color(white: 0.80)], startPoint: .top, endPoint: .bottom)
            : LinearGradient(colors: [Color(white: 0.20), Color(white: 0.40)], startPoint: .top, endPoint: .bottom)
    }
}
