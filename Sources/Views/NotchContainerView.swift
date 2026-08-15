import SwiftUI
import AppKit

public enum NotchViewMode: String, CaseIterable {
    case nook = "Nook"
    case tray = "Tray"
    case bt = "BT"
}

public struct NotchContainerView: View {
    @ObservedObject var panelController: NotchPanelController
    @ObservedObject var prefs = UserPreferences.shared
    @ObservedObject var mediaService = MediaRemoteService.shared
    @ObservedObject var shelfManager = DropShelfManager.shared
    @ObservedObject var sysMonitor = SystemMonitorService.shared
    @ObservedObject var timerService = NotchTimerService.shared
    @ObservedObject var cameraService = CameraService.shared
    @ObservedObject var btService = BluetoothService.shared
    
    @State private var viewMode: NotchViewMode = .nook
    @State private var showMirrorModal: Bool = false
    @State private var isCompactMediaHovered: Bool = false
    @State private var isPeekMediaHovered: Bool = false
    
    public init(panelController: NotchPanelController) {
        self.panelController = panelController
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            // Fluidly Morphing Background Shape
            NotchShape(earRadius: currentEarRadius, cornerRadius: currentCornerRadius)
                .fill(prefs.translucentNotchBackground ? Color.black.opacity(0.75) : Color.black)
                .overlay(
                    NotchShape(earRadius: currentEarRadius, cornerRadius: currentCornerRadius)
                        .stroke(Color.white.opacity(panelController.state == .expanded ? 0.08 : 0.0), lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(shadowOpacity1), radius: shadowRadius1, x: 0, y: shadowY1)
                .shadow(color: Color.black.opacity(shadowOpacity2), radius: shadowRadius2, x: 0, y: shadowY2)
                .frame(width: currentWidth, height: currentHeight)
                
            // Inner Content
            Group {
                switch panelController.state {
                case .compact:
                    if mediaService.currentTrack.isPlaying {
                        HStack {
                            Spacer()
                            Button(action: {
                                mediaService.togglePlayPause()
                            }) {
                                if isCompactMediaHovered {
                                    Image(systemName: "pause.fill")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(.white)
                                } else {
                                    AudioVisualizerView()
                                }
                            }
                            .frame(width: 24, height: currentHeight)
                            .contentShape(Rectangle())
                            .buttonStyle(.plain)
                            .onHover { hovering in
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    isCompactMediaHovered = hovering
                                }
                            }
                            .padding(.trailing, 8)
                        }
                        .frame(width: currentWidth, height: currentHeight)
                        .transition(.opacity)
                    } else {
                        Color.clear
                            .frame(width: currentWidth, height: currentHeight)
                    }
                case .peek:
                    hoverPeekBar
                        .transition(.opacity)
                case .expanded:
                    expandedDropdown
                        .transition(.opacity)
                }
            }
            .frame(width: currentWidth, height: currentHeight, alignment: .top)
        }
        .contentShape(Rectangle()) // Make the whole frame clickable
        .onTapGesture {
            if panelController.state == .compact || panelController.state == .peek {
                panelController.toggleExpanded()
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.72, blendDuration: 0), value: panelController.state)
        .animation(.spring(response: 0.45, dampingFraction: 0.72, blendDuration: 0), value: mediaService.currentTrack.isPlaying)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea()
        .contextMenu {
            // Right-Click Context Menu (Image 4)
            Button(action: {
                SettingsWindowManager.shared.openSettings()
            }) {
                Label("Open Settings", systemImage: "gearshape")
            }
            
            Divider()
            
            Button(action: {
                NSApp.terminate(nil)
            }) {
                Label("Quit OpenNotch", systemImage: "power")
            }
        }
    }
    
    // MARK: - Dynamic Shape Properties for Morphing
    
    private var currentWidth: CGFloat {
        let base: CGFloat
        switch panelController.state {
        case .compact: base = mediaService.currentTrack.isPlaying ? 210 : 170
        case .peek: base = NotchConstants.defaultCompactWidth
        case .expanded: base = CGFloat(prefs.expandedWidth)
        }
        return max(100, base + CGFloat(prefs.notchWidthOffset))
    }
    
    private var currentHeight: CGFloat {
        let base: CGFloat
        switch panelController.state {
        case .compact: base = 10
        case .peek: base = NotchConstants.defaultCompactHeight
        case .expanded: base = CGFloat(prefs.expandedHeight)
        }
        return max(8, base + CGFloat(prefs.notchHeightOffset))
    }
    
    private var currentEarRadius: CGFloat {
        switch panelController.state {
        case .compact: return 5
        case .peek: return 8
        case .expanded: return 14
        }
    }
    
    private var currentCornerRadius: CGFloat {
        switch panelController.state {
        case .compact: return 5
        case .peek: return 14
        case .expanded: return 24
        }
    }
    
    private var shadowOpacity1: Double {
        switch panelController.state {
        case .compact: return 0.0
        case .peek: return 0.40
        case .expanded: return 0.35
        }
    }
    
    private var shadowRadius1: CGFloat {
        switch panelController.state {
        case .compact: return 0
        case .peek: return 14
        case .expanded: return 28
        }
    }
    
    private var shadowY1: CGFloat {
        switch panelController.state {
        case .compact: return 0
        case .peek: return 7
        case .expanded: return 14
        }
    }
    
    private var shadowOpacity2: Double {
        switch panelController.state {
        case .compact: return 0.0
        case .peek: return 0.0
        case .expanded: return 0.18
        }
    }
    
    private var shadowRadius2: CGFloat {
        switch panelController.state {
        case .compact: return 0
        case .peek: return 0
        case .expanded: return 10
        }
    }
    
    private var shadowY2: CGFloat {
        switch panelController.state {
        case .compact: return 0
        case .peek: return 0
        case .expanded: return 4
        }
    }
    
    // MARK: - State 1: Normal Minimal Resting Notch (Image 1)
    // Handled by the shared ZStack background
    
    // MARK: - State 2: On Hover Expanded Peek Pill (Image 2)
    private var hoverPeekBar: some View {
        HStack(spacing: 8) {
            if timerService.isRunning {
                // Live Timer
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.orange)
                    Text(timerService.displayString)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }
                Spacer()
                Button("Stop") {
                    timerService.pause()
                }
                .font(.system(size: 9, weight: .bold))
                .buttonStyle(.plain)
                .foregroundStyle(.orange)
            } else if mediaService.currentTrack.isPlaying || !mediaService.currentTrack.title.isEmpty {
                // Live Media Playing
                HStack(spacing: 5) {
                    Image(systemName: "music.note")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.85))
                    Text(mediaService.currentTrack.title)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.95))
                        .lineLimit(1)
                        .frame(maxWidth: 100, alignment: .leading)
                }
                
                Spacer()
                
                Button(action: {
                    mediaService.togglePlayPause()
                }) {
                    if isPeekMediaHovered {
                        Image(systemName: mediaService.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    } else {
                        if mediaService.currentTrack.isPlaying {
                            AudioVisualizerView()
                        } else {
                            Image(systemName: "play.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isPeekMediaHovered = hovering
                    }
                }
            } else {
                // Idle Hover State Configured from Settings
                switch prefs.hoverPeekStyle {
                case .liveActivities, .clockDate:
                    LiveClockView()
                    Spacer()
                    LiveDateView()
                    
                case .systemStats:
                    HStack(spacing: 4) {
                        Image(systemName: "cpu")
                            .font(.system(size: 9))
                            .foregroundStyle(.cyan)
                        Text(String(format: "CPU %.0f%%", sysMonitor.stats.cpuUsagePercentage))
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    Spacer()
                    if let firstBt = btService.connectedDevices.first, let batt = firstBt.displayBattery {
                        HStack(spacing: 3) {
                            Image(systemName: firstBt.deviceType.iconName)
                                .font(.system(size: 9))
                            Text("\(batt)%")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                        }
                        .foregroundStyle(.green)
                    } else {
                        LiveClockView()
                    }
                    
                case .quickShortcuts:
                    HStack(spacing: 10) {
                        Button(action: {
                            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Music") {
                                NSWorkspace.shared.openApplication(at: url, configuration: .init())
                            }
                        }) {
                            Image(systemName: "music.note")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.spotify.client") {
                                NSWorkspace.shared.openApplication(at: url, configuration: .init())
                            }
                        }) {
                            Image(systemName: "dot.radiowaves.left.and.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.green)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            if let url = URL(string: "https://youtube.com") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            Image(systemName: "play.rectangle.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Button(action: {
                            SettingsWindowManager.shared.openSettings()
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.white.opacity(0.65))
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                    
                case .minimal:
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 9))
                            .foregroundStyle(.purple)
                        Text("Click to Open")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    Spacer()
                    LiveClockView()
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(width: NotchConstants.defaultCompactWidth, height: NotchConstants.defaultCompactHeight)
    }
    
    // MARK: - State 3: On Click Full Expanded Nook Hub (Image 3)
    private var expandedDropdown: some View {
        VStack(spacing: 8) {
            // Top Bar: [🪄 Nook | 📦 Tray | ᛒ BT] ................ [⚙️]
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
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            viewMode = .bt
                        }
                    }) {
                        HStack(spacing: 5) {
                            BluetoothIconView(size: 10)
                            Text("BT")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(viewMode == .bt ? Color.white : Color.white.opacity(0.40))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.leading, 18)
                
                Spacer()
                
                // Settings Gear Icon
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
            .frame(height: 18)
            .padding(.top, 6)
            
            // Dropdown Content
            ZStack(alignment: .top) {
                if viewMode == .nook {
                    nookContentView
                } else if viewMode == .tray {
                    trayContentView
                } else {
                    bluetoothContentView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
        .frame(width: currentWidth, height: currentHeight, alignment: .top)
    }
    
    // MARK: - Nook Mode (Image 3 Left Media Hub & Quick Launcher)
    private var nookContentView: some View {
        HStack(spacing: 16) {
            // Left: Media Player / Quick App Launcher
            if mediaService.currentTrack.isPlaying {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 10) {
                        Image(systemName: "music.note")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.85))
                            .frame(width: 36, height: 36)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mediaService.currentTrack.title)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.white)
                                .lineLimit(1)
                            
                            HStack(spacing: 6) {
                                Button(action: {
                                    mediaService.togglePlayPause()
                                }) {
                                    if isPeekMediaHovered {
                                        Image(systemName: mediaService.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(.white)
                                    } else {
                                        if mediaService.currentTrack.isPlaying {
                                            AudioVisualizerView()
                                        } else {
                                            Image(systemName: "pause.fill")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundStyle(.white.opacity(0.5))
                                        }
                                    }
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
            } else {
                // "No app seems to be running. Wanna open one?" (Exact Image 3)
                VStack(spacing: 4) {
                    Text("No app seems to be running.")
                        .font(.system(size: 9, weight: .regular))
                        .foregroundStyle(Color.white.opacity(0.6))
                    
                    Text("Wanna open one?")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.white)
                    
                    HStack(spacing: 8) {
                        // Apple Music
                        Button(action: {
                            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Music") {
                                NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
                            }
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(LinearGradient(colors: [Color.pink, Color.red], startPoint: .top, endPoint: .bottom))
                                    .frame(width: 24, height: 24)
                                Image(systemName: "music.note")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        .help("Launch Music")
                        
                        // VLC
                        Button(action: {
                            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "org.videolan.vlc") {
                                NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
                            }
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(LinearGradient(colors: [Color.orange, Color.orange.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                                    .frame(width: 24, height: 24)
                                Image(systemName: "cone.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        .help("Launch VLC")
                        
                        // YouTube
                        Button(action: {
                            if let url = URL(string: "https://youtube.com") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.red)
                                    .frame(width: 24, height: 24)
                                Image(systemName: "play.rectangle.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        .help("Open YouTube")
                        
                        // Spotify
                        Button(action: {
                            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.spotify.client") {
                                NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
                            }
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.green)
                                    .frame(width: 24, height: 24)
                                Image(systemName: "dot.radiowaves.left.and.right")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.black)
                            }
                        }
                        .buttonStyle(.plain)
                        .help("Launch Spotify")
                    }
                    .padding(.top, 2)
                }
                .frame(maxWidth: 190)
            }
            
            if prefs.showDividersBetweenWidgets {
                Divider()
                    .background(Color.white.opacity(0.12))
            }
            
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
            
            if prefs.showDividersBetweenWidgets {
                Divider()
                    .background(Color.white.opacity(0.12))
            }
            
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
    
    // MARK: - Tray Mode
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
    
    // MARK: - Bluetooth Tab
    private var bluetoothContentView: some View {
        VStack(spacing: 6) {
            if btService.devices.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "antenna.radiowaves.left.and.right.slash")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.white.opacity(0.75))
                    
                    Text("No Paired Bluetooth Devices")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.white)
                    
                    Button(action: {
                        btService.openBluetoothSettings()
                    }) {
                        Text("Open Bluetooth Settings")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.white.opacity(0.15)))
                            .foregroundStyle(Color.white)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 6)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(btService.devices) { device in
                            BluetoothDeviceCard(device: device) {
                                btService.toggleConnection(for: device)
                            }
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(.horizontal, 10)
    }
}

struct BluetoothDeviceCard: View {
    let device: BluetoothDeviceInfo
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(device.isConnected ? Color.blue.opacity(0.25) : Color.white.opacity(0.08))
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: device.deviceType.iconName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(device.isConnected ? Color.blue : Color.white.opacity(0.7))
                }
                
                Spacer()
                
                // Connection indicator dot
                Circle()
                    .fill(device.isConnected ? Color.green : Color.white.opacity(0.25))
                    .frame(width: 6, height: 6)
                    .shadow(color: device.isConnected ? Color.green.opacity(0.8) : Color.clear, radius: 3)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .frame(maxWidth: 110, alignment: .leading)
                
                HStack(spacing: 4) {
                    if let batt = device.displayBattery {
                        HStack(spacing: 3) {
                            Image(systemName: batteryIcon(for: batt))
                                .font(.system(size: 8))
                            Text("\(batt)%")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                        }
                        .foregroundStyle(batt > 20 ? Color.green : Color.orange)
                    } else if device.isConnected {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 8))
                            Text("Connected")
                                .font(.system(size: 9, weight: .semibold))
                        }
                        .foregroundStyle(Color.green.opacity(0.9))
                    } else {
                        Text("Not Connected")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.4))
                    }
                }
            }
            
            Button(action: onToggle) {
                Text(device.isConnected ? "Disconnect" : "Connect")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(device.isConnected ? Color.white.opacity(0.8) : Color.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .frame(maxWidth: .infinity)
                    .background(
                        Capsule().fill(device.isConnected ? Color.white.opacity(0.12) : Color.blue.opacity(0.6))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .frame(width: 125, height: 95)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(device.isConnected ? Color.blue.opacity(0.35) : Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    private func batteryIcon(for level: Int) -> String {
        if level > 80 { return "battery.100" }
        if level > 50 { return "battery.75" }
        if level > 25 { return "battery.50" }
        return "battery.25"
    }
}

struct AudioVisualizerView: View {
    @ObservedObject var mediaService = MediaRemoteService.shared
    
    var body: some View {
        HStack(spacing: 1.5) {
            ForEach(0..<4) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.green)
                    .frame(width: 2, height: max(2, 10 * mediaService.visualizerLevels[index]))
                    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: mediaService.visualizerLevels[index])
            }
        }
        .frame(height: 10)
    }
}

struct BluetoothIconShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        let centerX = rect.midX
        let leftX = rect.minX + w * 0.15
        let rightX = rect.maxX - w * 0.15
        let topY = rect.minY + h * 0.05
        let bottomY = rect.maxY - h * 0.05
        let upperY = rect.minY + h * 0.26
        let lowerY = rect.maxY - h * 0.26
        
        path.move(to: CGPoint(x: leftX, y: upperY))
        path.addLine(to: CGPoint(x: rightX, y: lowerY))
        path.addLine(to: CGPoint(x: centerX, y: bottomY))
        path.addLine(to: CGPoint(x: centerX, y: topY))
        path.addLine(to: CGPoint(x: rightX, y: upperY))
        path.addLine(to: CGPoint(x: leftX, y: lowerY))
        
        return path
    }
}

struct BluetoothIconView: View {
    var size: CGFloat = 11
    
    var body: some View {
        if let nsImg = NSImage(named: "NSBluetoothTemplate") {
            Image(nsImage: nsImg)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size * 1.25)
        } else {
            BluetoothIconShape()
                .stroke(style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))
                .frame(width: size, height: size * 1.25)
        }
    }
}

struct LiveClockView: View {
    @State private var timeString: String = ""
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock.fill")
                .font(.system(size: 9))
                .foregroundStyle(Color.white.opacity(0.8))
            Text(timeString.isEmpty ? currentTime : timeString)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white)
        }
        .onReceive(timer) { _ in
            timeString = currentTime
        }
    }
    
    private var currentTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
}

struct LiveDateView: View {
    var body: some View {
        Text(currentDate)
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .foregroundStyle(Color.white.opacity(0.75))
    }
    
    private var currentDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: Date())
    }
}
