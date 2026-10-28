import Foundation
import SwiftUI

public enum HUDEvent: Equatable, Sendable {
    case volume(level: Float, isMuted: Bool)
    case brightness(level: Float)
    case capsLock(isOn: Bool)
}

public enum IslandPresentationMode: Equatable, Sendable {
    case compact          // Minimal pill embracing the notch
    case hud(HUDEvent)    // Transient HUD alert (volume, brightness, caps lock)
    case expanded         // Medium drop-down pill with active widget overview
    case detailed         // Full interactive panel with tabs & controls
}

public enum WidgetType: String, CaseIterable, Identifiable, Codable, Sendable {
    case media = "Media"
    case system = "System"
    case shelf = "Shelf"
    case clipboard = "Clipboard"
    case timer = "Timer"
    case notes = "Notes"
    case calendar = "Calendar"
    case tools = "Tools"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .media: return "music.note"
        case .system: return "cpu"
        case .shelf: return "tray.and.arrow.down.fill"
        case .clipboard: return "doc.on.clipboard"
        case .timer: return "timer"
        case .notes: return "note.text"
        case .calendar: return "calendar"
        case .tools: return "wrench.and.screwdriver"
        }
    }
}
