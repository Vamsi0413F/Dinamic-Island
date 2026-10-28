import SwiftUI

public struct NotesWidgetView: View {
    @EnvironmentObject var stateManager: IslandStateManager
    @EnvironmentObject var settingsStore: SettingsStore
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Quick Scratchpad")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                Text("\(wordCount) words")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
                
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(stateManager.notesContent, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help("Copy Note")
                
                Button {
                    stateManager.notesContent = ""
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help("Clear Note")
            }
            
            TextEditor(text: $stateManager.notesContent)
                .font(.system(size: 12))
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.top, 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    private var wordCount: Int {
        let words = stateManager.notesContent.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }
}
