import SwiftUI
import AppKit

public struct TabPillButton: View {
    let tab: WidgetTab
    let isSelected: Bool
    let action: () -> Void
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 10, weight: .semibold))
                Text(tab.rawValue)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(isSelected ? Color.white.opacity(0.2) : Color.clear)
            )
            .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.6))
        }
        .buttonStyle(.plain)
    }
}

public struct NotchContainerView: View {
    @ObservedObject var windowManager: NotchWindowManager
    @ObservedObject var prefs = UserPreferences.shared
    @ObservedObject var mediaService = MediaRemoteService.shared
    @ObservedObject var shelfManager = DropShelfManager.shared
    @ObservedObject var sysMonitor = SystemMonitorService.shared
    @ObservedObject var timerService = NotchTimerService.shared
    
    @State private var isHovering: Bool = false
    @State private var hoverTimer: Timer?
    @State private var autoCloseTimer: Timer?
    
    public init(windowManager: NotchWindowManager) {
        self.windowManager = windowManager
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            if windowManager.isExpanded {
                expandedNotchBody
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .top))
                    ))
            } else {
                compactNotchBody
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: NotchConstants.springResponse, dampingFraction: NotchConstants.springDamping), value: windowManager.isExpanded)
        .onHover { hovering in
            handleHover(hovering)
        }
    }
    
    // MARK: - Compact Notch View
    private var compactNotchBody: some View {
        HStack(spacing: 8) {
            // Left Live Indicator
            HStack(spacing: 4) {
                if timerService.isRunning {
                    Image(systemName: "timer")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.orange)
                    
                    Text(timerService.displayString)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                } else if mediaService.currentTrack.isPlaying {
                    Image(systemName: "waveform")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.green)
                    
                    Text(mediaService.currentTrack.title)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                        .frame(maxWidth: 80)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.purple)
                    
                    Text("OpenNotch")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            
            Spacer()
            
            // Right Live Indicator
            HStack(spacing: 6) {
                if !shelfManager.files.isEmpty {
                    HStack(spacing: 2) {
                        Image(systemName: "tray.fill")
                            .font(.system(size: 9))
                        Text("\(shelfManager.files.count)")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(.cyan)
                }
                
                HStack(spacing: 2) {
                    Image(systemName: "cpu")
                        .font(.system(size: 9))
                    Text(String(format: "%.0f%%", sysMonitor.stats.cpuUsagePercentage))
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 14)
        .frame(width: NotchConstants.defaultCompactWidth, height: NotchConstants.defaultCompactHeight)
        .background(
            RoundedRectangle(cornerRadius: NotchConstants.notchCornerRadius, style: .continuous)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: NotchConstants.notchCornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: NotchConstants.springResponse, dampingFraction: NotchConstants.springDamping)) {
                windowManager.toggleExpanded()
            }
        }
    }
    
    // MARK: - Expanded Notch View
    private var expandedNotchBody: some View {
        VStack(spacing: 10) {
            tabBarHeader
            
            tabContentGroup
                .padding(.horizontal, 6)
                .padding(.bottom, 4)
        }
        .padding(14)
        .frame(width: prefs.expandedWidth, height: prefs.expandedHeight)
        .background(expandedBackground)
    }
    
    @ViewBuilder
    private var tabBarHeader: some View {
        HStack(spacing: 4) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(prefs.visibleTabs) { tab in
                        TabPillButton(
                            tab: tab,
                            isSelected: prefs.selectedTab == tab
                        ) {
                            withAnimation(.easeInOut(duration: 0.16)) {
                                prefs.selectedTab = tab
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.spring(response: NotchConstants.springResponse, dampingFraction: NotchConstants.springDamping)) {
                    windowManager.collapse()
                }
            }) {
                Image(systemName: "chevron.up.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .buttonStyle(.plain)
            .help("Collapse Notch")
        }
        .padding(.horizontal, 6)
        .padding(.top, 2)
    }
    
    @ViewBuilder
    private var tabContentGroup: some View {
        switch prefs.selectedTab {
        case .media:
            NowPlayingWidgetView()
        case .dropShelf:
            DropShelfWidgetView()
        case .mirror:
            CameraMirrorWidgetView()
        case .timer:
            TimerWidgetView()
        case .bluetooth:
            BluetoothWidgetView()
        case .pipelines:
            PipelinesWidgetView()
        case .devHUD:
            DevHUDWidgetView()
        case .calendar:
            UpcomingEventsWidgetView()
        case .settings:
            SettingsView()
        }
    }
    
    private var expandedBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: NotchConstants.expandedCornerRadius, style: .continuous)
                .fill(Color.black.opacity(0.88))
            
            RoundedRectangle(cornerRadius: NotchConstants.expandedCornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
            
            RoundedRectangle(cornerRadius: NotchConstants.expandedCornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.25),
                            Color.white.opacity(0.05),
                            Color.black.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        }
        .shadow(color: Color.black.opacity(0.5), radius: 24, x: 0, y: 12)
    }
    
    // MARK: - Hover Handlers
    private func handleHover(_ hovering: Bool) {
        isHovering = hovering
        guard prefs.alwaysOpenOnHover else { return }
        
        if hovering {
            autoCloseTimer?.invalidate()
            autoCloseTimer = nil
            
            if !windowManager.isExpanded {
                hoverTimer?.invalidate()
                hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { _ in
                    if self.isHovering && !self.windowManager.isExpanded {
                        withAnimation(.spring(response: NotchConstants.springResponse, dampingFraction: NotchConstants.springDamping)) {
                            self.windowManager.expand()
                        }
                    }
                }
            }
        } else {
            hoverTimer?.invalidate()
            hoverTimer = nil
            
            if windowManager.isExpanded {
                autoCloseTimer?.invalidate()
                autoCloseTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { _ in
                    if !self.isHovering && self.windowManager.isExpanded {
                        withAnimation(.spring(response: NotchConstants.springResponse, dampingFraction: NotchConstants.springDamping)) {
                            self.windowManager.collapse()
                        }
                    }
                }
            }
        }
    }
}
