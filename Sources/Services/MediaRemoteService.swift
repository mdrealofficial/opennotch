import Foundation
import AppKit
import Combine

public struct MediaTrackInfo: Equatable {
    public let title: String
    public let artist: String
    public let album: String
    public let isPlaying: Bool
    public let artworkData: Data?
    public let duration: Double
    public let position: Double
    public let sourceApp: String
    
    public init(title: String = "", artist: String = "", album: String = "", isPlaying: Bool = false, artworkData: Data? = nil, duration: Double = 0, position: Double = 0, sourceApp: String = "Media") {
        self.title = title
        self.artist = artist
        self.album = album
        self.isPlaying = isPlaying
        self.artworkData = artworkData
        self.duration = duration
        self.position = position
        self.sourceApp = sourceApp
    }
}

// MediaRemote C function signatures
private typealias MRMediaRemoteGetNowPlayingInfoFunction = @convention(c) (DispatchQueue, @escaping (NSDictionary?) -> Void) -> Void
private typealias MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction = @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void
private typealias MRMediaRemoteSendCommandFunction = @convention(c) (Int32, AnyObject?) -> Bool

public final class MediaRemoteService: ObservableObject {
    public static let shared = MediaRemoteService()
    
    @Published public var currentTrack = MediaTrackInfo()
    @Published public var visualizerLevels: [CGFloat] = [0.3, 0.6, 0.8, 0.4]
    
    private var timer: AnyCancellable?
    private var visualizerTimer: AnyCancellable?
    private var mediaRemoteHandle: UnsafeMutableRawPointer?
    
    private var getNowPlayingInfo: MRMediaRemoteGetNowPlayingInfoFunction?
    private var getIsPlaying: MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction?
    private var sendCommand: MRMediaRemoteSendCommandFunction?
    
    private init() {
        loadMediaRemote()
        startPolling()
        startVisualizer()
    }
    
    private func loadMediaRemote() {
        let path = "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote"
        mediaRemoteHandle = dlopen(path, RTLD_NOW)
        guard let handle = mediaRemoteHandle else {
            print("MediaRemote: Unable to load framework")
            return
        }
        
        if let ptr = dlsym(handle, "MRMediaRemoteGetNowPlayingInfo") {
            getNowPlayingInfo = unsafeBitCast(ptr, to: MRMediaRemoteGetNowPlayingInfoFunction.self)
        }
        if let ptr = dlsym(handle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying") {
            getIsPlaying = unsafeBitCast(ptr, to: MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction.self)
        }
        if let ptr = dlsym(handle, "MRMediaRemoteSendCommand") {
            sendCommand = unsafeBitCast(ptr, to: MRMediaRemoteSendCommandFunction.self)
        }
    }
    
    private func startPolling() {
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchMediaState()
            }
        fetchMediaState()
    }
    
    private func startVisualizer() {
        visualizerTimer = Timer.publish(every: 0.15, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.currentTrack.isPlaying {
                    self.visualizerLevels = [
                        CGFloat.random(in: 0.2...1.0),
                        CGFloat.random(in: 0.4...1.0),
                        CGFloat.random(in: 0.3...0.9),
                        CGFloat.random(in: 0.5...1.0)
                    ]
                } else {
                    self.visualizerLevels = [0.2, 0.2, 0.2, 0.2]
                }
            }
    }
    
    public func fetchMediaState() {
        guard let getNowPlayingInfo = getNowPlayingInfo,
              let getIsPlaying = getIsPlaying else { return }
        
        getIsPlaying(DispatchQueue.main) { [weak self] playing in
            guard let self = self else { return }
            
            getNowPlayingInfo(DispatchQueue.main) { infoDict in
                guard let dict = infoDict else {
                    if self.currentTrack.isPlaying != playing {
                        self.currentTrack = MediaTrackInfo(isPlaying: playing)
                    }
                    return
                }
                
                let title = dict["kMRMediaRemoteNowPlayingInfoTitle"] as? String ?? ""
                let artist = dict["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? ""
                let album = dict["kMRMediaRemoteNowPlayingInfoAlbum"] as? String ?? ""
                let artworkData = dict["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data
                let duration = dict["kMRMediaRemoteNowPlayingInfoDuration"] as? Double ?? 0
                let position = dict["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? Double ?? 0
                
                let track = MediaTrackInfo(
                    title: title.isEmpty ? (playing ? "Playing Audio" : "") : title,
                    artist: artist,
                    album: album,
                    isPlaying: playing,
                    artworkData: artworkData,
                    duration: duration,
                    position: position
                )
                
                if self.currentTrack != track {
                    self.currentTrack = track
                }
            }
        }
    }
    
    public func togglePlayPause() {
        _ = sendCommand?(0, nil) // 0 = TogglePlayPause
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.fetchMediaState()
        }
    }
    
    public func nextTrack() {
        _ = sendCommand?(4, nil) // 4 = NextTrack
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.fetchMediaState()
        }
    }
    
    public func previousTrack() {
        _ = sendCommand?(5, nil) // 5 = PreviousTrack
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.fetchMediaState()
        }
    }
}
