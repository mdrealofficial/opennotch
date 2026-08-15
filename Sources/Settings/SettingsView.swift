import SwiftUI

public enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "General"
    case gestures = "Gestures"
    case liveActivities = "Live Activities"
    case nook = "Nook"
    case tray = "Tray"
    case dropArea = "Drop Area"
    case license = "License"
    case about = "About"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .general: return "gearshape.fill"
        case .gestures: return "hand.tap.fill"
        case .liveActivities: return "clock.badge.checkmark.fill"
        case .nook: return "lamp.desk.fill"
        case .tray: return "square.dashed"
        case .dropArea: return "rectangle.and.hand.point.up.left.fill"
        case .license: return "key.fill"
        case .about: return "ellipsis.circle.fill"
        }
    }
}

public struct SettingsView: View {
    @ObservedObject var prefs = UserPreferences.shared
    @State private var activeTab: SettingsTab = .general
    @State private var liveActivitiesSubtab: Int = 0 // 0 = General, 1 = Customize
    @State private var nookSubtab: Int = 0 // 0 = General, 1 = Customize
    @State private var selectedActivity: String = "Media"
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // MARK: - Native Header Toolbar
            HStack(spacing: 12) {
                ForEach(SettingsTab.allCases) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.12)) {
                            activeTab = tab
                        }
                    }) {
                        VStack(spacing: 3) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 16))
                                .foregroundStyle(activeTab == tab ? Color.blue : Color.white.opacity(0.6))
                            
                            Text(tab.rawValue)
                                .font(.system(size: 10, weight: activeTab == tab ? .semibold : .regular))
                                .foregroundStyle(activeTab == tab ? Color.white : Color.white.opacity(0.7))
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(activeTab == tab ? Color.white.opacity(0.12) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 6)
            
            Divider()
                .background(Color.white.opacity(0.15))
            
            // MARK: - Tab Body
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 14) {
                    switch activeTab {
                    case .general:
                        generalTabContent
                    case .gestures:
                        gesturesTabContent
                    case .liveActivities:
                        liveActivitiesTabContent
                    case .nook:
                        nookTabContent
                    case .tray:
                        trayTabContent
                    case .dropArea:
                        dropAreaTabContent
                    case .license:
                        licenseTabContent
                    case .about:
                        aboutTabContent
                    }
                }
                .padding(12)
            }
            .frame(maxHeight: 180)
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - 1. General Tab
    private var generalTabContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Launch at login", isOn: Binding(
                get: { prefs.launchAtLogin },
                set: { prefs.toggleLaunchAtLogin($0) }
            ))
            
            Divider().background(Color.white.opacity(0.1))
            
            HStack {
                Text("Show in fullscreen:")
                    .frame(width: 140, alignment: .trailing)
                Picker("", selection: $prefs.fullscreenVisibilityRaw) {
                    ForEach(FullscreenVisibilityOption.allCases) { opt in
                        Text(opt.rawValue).tag(opt.rawValue)
                    }
                }
                .frame(width: 180)
            }
            
            HStack {
                Text("Media source:")
                    .frame(width: 140, alignment: .trailing)
                Picker("", selection: $prefs.mediaSourceRaw) {
                    ForEach(MediaSourceOption.allCases) { opt in
                        Text(opt.rawValue).tag(opt.rawValue)
                    }
                }
                .frame(width: 180)
            }
            
            // Notch Toggles
            VStack(alignment: .leading, spacing: 6) {
                Toggle("Prefer round buttons", isOn: $prefs.preferRoundButtons)
                Text("Use capsules instead of rounded rectangles for buttons.")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.leading, 20)
                
                Toggle("Translucent notch background (experimental)", isOn: $prefs.translucentNotchBackground)
                Toggle("Always open on hover", isOn: $prefs.alwaysOpenOnHover)
                Toggle("Disable haptics", isOn: $prefs.disableHaptics)
            }
            .padding(.leading, 60)
            
            // Content Padding Slider
            HStack {
                Text("Content padding:")
                    .frame(width: 140, alignment: .trailing)
                Slider(value: $prefs.contentPadding, in: 4...24, step: 1)
                    .tint(.blue)
                Text("\(Int(prefs.contentPadding))")
                    .frame(width: 30)
            }
            
            // Notch Fine Tune
            VStack(alignment: .leading, spacing: 4) {
                Text("Notch fine tune: (Offsets width & height)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                
                HStack {
                    Text("Width:")
                        .frame(width: 60, alignment: .trailing)
                    Slider(value: $prefs.notchWidthOffset, in: -40...40, step: 2)
                        .tint(.blue)
                    Text("\(Int(prefs.notchWidthOffset))")
                        .frame(width: 30)
                }
                HStack {
                    Text("Height:")
                        .frame(width: 60, alignment: .trailing)
                    Slider(value: $prefs.notchHeightOffset, in: -20...20, step: 1)
                        .tint(.blue)
                    Text("\(Int(prefs.notchHeightOffset))")
                        .frame(width: 30)
                }
            }
            .padding(.leading, 60)
            
            Divider().background(Color.white.opacity(0.1))
            
            // Handler (No-Notch Screens)
            VStack(alignment: .leading, spacing: 6) {
                Toggle("Enable Handler (no-notch screens)", isOn: $prefs.enableHandlerNoNotch)
                
                HStack {
                    Text("Width:")
                        .frame(width: 60, alignment: .trailing)
                    Slider(value: $prefs.handlerWidth, in: 100...300, step: 4)
                        .tint(.blue)
                    Text("\(Int(prefs.handlerWidth))")
                        .frame(width: 30)
                }
                HStack {
                    Text("Height:")
                        .frame(width: 60, alignment: .trailing)
                    Slider(value: $prefs.handlerHeight, in: 4...20, step: 1)
                        .tint(.blue)
                    Text("\(Int(prefs.handlerHeight))")
                        .frame(width: 30)
                }
                
                Toggle("Transparent handler", isOn: $prefs.transparentHandler)
            }
            .padding(.leading, 60)
            
            Divider().background(Color.white.opacity(0.1))
            
            HStack(spacing: 12) {
                Button("Reset all settings") {
                    prefs.resetAllSettings()
                }
                .controlSize(.small)
                
                Button("Quit OpenNotch") {
                    NSApp.terminate(nil)
                }
                .controlSize(.small)
            }
            .padding(.leading, 60)
        }
        .font(.system(size: 11))
        .foregroundStyle(.white)
    }
    
    // MARK: - 2. Gestures Tab
    private var gesturesTabContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Allow gestures when hovering the notch", isOn: $prefs.allowHoverGestures)
            Toggle("Open/close notch with vertical gestures", isOn: $prefs.verticalGestureOpenClose)
            Toggle("Control media with horizontal gestures", isOn: $prefs.horizontalGestureMedia)
            Toggle("Invert media gestures actions", isOn: $prefs.invertMediaGestures)
            
            Text("If on, a left swipe will start the next song; if off, the previous one.")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.leading, 20)
        }
        .font(.system(size: 11))
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
    }
    
    // MARK: - 3. Live Activities Tab
    private var liveActivitiesTabContent: some View {
        VStack(spacing: 10) {
            Picker("", selection: $liveActivitiesSubtab) {
                Text("General").tag(0)
                Text("Customize activities").tag(1)
            }
            .pickerStyle(.segmented)
            .frame(width: 260)
            
            if liveActivitiesSubtab == 0 {
                // Live Activities General
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Enable live activities", isOn: $prefs.enableLiveActivities)
                    Toggle("Hide in non notched screens", isOn: $prefs.hideInNonNotchedScreens)
                    
                    HStack {
                        Text("Inactivity timeout:")
                        Slider(value: $prefs.inactivityTimeout, in: 2...30, step: 1)
                            .tint(.blue)
                        Text("\(Int(prefs.inactivityTimeout))s")
                    }
                    
                    Toggle("Enable interactive activities", isOn: $prefs.enableInteractiveActivities)
                    Toggle("Enable Quick Peek", isOn: $prefs.enableQuickPeek)
                    Toggle("Unhide Automatically", isOn: $prefs.unhideAutomatically)
                    Toggle("Show song change", isOn: $prefs.showSongChange)
                    
                    Text("Show in fullscreen:")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.top, 4)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                        Toggle("🎵 Media", isOn: $prefs.fullscreenMedia)
                        Toggle("📦 Files Tray", isOn: $prefs.fullscreenFilesTray)
                        Toggle("📅 Calendar", isOn: $prefs.fullscreenCalendar)
                        Toggle("⬇️ New Update", isOn: $prefs.fullscreenNewUpdate)
                        Toggle("🎧 Bluetooth", isOn: $prefs.fullscreenBluetooth)
                        Toggle("⚡️ Battery", isOn: $prefs.fullscreenBattery)
                        Toggle("⏱️ Timer Ended", isOn: $prefs.fullscreenTimerEnded)
                    }
                }
            } else {
                // Live Activities Customize
                HStack(alignment: .top, spacing: 14) {
                    // Left sidebar of activities
                    VStack(alignment: .leading, spacing: 4) {
                        ActivityRow(name: "Media", icon: "music.note", isSelected: selectedActivity == "Media") {
                            selectedActivity = "Media"
                        }
                        ActivityRow(name: "Files Tray", icon: "tray.fill", isSelected: selectedActivity == "Files Tray") {
                            selectedActivity = "Files Tray"
                        }
                        ActivityRow(name: "Calendar", icon: "calendar", isSelected: selectedActivity == "Calendar") {
                            selectedActivity = "Calendar"
                        }
                        ActivityRow(name: "Bluetooth", icon: "airpodspro", isSelected: selectedActivity == "Bluetooth") {
                            selectedActivity = "Bluetooth"
                        }
                        ActivityRow(name: "Battery", icon: "bolt.fill", isSelected: selectedActivity == "Battery") {
                            selectedActivity = "Battery"
                        }
                    }
                    .frame(width: 120)
                    
                    // Right detail editor
                    VStack(alignment: .leading, spacing: 8) {
                        // Live Notch Preview Canvas
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue.opacity(0.7))
                                .frame(height: 50)
                            
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(.purple)
                                Capsule()
                                    .fill(Color.black)
                                    .frame(width: 140, height: 24)
                                    .overlay(
                                        HStack {
                                            Image(systemName: "music.note")
                                                .font(.system(size: 8))
                                            Spacer()
                                            VisualizerBarView(levels: [0.3, 0.7, 0.4], barColor: .green)
                                        }
                                        .padding(.horizontal, 8)
                                    )
                            }
                        }
                        
                        HStack {
                            Text("Album corner radius:")
                            Slider(value: $prefs.albumCornerRadius, in: 0...14, step: 1)
                                .tint(.blue)
                            Text("\(Int(prefs.albumCornerRadius))")
                        }
                        
                        Picker("Effect type:", selection: $prefs.visualizerEffectRaw) {
                            ForEach(LiveVisualizerEffect.allCases) { eff in
                                Text(eff.rawValue).tag(eff.rawValue)
                            }
                        }
                        
                        Toggle("Colored effects", isOn: $prefs.coloredEffects)
                    }
                }
            }
        }
        .font(.system(size: 11))
        .foregroundStyle(.white)
    }
    
    // MARK: - 4. Nook Tab
    private var nookTabContent: some View {
        VStack(spacing: 10) {
            Picker("", selection: $nookSubtab) {
                Text("General").tag(0)
                Text("Customize widgets").tag(1)
            }
            .pickerStyle(.segmented)
            .frame(width: 260)
            
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Enable nook", isOn: $prefs.enableNook)
                Text("If disabled, clicking on the notch won't do anything.")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.leading, 20)
                
                Toggle("Show dividers between widgets", isOn: $prefs.showDividersBetweenWidgets)
            }
            .font(.system(size: 11))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - 5. Tray Tab
    private var trayTabContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("File Tray & Drop Shelf Settings")
                .font(.system(size: 12, weight: .bold))
            Toggle("Enable Drop Shelf in Nook", isOn: .constant(true))
            Toggle("Auto-clear completed transfers", isOn: .constant(false))
            Toggle("Show file size previews", isOn: .constant(true))
        }
        .font(.system(size: 11))
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
    }
    
    // MARK: - 6. Drop Area Tab
    @State private var dropAreaSubtab: Int = 0
    
    private var dropAreaTabContent: some View {
        VStack(spacing: 12) {
            Picker("", selection: $dropAreaSubtab) {
                Text("General").tag(0)
                Text("Customize pipelines").tag(1)
            }
            .pickerStyle(.segmented)
            .frame(width: 260)
            
            if dropAreaSubtab == 0 {
                HStack {
                    Text("Width:")
                        .frame(width: 60, alignment: .trailing)
                    Slider(value: $prefs.dropAreaWidth, in: 4...40, step: 1)
                        .tint(.blue)
                    Text("\(Int(prefs.dropAreaWidth))")
                        .frame(width: 30)
                }
                .padding(.horizontal, 40)
                .padding(.top, 10)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Configured Drop Pipelines:")
                        .font(.system(size: 11, weight: .bold))
                    Text("• AirDrop Stash & Hold")
                    Text("• Quick Share to Terminal / Git")
                    Text("• File Hash & Size Calculator")
                }
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal, 40)
                .padding(.top, 6)
            }
        }
        .font(.system(size: 11))
        .foregroundStyle(.white)
    }
    
    // MARK: - 7. License Tab
    private var licenseTabContent: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 28))
                .foregroundStyle(.green)
            
            Text("100% Free & Open-Source (MIT)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
            
            Text("OpenNotch is community-owned software. No subscription or license key needed.")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(8)
    }
    
    // MARK: - 8. About Tab
    private var aboutTabContent: some View {
        VStack(spacing: 12) {
            // Header Row
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.black, Color.purple.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 54, height: 54)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    
                    Text("◡̈")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("OpenNotch")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        Button("Check for Updates...") {
                            if let url = URL(string: "https://github.com/mdrealofficial/opennotch/releases/latest") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .controlSize(.small)
                    }
                    
                    Text("v1.0.0 (see changelog)")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.6))
                    
                    HStack(spacing: 16) {
                        Toggle("Auto download updates", isOn: $prefs.autoDownloadUpdates)
                        Toggle("Auto check for updates", isOn: $prefs.autoCheckUpdates)
                    }
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 10)
            
            Divider().background(Color.white.opacity(0.12))
            
            // Community Statement
            VStack(spacing: 4) {
                Text("OpenNotch is crafted by")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.6))
                
                Text("the Dev Community")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .purple.opacity(0.5), radius: 10, x: 0, y: 0)
                
                Text("A global group of passionate developers building amazing free software for macOS together.")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            // Link Pills
            HStack(spacing: 8) {
                LinkButton(title: "GitHub Repo", icon: "globe", urlString: "https://github.com/mdrealofficial/opennotch")
                LinkButton(title: "Discussions", icon: "bubble.left.and.bubble.right.fill", urlString: "https://github.com/mdrealofficial/opennotch/discussions")
                LinkButton(title: "MIT License", icon: "doc.text.fill", urlString: "https://github.com/mdrealofficial/opennotch/blob/main/LICENSE")
                LinkButton(title: "Privacy Policy", icon: "hand.raised.fill", urlString: "https://github.com/mdrealofficial/opennotch#license")
            }
            .padding(.top, 4)
        }
        .font(.system(size: 11))
        .foregroundStyle(.white)
        .padding(.vertical, 4)
    }
}

public struct LinkButton: View {
    let title: String
    let icon: String
    let urlString: String
    
    public var body: some View {
        Button(action: {
            if let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.white.opacity(0.08)))
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
            .foregroundStyle(.white.opacity(0.85))
        }
        .buttonStyle(.plain)
    }
}

public struct ActivityRow: View {
    let name: String
    let icon: String
    let isSelected: Bool
    let onSelect: () -> Void
    
    public var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(name)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.blue.opacity(0.4) : Color.clear)
            )
            .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.7))
        }
        .buttonStyle(.plain)
    }
}
