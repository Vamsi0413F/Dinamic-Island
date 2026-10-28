import Foundation
import AppKit

public struct ClipboardItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let text: String?
    public let imageHash: String?
    public let date: Date
    public var isPinned: Bool
    public var isSensitive: Bool
    
    public init(
        id: UUID = UUID(),
        text: String?,
        imageHash: String? = nil,
        date: Date = Date(),
        isPinned: Bool = false,
        isSensitive: Bool = false
    ) {
        self.id = id
        self.text = text
        self.imageHash = imageHash
        self.date = date
        self.isPinned = isPinned
        self.isSensitive = isSensitive
    }
}
