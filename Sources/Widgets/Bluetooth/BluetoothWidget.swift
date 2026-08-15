import SwiftUI
import IOBluetooth
import Combine

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
                    BluetoothDeviceCard(device: device) {
                        btService.toggleConnection(for: device)
                    }
                }
            }
        }
    }
}
