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
        self.ignoresMouseEvents = true
        self.acceptsMouseMovedEvents = true
        self.hidesOnDeactivate = false
        
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
            NSPasteboard.PasteboardType("public.data"),
            NSPasteboard.PasteboardType("NSFilenamesPboardType")
        ])
    }
    
    public override var canBecomeKey: Bool {
        return true
    }
    
    public override var canBecomeMain: Bool {
        return false
    }
}

public final class NotchHostingView<Content: View>: NSHostingView<Content> {
    public weak var panelController: NotchPanelController?
    
    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
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
            NSPasteboard.PasteboardType("public.data"),
            NSPasteboard.PasteboardType("NSFilenamesPboardType")
        ])
    }
    
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
    
    public override func prepareForDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        return true
    }
    
    public override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        return panelController?.handlePerformDrag(sender) ?? false
    }
    
    public override func concludeDragOperation(_ sender: (any NSDraggingInfo)?) {
        // Concluded
    }
}
