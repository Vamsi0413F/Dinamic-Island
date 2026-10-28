import Foundation
import AppKit

@MainActor
public final class MediaService: ObservableObject {
    public static let shared = MediaService()
    
    @Published public private(set) var currentTrack = MediaTrack() {
        didSet {
            updateVisualizerTimerState()
        }
    }
    @Published public private(set) var visualizerLevels: [CGFloat] = [0.15, 0.25, 0.15, 0.3, 0.2, 0.15, 0.25, 0.15]
    
    private var pollTimer: Timer?
    private var visualizerTimer: Timer?
    
    public init() {
        setupDistributedNotifications()
        refreshNowPlaying()
        startPollTimer()
    }
    
    private func setupDistributedNotifications() {
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshNowPlaying()
            }
        }
        
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshNowPlaying()
            }
        }
    }
    
    private func startPollTimer() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshNowPlaying()
            }
        }
    }
    
    private func updateVisualizerTimerState() {
        if currentTrack.isPlaying && visualizerTimer == nil {
            visualizerTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self = self, self.currentTrack.isPlaying else { return }
                    self.visualizerLevels = (0..<8).map { _ in
                        CGFloat.random(in: 0.2...0.95)
                    }
                }
            }
        } else if !currentTrack.isPlaying && visualizerTimer != nil {
            visualizerTimer?.invalidate()
            visualizerTimer = nil
            visualizerLevels = [0.15, 0.25, 0.15, 0.3, 0.2, 0.15, 0.25, 0.15]
        }
    }
    
    public func refreshNowPlaying() {
        Task.detached(priority: .userInitiated) {
            // Check Apple Music first
            if let track = self.fetchMusicTrack() {
                await MainActor.run {
                    self.currentTrack = track
                }
                return
            }
            
            // Check Spotify
            if let track = self.fetchSpotifyTrack() {
                await MainActor.run {
                    self.currentTrack = track
                }
                return
            }
            
            // If neither is running or playing, set idle
            await MainActor.run {
                if self.currentTrack.isPlaying {
                    self.currentTrack.isPlaying = false
                }
            }
        }
    }
    
    private nonisolated func fetchMusicTrack() -> MediaTrack? {
        let script = """
        if application "Music" is running then
            tell application "Music"
                if player state is playing or player state is paused then
                    set trackName to name of current track
                    set trackArtist to artist of current track
                    set trackAlbum to album of current track
                    set trackDuration to duration of current track
                    set trackPos to player position
                    set isPlaying to (player state is playing)
                    return trackName & "|||" & trackArtist & "|||" & trackAlbum & "|||" & (trackDuration as string) & "|||" & (trackPos as string) & "|||" & (isPlaying as string)
                end if
            end tell
        end if
        return ""
        """
        guard let output = executeAppleScript(script), !output.isEmpty else { return nil }
        let parts = output.components(separatedBy: "|||")
        guard parts.count >= 6 else { return nil }
        
        return MediaTrack(
            title: parts[0],
            artist: parts[1],
            album: parts[2],
            duration: Double(parts[3]) ?? 0,
            position: Double(parts[4]) ?? 0,
            isPlaying: parts[5].trimmingCharacters(in: .whitespacesAndNewlines) == "true",
            playerSource: "Music"
        )
    }
    
    private nonisolated func fetchSpotifyTrack() -> MediaTrack? {
        let script = """
        if application "Spotify" is running then
            tell application "Spotify"
                if player state is playing or player state is paused then
                    set trackName to name of current track
                    set trackArtist to artist of current track
                    set trackAlbum to album of current track
                    set trackDuration to (duration of current track) / 1000
                    set trackPos to player position
                    set isPlaying to (player state is playing)
                    return trackName & "|||" & trackArtist & "|||" & trackAlbum & "|||" & (trackDuration as string) & "|||" & (trackPos as string) & "|||" & (isPlaying as string)
                end if
            end tell
        end if
        return ""
        """
        guard let output = executeAppleScript(script), !output.isEmpty else { return nil }
        let parts = output.components(separatedBy: "|||")
        guard parts.count >= 6 else { return nil }
        
        return MediaTrack(
            title: parts[0],
            artist: parts[1],
            album: parts[2],
            duration: Double(parts[3]) ?? 0,
            position: Double(parts[4]) ?? 0,
            isPlaying: parts[5].trimmingCharacters(in: .whitespacesAndNewlines) == "true",
            playerSource: "Spotify"
        )
    }
    
    public func togglePlayPause() {
        let source = currentTrack.playerSource
        Task.detached {
            let script = """
            if application "\(source)" is running then
                tell application "\(source)" to playpause
            end if
            """
            _ = self.executeAppleScript(script)
            await self.refreshNowPlaying()
        }
    }
    
    public func nextTrack() {
        let source = currentTrack.playerSource
        Task.detached {
            let script = """
            if application "\(source)" is running then
                tell application "\(source)" to next track
            end if
            """
            _ = self.executeAppleScript(script)
            await self.refreshNowPlaying()
        }
    }
    
    public func previousTrack() {
        let source = currentTrack.playerSource
        Task.detached {
            let script = """
            if application "\(source)" is running then
                tell application "\(source)" to previous track
            end if
            """
            _ = self.executeAppleScript(script)
            await self.refreshNowPlaying()
        }
    }
    
    public func seek(to position: Double) {
        let source = currentTrack.playerSource
        Task.detached {
            let script = """
            if application "\(source)" is running then
                tell application "\(source)" to set player position to \(position)
            end if
            """
            _ = self.executeAppleScript(script)
        }
    }
    
    private nonisolated func executeAppleScript(_ source: String) -> String? {
        var error: NSDictionary?
        guard let scriptObject = NSAppleScript(source: source) else { return nil }
        let output = scriptObject.executeAndReturnError(&error)
        if error != nil {
            return nil
        }
        return output.stringValue
    }
    
    isolated deinit {
        pollTimer?.invalidate()
        visualizerTimer?.invalidate()
    }
}
