import Foundation
import AppKit
import Combine

public struct MediaTrackInfo: Equatable {
    public var title: String = "Not Playing"
    public var artist: String = "Apple Music / Spotify"
    public var album: String = ""
    public var isPlaying: Bool = false
    public var duration: Double = 0
    public var position: Double = 0
    public var artwork: NSImage? = nil
    public var sourceApp: String = "Music"
    
    public static let placeholder = MediaTrackInfo(
        title: "No Media Playing",
        artist: "Play audio in Apple Music or Spotify",
        album: "OpenNotch Media Hub",
        isPlaying: false,
        duration: 180,
        position: 0,
        artwork: nil,
        sourceApp: "System"
    )
}

public final class MediaRemoteService: ObservableObject {
    public static let shared = MediaRemoteService()
    
    @Published public private(set) var currentTrack: MediaTrackInfo = .placeholder
    @Published public var visualizerLevels: [CGFloat] = [0.2, 0.4, 0.6, 0.3, 0.7, 0.5, 0.3, 0.8]
    
    private var timer: AnyCancellable?
    private var visualizerTimer: AnyCancellable?
    
    private init() {
        startPolling()
        startVisualizerSimulation()
    }
    
    public func startPolling() {
        timer = Timer.publish(every: 1.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshTrackInfo()
            }
        refreshTrackInfo()
    }
    
    public func refreshTrackInfo() {
        // Check Apple Music
        if let musicInfo = fetchAppleMusicTrack() {
            DispatchQueue.main.async {
                self.currentTrack = musicInfo
            }
            return
        }
        
        // Check Spotify
        if let spotifyInfo = fetchSpotifyTrack() {
            DispatchQueue.main.async {
                self.currentTrack = spotifyInfo
            }
            return
        }
        
        // Fallback default
        if currentTrack.title != "No Media Playing" && !currentTrack.isPlaying {
            DispatchQueue.main.async {
                self.currentTrack = .placeholder
            }
        }
    }
    
    public func togglePlayPause() {
        if isAppRunning("com.apple.Music") {
            runAppleScript("""
            tell application "Music"
                playpause
            end tell
            """)
        } else if isAppRunning("com.spotify.client") {
            runAppleScript("""
            tell application "Spotify"
                playpause
            end tell
            """)
        }
        refreshTrackInfo()
    }
    
    public func nextTrack() {
        if isAppRunning("com.apple.Music") {
            runAppleScript("""
            tell application "Music" to next track
            """)
        } else if isAppRunning("com.spotify.client") {
            runAppleScript("""
            tell application "Spotify" to next track
            """)
        }
        refreshTrackInfo()
    }
    
    public func previousTrack() {
        if isAppRunning("com.apple.Music") {
            runAppleScript("""
            tell application "Music" to previous track
            """)
        } else if isAppRunning("com.spotify.client") {
            runAppleScript("""
            tell application "Spotify" to previous track
            """)
        }
        refreshTrackInfo()
    }
    
    private func fetchAppleMusicTrack() -> MediaTrackInfo? {
        guard isAppRunning("com.apple.Music") else { return nil }
        
        let script = """
        tell application "Music"
            if player state is playing or player state is paused then
                set trackName to name of current track
                set artistName to artist of current track
                set albumName to album of current track
                set isPlay to (player state is playing)
                set curPos to player position
                set trackDur to duration of current track
                return trackName & "||" & artistName & "||" & albumName & "||" & (isPlay as text) & "||" & (curPos as text) & "||" & (trackDur as text)
            end if
        end tell
        """
        guard let output = runAppleScript(script), !output.isEmpty else { return nil }
        let parts = output.components(separatedBy: "||")
        guard parts.count >= 6 else { return nil }
        
        return MediaTrackInfo(
            title: parts[0],
            artist: parts[1],
            album: parts[2],
            isPlaying: parts[3].lowercased() == "true",
            duration: Double(parts[5]) ?? 180,
            position: Double(parts[4]) ?? 0,
            artwork: nil,
            sourceApp: "Apple Music"
        )
    }
    
    private func fetchSpotifyTrack() -> MediaTrackInfo? {
        guard isAppRunning("com.spotify.client") else { return nil }
        
        let script = """
        tell application "Spotify"
            if player state is playing or player state is paused then
                set trackName to name of current track
                set artistName to artist of current track
                set albumName to album of current track
                set isPlay to (player state is playing)
                set curPos to player position
                set trackDur to (duration of current track) / 1000
                return trackName & "||" & artistName & "||" & albumName & "||" & (isPlay as text) & "||" & (curPos as text) & "||" & (trackDur as text)
            end if
        end tell
        """
        guard let output = runAppleScript(script), !output.isEmpty else { return nil }
        let parts = output.components(separatedBy: "||")
        guard parts.count >= 6 else { return nil }
        
        return MediaTrackInfo(
            title: parts[0],
            artist: parts[1],
            album: parts[2],
            isPlaying: parts[3].lowercased() == "true",
            duration: Double(parts[5]) ?? 180,
            position: Double(parts[4]) ?? 0,
            artwork: nil,
            sourceApp: "Spotify"
        )
    }
    
    private func isAppRunning(_ bundleId: String) -> Bool {
        return NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).first != nil
    }
    
    @discardableResult
    private func runAppleScript(_ source: String) -> String? {
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: source) {
            let output = scriptObject.executeAndReturnError(&error)
            if error == nil {
                return output.stringValue
            }
        }
        return nil
    }
    
    private func startVisualizerSimulation() {
        visualizerTimer = Timer.publish(every: 0.12, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.currentTrack.isPlaying {
                    self.visualizerLevels = (0..<8).map { _ in
                        CGFloat.random(in: 0.15...0.95)
                    }
                } else {
                    self.visualizerLevels = Array(repeating: 0.1, count: 8)
                }
            }
    }
}
