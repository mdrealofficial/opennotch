import AppKit
import SwiftUI
import Combine
import UniformTypeIdentifiers

public enum NotchState {
    case compact    // State 1: Normal minimal resting notch (170 x 12)
    case peek       // State 2: On Hover peek pill (220 x 36)
    case expanded   // State 3: On Click full Nook / Tray hub (580 x 155)
    case dropTarget // State 4: On Dragging file/URL to notch (430 x 72)
}

public enum DropZoneTarget {
    case none
    case filesTray
    case airdrop
}

public final class NotchPanelController: ObservableObject, Identifiable {
    public let id = UUID()
    public let screen: NSScreen
    public let panel: NotchPanel
    @Published public var state: NotchState = .compact
    @Published public var isHovered: Bool = false
    @Published public var activeDropZone: DropZoneTarget = .none
    
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
        case .dropTarget:
            width = 430
            height = 72
        }
        
        let x = floor(screenFrame.midX - (width / 2))
        let y = screenFrame.maxY - height
        return NSRect(x: x, y: y, width: width, height: height)
    }
    
    public func updateHoverState(isInside: Bool) {
        self.isHovered = isInside
        
        if state == .dropTarget {
            return
        }
        
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
        self.activeDropZone = .none
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
    
    public func enterDropTargetMode() {
        if state != .dropTarget {
            self.state = .dropTarget
            self.panel.ignoresMouseEvents = false
        }
    }
    
    // MARK: - Drag and Drop Handling
    
    public func handleDraggingEntered(_ sender: NSDraggingInfo) {
        enterDropTargetMode()
        updateDropZone(location: sender.draggingLocation)
    }
    
    public func handleDraggingUpdated(_ sender: NSDraggingInfo) {
        enterDropTargetMode()
        updateDropZone(location: sender.draggingLocation)
    }
    
    public func handleDraggingExited(_ sender: NSDraggingInfo?) {
        self.activeDropZone = .none
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            if self.state == .dropTarget {
                self.collapse()
            }
        }
    }
    
    private func updateDropZone(location: NSPoint) {
        let visibleRect = activeVisibleScreenRect()
        // Determine whether mouse is in left half (Files Tray) or right half (AirDrop)
        let midX = visibleRect.midX
        if location.x < midX {
            self.activeDropZone = .filesTray
        } else {
            self.activeDropZone = .airdrop
        }
    }
    
    public func handlePerformDrag(_ sender: NSDraggingInfo) -> Bool {
        let pboard = sender.draggingPasteboard
        var urlsToShare: [URL] = []
        
        if let urls = pboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            urlsToShare = urls
        }
        
        if urlsToShare.isEmpty {
            if let string = pboard.string(forType: .string) {
                if let url = URL(string: string), url.scheme != nil {
                    urlsToShare = [url]
                } else {
                    // Create temp file for text snippet
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Snippet.txt")
                    try? string.write(to: tempURL, atomically: true, encoding: .utf8)
                    urlsToShare = [tempURL]
                }
            }
        }
        
        guard !urlsToShare.isEmpty else {
            collapse()
            return false
        }
        
        let targetZone = self.activeDropZone
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if targetZone == .airdrop {
                if let service = NSSharingService(named: .sendViaAirDrop) {
                    if service.canPerform(withItems: urlsToShare) {
                        service.perform(withItems: urlsToShare)
                    }
                }
            } else {
                // Files Tray
                for url in urlsToShare {
                    DropShelfManager.shared.addFile(url: url)
                }
            }
            
            // Switch to expanded tray mode to show the stashed file, or collapse smoothly
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.collapse()
            }
        }
        
        return true
    }
}

public final class NotchWindowManager: ObservableObject {
    public static let shared = NotchWindowManager()
    
    private var controllers: [NotchPanelController] = []
    private var cancellables = Set<AnyCancellable>()
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    private var globalDragMonitor: Any?
    private var globalMouseUpMonitor: Any?
    
    private init() {
        setupNotifications()
        setupMouseMonitors()
    }
    
    deinit {
        if let monitor = globalMouseMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = localMouseMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = globalDragMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = globalMouseUpMonitor { NSEvent.removeMonitor(monitor) }
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
            let hostingView = NotchHostingView(rootView: NotchContainerView(panelController: controller))
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
    
    private func setupMouseMonitors() {
        // Global monitor for mouse moves
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
            self?.processMouseLocation(NSEvent.mouseLocation, isDragging: false)
        }
        
        // Local monitor for mouse moves
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.processMouseLocation(NSEvent.mouseLocation, isDragging: false)
            return event
        }
        
        // Global monitor for dragging items towards the notch
        globalDragMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged]) { [weak self] _ in
            self?.processMouseLocation(NSEvent.mouseLocation, isDragging: true)
        }
        
        // Global monitor for releasing mouse button
        globalMouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] _ in
            guard let self = self else { return }
            for c in self.controllers {
                if c.state == .dropTarget {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        c.collapse()
                    }
                }
            }
        }
    }
    
    private func processMouseLocation(_ mouseLoc: NSPoint, isDragging: Bool) {
        let prefs = UserPreferences.shared
        
        for controller in controllers {
            let visibleRect = controller.activeVisibleScreenRect()
            let screenMaxY = controller.screen.frame.maxY
            let screenMidX = controller.screen.frame.midX
            
            if isDragging {
                // Generous drag trigger zone near the top notch
                let inDragZone = mouseLoc.y >= screenMaxY - 140 && abs(mouseLoc.x - screenMidX) <= 240
                if inDragZone {
                    controller.enterDropTargetMode()
                } else if controller.state == .dropTarget && mouseLoc.y < screenMaxY - 180 {
                    controller.collapse()
                }
                continue
            }
            
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
            } else if controller.state != .dropTarget {
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
