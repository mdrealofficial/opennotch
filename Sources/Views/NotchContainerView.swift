import SwiftUI
import AppKit

public enum NotchViewMode: String, CaseIterable {
    case nook = "Nook"
    case tray = "Tray"
}

public struct NotchContainerView: View {
    @ObservedObject var windowManager: NotchWindowManager
    @ObservedObject var prefs = UserPreferences.shared
    @ObservedObject var mediaService = MediaRemoteService.shared
    @ObservedObject var shelfManager = DropShelfManager.shared
    @ObservedObject var sysMonitor = SystemMonitorService.shared
    @ObservedObject var timerService = NotchTimerService.shared
    @ObservedObject var cameraService = CameraService.shared
    
    @State private var viewMode: NotchViewMode = .nook
    @State private var isHovering: Bool = false
    @State private var hoverTimer: Timer?
    @State private var autoCloseTimer: Timer?
    @State private var showMirrorModal: Bool = false
    
    public init(windowManager: NotchWindowManager) {
        self.windowManager = windowManager
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            if windowManager.isExpanded {
                expandedDropdown
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.97, anchor: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.97, anchor: .top))
                    ))
            } else {
                compactNotchBar
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: NotchConstants.springResponse, dampingFraction: NotchConstants.springDamping), value: windowManager.isExpanded)
        .onHover { hovering in
            handleHover(hovering)
        }
    }
    
    // MARK: - 1. Compact Notch Bar (Resting attached to MacBook Notch)
    private var compactNotchBar: some View {
        HStack(spacing: 8) {
            // Left Live Status
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
                        .foregroundStyle(.white.opacity(0.9))
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
            
            // Right Live Status
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
        .padding(.horizontal, 16)
        .frame(width: NotchConstants.defaultCompactWidth, height: NotchConstants.defaultCompactHeight)
        .background(
            NotchShape(earRadius: 6, cornerRadius: NotchConstants.notchCornerRadius)
                .fill(Color.black)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: NotchConstants.springResponse, dampingFraction: NotchConstants.springDamping)) {
                windowManager.toggleExpanded()
            }
        }
    }
    
    // MARK: - 2. Expanded Notch Dropdown (Exact NotchNook Organic Shape & Layout)
    private var expandedDropdown: some View {
        VStack(spacing: 6) {
            // Top Bar: [🪄 Nook | 📦 Tray] ................ [⚙️]
            HStack {
                HStack(spacing: 12) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            viewMode = .nook
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "lamp.desk.fill")
                                .font(.system(size: 11))
                            Text("Nook")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(viewMode == .nook ? Color.white : Color.white.opacity(0.40))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            viewMode = .tray
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "tray.fill")
                                .font(.system(size: 11))
                            Text("Tray")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(viewMode == .tray ? Color.white : Color.white.opacity(0.40))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.leading, 18)
                
                Spacer()
                
                // Settings Gear Icon (Opens Dedicated Settings Window)
                Button(action: {
                    SettingsWindowManager.shared.openSettings()
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.65))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 18)
                .help("Open Settings")
            }
            .padding(.top, 6)
            
            // Dropdown Content
            if viewMode == .nook {
                nookContentView
            } else {
                trayContentView
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
        .frame(width: NotchConstants.defaultExpandedWidth, height: NotchConstants.defaultExpandedHeight)
        .background(
            NotchShape(earRadius: 12, cornerRadius: NotchConstants.expandedCornerRadius)
                .fill(Color.black)
                .shadow(color: Color.black.opacity(0.7), radius: 24, x: 0, y: 12)
        )
    }
    
    // MARK: - Nook Mode (3-Section Layout: Media | Shortcuts | Mirror)
    private var nookContentView: some View {
        HStack(spacing: 16) {
            // Left: Media Player
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Image(systemName: mediaService.currentTrack.isPlaying ? "music.note" : "waveform")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .frame(width: 36, height: 36)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(mediaService.currentTrack.title.isEmpty || mediaService.currentTrack.title == "No Media Playing" ? "Apple Music" : mediaService.currentTrack.title)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white)
                            .lineLimit(1)
                        
                        HStack(spacing: 6) {
                            Button(action: {
                                mediaService.togglePlayPause()
                            }) {
                                Image(systemName: mediaService.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                mediaService.nextTrack()
                            }) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Track Timeline Slider
                VStack(spacing: 2) {
                    ProgressView(value: min(1.0, max(0.0, mediaService.currentTrack.duration > 0 ? mediaService.currentTrack.position / mediaService.currentTrack.duration : 0.35)))
                        .progressViewStyle(.linear)
                        .tint(.white)
                    
                    HStack {
                        Text("0:14")
                        Spacer()
                        Text("0:25")
                    }
                    .font(.system(size: 8, weight: .regular, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                }
            }
            .frame(maxWidth: 190, alignment: .leading)
            
            Divider()
                .background(Color.white.opacity(0.12))
            
            // Middle: Shortcuts / Actions
            VStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.white.opacity(0.85))
                
                Text("Choose your shortcuts\nin settings.")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    SettingsWindowManager.shared.openSettings()
                }) {
                    Text("Choose Shortcuts")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.white.opacity(0.15)))
                        .foregroundStyle(Color.white)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: 170)
            
            Divider()
                .background(Color.white.opacity(0.12))
            
            // Right: Circular Mirror / Action Button
            VStack(spacing: 4) {
                Button(action: {
                    showMirrorModal.toggle()
                    if showMirrorModal {
                        cameraService.startSession()
                    } else {
                        cameraService.stopSession()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 58, height: 58)
                        
                        if showMirrorModal && cameraService.hasPermission {
                            CameraPreviewView()
                                .frame(width: 58, height: 58)
                                .clipShape(Circle())
                        } else {
                            VStack(spacing: 2) {
                                Image(systemName: "video.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color.white)
                                
                                Text("Mirror")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(Color.white.opacity(0.8))
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: 90)
        }
        .padding(.horizontal, 10)
        .padding(.top, 2)
    }
    
    // MARK: - Tray Mode (Photo 4 Exact Layout)
    private var trayContentView: some View {
        VStack(spacing: 8) {
            if shelfManager.files.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "tray.and.arrow.down.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(Color.white.opacity(0.75))
                    
                    Text("Files Tray")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.white)
                    
                    Text("Drag and drop files here to stash them")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(shelfManager.files) { file in
                            StashedFileCard(file: file) {
                                shelfManager.removeFile(id: file.id)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(.horizontal, 10)
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
