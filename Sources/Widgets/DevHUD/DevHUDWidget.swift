import SwiftUI

public struct DevHUDWidgetView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var sysMonitor = SystemMonitorService.shared
    @State private var quickText: String = ""
    @State private var convertedText: String = ""
    @State private var showDevTool: Bool = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 12) {
            // Metrics Row
            HStack(spacing: 12) {
                MetricCard(
                    title: "CPU Load",
                    value: String(format: "%.1f%%", sysMonitor.stats.cpuUsagePercentage),
                    progress: sysMonitor.stats.cpuUsagePercentage / 100,
                    icon: "cpu",
                    color: cpuColor(sysMonitor.stats.cpuUsagePercentage)
                )
                
                MetricCard(
                    title: "Memory",
                    value: String(format: "%.1f / %.0f GB", sysMonitor.stats.ramUsedGB, sysMonitor.stats.ramTotalGB),
                    progress: sysMonitor.stats.ramPercentage / 100,
                    icon: "memorychip",
                    color: OpenNotchTheme.accentBlue
                )
                
                MetricCard(
                    title: "Battery",
                    value: "\(sysMonitor.stats.batteryLevel)% \(sysMonitor.stats.isCharging ? "⚡️" : "")",
                    progress: Double(sysMonitor.stats.batteryLevel) / 100,
                    icon: batteryIcon(level: sysMonitor.stats.batteryLevel, isCharging: sysMonitor.stats.isCharging),
                    color: OpenNotchTheme.accentGreen
                )
                
                MetricCard(
                    title: "Uptime",
                    value: sysMonitor.stats.uptimeString,
                    progress: 1.0,
                    icon: "clock.arrow.circlepath",
                    color: OpenNotchTheme.accentOrange
                )
            }
            
            // Quick Developer Actions
            HStack(spacing: 10) {
                Button(action: {
                    openTerminal()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "terminal.fill")
                        Text("New Terminal")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(OpenNotchTheme.tabSelectedFill(for: colorScheme))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(OpenNotchTheme.cardBorder(for: colorScheme), lineWidth: 1)
                    )
                    .foregroundStyle(Color.primary)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    copyCurrentTimestamp()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.clock")
                        Text("Unix Time")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(OpenNotchTheme.tabSelectedFill(for: colorScheme))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(OpenNotchTheme.cardBorder(for: colorScheme), lineWidth: 1)
                    )
                    .foregroundStyle(Color.primary)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("macOS \(ProcessInfo.processInfo.operatingSystemVersionString)")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(Color.secondary)
            }
        }
    }
    
    private func cpuColor(_ usage: Double) -> Color {
        if usage > 80 { return OpenNotchTheme.accentRed }
        if usage > 50 { return OpenNotchTheme.accentOrange }
        return OpenNotchTheme.accentPurple
    }
    
    private func batteryIcon(level: Int, isCharging: Bool) -> String {
        if isCharging { return "battery.100.bolt" }
        if level > 75 { return "battery.100" }
        if level > 50 { return "battery.75" }
        if level > 25 { return "battery.50" }
        return "battery.25"
    }
    
    private func openTerminal() {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal") {
            let config = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.openApplication(at: url, configuration: config)
        }
    }
    
    private func copyCurrentTimestamp() {
        let ts = String(Int(Date().timeIntervalSince1970))
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(ts, forType: .string)
    }
}

public struct MetricCard: View {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let value: String
    let progress: Double
    let icon: String
    let color: Color
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(color)
                
                Spacer()
                
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.secondary)
            }
            
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
            
            ProgressView(value: min(1.0, max(0.0, progress)))
                .progressViewStyle(.linear)
                .tint(color)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(OpenNotchTheme.cardFill(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(OpenNotchTheme.cardBorder(for: colorScheme), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 6, x: 0, y: 2)
    }
}
