import Foundation
import AppKit

public struct ShelfItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let url: URL
    public let name: String
    public let fileSize: Int64
    public let isDirectory: Bool
    public let dateAdded: Date
    
    public init(url: URL) {
        self.id = UUID()
        self.url = url
        self.name = url.lastPathComponent
        self.dateAdded = Date()
        
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        self.isDirectory = isDir.boolValue
        
        let attrs = (try? FileManager.default.attributesOfItem(atPath: url.path)) ?? [:]
        self.fileSize = (attrs[.size] as? Int64) ?? 0
    }
    
    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
}
