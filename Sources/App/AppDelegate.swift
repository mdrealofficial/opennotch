import AppKit
import SwiftUI

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as accessory (menu bar utility / no dock icon)
        NSApp.setActivationPolicy(.accessory)
        
        // Setup Notch Window Manager
        NotchWindowManager.shared.setup()
        
        // Setup Menu Bar Item
        setupStatusItem()
        
        // Setup Global Hotkey Monitor (Option + Space)
        setupGlobalKeyMonitor()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "sparkles.rectangle.stack.fill", accessibilityDescription: "OpenNotch")
        }
        
        let menu = NSMenu()
        
        let toggleItem = NSMenuItem(title: "Toggle OpenNotch", action: #selector(toggleNotch), keyEquivalent: "n")
        toggleItem.keyEquivalentModifierMask = [.option, .command]
        menu.addItem(toggleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let mediaItem = NSMenuItem(title: "Media Hub", action: #selector(showMediaTab), keyEquivalent: "1")
        mediaItem.keyEquivalentModifierMask = [.command]
        menu.addItem(mediaItem)
        
        let dropShelfItem = NSMenuItem(title: "Drop Shelf", action: #selector(showDropShelfTab), keyEquivalent: "2")
        dropShelfItem.keyEquivalentModifierMask = [.command]
        menu.addItem(dropShelfItem)
        
        let devHUDItem = NSMenuItem(title: "Dev HUD", action: #selector(showDevHUDTab), keyEquivalent: "3")
        devHUDItem.keyEquivalentModifierMask = [.command]
        menu.addItem(devHUDItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(showSettingsTab), keyEquivalent: ",")
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit OpenNotch", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc private func toggleNotch() {
        NotchWindowManager.shared.toggleExpanded()
    }
    
    @objc private func showMediaTab() {
        UserPreferences.shared.selectedTab = .media
        NotchWindowManager.shared.expand()
    }
    
    @objc private func showDropShelfTab() {
        UserPreferences.shared.selectedTab = .dropShelf
        NotchWindowManager.shared.expand()
    }
    
    @objc private func showDevHUDTab() {
        UserPreferences.shared.selectedTab = .devHUD
        NotchWindowManager.shared.expand()
    }
    
    @objc private func showSettingsTab() {
        UserPreferences.shared.selectedTab = .settings
        NotchWindowManager.shared.expand()
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    private func setupGlobalKeyMonitor() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains([.command, .option]) && event.charactersIgnoringModifiers == "n" {
                NotchWindowManager.shared.toggleExpanded()
                return nil
            }
            return event
        }
    }
}
