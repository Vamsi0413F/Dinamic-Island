import Foundation
import AppKit

public struct MediaTrack: Equatable, Sendable {
    public var title: String
    public var artist: String
    public var album: String
    public var duration: Double
    public var position: Double
    public var isPlaying: Bool
    public var playerSource: String // "Apple Music", "Spotify", etc.
    public var artworkData: Data?
    
    public init(
        title: String = "Not Playing",
        artist: String = "No Artist",
        album: String = "",
        duration: Double = 0,
        position: Double = 0,
        isPlaying: Bool = false,
        playerSource: String = "Music",
        artworkData: Data? = nil
    ) {
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.position = position
        self.isPlaying = isPlaying
        self.playerSource = playerSource
        self.artworkData = artworkData
    }
}
