import AppKit
import SwiftUI

public final class NotchPanel: NSPanel {
    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.isFloatingPanel = true
        self.level = .statusBar + 2
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .fullScreenAuxiliary,
            .ignoresCycle
        ]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true
        self.hidesOnDeactivate = false
    }
    
    public override var canBecomeKey: Bool {
        return false
    }
    
    public override var canBecomeMain: Bool {
        return false
    }
}

public final class NotchPassThroughHostingView<Content: View>: NSHostingView<Content> {
    public weak var panelController: NotchPanelController?
    
    public override func hitTest(_ point: NSPoint) -> NSView? {
        guard let controller = panelController else {
            return super.hitTest(point)
        }
        
        let activeWidth: CGFloat = controller.isExpanded
            ? NotchConstants.defaultExpandedWidth + 24
            : NotchConstants.defaultCompactWidth + 16
        
        let activeHeight: CGFloat = controller.isExpanded
            ? NotchConstants.defaultExpandedHeight + 16
            : NotchConstants.defaultCompactHeight + 8
        
        let minX = (bounds.width - activeWidth) / 2
        let maxX = minX + activeWidth
        let minY = bounds.height - activeHeight
        let maxY = bounds.height
        
        let activeRect = NSRect(x: minX, y: minY, width: activeWidth, height: maxY - minY)
        
        if NSPointInRect(point, activeRect) {
            return super.hitTest(point)
        }
        
        // Pass click through to underlying windows
        return nil
    }
}
