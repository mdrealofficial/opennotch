import AppKit
import SwiftUI
import Combine

public enum NotchState {
    case compact   // State 1: Normal minimal resting notch (170 x 12)
    case peek      // State 2: On Hover peek pill (220 x 36)
    case expanded  // State 3: On Click full Nook / Tray hub (580 x 155)
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
    
    /// Returns the exact active physical bounding box of the visible notch in screen coordinates.
    public func activeVisibleScreenRect() -> NSRect {
        let screenFrame = screen.frame
        let width: CGFloat
        let height: CGFloat
        
        switch state {
        case .compact:
            width = MediaRemoteService.shared.currentTrack.isPlaying ? 210 : 170
            height = 12
        case .peek:
            width = NotchConstants.defaultCompactWidth // 220
            height = NotchConstants.defaultCompactHeight // 34
        case .expanded:
            width = CGFloat(UserPreferences.shared.expandedWidth)
            height = CGFloat(UserPreferences.shared.expandedHeight)
        }
        
        let x = floor(screenFrame.midX - (width / 2))
        let y = screenFrame.maxY - height
        return NSRect(x: x, y: y, width: width, height: height)
    }
    
    public func updateHoverState(isInside: Bool) {
        self.isHovered = isInside
        
        if isInside {
            if state != .expanded && state != .peek {
                self.state = .peek
            }
        } else {
            if state != .expanded && state != .compact {
                self.state = .compact
            }
        }
        
        self.panel.ignoresMouseEvents = !isInside && (state != .expanded)
    }
    
    public func expand() {
        self.state = .expanded
        self.panel.ignoresMouseEvents = false
    }
    
    public func collapse() {
        self.state = self.isHovered ? .peek : .compact
        self.panel.ignoresMouseEvents = !self.isHovered
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
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    
    private init() {
        setupNotifications()
        setupMouseMonitors()
    }
    
    deinit {
        if let monitor = globalMouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localMouseMonitor {
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
    
    private func setupMouseMonitors() {
        // Global monitor (when other apps like Chrome/Finder are active)
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
            self?.processMouseLocation(NSEvent.mouseLocation)
        }
        
        // Local monitor (when our app is active)
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.processMouseLocation(NSEvent.mouseLocation)
            return event
        }
    }
    
    private func processMouseLocation(_ mouseLoc: NSPoint) {
        let prefs = UserPreferences.shared
        
        for controller in controllers {
            let visibleRect = controller.activeVisibleScreenRect()
            let screenMaxY = controller.screen.frame.maxY
            
            // Expand hover hit-box generously:
            var hoverRect = visibleRect.insetBy(dx: -40, dy: -30)
            if hoverRect.maxY < screenMaxY + 25 {
                hoverRect.size.height = (screenMaxY + 25) - hoverRect.origin.y
            }
            
            let isInside = hoverRect.contains(mouseLoc)
            
            if controller.state == .expanded {
                if !prefs.preventClosingOnMouseLeave {
                    let expandedRect = controller.activeVisibleScreenRect().insetBy(dx: -40, dy: -40)
                    if !expandedRect.contains(mouseLoc) {
                        controller.collapse()
                    }
                }
            } else {
                if prefs.alwaysOpenOnHover {
                    controller.updateHoverState(isInside: isInside)
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
