import SwiftUI

public enum SettingsCategory: String, CaseIterable, Identifiable {
    case general = "General"
    case appearance = "Appearance"
    case widgets = "Widgets"
    case about = "About"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .general: return "slider.horizontal.3"
        case .appearance: return "paintbrush.fill"
        case .widgets: return "square.grid.2x2.fill"
        case .about: return "info.circle.fill"
        }
    }
}

public struct SettingsView: View {
    @ObservedObject var prefs = UserPreferences.shared
    @State private var selectedCategory: SettingsCategory = .general
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 12) {
            // Category Bar
            HStack(spacing: 8) {
                ForEach(SettingsCategory.allCases) { cat in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedCategory = cat
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: cat.icon)
                                .font(.system(size: 10))
                            Text(cat.rawValue)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(selectedCategory == cat ? Color.purple.opacity(0.3) : Color.white.opacity(0.06))
                        )
                        .foregroundStyle(selectedCategory == cat ? Color.white : Color.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
            }
            
            Divider()
                .background(Color.white.opacity(0.12))
            
            // Category Content
            ScrollView(.vertical, showsIndicators: false) {
                switch selectedCategory {
                case .general:
                    generalSettingsView
                case .appearance:
                    appearanceSettingsView
                case .widgets:
                    widgetTogglesView
                case .about:
                    aboutSettingsView
                }
            }
            .frame(maxHeight: 160)
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - General Settings
    private var generalSettingsView: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Expand on Mouse Hover", isOn: $prefs.enableHoverExpansion)
                    .toggleStyle(.switch)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white)
                
                Toggle("Launch at Login", isOn: Binding(
                    get: { prefs.launchAtLogin },
                    set: { prefs.toggleLaunchAtLogin($0) }
                ))
                .toggleStyle(.switch)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white)
                
                Toggle("Haptic Feedback & Sounds", isOn: $prefs.enableHaptics)
                    .toggleStyle(.switch)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "Hover Delay: %.2fs", prefs.hoverDelay))
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.8))
                    Slider(value: $prefs.hoverDelay, in: 0.05...0.5, step: 0.05)
                        .tint(.purple)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "Auto-Close Delay: %.2fs", prefs.autoCollapseDelay))
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.8))
                    Slider(value: $prefs.autoCollapseDelay, in: 0.2...1.2, step: 0.1)
                        .tint(.purple)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Appearance Settings
    private var appearanceSettingsView: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Theme Preset")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))
                
                Picker("", selection: $prefs.themePresetRaw) {
                    ForEach(AppThemePreset.allCases) { preset in
                        Text(preset.rawValue).tag(preset.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Border Glow: \(Int(prefs.borderGlowOpacity * 100))%")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.8))
                    Slider(value: $prefs.borderGlowOpacity, in: 0.05...0.6, step: 0.05)
                        .tint(.cyan)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Expanded Width: \(Int(prefs.expandedWidth)) pt")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.8))
                    Slider(value: $prefs.expandedWidth, in: 520...720, step: 20)
                        .tint(.cyan)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Expanded Height: \(Int(prefs.expandedHeight)) pt")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.8))
                    Slider(value: $prefs.expandedHeight, in: 220...320, step: 10)
                        .tint(.cyan)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Widget Toggles
    private var widgetTogglesView: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            Toggle("🎵 Media Player", isOn: $prefs.showMediaWidget)
            Toggle("📦 Drop Shelf", isOn: $prefs.showDropShelfWidget)
            Toggle("🪞 Camera Mirror", isOn: $prefs.showMirrorWidget)
            Toggle("⏱️ Timer & Stopwatch", isOn: $prefs.showTimerWidget)
            Toggle("🎧 Bluetooth Gear", isOn: $prefs.showBluetoothWidget)
            Toggle("⚡️ Shortcuts / Pipelines", isOn: $prefs.showPipelinesWidget)
            Toggle("💻 Dev HUD Stats", isOn: $prefs.showDevHUDWidget)
            Toggle("📅 Calendar & Notes", isOn: $prefs.showCalendarWidget)
        }
        .toggleStyle(.switch)
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(.white)
    }
    
    // MARK: - About
    private var aboutSettingsView: some View {
        HStack(spacing: 16) {
            Image(systemName: "sparkles.rectangle.stack.fill")
                .font(.system(size: 32))
                .foregroundStyle(.purple)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("OpenNotch v1.0.0")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("Free, open-source macOS Dynamic Island & Notch Hub.")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.7))
                
                Text("GitHub: github.com/mdrealofficial/opennotch")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.cyan)
            }
        }
        .padding(.vertical, 8)
    }
}
