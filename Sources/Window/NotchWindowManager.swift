import AppKit
import SwiftUI
import Combine

public enum NotchState {
    case compact   // State 1: Normal minimal resting notch (170 x 12)
    case peek      // State 2: On Hover peek pill (220 x 36)
    case expanded  // State 3: On Click full Nook / Tray hub (580 x 165)
}

public final class NotchPanelController: ObservableObject, Identifiable {
    public let id = UUID()
    public let screen: NSScreen
    public let panel: NotchPanel
    @Published public var state: NotchState = .compact
    @Published public var isHovered: Bool = false
    
    private var globalEventMonitor: Any?
    
    public var isExpanded: Bool {
        state == .expanded
    }
    
    public init(screen: NSScreen) {
        self.screen = screen
        let initialFrame = Self.frame(for: .compact, on: screen)
        self.panel = NotchPanel(contentRect: initialFrame)
        self.updateFrame()
        self.setupMouseTracking()
    }
    
    deinit {
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    public static func frame(for state: NotchState, on screen: NSScreen) -> NSRect {
        let screenFrame = screen.frame
        let width: CGFloat
        let height: CGFloat
        
        switch state {
        case .compact:
            width = 170
            height = 12
        case .peek:
            width = NotchConstants.defaultCompactWidth + 10 // 230
            height = NotchConstants.defaultCompactHeight + 8 // 42
        case .expanded:
            width = NotchConstants.defaultExpandedWidth + 16 // 596
            height = NotchConstants.defaultExpandedHeight + 16 // 171
        }
        
        let x = floor(screenFrame.midX - (width / 2))
        let y = screenFrame.maxY - height
        return NSRect(x: x, y: y, width: width, height: height)
    }
    
    public func updateFrame() {
        let targetFrame = Self.frame(for: state, on: screen)
        panel.setFrame(targetFrame, display: true)
    }
    
    public func setHovered(_ hovered: Bool) {
        self.isHovered = hovered
        if state != .expanded {
            withAnimation(.spring(response: 0.26, dampingFraction: 0.88)) {
                self.state = hovered ? .peek : .compact
            }
            self.updateFrame()
        }
    }
    
    public func expand() {
        withAnimation(.spring(response: NotchConstants.springResponse, dampingFraction: NotchConstants.springDamping)) {
            self.state = .expanded
        }
        self.updateFrame()
    }
    
    public func collapse() {
        withAnimation(.spring(response: NotchConstants.springResponse, dampingFraction: NotchConstants.springDamping)) {
            self.state = self.isHovered ? .peek : .compact
        }
        self.updateFrame()
    }
    
    public func toggleExpanded() {
        if state == .expanded {
            collapse()
        } else {
            expand()
        }
    }
    
    private func setupMouseTracking() {
        // Global mouse move monitor to reliably detect entering/leaving notch without taking over screen clicks
        globalEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.checkMousePosition(event.locationInWindow)
            return event
        }
    }
    
    private func checkMousePosition(_ location: NSPoint) {
        // If expanded, let view hover handle closing
        guard state != .expanded else { return }
        
        let mouseScreenPoint = NSEvent.mouseLocation
        let peekRect = Self.frame(for: .peek, on: screen)
        
        if NSPointInRect(mouseScreenPoint, peekRect) {
            if !isHovered {
                setHovered(true)
            }
        } else {
            if isHovered {
                setHovered(false)
            }
        }
    }
}

public final class NotchWindowManager: ObservableObject {
    public static let shared = NotchWindowManager()
    
    private var controllers: [NotchPanelController] = []
    private var cancellables = Set<AnyCancellable>()
    private var globalMouseMonitor: Any?
    
    private init() {
        setupNotifications()
        setupGlobalMonitor()
    }
    
    deinit {
        if let monitor = globalMouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
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
            hostingView.autoresizingMask = [.width, .height]
            controller.panel.contentView = hostingView
            controller.updateFrame()
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
    
    private func setupGlobalMonitor() {
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
            guard let self = self else { return }
            let mouseLoc = NSEvent.mouseLocation
            for controller in self.controllers {
                if controller.state != .expanded {
                    let peekRect = NotchPanelController.frame(for: .peek, on: controller.screen)
                    let inRect = NSPointInRect(mouseLoc, peekRect)
                    if inRect && !controller.isHovered {
                        controller.setHovered(true)
                    } else if !inRect && controller.isHovered {
                        controller.setHovered(false)
                    }
                }
            }
        }
    }
    
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
