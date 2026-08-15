import AppKit

public struct NotchScreenInfo {
    public let hasPhysicalNotch: Bool
    public let notchWidth: CGFloat
    public let notchHeight: CGFloat
    public let screenFrame: NSRect
    public let visibleFrame: NSRect
    
    public init(screen: NSScreen) {
        self.screenFrame = screen.frame
        self.visibleFrame = screen.visibleFrame
        
        let topInset = screen.safeAreaInsets.top
        if topInset > 0 {
            self.hasPhysicalNotch = true
            self.notchHeight = max(topInset, NotchConstants.defaultCompactHeight)
            // MacBook notch is typically ~210-230 points wide
            self.notchWidth = 220
        } else {
            self.hasPhysicalNotch = false
            self.notchHeight = NotchConstants.defaultCompactHeight
            self.notchWidth = NotchConstants.defaultCompactWidth
        }
    }
    
    public func compactFrame(customWidth: CGFloat? = nil, customHeight: CGFloat? = nil) -> NSRect {
        let width = customWidth ?? notchWidth
        let height = customHeight ?? notchHeight
        let x = screenFrame.midX - (width / 2)
        let y = screenFrame.maxY - height
        return NSRect(x: x, y: y, width: width, height: height)
    }
    
    public func expandedFrame(expandedWidth: CGFloat = NotchConstants.defaultExpandedWidth,
                              expandedHeight: CGFloat = NotchConstants.defaultExpandedHeight) -> NSRect {
        let x = screenFrame.midX - (expandedWidth / 2)
        let y = screenFrame.maxY - expandedHeight
        return NSRect(x: x, y: y, width: expandedWidth, height: expandedHeight)
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
