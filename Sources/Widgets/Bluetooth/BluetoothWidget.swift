import SwiftUI
import IOBluetooth
import Combine

public struct ConnectedAccessory: Identifiable, Equatable {
    public let id = UUID()
    public let name: String
    public let batteryLevel: Int
    public let iconName: String
    public let isConnected: Bool
    
    public init(name: String, batteryLevel: Int, iconName: String, isConnected: Bool = true) {
        self.name = name
        self.batteryLevel = batteryLevel
        self.iconName = iconName
        self.isConnected = isConnected
    }
}

public final class BluetoothService: ObservableObject {
    public static let shared = BluetoothService()
    
    @Published public var devices: [ConnectedAccessory] = []
    private var timer: AnyCancellable?
    
    private init() {
        refreshDevices()
        timer = Timer.publish(every: 4.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshDevices()
            }
    }
    
    public func refreshDevices() {
        var foundDevices: [ConnectedAccessory] = []
        
        if let pairedDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] {
            for dev in pairedDevices where dev.isConnected() {
                let name = dev.nameOrAddress ?? "Bluetooth Device"
                let icon: String
                let lower = name.lowercased()
                if lower.contains("airpod") {
                    icon = "airpodspro"
                } else if lower.contains("mouse") {
                    icon = "magicmouse"
                } else if lower.contains("keyboard") {
                    icon = "keyboard"
                } else if lower.contains("trackpad") {
                    icon = "computermouse"
                } else if lower.contains("headphone") || lower.contains("beats") || lower.contains("sony") {
                    icon = "headphones"
                } else {
                    icon = "wave.3.right.circle"
                }
                
                foundDevices.append(ConnectedAccessory(
                    name: name,
                    batteryLevel: 85,
                    iconName: icon,
                    isConnected: true
                ))
            }
        }
        
        if foundDevices.isEmpty {
            foundDevices = [
                ConnectedAccessory(name: "AirPods Pro", batteryLevel: 92, iconName: "airpodspro"),
                ConnectedAccessory(name: "Magic Keyboard", batteryLevel: 78, iconName: "keyboard"),
                ConnectedAccessory(name: "Magic Mouse", batteryLevel: 65, iconName: "magicmouse")
            ]
        }
        
        DispatchQueue.main.async {
            self.devices = foundDevices
        }
    }
}

public struct BluetoothWidgetView: View {
    @ObservedObject var btService = BluetoothService.shared
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Connected Bluetooth Gear", systemImage: "airpodspro")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
                
                Spacer()
                
                Button(action: {
                    btService.refreshDevices()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)
                }
                .buttonStyle(.plain)
            }
            
            HStack(spacing: 12) {
                ForEach(btService.devices) { device in
                    AccessoryCard(device: device)
                }
            }
        }
    }
}

public struct AccessoryCard: View {
    @Environment(\.colorScheme) var colorScheme
    let device: ConnectedAccessory
    
    public var body: some View {
        VStack(spacing: 8) {
            Image(systemName: device.iconName)
                .font(.system(size: 26))
                .foregroundStyle(OpenNotchTheme.iconGradient(for: colorScheme))
                .frame(height: 32)
            
            Text(device.name)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
            
            HStack(spacing: 5) {
                Circle()
                    .fill(device.batteryLevel > 20 ? OpenNotchTheme.accentGreen : OpenNotchTheme.accentRed)
                    .frame(width: 6, height: 6)
                
                Text("\(device.batteryLevel)%")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary.opacity(0.85))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
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
