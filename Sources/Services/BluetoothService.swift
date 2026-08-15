import Foundation
import AppKit
import IOBluetooth
import Combine
import IOKit

public enum BluetoothDeviceType: String, CaseIterable {
    case airpods = "AirPods"
    case headphones = "Headphones"
    case mouse = "Mouse"
    case keyboard = "Keyboard"
    case trackpad = "Trackpad"
    case speaker = "Speaker"
    case phone = "Phone"
    case computer = "Computer"
    case generic = "Bluetooth Device"
    
    public var iconName: String {
        switch self {
        case .airpods: return "airpodspro"
        case .headphones: return "headphones"
        case .mouse: return "magicmouse"
        case .keyboard: return "keyboard"
        case .trackpad: return "computermouse"
        case .speaker: return "hifispeaker.fill"
        case .phone: return "iphone"
        case .computer: return "macbook"
        case .generic: return "dot.radiowaves.left.and.right"
        }
    }
}

public struct BluetoothDeviceInfo: Identifiable, Equatable {
    public var id: String { address }
    public let name: String
    public let address: String
    public let isConnected: Bool
    public let batteryLevel: Int? // Overall or single battery %
    public let batteryLeft: Int?
    public let batteryRight: Int?
    public let batteryCase: Int?
    public let deviceType: BluetoothDeviceType
    
    public var displayBattery: Int? {
        if let b = batteryLevel, b > 0 { return b }
        if let l = batteryLeft, l > 0 { return l }
        if let r = batteryRight, r > 0 { return r }
        return nil
    }
}

public final class BluetoothService: ObservableObject {
    public static let shared = BluetoothService()
    
    @Published public private(set) var devices: [BluetoothDeviceInfo] = []
    @Published public private(set) var connectedDevices: [BluetoothDeviceInfo] = []
    @Published public private(set) var isScanning: Bool = false
    
    private var timer: AnyCancellable?
    private let queue = DispatchQueue(label: "com.opennotch.bluetooth", qos: .utility)
    
    private init() {
        startPolling()
    }
    
    public func startPolling() {
        timer = Timer.publish(every: 3.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshDevices()
            }
        refreshDevices()
    }
    
    public func refreshDevices() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // 1. Fetch paired devices via IOBluetooth
            guard let paired = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
                DispatchQueue.main.async {
                    self.devices = []
                    self.connectedDevices = []
                }
                return
            }
            
            // 2. Fetch battery levels via IORegistry and system profiler
            let hidBatteries = self.fetchHIDBatteries()
            let profilerBatteries = self.fetchProfilerBatteries()
            
            var result: [BluetoothDeviceInfo] = []
            
            for device in paired {
                let name = device.nameOrAddress ?? "Unknown Device"
                let address = device.addressString ?? UUID().uuidString
                let isConnected = device.isConnected()
                let type = self.categorizeDevice(name: name, device: device)
                
                let battery = self.extractBattery(device: device, name: name, address: address, hid: hidBatteries, profiler: profilerBatteries)
                
                let info = BluetoothDeviceInfo(
                    name: name,
                    address: address,
                    isConnected: isConnected,
                    batteryLevel: battery,
                    batteryLeft: nil,
                    batteryRight: nil,
                    batteryCase: nil,
                    deviceType: type
                )
                result.append(info)
            }
            
            // Sort: Connected devices first, then alphabetically
            result.sort { (a, b) -> Bool in
                if a.isConnected != b.isConnected {
                    return a.isConnected && !b.isConnected
                }
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
            
            DispatchQueue.main.async {
                self.devices = result
                self.connectedDevices = result.filter { $0.isConnected }
            }
        }
    }
    
    private func extractBattery(device: IOBluetoothDevice, name: String, address: String, hid: [String: Int], profiler: [String: Int]) -> Int? {
        // 1. Check system profiler dictionary
        let normalizedAddr = address.replacingOccurrences(of: "-", with: ":").uppercased()
        if let batt = profiler[normalizedAddr] ?? profiler[name] {
            return batt
        }
        
        // 2. Check HID registry
        for (hidName, batt) in hid {
            if name.localizedCaseInsensitiveContains(hidName) || hidName.localizedCaseInsensitiveContains(name) {
                return batt
            }
        }
        
        // 3. Check IOBluetoothDevice selectors
        let selectors = ["batteryPercentSingle", "batteryPercentCombined", "batteryPercentLeft", "batteryPercentRight", "headsetBattery"]
        for s in selectors {
            let sel = NSSelectorFromString(s)
            if device.responds(to: sel) {
                typealias Getter = @convention(c) (AnyObject, Selector) -> UInt8
                let val = unsafeBitCast(device.method(for: sel), to: Getter.self)(device, sel)
                if val > 0 && val <= 100 {
                    return Int(val)
                }
            }
        }
        
        return nil
    }
    
    private func fetchProfilerBatteries() -> [String: Int] {
        var result: [String: Int] = [:]
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        process.arguments = ["SPBluetoothDataType", "-json"]
        let pipe = Pipe()
        process.standardOutput = pipe
        try? process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let array = json["SPBluetoothDataType"] as? [[String: Any]] else { return result }
        
        for item in array {
            if let connected = item["device_connected"] as? [[String: Any]] {
                for devDict in connected {
                    for (devName, devProps) in devDict {
                        if let props = devProps as? [String: Any] {
                            let addr = (props["device_address"] as? String)?.uppercased()
                            var batt: Int? = nil
                            if let b = props["device_batteryLevelMain"] as? String, let num = Int(b.replacingOccurrences(of: "%", with: "")) {
                                batt = num
                            } else if let b = props["device_batteryPercentCase"] as? String, let num = Int(b.replacingOccurrences(of: "%", with: "")) {
                                batt = num
                            }
                            if let b = batt {
                                if let a = addr { result[a] = b }
                                result[devName] = b
                            }
                        }
                    }
                }
            }
        }
        return result
    }
    
    public func toggleConnection(for device: BluetoothDeviceInfo) {
        queue.async { [weak self] in
            guard let paired = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice],
                  let target = paired.first(where: { $0.addressString == device.address }) else { return }
            
            if target.isConnected() {
                target.closeConnection()
            } else {
                target.openConnection()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self?.refreshDevices()
            }
        }
    }
    
    public func openBluetoothSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.BluetoothSettings") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func categorizeDevice(name: String, device: IOBluetoothDevice) -> BluetoothDeviceType {
        let lower = name.lowercased()
        if lower.contains("airpod") { return .airpods }
        if lower.contains("headphone") || lower.contains("wh-") || lower.contains("wf-") || lower.contains("qc35") || lower.contains("qc45") || lower.contains("beats") || lower.contains("buds") || lower.contains("ear") {
            return .headphones
        }
        if lower.contains("mouse") || lower.contains("mx master") || lower.contains("anywhere") { return .mouse }
        if lower.contains("keyboard") || lower.contains("keychron") || lower.contains("k380") || lower.contains("logi k") { return .keyboard }
        if lower.contains("trackpad") { return .trackpad }
        if lower.contains("speaker") || lower.contains("soundbar") || lower.contains("echo") || lower.contains("jbl") || lower.contains("bose") { return .speaker }
        if lower.contains("iphone") || lower.contains("pixel") || lower.contains("galaxy") || lower.contains("phone") { return .phone }
        if lower.contains("macbook") || lower.contains("mac") || lower.contains("imac") { return .computer }
        
        // Check Bluetooth Major Device Class
        let major = device.deviceClassMajor
        switch major {
        case 4: return .headphones // Audio/Video
        case 5: return .mouse      // Peripheral
        case 2: return .phone      // Phone
        case 1: return .computer   // Computer
        default: return .generic
        }
    }
    
    private func fetchHIDBatteries() -> [String: Int] {
        var result: [String: Int] = [:]
        
        var iterator: io_iterator_t = 0
        let matching = IOServiceMatching("AppleDeviceManagementHIDEventService")
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == kIOReturnSuccess else {
            return result
        }
        
        var service = IOIteratorNext(iterator)
        while service != 0 {
            if let name = IORegistryEntryCreateCFProperty(service, "Product" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String,
               let battery = IORegistryEntryCreateCFProperty(service, "BatteryPercent" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Int {
                result[name] = battery
            }
            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }
        IOObjectRelease(iterator)
        return result
    }
}
