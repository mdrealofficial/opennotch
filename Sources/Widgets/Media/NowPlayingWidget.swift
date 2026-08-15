import SwiftUI

public struct NowPlayingWidgetView: View {
    @ObservedObject var mediaService = MediaRemoteService.shared
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 16) {
            // Album Art or App Icon
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: mediaService.currentTrack.isPlaying ? "music.note" : "waveform")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            // Track Info & Progress
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(mediaService.currentTrack.title)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        
                        Text(mediaService.currentTrack.artist)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    VisualizerBarView(
                        levels: mediaService.visualizerLevels,
                        barColor: mediaService.currentTrack.isPlaying ? Color.green : Color.white.opacity(0.4)
                    )
                }
                
                // Progress Bar
                ProgressView(value: min(1.0, max(0.0, mediaService.currentTrack.duration > 0 ? mediaService.currentTrack.position / mediaService.currentTrack.duration : 0.3)))
                    .progressViewStyle(.linear)
                    .tint(.purple)
                
                // Controls
                HStack(spacing: 18) {
                    Text(mediaService.currentTrack.sourceApp)
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.white.opacity(0.15)))
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Button(action: { mediaService.previousTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { mediaService.togglePlayPause() }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: mediaService.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.black)
                                .offset(x: mediaService.currentTrack.isPlaying ? 0 : 1)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { mediaService.nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 4)
    }
}
