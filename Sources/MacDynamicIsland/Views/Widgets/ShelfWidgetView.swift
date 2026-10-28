import SwiftUI
import UniformTypeIdentifiers

public struct ShelfWidgetView: View {
    @EnvironmentObject var shelfService: FileShelfService
    @EnvironmentObject var settingsStore: SettingsStore
    
    @State private var isTargeted: Bool = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 10) {
            if shelfService.items.isEmpty {
                // Empty drop target
                VStack(spacing: 8) {
                    Image(systemName: "tray.and.arrow.down")
                        .font(.system(size: 28))
                        .foregroundColor(isTargeted ? settingsStore.accentColor : .white.opacity(0.4))
                    
                    Text("Drag & drop files or folders here")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("Temporary shelf persists across all spaces")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            isTargeted ? settingsStore.accentColor : Color.white.opacity(0.15),
                            style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                        )
                )
            } else {
                // Shelf items list
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 8) {
                        ForEach(shelfService.items) { item in
                            shelfItemRow(item)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 220)
                
                // Bottom Shelf Toolbar
                HStack {
                    Text("\(shelfService.items.count) item\(shelfService.items.count == 1 ? "" : "s")")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Spacer()
                    
                    Button("Clear All") {
                        shelfService.clearAll()
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.red.opacity(0.8))
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
            return true
        }
    }
    
    @ViewBuilder
    private func shelfItemRow(_ item: ShelfItem) -> some View {
        HStack(spacing: 10) {
            Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                .foregroundColor(item.isDirectory ? .cyan : settingsStore.accentColor)
                .font(.system(size: 18))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(item.formattedSize)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 8) {
                Button {
                    shelfService.openFile(item: item)
                } label: {
                    Image(systemName: "arrow.up.forward.app")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help("Open File")
                
                Button {
                    shelfService.revealInFinder(item: item)
                } label: {
                    Image(systemName: "folder")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help("Reveal in Finder")
                
                Button {
                    Task {
                        _ = await shelfService.zipItem(item: item)
                    }
                } label: {
                    Image(systemName: "archivebox")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help("Compress to ZIP")
                
                Button {
                    shelfService.removeItem(item)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
                .help("Remove from Shelf")
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url = url {
                    Task { @MainActor in
                        self.shelfService.addURLs([url])
                    }
                }
            }
        }
    }
}
