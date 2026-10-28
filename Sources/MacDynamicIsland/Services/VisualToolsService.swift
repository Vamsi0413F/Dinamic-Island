import Foundation
import AppKit
@preconcurrency import AVFoundation
import Vision

@MainActor
public final class VisualToolsService: ObservableObject {
    public static let shared = VisualToolsService()
    
    // Camera
    @Published public private(set) var isCameraActive: Bool = false
    @Published public private(set) var captureSession: AVCaptureSession?
    @Published public var cameraPermissionGranted: Bool = false
    
    // Color Picker
    @Published public var pickedColorHex: String = "#0A84FF"
    @Published public var pickedColorRGB: String = "rgb(10, 132, 255)"
    
    // Teleprompter
    @Published public var teleprompterText: String = "MacDynamicIsland Teleprompter\n\nSpeak naturally, stay focused, and look right at the camera notch."
    @Published public var teleprompterScrollSpeed: Double = 30.0 // points per sec
    @Published public var teleprompterFontSize: CGFloat = 18.0
    @Published public var isTeleprompterScrolling: Bool = false
    
    public init() {
        checkCameraPermission()
    }
    
    // MARK: - Camera Mirror
    public func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraPermissionGranted = true
        default:
            cameraPermissionGranted = false
        }
    }
    
    public func requestCameraPermission() async -> Bool {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        cameraPermissionGranted = granted
        return granted
    }
    
    public func startCamera() {
        guard !isCameraActive else { return }
        
        let session = AVCaptureSession()
        session.sessionPreset = .high
        
        guard let device = AVCaptureDevice.default(for: .video) else {
            print("[VisualToolsService] No camera device found")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            self.captureSession = session
            self.isCameraActive = true
            
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        } catch {
            print("[VisualToolsService] Failed to start camera: \(error.localizedDescription)")
        }
    }
    
    public func stopCamera() {
        guard isCameraActive, let session = captureSession else { return }
        self.captureSession = nil
        self.isCameraActive = false
        DispatchQueue.global(qos: .userInitiated).async {
            session.stopRunning()
        }
    }
    
    // MARK: - Color Picker
    public func pickColor() async {
        let sampler = NSColorSampler()
        if let selected = await sampler.sample() {
            guard let rgbColor = selected.usingColorSpace(.sRGB) else { return }
            let r = Int(rgbColor.redComponent * 255)
            let g = Int(rgbColor.greenComponent * 255)
            let b = Int(rgbColor.blueComponent * 255)
            
            let hex = String(format: "#%02X%02X%02X", r, g, b)
            self.pickedColorHex = hex
            self.pickedColorRGB = "rgb(\(r), \(g), \(b))"
            
            // Also copy to clipboard
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(hex, forType: .string)
        }
    }
    
    // MARK: - Screenshot Capture
    public func captureInteractiveScreenshot() {
        Task.detached {
            let tempPath = "/tmp/island_screenshot_\(UUID().uuidString).png"
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            // -i interactive region, -c copy to clipboard, or save to path
            process.arguments = ["-i", "-c", tempPath]
            
            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                print("[VisualToolsService] Screencapture error: \(error.localizedDescription)")
            }
        }
    }
}
