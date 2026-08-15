import SwiftUI
import AVFoundation
import AppKit

public final class CameraService: NSObject, ObservableObject {
    public static let shared = CameraService()
    
    @Published public var isRunning: Bool = false
    @Published public var hasPermission: Bool = false
    public let captureSession = AVCaptureSession()
    private var isConfigured = false
    
    private override init() {
        super.init()
        checkPermission()
    }
    
    public func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            hasPermission = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.hasPermission = granted
                }
            }
        default:
            hasPermission = false
        }
    }
    
    public func startSession() {
        guard hasPermission else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            if !self.isConfigured {
                self.setupCaptureSession()
            }
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                DispatchQueue.main.async {
                    self.isRunning = true
                }
            }
        }
    }
    
    public func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                DispatchQueue.main.async {
                    self.isRunning = false
                }
            }
        }
    }
    
    private func setupCaptureSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high
        
        if let videoDevice = AVCaptureDevice.default(for: .video),
           let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
           captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
            isConfigured = true
        }
        
        captureSession.commitConfiguration()
    }
}

public struct CameraPreviewView: NSViewRepresentable {
    @ObservedObject var cameraService = CameraService.shared
    
    public init() {}
    
    public func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        let previewLayer = AVCaptureVideoPreviewLayer(session: cameraService.captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.cornerRadius = 14
        previewLayer.masksToBounds = true
        view.layer = previewLayer
        return view
    }
    
    public func updateNSView(_ nsView: NSView, context: Context) {
        if let layer = nsView.layer as? AVCaptureVideoPreviewLayer {
            layer.frame = nsView.bounds
        }
    }
}

public struct CameraMirrorWidgetView: View {
    @ObservedObject var cameraService = CameraService.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label("Video Call Mirror Check", systemImage: "camera.fill")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Circle()
                    .fill(cameraService.isRunning ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                
                Text(cameraService.isRunning ? "Live Camera" : "Standby")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            ZStack {
                if cameraService.hasPermission {
                    CameraPreviewView()
                        .frame(maxWidth: .infinity, maxHeight: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                        )
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.badge.ellipsis")
                            .font(.system(size: 30))
                            .foregroundStyle(.yellow)
                        
                        Text("Camera access needed for Mirror Widget")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white)
                        
                        Button("Grant Access") {
                            cameraService.checkPermission()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 140)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06)))
                }
            }
        }
        .onAppear {
            cameraService.startSession()
        }
        .onDisappear {
            cameraService.stopSession()
        }
    }
}
