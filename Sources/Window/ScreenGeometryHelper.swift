import AppKit

public struct NotchScreenInfo {
    public let hasPhysicalNotch: Bool
    public let notchWidth: CGFloat
    public let notchHeight: CGFloat
    public let screenFrame: NSRect
    public let visibleFrame: NSRect
    
    public static let canvasWidth: CGFloat = 660
    public static let canvasHeight: CGFloat = 220
    
    public init(screen: NSScreen) {
        self.screenFrame = screen.frame
        self.visibleFrame = screen.visibleFrame
        
        let topInset = screen.safeAreaInsets.top
        if topInset > 0 {
            self.hasPhysicalNotch = true
            self.notchHeight = max(topInset, 34)
            self.notchWidth = 220
        } else {
            self.hasPhysicalNotch = false
            self.notchHeight = 34
            self.notchWidth = 220
        }
    }
    
    /// Stable, fixed window frame spanning the maximum interactive area.
    /// This prevents dynamic window frame resizes and eliminates 100% of AppKit constraint crashes.
    public func windowFrame() -> NSRect {
        let x = floor(screenFrame.midX - (Self.canvasWidth / 2))
        let y = screenFrame.maxY - Self.canvasHeight
        return NSRect(x: x, y: y, width: Self.canvasWidth, height: Self.canvasHeight)
    }
}

public enum ScreenGeometryHelper {
    public static func mainScreenInfo() -> NotchScreenInfo {
        let targetScreen = NSScreen.screens.first { screen in
            screen.safeAreaInsets.top > 0
        } ?? NSScreen.main ?? NSScreen.screens[0]
        
        return NotchScreenInfo(screen: targetScreen)
    }
    
    public static func screenInfo(for screen: NSScreen) -> NotchScreenInfo {
        return NotchScreenInfo(screen: screen)
    }
}
