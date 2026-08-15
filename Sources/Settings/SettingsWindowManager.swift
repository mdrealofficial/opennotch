import AppKit
import SwiftUI

public final class SettingsWindowManager: ObservableObject {
    public static let shared = SettingsWindowManager()
    
    private var windowController: NSWindowController?
    
    private init() {}
    
    public func openSettings() {
        if let existing = windowController?.window {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 540),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "OpenNotch Settings"
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.isMovable = true
        window.isMovableByWindowBackground = true
        
        let controller = NSWindowController(window: window)
        self.windowController = controller
        
        controller.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
