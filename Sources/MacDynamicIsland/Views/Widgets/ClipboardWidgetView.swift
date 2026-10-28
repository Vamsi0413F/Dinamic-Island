import SwiftUI

public struct ClipboardWidgetView: View {
    @EnvironmentObject var clipboardService: ClipboardService
    @EnvironmentObject var settingsStore: SettingsStore
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 10) {
            // Search & Controls bar
            HStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.4))
                        .font(.system(size: 11))
                    
                    TextField("Search history...", text: $clipboardService.searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                    
                    if !clipboardService.searchText.isEmpty {
                        Button {
                            clipboardService.searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.4))
                                .font(.system(size: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Pause button
                Button {
                    clipboardService.isMonitoringPaused.toggle()
                } label: {
                    Image(systemName: clipboardService.isMonitoringPaused ? "pause.circle.fill" : "pause.circle")
                        .foregroundColor(clipboardService.isMonitoringPaused ? .orange : .white.opacity(0.6))
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .help(clipboardService.isMonitoringPaused ? "Resume Clipboard Monitoring" : "Pause Clipboard Monitoring")
                
                // Clear unpinned
                Button {
                    clipboardService.clearUnpinned()
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
                .help("Clear Unpinned History")
            }
            
            // Clippings List
            if clipboardService.filteredItems.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.3))
                    Text("No clipboard items found")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 30)
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 6) {
                        ForEach(clipboardService.filteredItems) { item in
                            clipboardRow(item)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(maxHeight: 220)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    @ViewBuilder
    private func clipboardRow(_ item: ClipboardItem) -> some View {
        HStack(spacing: 10) {
            Button {
                clipboardService.copyToPasteboard(item: item)
            } label: {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: item.isSensitive ? "lock.shield.fill" : "doc.text")
                        .foregroundColor(item.isSensitive ? .orange : settingsStore.accentColor)
                        .font(.system(size: 12))
                        .padding(.top, 2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.text ?? "")
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Text(formatDate(item.date))
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            
            // Pin toggle
            Button {
                clipboardService.togglePin(item: item)
            } label: {
                Image(systemName: item.isPinned ? "pin.fill" : "pin")
                    .foregroundColor(item.isPinned ? settingsStore.accentColor : .white.opacity(0.3))
                    .font(.system(size: 11))
            }
            .buttonStyle(.plain)
            
            // Remove
            Button {
                clipboardService.removeItem(item: item)
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.white.opacity(0.3))
                    .font(.system(size: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
