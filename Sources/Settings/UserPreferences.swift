import SwiftUI
import Combine

public final class UserPreferences: ObservableObject {
    public static let shared = UserPreferences()
    
    @AppStorage("enableHoverExpansion") public var enableHoverExpansion: Bool = true
    @AppStorage("hoverDelay") public var hoverDelay: Double = 0.15
    @AppStorage("autoCollapseDelay") public var autoCollapseDelay: Double = 0.4
    @AppStorage("expandedWidth") public var expandedWidth: Double = 580
    @AppStorage("expandedHeight") public var expandedHeight: Double = 250
    @AppStorage("themePreset") public var themePreset: String = "midnight"
    @AppStorage("enableHaptics") public var enableHaptics: Bool = true
    @AppStorage("floatingIslandOffset") public var floatingIslandOffset: Double = 8
    @AppStorage("selectedTabRaw") public var selectedTabRaw: String = WidgetTab.media.rawValue
    
    public var selectedTab: WidgetTab {
        get { WidgetTab(rawValue: selectedTabRaw) ?? .media }
        set { selectedTabRaw = newValue.rawValue }
    }
    
    private init() {}
}
