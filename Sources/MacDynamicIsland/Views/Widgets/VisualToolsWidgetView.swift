import SwiftUI
import AVFoundation

public struct CameraPreviewView: NSViewRepresentable {
    public let session: AVCaptureSession?
    
    public init(session: AVCaptureSession?) {
        self.session = session
    }
    
    public func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        
        if let session = session {
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            previewLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
            view.layer?.addSublayer(previewLayer)
        }
        return view
    }
    
    public func updateNSView(_ nsView: NSView, context: Context) {
        if let previewLayer = nsView.layer?.sublayers?.first(where: { $0 is AVCaptureVideoPreviewLayer }) as? AVCaptureVideoPreviewLayer {
            if previewLayer.session !== session {
                previewLayer.session = session
            }
            previewLayer.frame = nsView.bounds
        }
    }
}

public struct VisualToolsWidgetView: View {
    @EnvironmentObject var toolsService: VisualToolsService
    @EnvironmentObject var settingsStore: SettingsStore
    
    @State private var activeToolTab: Int = 0 // 0: Quick Tools, 1: Camera Mirror, 2: Teleprompter
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 10) {
            // Sub-tabs
            HStack(spacing: 8) {
                toolTabButton("Quick Tools", index: 0, icon: "wand.and.stars")
                toolTabButton("Camera Mirror", index: 1, icon: "camera")
                toolTabButton("Teleprompter", index: 2, icon: "text.bubble")
                Spacer()
            }
            
            switch activeToolTab {
            case 0:
                quickToolsView
            case 1:
                cameraMirrorView
            case 2:
                teleprompterView
            default:
                EmptyView()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    @ViewBuilder
    private func toolTabButton(_ title: String, index: Int, icon: String) -> some View {
        Button {
            activeToolTab = index
            if index != 1 && toolsService.isCameraActive {
                toolsService.stopCamera()
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 11, weight: activeToolTab == index ? .bold : .medium))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(activeToolTab == index ? settingsStore.accentColor.opacity(0.3) : Color.white.opacity(0.06))
            .foregroundColor(activeToolTab == index ? .white : .white.opacity(0.6))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Quick Tools
    private var quickToolsView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Color Picker Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "eyedropper.halffull")
                            .foregroundColor(settingsStore.accentColor)
                        Text("Color Sampler")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(hex: toolsService.pickedColorHex) ?? .blue)
                            .frame(width: 24, height: 24)
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(toolsService.pickedColorHex)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                            Text(toolsService.pickedColorRGB)
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    
                    Button("Pick Any Pixel") {
                        Task {
                            await toolsService.pickColor()
                        }
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.1))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // Screenshot Region Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "camera.viewfinder")
                            .foregroundColor(.cyan)
                        Text("Screen Capture")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("Select any screen region to instantly copy to clipboard & OCR.")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Button("Capture Region") {
                        toolsService.captureInteractiveScreenshot()
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.cyan.opacity(0.2))
                    .foregroundColor(.cyan)
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
    
    // MARK: - Camera Mirror
    private var cameraMirrorView: some View {
        VStack(spacing: 8) {
            if toolsService.isCameraActive {
                CameraPreviewView(session: toolsService.captureSession)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                
                Button("Stop Mirror") {
                    toolsService.stopCamera()
                }
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background(Color.red.opacity(0.3))
                .foregroundColor(.red)
                .clipShape(Capsule())
                .buttonStyle(.plain)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "video.slash")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.4))
                    
                    Text("Camera Preview Idle")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Quick mirror right beneath your notch before hopping on a video call.")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                    
                    Button("Start Camera Mirror") {
                        Task {
                            if !toolsService.cameraPermissionGranted {
                                _ = await toolsService.requestCameraPermission()
                            }
                            toolsService.startCamera()
                        }
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(settingsStore.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 20)
            }
        }
    }
    
    // MARK: - Teleprompter
    private var teleprompterView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Scrolling Speed: \(Int(toolsService.teleprompterScrollSpeed))")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.6))
                
                Slider(value: $toolsService.teleprompterScrollSpeed, in: 10...80)
                    .frame(width: 120)
                
                Spacer()
                
                Button(toolsService.isTeleprompterScrolling ? "Pause" : "Scroll") {
                    toolsService.isTeleprompterScrolling.toggle()
                }
                .font(.system(size: 11, weight: .bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 3)
                .background(toolsService.isTeleprompterScrolling ? Color.orange.opacity(0.3) : settingsStore.accentColor)
                .foregroundColor(.white)
                .clipShape(Capsule())
                .buttonStyle(.plain)
            }
            
            TextEditor(text: $toolsService.teleprompterText)
                .font(.system(size: toolsService.teleprompterFontSize))
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(height: 140)
        }
    }
}
