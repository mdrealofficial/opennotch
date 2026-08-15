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
            self.notchHeight = max(topInset, 34)
            self.notchWidth = 220
        } else {
            self.hasPhysicalNotch = false
            self.notchHeight = 34
            self.notchWidth = 220
        }
    }
    
    public func compactFrame(customWidth: CGFloat? = nil, customHeight: CGFloat? = nil) -> NSRect {
        let width = customWidth ?? (hasPhysicalNotch ? notchWidth : 220)
        let height = customHeight ?? (hasPhysicalNotch ? notchHeight : 34)
        let x = floor(screenFrame.midX - (width / 2))
        let y = screenFrame.maxY - height
        return NSRect(x: x, y: y, width: width, height: height)
    }
    
    public func expandedFrame(expandedWidth: CGFloat = NotchConstants.defaultExpandedWidth,
                              expandedHeight: CGFloat = NotchConstants.defaultExpandedHeight) -> NSRect {
        let x = floor(screenFrame.midX - (expandedWidth / 2))
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
