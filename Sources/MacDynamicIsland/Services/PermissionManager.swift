import Foundation
import AppKit
import AVFoundation
import EventKit

@MainActor
public final class PermissionManager: ObservableObject {
    public static let shared = PermissionManager()
    
    @Published public private(set) var hasCameraPermission: Bool = false
    @Published public private(set) var hasCalendarPermission: Bool = false
    @Published public private(set) var isAccessibilityTrusted: Bool = false
    
    public init() {
        checkAll()
    }
    
    public func checkAll() {
        // Camera
        hasCameraPermission = (AVCaptureDevice.authorizationStatus(for: .video) == .authorized)
        
        // Calendar
        if #available(macOS 14.0, *) {
            let status = EKEventStore.authorizationStatus(for: .event)
            hasCalendarPermission = (status == .fullAccess || status == .writeOnly)
        } else {
            hasCalendarPermission = (EKEventStore.authorizationStatus(for: .event) == .authorized)
        }
        
        // Accessibility
        isAccessibilityTrusted = AXIsProcessTrusted()
    }
    
    public func openSystemSettingsPrivacy(pane: String) {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_\(pane)") else { return }
        NSWorkspace.shared.open(url)
    }
}
