import SwiftUI
import AppKit

public enum NotchViewMode: String, CaseIterable {
    case nook = "Nook"
    case tray = "Tray"
}

public struct NotchContainerView: View {
    @ObservedObject var panelController: NotchPanelController
    @ObservedObject var prefs = UserPreferences.shared
    @ObservedObject var mediaService = MediaRemoteService.shared
    @ObservedObject var shelfManager = DropShelfManager.shared
    @ObservedObject var sysMonitor = SystemMonitorService.shared
    @ObservedObject var timerService = NotchTimerService.shared
    @ObservedObject var cameraService = CameraService.shared
    
    @State private var viewMode: NotchViewMode = .nook
    @State private var showMirrorModal: Bool = false
    
    public init(panelController: NotchPanelController) {
        self.panelController = panelController
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            switch panelController.state {
            case .compact:
                // State 1: Normal Minimal Resting Notch (Image 1)
                compactRestingBar
                    .transition(.opacity)
            case .peek:
                // State 2: On Hover Expanded Peek Pill (Image 2)
                hoverPeekBar
                    .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            case .expanded:
                // State 3: On Click Full Nook Hub (Image 3)
                expandedDropdown
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.96, anchor: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.96, anchor: .top))
                    ))
            }
        }
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
        .onHover { hovering in
            panelController.setHovered(hovering)
        }
    }
    
    // MARK: - State 1: Normal Minimal Resting Notch (Image 1)
    private var compactRestingBar: some View {
        Rectangle()
            .fill(Color.black)
            .frame(width: 170, height: 10)
            .clipShape(NotchShape(earRadius: 4, cornerRadius: 8))
            .contentShape(Rectangle())
            .onTapGesture {
                panelController.toggleExpanded()
            }
    }
    
    // MARK: - State 2: On Hover Expanded Peek Pill (Image 2)
    private var hoverPeekBar: some View {
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
        .padding(.horizontal, 14)
        .frame(width: NotchConstants.defaultCompactWidth, height: NotchConstants.defaultCompactHeight)
        .background(
            NotchShape(earRadius: 6, cornerRadius: 14)
                .fill(Color.black)
                .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 6)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            panelController.toggleExpanded()
        }
    }
    
    // MARK: - State 3: On Click Full Expanded Nook Hub (Image 3)
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
            ZStack {
                NotchShape(earRadius: 12, cornerRadius: 22)
                    .fill(Color.black)
                    .overlay(
                        NotchShape(earRadius: 12, cornerRadius: 22)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                    )
            }
            .shadow(color: Color.black.opacity(0.32), radius: 28, x: 0, y: 14)
            .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 4)
        )
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
                            NSWorkspace.shared.launchApplication("Music")
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
                            NSWorkspace.shared.launchApplication("VLC")
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
                            NSWorkspace.shared.launchApplication("Spotify")
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
}
