import AppKit
import SwiftUI
import Combine

public enum NotchState {
    case compact   // State 1: Normal minimal resting notch
    case peek      // State 2: On Hover slight extension
    case expanded  // State 3: On Click full Nook / Tray hub
}

public final class NotchPanelController: ObservableObject, Identifiable {
    public let id = UUID()
    public let screen: NSScreen
    public let panel: NotchPanel
    @Published public var state: NotchState = .compact
    @Published public var isHovered: Bool = false
    
    public var isExpanded: Bool {
        state == .expanded
    }
    
    public init(screen: NSScreen) {
        self.screen = screen
        let screenInfo = ScreenGeometryHelper.screenInfo(for: screen)
        let frame = screenInfo.windowFrame()
        self.panel = NotchPanel(contentRect: frame)
    }
    
    public func setHovered(_ hovered: Bool) {
        self.isHovered = hovered
        if state != .expanded {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                self.state = hovered ? .peek : .compact
            }
        }
    }
    
    public func expand() {
        withAnimation(.spring(response: NotchConstants.springResponse, dampingFraction: NotchConstants.springDamping)) {
            self.state = .expanded
        }
    }
    
    public func collapse() {
        withAnimation(.spring(response: NotchConstants.springResponse, dampingFraction: NotchConstants.springDamping)) {
            self.state = self.isHovered ? .peek : .compact
        }
    }
    
    public func toggleExpanded() {
        if state == .expanded {
            collapse()
        } else {
            expand()
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
            let hostingView = NotchPassThroughHostingView(rootView: NotchContainerView(panelController: controller))
            hostingView.panelController = controller
            hostingView.autoresizingMask = [.width, .height]
            controller.panel.contentView = hostingView
            controller.panel.setFrame(ScreenGeometryHelper.screenInfo(for: screen).windowFrame(), display: true)
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
    
    public func updatePanelFrames(animated: Bool = true) {}
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                self?.rebuildPanels()
            }
            .store(in: &cancellables)
        
        UserDefaults.standard.publisher(for: \.screenDisplayModeRawKey)
            .sink { [weak self] _ in
                self?.rebuildPanels()
            }
            .store(in: &cancellables)
    }
}

private extension UserDefaults {
    @objc dynamic var screenDisplayModeRawKey: String? {
        return string(forKey: "screenDisplayMode")
    }
}
