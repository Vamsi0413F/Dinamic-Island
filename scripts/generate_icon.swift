import AppKit
import CoreGraphics
import Foundation

let sourcePath = "/Users/vamsi/.gemini/antigravity/brain/b9f23425-bc24-4919-b91e-03d954df7112/.user_uploaded/media_1793202234884_42b8c895.png"
let sourceURL = URL(fileURLWithPath: sourcePath)

guard let nsImage = NSImage(contentsOf: sourceURL),
      let originalCG = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    fatalError("Failed to load source image at \(sourcePath)")
}

let origW = originalCG.width
let origH = originalCG.height

// Step 1: Read raw pixels and extract transparent alpha mask
let colorSpace = CGColorSpaceCreateDeviceRGB()
let bytesPerPixel = 4
let bytesPerRow = bytesPerPixel * origW
var rawPixels = [UInt8](repeating: 0, count: bytesPerRow * origH)

guard let context = CGContext(
    data: &rawPixels,
    width: origW,
    height: origH,
    bitsPerComponent: 8,
    bytesPerRow: bytesPerRow,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fatalError("Failed to create CGContext")
}

context.draw(originalCG, in: CGRect(x: 0, y: 0, width: origW, height: origH))

// Create transparent pixel buffer:
// Background is white (~255), artwork is black (~0).
// Invert luminance so black becomes full opacity (255) and white becomes 0.
var transparentPixels = [UInt8](repeating: 0, count: bytesPerRow * origH)

for y in 0..<origH {
    for x in 0..<origW {
        let offset = (y * bytesPerRow) + (x * bytesPerPixel)
        let r = Double(rawPixels[offset])
        let g = Double(rawPixels[offset + 1])
        let b = Double(rawPixels[offset + 2])
        
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        // Invert luminance: 255 (white) -> 0 alpha, 0 (black) -> 255 alpha
        // Smooth thresholding to preserve anti-aliased brush edges
        let alphaDouble = max(0.0, min(255.0, (250.0 - luminance) * (255.0 / 230.0)))
        let alpha = UInt8(alphaDouble)
        
        // Deep black color with calculated alpha
        transparentPixels[offset] = 0
        transparentPixels[offset + 1] = 0
        transparentPixels[offset + 2] = 0
        transparentPixels[offset + 3] = alpha
    }
}

guard let transparentCG = CGContext(
    data: &transparentPixels,
    width: origW,
    height: origH,
    bitsPerComponent: 8,
    bytesPerRow: bytesPerRow,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)?.makeImage() else {
    fatalError("Failed to create transparent CGImage")
}

// Step 2: Render into 1024x1024 macOS App Icon canvas
// With subtle Apple squircle card background (pure dark & light variants)
func renderMasterIcon(darkTheme: Bool) -> CGImage {
    let size = 1024
    let ctx = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: size * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    
    // Background squircle (macOS rounded rect: 1024x1024 with 22.5% radius = 230pt)
    let margin: CGFloat = 80
    let iconRect = CGRect(x: margin, y: margin, width: CGFloat(size) - margin * 2, height: CGFloat(size) - margin * 2)
    let cornerRadius: CGFloat = 190.0
    let path = CGPath(roundedRect: iconRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    
    if darkTheme {
        // Premium Dark Island aesthetic: OLED dark slate gradient with subtle inner rim
        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()
        
        let colors = [
            NSColor(calibratedWhite: 0.14, alpha: 1.0).cgColor,
            NSColor(calibratedWhite: 0.04, alpha: 1.0).cgColor
        ] as CFArray
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0])!
        ctx.drawLinearGradient(gradient, start: CGPoint(x: 512, y: 1024 - margin), end: CGPoint(x: 512, y: margin), options: [])
        
        // Inner rim highlight
        ctx.setStrokeColor(NSColor(calibratedWhite: 1.0, alpha: 0.15).cgColor)
        ctx.setLineWidth(4.0)
        ctx.addPath(path)
        ctx.strokePath()
        ctx.restoreGState()
        
        // Draw calligraphic symbol in crisp white/silver with subtle glow
        let symbolMargin: CGFloat = 180
        let symbolRect = CGRect(x: symbolMargin, y: symbolMargin, width: CGFloat(size) - symbolMargin * 2, height: CGFloat(size) - symbolMargin * 2)
        
        // Mask with transparentCG to draw pure white symbol
        ctx.saveGState()
        ctx.clip(to: symbolRect, mask: transparentCG)
        ctx.setFillColor(NSColor(calibratedWhite: 0.98, alpha: 1.0).cgColor)
        ctx.fill(symbolRect)
        ctx.restoreGState()
    } else {
        // Clean original design: Pure transparent/white background with black brushed logo
        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()
        
        let colors = [
            NSColor(calibratedWhite: 1.0, alpha: 1.0).cgColor,
            NSColor(calibratedWhite: 0.94, alpha: 1.0).cgColor
        ] as CFArray
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0])!
        ctx.drawLinearGradient(gradient, start: CGPoint(x: 512, y: 1024 - margin), end: CGPoint(x: 512, y: margin), options: [])
        
        ctx.setStrokeColor(NSColor(calibratedWhite: 0.0, alpha: 0.08).cgColor)
        ctx.setLineWidth(3.0)
        ctx.addPath(path)
        ctx.strokePath()
        ctx.restoreGState()
        
        // Draw black calligraphic logo
        let symbolMargin: CGFloat = 180
        let symbolRect = CGRect(x: symbolMargin, y: symbolMargin, width: CGFloat(size) - symbolMargin * 2, height: CGFloat(size) - symbolMargin * 2)
        ctx.saveGState()
        ctx.clip(to: symbolRect, mask: transparentCG)
        ctx.setFillColor(NSColor(calibratedWhite: 0.08, alpha: 1.0).cgColor)
        ctx.fill(symbolRect)
        ctx.restoreGState()
    }
    
    return ctx.makeImage()!
}

// Save images
let fileManager = FileManager.default
let projectDir = FileManager.default.currentDirectoryPath
let resourcesDir = "\(projectDir)/Resources"
let iconsetDir = "\(projectDir)/build/AppIcon.iconset"
let assetsAppIconDir = "\(projectDir)/Sources/MacDynamicIsland/Resources/Assets.xcassets/AppIcon.appiconset"

try? fileManager.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)
try? fileManager.createDirectory(atPath: assetsAppIconDir, withIntermediateDirectories: true)
try? fileManager.createDirectory(atPath: resourcesDir, withIntermediateDirectories: true)

// Use Dark Theme (fits Dynamic Island & OLED notch perfectly while maintaining original design)
let masterImage = renderMasterIcon(darkTheme: true)
let masterRep = NSBitmapImageRep(cgImage: masterImage)
if let pngData = masterRep.representation(using: .png, properties: [:]) {
    try! pngData.write(to: URL(fileURLWithPath: "\(resourcesDir)/AppIcon-1024.png"))
    try! pngData.write(to: URL(fileURLWithPath: "\(assetsAppIconDir)/AppIcon-1024.png"))
}

// Generate light variant for reference
let lightMaster = renderMasterIcon(darkTheme: false)
let lightRep = NSBitmapImageRep(cgImage: lightMaster)
if let lightData = lightRep.representation(using: .png, properties: [:]) {
    try! lightData.write(to: URL(fileURLWithPath: "\(resourcesDir)/AppIcon-Light-1024.png"))
}

// Iconset dimensions required by iconutil
let iconSizes: [(name: String, size: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for item in iconSizes {
    let resizedCtx = CGContext(
        data: nil,
        width: item.size,
        height: item.size,
        bitsPerComponent: 8,
        bytesPerRow: item.size * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    resizedCtx.interpolationQuality = .high
    resizedCtx.draw(masterImage, in: CGRect(x: 0, y: 0, width: item.size, height: item.size))
    
    if let resizedCG = resizedCtx.makeImage() {
        let rep = NSBitmapImageRep(cgImage: resizedCG)
        if let data = rep.representation(using: .png, properties: [:]) {
            try! data.write(to: URL(fileURLWithPath: "\(iconsetDir)/\(item.name)"))
            try! data.write(to: URL(fileURLWithPath: "\(assetsAppIconDir)/\(item.name)"))
        }
    }
}

print("==> Iconset successfully generated at \(iconsetDir)")
