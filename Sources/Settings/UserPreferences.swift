import SwiftUI
import Combine
import ServiceManagement

public enum FullscreenVisibilityOption: String, CaseIterable, Identifiable {
    case notchedOnly = "On notched screens"
    case always = "Always"
    case never = "Never"
    
    public var id: String { rawValue }
}

public enum MediaSourceOption: String, CaseIterable, Identifiable {
    case system = "System"
    case appleMusic = "Apple Music"
    case spotify = "Spotify"
    
    public var id: String { rawValue }
}

public enum LiveVisualizerEffect: String, CaseIterable, Identifiable {
    case spectrograph = "Audio Spectrograph"
    case waves = "Waves"
    case vibratingCircle = "Vibrating Circle"
    case gif = "GIF"
    
    public var id: String { rawValue }
}

public enum ScreenDisplayMode: String, CaseIterable, Identifiable {
    case allScreens = "All Connected Displays"
    case mainOnly = "Main Screen Only"
    case followCursor = "Active Screen (Follow Cursor)"
    
    public var id: String { rawValue }
}

public final class UserPreferences: ObservableObject {
    public static let shared = UserPreferences()
    
    // MARK: - General Tab
    @AppStorage("launchAtLogin") public var launchAtLogin: Bool = false
    @AppStorage("screenDisplayMode") public var screenDisplayModeRaw: String = ScreenDisplayMode.allScreens.rawValue
    @AppStorage("fullscreenVisibility") public var fullscreenVisibilityRaw: String = FullscreenVisibilityOption.notchedOnly.rawValue
    @AppStorage("mediaSource") public var mediaSourceRaw: String = MediaSourceOption.system.rawValue
    
    // Notch Toggles
    @AppStorage("preferRoundButtons") public var preferRoundButtons: Bool = true
    @AppStorage("translucentNotchBackground") public var translucentNotchBackground: Bool = false
    @AppStorage("alwaysOpenOnHover") public var alwaysOpenOnHover: Bool = true
    @AppStorage("disableHaptics") public var disableHaptics: Bool = false
    @AppStorage("preventClosingOnMouseLeave") public var preventClosingOnMouseLeave: Bool = true
    @AppStorage("lockWhileTyping") public var lockWhileTyping: Bool = false
    
    // Fine Tune & Content
    @AppStorage("contentPadding") public var contentPadding: Double = 12
    @AppStorage("notchWidthOffset") public var notchWidthOffset: Double = 0
    @AppStorage("notchHeightOffset") public var notchHeightOffset: Double = 0
    
    // Non-Notched Handler
    @AppStorage("enableHandlerNoNotch") public var enableHandlerNoNotch: Bool = true
    @AppStorage("handlerWidth") public var handlerWidth: Double = 184
    @AppStorage("handlerHeight") public var handlerHeight: Double = 8
    @AppStorage("transparentHandler") public var transparentHandler: Bool = false
    @AppStorage("demoMode") public var demoMode: Bool = false
    
    // Drop Area
    @AppStorage("dropAreaWidth") public var dropAreaWidth: Double = 11
    @AppStorage("autoDownloadUpdates") public var autoDownloadUpdates: Bool = false
    @AppStorage("autoCheckUpdates") public var autoCheckUpdates: Bool = true
    
    // MARK: - Gestures Tab
    @AppStorage("allowHoverGestures") public var allowHoverGestures: Bool = true
    @AppStorage("verticalGestureOpenClose") public var verticalGestureOpenClose: Bool = true
    @AppStorage("horizontalGestureMedia") public var horizontalGestureMedia: Bool = true
    @AppStorage("invertMediaGestures") public var invertMediaGestures: Bool = false
    
    // MARK: - Live Activities Tab
    @AppStorage("enableLiveActivities") public var enableLiveActivities: Bool = true
    @AppStorage("hideInNonNotchedScreens") public var hideInNonNotchedScreens: Bool = false
    @AppStorage("inactivityTimeout") public var inactivityTimeout: Double = 10
    @AppStorage("enableInteractiveActivities") public var enableInteractiveActivities: Bool = true
    @AppStorage("enableQuickPeek") public var enableQuickPeek: Bool = true
    @AppStorage("unhideAutomatically") public var unhideAutomatically: Bool = true
    @AppStorage("showSongChange") public var showSongChange: Bool = false
    
    // Show in Fullscreen checkboxes
    @AppStorage("fullscreenMedia") public var fullscreenMedia: Bool = true
    @AppStorage("fullscreenFilesTray") public var fullscreenFilesTray: Bool = true
    @AppStorage("fullscreenCalendar") public var fullscreenCalendar: Bool = true
    @AppStorage("fullscreenNewUpdate") public var fullscreenNewUpdate: Bool = true
    @AppStorage("fullscreenBluetooth") public var fullscreenBluetooth: Bool = true
    @AppStorage("fullscreenBattery") public var fullscreenBattery: Bool = true
    @AppStorage("fullscreenTimerEnded") public var fullscreenTimerEnded: Bool = true
    
    // Customize Activities
    @AppStorage("albumCornerRadius") public var albumCornerRadius: Double = 5
    @AppStorage("visualizerEffect") public var visualizerEffectRaw: String = LiveVisualizerEffect.spectrograph.rawValue
    @AppStorage("coloredEffects") public var coloredEffects: Bool = true
    
    // MARK: - Nook Tab (Hub)
    @AppStorage("enableNook") public var enableNook: Bool = true
    @AppStorage("showDividersBetweenWidgets") public var showDividersBetweenWidgets: Bool = true
    @AppStorage("expandedWidth") public var expandedWidth: Double = 620
    @AppStorage("expandedHeight") public var expandedHeight: Double = 270
    
    // Active Tab Selection
    @AppStorage("selectedTabRaw") public var selectedTabRaw: String = WidgetTab.media.rawValue
    
    public var selectedTab: WidgetTab {
        get { WidgetTab(rawValue: selectedTabRaw) ?? .media }
        set { selectedTabRaw = newValue.rawValue }
    }
    
    public var visibleTabs: [WidgetTab] {
        return WidgetTab.allCases
    }
    
    public var fullscreenVisibility: FullscreenVisibilityOption {
        get { FullscreenVisibilityOption(rawValue: fullscreenVisibilityRaw) ?? .notchedOnly }
        set { fullscreenVisibilityRaw = newValue.rawValue }
    }
    
    public var mediaSource: MediaSourceOption {
        get { MediaSourceOption(rawValue: mediaSourceRaw) ?? .system }
        set { mediaSourceRaw = newValue.rawValue }
    }
    
    public var visualizerEffect: LiveVisualizerEffect {
        get { LiveVisualizerEffect(rawValue: visualizerEffectRaw) ?? .spectrograph }
        set { visualizerEffectRaw = newValue.rawValue }
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
    
    public func resetAllSettings() {
        launchAtLogin = false
        preferRoundButtons = true
        translucentNotchBackground = false
        alwaysOpenOnHover = true
        disableHaptics = false
        preventClosingOnMouseLeave = true
        lockWhileTyping = false
        contentPadding = 12
        notchWidthOffset = 0
        notchHeightOffset = 0
        enableHandlerNoNotch = true
        handlerWidth = 184
        handlerHeight = 8
        transparentHandler = false
        demoMode = false
        
        allowHoverGestures = true
        verticalGestureOpenClose = true
        horizontalGestureMedia = true
        invertMediaGestures = false
        
        enableLiveActivities = true
        hideInNonNotchedScreens = false
        inactivityTimeout = 10
        enableInteractiveActivities = true
        enableQuickPeek = true
        unhideAutomatically = true
        showSongChange = false
        
        albumCornerRadius = 5
        visualizerEffectRaw = LiveVisualizerEffect.spectrograph.rawValue
        coloredEffects = true
        
        enableNook = true
        showDividersBetweenWidgets = true
        expandedWidth = 620
        expandedHeight = 270
    }
    
    private init() {}
}
