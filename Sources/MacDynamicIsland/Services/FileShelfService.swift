import Foundation
import AppKit

@MainActor
public final class FileShelfService: ObservableObject {
    public static let shared = FileShelfService()
    
    @Published public private(set) var items: [ShelfItem] = []
    
    public init() {}
    
    public func addURLs(_ urls: [URL]) {
        for url in urls {
            if !items.contains(where: { $0.url == url }) {
                items.append(ShelfItem(url: url))
            }
        }
    }
    
    public func removeItem(_ item: ShelfItem) {
        items.removeAll { $0.id == item.id }
    }
    
    public func clearAll() {
        items.removeAll()
    }
    
    public func revealInFinder(item: ShelfItem) {
        NSWorkspace.shared.selectFile(item.url.path, inFileViewerRootedAtPath: "")
    }
    
    public func openFile(item: ShelfItem) {
        NSWorkspace.shared.open(item.url)
    }
    
    public func zipItem(item: ShelfItem) async -> URL? {
        let parentDir = item.url.deletingLastPathComponent()
        let zipName = item.url.deletingPathExtension().lastPathComponent + ".zip"
        let destURL = parentDir.appendingPathComponent(zipName)
        
        return await Task.detached {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
            process.arguments = ["-c", "-k", "--sequesterRsrc", item.url.path, destURL.path]
            
            do {
                try process.run()
                process.waitUntilExit()
                if process.terminationStatus == 0 {
                    return destURL
                }
            } catch {
                print("[FileShelfService] Zip error: \(error.localizedDescription)")
            }
            return nil
        }.value
    }
}
