import AppKit
import Foundation
import CoreGraphics

public struct ScreenNotchInfo: Equatable, Sendable {
    public let hasNotch: Bool
    public let notchWidth: CGFloat
    public let notchHeight: CGFloat
    public let screenFrame: CGRect
    public let visibleFrame: CGRect
    public let safeAreaTop: CGFloat
    public let scaleFactor: CGFloat
    public let isBuiltIn: Bool
    public let screenName: String
    
    public init(
        hasNotch: Bool,
        notchWidth: CGFloat,
        notchHeight: CGFloat,
        screenFrame: CGRect,
        visibleFrame: CGRect = .zero,
        safeAreaTop: CGFloat,
        scaleFactor: CGFloat = 2.0,
        isBuiltIn: Bool = true,
        screenName: String = "Display"
    ) {
        self.hasNotch = hasNotch
        self.notchWidth = notchWidth
        self.notchHeight = notchHeight
        self.screenFrame = screenFrame
        self.visibleFrame = visibleFrame
        self.safeAreaTop = safeAreaTop
        self.scaleFactor = scaleFactor
        self.isBuiltIn = isBuiltIn
        self.screenName = screenName
    }
}

@MainActor
public final class ScreenNotchDetector {
    public static let shared = ScreenNotchDetector()
    
    public func targetScreen() -> NSScreen {
        // If preferred built-in screen with notch exists, find it
        if SettingsStore.shared.preferBuiltInNotchDisplay {
            if let builtInWithNotch = NSScreen.screens.first(where: { screen in
                let isBuiltin = isScreenBuiltIn(screen)
                return isBuiltin && screen.safeAreaInsets.top > 0
            }) {
                return builtInWithNotch
            }
            
            if let anyWithNotch = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) {
                return anyWithNotch
            }
        }
        
        return NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
    }
    
    public func detectNotch(on explicitScreen: NSScreen? = nil) -> ScreenNotchInfo {
        let screen = explicitScreen ?? targetScreen()
        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        let safeAreaTop = screen.safeAreaInsets.top
        let scaleFactor = screen.backingScaleFactor > 0 ? screen.backingScaleFactor : 2.0
        let isBuiltin = isScreenBuiltIn(screen)
        let screenName = screen.localizedName
        
        var detectedWidth: CGFloat = 0
        var detectedHeight: CGFloat = safeAreaTop
        var hasNotch = safeAreaTop > 0
        
        // Exact hardware cutout detection via auxiliary areas
        if let leftArea = screen.auxiliaryTopLeftArea,
           let rightArea = screen.auxiliaryTopRightArea {
            hasNotch = true
            let calculatedWidth = rightArea.minX - leftArea.maxX
            if calculatedWidth > 40 && calculatedWidth < 500 {
                detectedWidth = calculatedWidth
            }
            detectedHeight = screenFrame.maxY - leftArea.minY
        }
        
        if hasNotch {
            if detectedWidth <= 0 {
                // Fallback width if auxiliary areas were missing but safeAreaTop > 0
                detectedWidth = 208.0
            }
            if detectedHeight <= 0 {
                detectedHeight = max(34.0, safeAreaTop)
            }
        } else {
            // Floating fallback for external monitors or non-notch Macs
            detectedWidth = 190.0
            detectedHeight = 32.0
        }
        
        return ScreenNotchInfo(
            hasNotch: hasNotch,
            notchWidth: detectedWidth,
            notchHeight: detectedHeight,
            screenFrame: screenFrame,
            visibleFrame: visibleFrame,
            safeAreaTop: safeAreaTop,
            scaleFactor: scaleFactor,
            isBuiltIn: isBuiltin,
            screenName: screenName
        )
    }
    
    private func isScreenBuiltIn(_ screen: NSScreen) -> Bool {
        guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
            return false
        }
        return CGDisplayIsBuiltin(screenNumber) != 0
    }
}
