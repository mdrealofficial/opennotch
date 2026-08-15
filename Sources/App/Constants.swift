import SwiftUI

public enum NotchConstants {
    public static let defaultCompactWidth: CGFloat = 210
    public static let defaultCompactHeight: CGFloat = 34
    
    public static let defaultExpandedWidth: CGFloat = 620
    public static let defaultExpandedHeight: CGFloat = 270
    
    public static let notchCornerRadius: CGFloat = 18
    public static let expandedCornerRadius: CGFloat = 28
    
    public static let springResponse: Double = 0.36
    public static let springDamping: Double = 0.82
    
    public static let hoverDelay: Double = 0.15
    public static let autoCloseDelay: Double = 0.4
}

public enum WidgetTab: String, CaseIterable, Identifiable {
    case media = "Media"
    case dropShelf = "Drop Shelf"
    case mirror = "Mirror"
    case timer = "Timer"
    case bluetooth = "Devices"
    case pipelines = "Shortcuts"
    case devHUD = "Dev HUD"
    case calendar = "Calendar"
    case settings = "Settings"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .media: return "music.note"
        case .dropShelf: return "tray.and.arrow.down.fill"
        case .mirror: return "camera.fill"
        case .timer: return "timer"
        case .bluetooth: return "airpodspro"
        case .pipelines: return "bolt.fill"
        case .devHUD: return "terminal.fill"
        case .calendar: return "calendar"
        case .settings: return "gearshape.fill"
        }
    }
}
