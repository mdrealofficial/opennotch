import AppKit
import SwiftUI
import UniformTypeIdentifiers

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
        // By default ignore mouse events so underlying apps receive all clicks.
        // Dynamically toggled to false only when mouse enters the visible notch frame or during drags.
        self.ignoresMouseEvents = true
        self.acceptsMouseMovedEvents = true
        self.hidesOnDeactivate = false
        
        // Register for all dragged file and URL types
        self.registerForDraggedTypes([
            .fileURL,
            .URL,
            .string,
            .tiff,
            .png,
            .rtf,
            NSPasteboard.PasteboardType("public.item"),
            NSPasteboard.PasteboardType("public.file-url"),
            NSPasteboard.PasteboardType("public.content"),
            NSPasteboard.PasteboardType("public.data")
        ])
    }
    
    public override var canBecomeKey: Bool {
        return false
    }
    
    public override var canBecomeMain: Bool {
        return false
    }
}

public final class NotchHostingView<Content: View>: NSHostingView<Content> {
    public weak var panelController: NotchPanelController?
    
    public override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        panelController?.handleDraggingEntered(sender)
        return .copy
    }
    
    public override func draggingUpdated(_ sender: any NSDraggingInfo) -> NSDragOperation {
        panelController?.handleDraggingUpdated(sender)
        return .copy
    }
    
    public override func draggingExited(_ sender: (any NSDraggingInfo)?) {
        panelController?.handleDraggingExited(sender)
    }
    
    public override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        return panelController?.handlePerformDrag(sender) ?? false
    }
}
