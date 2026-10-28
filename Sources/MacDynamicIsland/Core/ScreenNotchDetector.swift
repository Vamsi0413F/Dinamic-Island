import AppKit
import Foundation

public struct ScreenNotchInfo: Equatable, Sendable {
    public let hasNotch: Bool
    public let notchWidth: CGFloat
    public let notchHeight: CGFloat
    public let screenFrame: CGRect
    public let safeAreaTop: CGFloat
    
    public init(
        hasNotch: Bool,
        notchWidth: CGFloat,
        notchHeight: CGFloat,
        screenFrame: CGRect,
        safeAreaTop: CGFloat
    ) {
        self.hasNotch = hasNotch
        self.notchWidth = notchWidth
        self.notchHeight = notchHeight
        self.screenFrame = screenFrame
        self.safeAreaTop = safeAreaTop
    }
}

@MainActor
public final class ScreenNotchDetector {
    public static let shared = ScreenNotchDetector()
    
    public func detectNotch(on screen: NSScreen? = NSScreen.main) -> ScreenNotchInfo {
        guard let screen = screen ?? NSScreen.main else {
            return ScreenNotchInfo(
                hasNotch: false,
                notchWidth: 200,
                notchHeight: 32,
                screenFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
                safeAreaTop: 0
            )
        }
        
        let screenFrame = screen.frame
        let safeAreaTop = screen.safeAreaInsets.top
        
        // Check for notch cutout areas
        var detectedWidth: CGFloat = 210
        var detectedHeight: CGFloat = safeAreaTop > 0 ? safeAreaTop : 34
        var hasNotch = safeAreaTop > 0
        
        if let leftArea = screen.auxiliaryTopLeftArea,
           let rightArea = screen.auxiliaryTopRightArea {
            hasNotch = true
            let calculatedWidth = rightArea.minX - leftArea.maxX
            if calculatedWidth > 50 && calculatedWidth < 400 {
                detectedWidth = calculatedWidth
            }
            detectedHeight = screenFrame.maxY - leftArea.minY
        }
        
        if !hasNotch {
            // Non-notch fallback pill
            detectedWidth = 190
            detectedHeight = 32
        }
        
        return ScreenNotchInfo(
            hasNotch: hasNotch,
            notchWidth: detectedWidth,
            notchHeight: detectedHeight,
            screenFrame: screenFrame,
            safeAreaTop: safeAreaTop
        )
    }
}
