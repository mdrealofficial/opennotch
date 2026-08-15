import SwiftUI

public enum OpenNotchTheme {
    // Deep Obsidian OLED Backgrounds
    public static let containerBackground = Color(red: 12/255, green: 12/255, blue: 14/255)
    public static let cardBackground = Color(red: 22/255, green: 22/255, blue: 26/255)
    public static let cardBackgroundHover = Color(red: 28/255, green: 28/255, blue: 34/255)
    public static let inputBackground = Color(red: 16/255, green: 16/255, blue: 18/255)
    
    // Borders & Dividers
    public static let cardBorder = Color.white.opacity(0.08)
    public static let containerBorder = Color.white.opacity(0.14)
    public static let subtleDivider = Color.white.opacity(0.10)
    
    // Typography
    public static let textPrimary = Color.white
    public static let textSecondary = Color(white: 0.65)
    public static let textTertiary = Color(white: 0.45)
    
    // Accents & Gradients
    public static let silverIconGradient = LinearGradient(
        colors: [Color.white, Color(white: 0.80)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    public static let purpleAuraGradient = LinearGradient(
        colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let accentGreen = Color(red: 52/255, green: 199/255, blue: 89/255)
    public static let accentOrange = Color(red: 255/255, green: 149/255, blue: 0/255)
    public static let accentRed = Color(red: 255/255, green: 59/255, blue: 48/255)
    public static let accentCyan = Color(red: 50/255, green: 173/255, blue: 230/255)
}
