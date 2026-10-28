import SwiftUI

public struct IslandHUDView: View {
    public let event: HUDEvent
    
    @EnvironmentObject var settingsStore: SettingsStore
    
    public init(event: HUDEvent) {
        self.event = event
    }
    
    private var notchInfo: ScreenNotchInfo {
        ScreenNotchDetector.shared.detectNotch()
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            leadingContent
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Middle hardware notch cutout spacer
            if notchInfo.hasNotch {
                Spacer()
                    .frame(width: max(0, (notchInfo.notchWidth + settingsStore.notchWidthOffset) - 70))
            } else {
                Spacer()
                    .frame(minWidth: 8, maxWidth: 20)
            }
            
            trailingContent
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .frame(height: max(38, notchInfo.notchHeight + 2))
    }
    
    @ViewBuilder
    private var leadingContent: some View {
        switch event {
        case .volume(let level, let isMuted):
            HStack(spacing: 6) {
                Image(systemName: speakerIcon(level: level, isMuted: isMuted))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(isMuted ? .red : settingsStore.accentColor)
                
                Text(isMuted ? "Muted" : "\(Int(level * 100))%")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            
        case .brightness(let level):
            HStack(spacing: 6) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.yellow)
                
                Text("\(Int(level * 100))%")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            
        case .capsLock(let isOn):
            HStack(spacing: 5) {
                Image(systemName: "capslock.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isOn ? .yellow : .white.opacity(0.5))
                
                Text("Caps Lock")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }
    
    @ViewBuilder
    private var trailingContent: some View {
        switch event {
        case .volume(let level, let isMuted):
            // Smooth progress indicator
            hudProgressBar(value: isMuted ? 0.0 : Double(level), tint: isMuted ? .red : settingsStore.accentColor)
            
        case .brightness(let level):
            hudProgressBar(value: Double(level), tint: .yellow)
            
        case .capsLock(let isOn):
            Text(isOn ? "ON" : "OFF")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(isOn ? Color.yellow.opacity(0.2) : Color.white.opacity(0.08))
                .foregroundColor(isOn ? .yellow : .white.opacity(0.5))
                .clipShape(Capsule())
        }
    }
    
    @ViewBuilder
    private func hudProgressBar(value: Double, tint: Color) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.18))
                    .frame(height: 5)
                
                Capsule()
                    .fill(tint)
                    .frame(width: max(4, geo.size.width * min(1.0, max(0.0, value))), height: 5)
                    .animation(.interactiveSpring(response: 0.2, dampingFraction: 0.8), value: value)
            }
        }
        .frame(width: 65, height: 5)
    }
    
    private func speakerIcon(level: Float, isMuted: Bool) -> String {
        if isMuted || level <= 0.001 {
            return "speaker.slash.fill"
        } else if level < 0.33 {
            return "speaker.wave.1.fill"
        } else if level < 0.66 {
            return "speaker.wave.2.fill"
        } else {
            return "speaker.wave.3.fill"
        }
    }
}
