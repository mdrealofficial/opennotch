import SwiftUI
import Combine
import ServiceManagement

public enum AppThemePreset: String, CaseIterable, Identifiable {
    case obsidian = "Obsidian Dark"
    case glassmorphism = "Frosted Glass"
    case neonCyber = "Neon Glow"
    case titanium = "Titanium Mist"
    
    public var id: String { rawValue }
    
    public var accentColors: [Color] {
        switch self {
        case .obsidian:
            return [Color.white.opacity(0.18), Color.white.opacity(0.04)]
        case .glassmorphism:
            return [Color.cyan.opacity(0.4), Color.purple.opacity(0.3)]
        case .neonCyber:
            return [Color.green.opacity(0.6), Color.cyan.opacity(0.5)]
        case .titanium:
            return [Color.white.opacity(0.3), Color.gray.opacity(0.2)]
        }
    }
}

public final class UserPreferences: ObservableObject {
    public static let shared = UserPreferences()
    
    // Behavior & Triggers
    @AppStorage("enableHoverExpansion") public var enableHoverExpansion: Bool = true
    @AppStorage("hoverDelay") public var hoverDelay: Double = 0.15
    @AppStorage("autoCollapseDelay") public var autoCollapseDelay: Double = 0.4
    @AppStorage("enableHaptics") public var enableHaptics: Bool = true
    @AppStorage("launchAtLogin") public var launchAtLogin: Bool = false
    
    // Dimensions & Geometry
    @AppStorage("expandedWidth") public var expandedWidth: Double = 620
    @AppStorage("expandedHeight") public var expandedHeight: Double = 270
    @AppStorage("floatingIslandOffset") public var floatingIslandOffset: Double = 8
    @AppStorage("compactPillWidth") public var compactPillWidth: Double = 210
    
    // Appearance & Style
    @AppStorage("themePresetRaw") public var themePresetRaw: String = AppThemePreset.obsidian.rawValue
    @AppStorage("borderGlowOpacity") public var borderGlowOpacity: Double = 0.2
    @AppStorage("glassBlurIntensity") public var glassBlurIntensity: Double = 0.85
    
    // Widget Visibility Toggles
    @AppStorage("showMediaWidget") public var showMediaWidget: Bool = true
    @AppStorage("showDropShelfWidget") public var showDropShelfWidget: Bool = true
    @AppStorage("showMirrorWidget") public var showMirrorWidget: Bool = true
    @AppStorage("showTimerWidget") public var showTimerWidget: Bool = true
    @AppStorage("showBluetoothWidget") public var showBluetoothWidget: Bool = true
    @AppStorage("showPipelinesWidget") public var showPipelinesWidget: Bool = true
    @AppStorage("showDevHUDWidget") public var showDevHUDWidget: Bool = true
    @AppStorage("showCalendarWidget") public var showCalendarWidget: Bool = true
    
    @AppStorage("selectedTabRaw") public var selectedTabRaw: String = WidgetTab.media.rawValue
    
    public var selectedTab: WidgetTab {
        get { WidgetTab(rawValue: selectedTabRaw) ?? .media }
        set { selectedTabRaw = newValue.rawValue }
    }
    
    public var currentTheme: AppThemePreset {
        get { AppThemePreset(rawValue: themePresetRaw) ?? .obsidian }
        set { themePresetRaw = newValue.rawValue }
    }
    
    public var visibleTabs: [WidgetTab] {
        var tabs: [WidgetTab] = []
        if showMediaWidget { tabs.append(.media) }
        if showDropShelfWidget { tabs.append(.dropShelf) }
        if showMirrorWidget { tabs.append(.mirror) }
        if showTimerWidget { tabs.append(.timer) }
        if showBluetoothWidget { tabs.append(.bluetooth) }
        if showPipelinesWidget { tabs.append(.pipelines) }
        if showDevHUDWidget { tabs.append(.devHUD) }
        if showCalendarWidget { tabs.append(.calendar) }
        tabs.append(.settings) // Settings always accessible
        return tabs
    }
    
    public func toggleLaunchAtLogin(_ enable: Bool) {
        launchAtLogin = enable
        if #available(macOS 13.0, *) {
            do {
                if enable {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Launch at login toggle: \(error.localizedDescription)")
            }
        }
    }
    
    private init() {}
}
