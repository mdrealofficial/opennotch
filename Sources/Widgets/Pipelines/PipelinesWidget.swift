import SwiftUI
import AppKit

public struct PipelineAction: Identifiable {
    public let id = UUID()
    public let title: String
    public let subtitle: String
    public let icon: String
    public let color: Color
    public let action: () -> Void
    
    public init(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.action = action
    }
}

public struct PipelinesWidgetView: View {
    @State private var statusMessage: String? = nil
    
    public init() {}
    
    private var actions: [PipelineAction] {
        [
            PipelineAction(
                title: "Dark / Light Mode",
                subtitle: "Toggle system appearance",
                icon: "circle.righthalf.filled",
                color: Color.indigo
            ) {
                toggleAppearance()
            },
            PipelineAction(
                title: "Take Screenshot",
                subtitle: "Interactive capture to clipboard",
                icon: "camera.viewfinder",
                color: Color.pink
            ) {
                takeScreenshot()
            },
            PipelineAction(
                title: "Lock Screen",
                subtitle: "Instantly lock Mac",
                icon: "lock.fill",
                color: Color.orange
            ) {
                lockScreen()
            },
            PipelineAction(
                title: "Empty Trash",
                subtitle: "Clean temporary waste",
                icon: "trash.fill",
                color: Color.red
            ) {
                emptyTrash()
            }
        ]
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Shortcuts & Pipelines Runner", systemImage: "bolt.fill")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(OpenNotchTheme.textPrimary)
                
                Spacer()
                
                if let msg = statusMessage {
                    Text(msg)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(OpenNotchTheme.accentGreen)
                        .transition(.opacity)
                }
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(actions) { item in
                    Button(action: {
                        item.action()
                        withAnimation {
                            statusMessage = "\(item.title) executed"
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                statusMessage = nil
                            }
                        }
                    }) {
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(item.color.opacity(0.18))
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: item.icon)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(item.color)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(OpenNotchTheme.textPrimary)
                                
                                Text(item.subtitle)
                                    .font(.system(size: 9, weight: .regular))
                                    .foregroundStyle(OpenNotchTheme.textSecondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(OpenNotchTheme.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(OpenNotchTheme.cardBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func toggleAppearance() {
        let script = """
        tell application "System Events"
            tell appearance preferences
                set dark mode to not dark mode
            end tell
        end tell
        """
        NSAppleScript(source: script)?.executeAndReturnError(nil)
    }
    
    private func takeScreenshot() {
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-ic"]
        try? task.run()
    }
    
    private func lockScreen() {
        let script = """
        tell application "System Events" to key code 12 using {control down, command down}
        """
        NSAppleScript(source: script)?.executeAndReturnError(nil)
    }
    
    private func emptyTrash() {
        let script = """
        tell application "Finder" to empty trash
        """
        NSAppleScript(source: script)?.executeAndReturnError(nil)
    }
}
