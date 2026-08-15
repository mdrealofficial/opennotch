import AppKit

public struct NotchScreenInfo {
    public let hasPhysicalNotch: Bool
    public let notchWidth: CGFloat
    public let notchHeight: CGFloat
    public let screenFrame: NSRect
    public let visibleFrame: NSRect
    
    // Generous transparent shadow margin so SwiftUI drop shadows never clip
    public static let shadowPaddingX: CGFloat = 40
    public static let shadowPaddingBottom: CGFloat = 40
    
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
        let contentWidth = customWidth ?? (hasPhysicalNotch ? notchWidth : 220)
        let contentHeight = customHeight ?? (hasPhysicalNotch ? notchHeight : 34)
        
        let totalWidth = contentWidth + (Self.shadowPaddingX * 2)
        let totalHeight = contentHeight + Self.shadowPaddingBottom
        
        let x = floor(screenFrame.midX - (totalWidth / 2))
        let y = screenFrame.maxY - totalHeight
        return NSRect(x: x, y: y, width: totalWidth, height: totalHeight)
    }
    
    public func expandedFrame(expandedWidth: CGFloat = NotchConstants.defaultExpandedWidth,
                              expandedHeight: CGFloat = NotchConstants.defaultExpandedHeight) -> NSRect {
        let totalWidth = expandedWidth + (Self.shadowPaddingX * 2)
        let totalHeight = expandedHeight + Self.shadowPaddingBottom
        
        let x = floor(screenFrame.midX - (totalWidth / 2))
        let y = screenFrame.maxY - totalHeight
        return NSRect(x: x, y: y, width: totalWidth, height: totalHeight)
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
