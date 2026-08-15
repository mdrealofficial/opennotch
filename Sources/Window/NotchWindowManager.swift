import AppKit
import SwiftUI
import Combine

public final class NotchWindowManager: ObservableObject {
    public static let shared = NotchWindowManager()
    
    @Published public private(set) var isExpanded: Bool = false
    
    private var panel: NotchPanel?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupScreenNotifications()
    }
    
    public func setup() {
        let screenInfo = ScreenGeometryHelper.mainScreenInfo()
        let initialFrame = screenInfo.compactFrame()
        
        let panel = NotchPanel(contentRect: initialFrame)
        let hostingView = NSHostingView(rootView: NotchContainerView(windowManager: self))
        panel.contentView = hostingView
        
        self.panel = panel
        updatePanelFrame(animated: false)
        panel.orderFrontRegardless()
    }
    
    public func expand() {
        guard !isExpanded else { return }
        isExpanded = true
        updatePanelFrame(animated: true)
    }
    
    public func collapse() {
        guard isExpanded else { return }
        isExpanded = false
        updatePanelFrame(animated: true)
    }
    
    public func toggleExpanded() {
        if isExpanded {
            collapse()
        } else {
            expand()
        }
    }
    
    public func updatePanelFrame(animated: Bool = true) {
        guard let panel = panel else { return }
        let screenInfo = ScreenGeometryHelper.mainScreenInfo()
        let prefs = UserPreferences.shared
        
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
                panel.animator().setFrame(targetFrame, display: true)
            }
        } else {
            panel.setFrame(targetFrame, display: true)
        }
    }
    
    private func setupScreenNotifications() {
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                self?.updatePanelFrame(animated: false)
            }
            .store(in: &cancellables)
    }
}
