import SwiftUI

public struct SettingsView: View {
    @ObservedObject var prefs = UserPreferences.shared
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("OpenNotch Preferences", systemImage: "gearshape.fill")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Text("v1.0.0 (Open Source)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
            
            Divider()
                .background(Color.white.opacity(0.15))
            
            HStack(alignment: .top, spacing: 20) {
                // Left Column: Behavior
                VStack(alignment: .leading, spacing: 12) {
                    Text("Behavior")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                    
                    Toggle("Expand on Mouse Hover", isOn: $prefs.enableHoverExpansion)
                        .toggleStyle(.switch)
                        .font(.system(size: 12))
                        .foregroundStyle(.white)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(format: "Hover Delay: %.2fs", prefs.hoverDelay))
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.8))
                        
                        Slider(value: $prefs.hoverDelay, in: 0.05...0.6, step: 0.05)
                            .tint(.purple)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(format: "Auto-Close Delay: %.2fs", prefs.autoCollapseDelay))
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.8))
                        
                        Slider(value: $prefs.autoCollapseDelay, in: 0.2...1.5, step: 0.1)
                            .tint(.purple)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Right Column: Appearance & Dimensions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Appearance")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Expanded Width: \(Int(prefs.expandedWidth)) pt")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.8))
                        
                        Slider(value: $prefs.expandedWidth, in: 480...720, step: 20)
                            .tint(.cyan)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "command")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.6))
                        
                        Text("Toggle Hotkey: ⌥ + Space (or hover notch)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.06)))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
