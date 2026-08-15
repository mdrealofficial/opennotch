import AppKit
import SwiftUI
import Combine

public final class NotchWindowManager: ObservableObject {
    public static let shared = NotchWindowManager()
    
    @Published public private(set) var isExpanded: Bool = false
    
    private var panels: [(panel: NotchPanel, screen: NSScreen)] = []
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupNotifications()
    }
    
    public func setup() {
        rebuildPanels()
    }
    
    public func rebuildPanels() {
        // Clean up existing panels
        for item in panels {
            item.panel.close()
        }
        panels.removeAll()
        
        let prefs = UserPreferences.shared
        let mode = ScreenDisplayMode(rawValue: prefs.screenDisplayModeRaw) ?? .allScreens
        
        let targetScreens: [NSScreen]
        switch mode {
        case .allScreens:
            targetScreens = NSScreen.screens
        case .mainOnly:
            if let main = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) ?? NSScreen.main ?? NSScreen.screens.first {
                targetScreens = [main]
            } else {
                targetScreens = NSScreen.screens
            }
        case .followCursor:
            let mouseLoc = NSEvent.mouseLocation
            if let current = NSScreen.screens.first(where: { NSPointInRect(mouseLoc, $0.frame) }) ?? NSScreen.main {
                targetScreens = [current]
            } else {
                targetScreens = [NSScreen.screens[0]]
            }
        }
        
        for screen in targetScreens {
            let screenInfo = ScreenGeometryHelper.screenInfo(for: screen)
            let initialFrame = isExpanded
                ? screenInfo.expandedFrame(expandedWidth: prefs.expandedWidth, expandedHeight: prefs.expandedHeight)
                : screenInfo.compactFrame()
            
            let panel = NotchPanel(contentRect: initialFrame)
            let hostingView = NSHostingView(rootView: NotchContainerView(windowManager: self))
            panel.contentView = hostingView
            panel.setFrame(initialFrame, display: true)
            panel.orderFrontRegardless()
            
            panels.append((panel: panel, screen: screen))
        }
    }
    
    public func expand() {
        guard !isExpanded else { return }
        isExpanded = true
        updatePanelFrames(animated: true)
    }
    
    public func collapse() {
        guard isExpanded else { return }
        isExpanded = false
        updatePanelFrames(animated: true)
    }
    
    public func toggleExpanded() {
        if isExpanded {
            collapse()
        } else {
            expand()
        }
    }
    
    public func updatePanelFrames(animated: Bool = true) {
        let prefs = UserPreferences.shared
        
        for item in panels {
            let screenInfo = ScreenGeometryHelper.screenInfo(for: item.screen)
            let targetFrame: NSRect
            if isExpanded {
                targetFrame = screenInfo.expandedFrame(
                    expandedWidth: prefs.expandedWidth,
                    expandedHeight: prefs.expandedHeight
                )
            } else {
                targetFrame = screenInfo.compactFrame()
            }
            
            if animated {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.28
                    context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                    item.panel.animator().setFrame(targetFrame, display: true)
                }
            } else {
                item.panel.setFrame(targetFrame, display: true)
            }
        }
    }
    
    private func setupNotifications() {
        // Screen resolution / plug / unplug changes
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                self?.rebuildPanels()
            }
            .store(in: &cancellables)
        
        // Listen to ScreenDisplayMode user preference changes
        UserDefaults.standard.publisher(for: \.screenDisplayModeRawKey)
            .sink { [weak self] _ in
                self?.rebuildPanels()
            }
            .store(in: &cancellables)
    }
}

// Swift KVO extension for UserDefaults screenDisplayMode
private extension UserDefaults {
    @objc dynamic var screenDisplayModeRawKey: String? {
        return string(forKey: "screenDisplayMode")
    }
}
