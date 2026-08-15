import Foundation
import AppKit
import AVFoundation
import CoreBluetooth

public final class PermissionManager: ObservableObject {
    public static let shared = PermissionManager()
    
    @Published public var isAccessibilityGranted: Bool = false
    @Published public var cameraStatus: AVAuthorizationStatus = .notDetermined
    
    private init() {
        checkPermissions()
    }
    
    public func checkPermissions() {
        self.isAccessibilityGranted = AXIsProcessTrusted()
        self.cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    public func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        self.isAccessibilityGranted = accessEnabled
        
        if !accessEnabled {
            // Open macOS Accessibility Settings directly
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    public func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.cameraStatus = granted ? .authorized : .denied
                completion(granted)
            }
        }
    }
    
    public func openSystemSettings(for pane: String = "Privacy_Accessibility") {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)") {
            NSWorkspace.shared.open(url)
        }
    }
}
