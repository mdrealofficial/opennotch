import AppKit
import SwiftUI
import Combine

public final class NotchPanelController: ObservableObject, Identifiable {
    public let id = UUID()
    public let screen: NSScreen
    public let panel: NotchPanel
    @Published public var isExpanded: Bool = false
    
    public init(screen: NSScreen) {
        self.screen = screen
        let screenInfo = ScreenGeometryHelper.screenInfo(for: screen)
        let initialFrame = screenInfo.compactFrame()
        self.panel = NotchPanel(contentRect: initialFrame)
    }
    
    public func expand() {
        guard !isExpanded else { return }
        isExpanded = true
        updateFrame(animated: true)
    }
    
    public func collapse() {
        guard isExpanded else { return }
        isExpanded = false
        updateFrame(animated: true)
    }
    
    public func toggleExpanded() {
        if isExpanded {
            collapse()
        } else {
            expand()
        }
    }
    
    public func updateFrame(animated: Bool = true) {
        let prefs = UserPreferences.shared
        let screenInfo = ScreenGeometryHelper.screenInfo(for: screen)
        let targetFrame: NSRect = isExpanded
            ? screenInfo.expandedFrame(expandedWidth: prefs.expandedWidth, expandedHeight: prefs.expandedHeight)
            : screenInfo.compactFrame()
        
        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.28
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                self.panel.animator().setFrame(targetFrame, display: true)
            }
        } else {
            self.panel.setFrame(targetFrame, display: true)
        }
    }
}

public final class NotchWindowManager: ObservableObject {
    public static let shared = NotchWindowManager()
    
    private var controllers: [NotchPanelController] = []
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupNotifications()
    }
    
    public func setup() {
        rebuildPanels()
    }
    
    public func rebuildPanels() {
        for c in controllers {
            c.panel.close()
        }
        controllers.removeAll()
        
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
            let controller = NotchPanelController(screen: screen)
            let hostingView = NSHostingView(rootView: NotchContainerView(panelController: controller))
            controller.panel.contentView = hostingView
            controller.updateFrame(animated: false)
            controller.panel.orderFrontRegardless()
            
            controllers.append(controller)
        }
    }
    
    public func activeController() -> NotchPanelController? {
        let mouseLoc = NSEvent.mouseLocation
        return controllers.first(where: { NSPointInRect(mouseLoc, $0.screen.frame) }) ?? controllers.first
    }
    
    public func expand() {
        activeController()?.expand()
    }
    
    public func collapse() {
        for c in controllers {
            c.collapse()
        }
    }
    
    public func toggleExpanded() {
        activeController()?.toggleExpanded()
    }
    
    public func updatePanelFrames(animated: Bool = true) {
        for c in controllers {
            c.updateFrame(animated: animated)
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
