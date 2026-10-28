import SwiftUI

public struct MediaWidgetView: View {
    @EnvironmentObject var mediaService: MediaService
    @EnvironmentObject var settingsStore: SettingsStore
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                // Album artwork or vinyl placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [settingsStore.accentColor.opacity(0.8), .purple.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 58, height: 58)
                    
                    Image(systemName: "music.note")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                .shadow(color: settingsStore.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(mediaService.currentTrack.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(mediaService.currentTrack.playerSource)
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Capsule())
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Text(mediaService.currentTrack.artist)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                    
                    if !mediaService.currentTrack.album.isEmpty {
                        Text(mediaService.currentTrack.album)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                            .lineLimit(1)
                    }
                }
            }
            
            // Progress Bar / Scrubber
            VStack(spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 4)
                        
                        let progress = mediaService.currentTrack.duration > 0
                            ? CGFloat(mediaService.currentTrack.position / mediaService.currentTrack.duration)
                            : 0.0
                        
                        Capsule()
                            .fill(settingsStore.accentColor)
                            .frame(width: max(4, geo.size.width * min(1.0, progress)), height: 4)
                    }
                }
                .frame(height: 6)
                
                HStack {
                    Text(formatTime(mediaService.currentTrack.position))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Spacer()
                    
                    Text(formatTime(mediaService.currentTrack.duration))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            // Media Controls
            HStack(spacing: 24) {
                // Previous
                Button {
                    mediaService.previousTrack()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                
                // Play / Pause
                Button {
                    mediaService.togglePlayPause()
                } label: {
                    ZStack {
                        Circle()
                            .fill(settingsStore.accentColor)
                            .frame(width: 38, height: 38)
                        
                        Image(systemName: mediaService.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                
                // Next
                Button {
                    mediaService.nextTrack()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // Audio visualizer bars
                HStack(spacing: 3) {
                    ForEach(0..<mediaService.visualizerLevels.count, id: \.self) { idx in
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(settingsStore.accentColor)
                            .frame(width: 3, height: max(4, 20 * mediaService.visualizerLevels[idx]))
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let total = Int(seconds)
        let mins = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
