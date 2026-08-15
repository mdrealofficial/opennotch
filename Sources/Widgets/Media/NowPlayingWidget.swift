import SwiftUI

public struct NowPlayingWidgetView: View {
    @ObservedObject var mediaService = MediaRemoteService.shared
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 16) {
            // Album Art / Music Icon
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 40/255, green: 20/255, blue: 60/255), Color(red: 20/255, green: 20/255, blue: 35/255)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .shadow(color: Color.purple.opacity(0.25), radius: 10, x: 0, y: 4)
                
                Image(systemName: mediaService.currentTrack.isPlaying ? "music.note" : "waveform")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(OpenNotchTheme.silverIconGradient)
            }
            
            // Track Info & Progress
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(mediaService.currentTrack.title)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(OpenNotchTheme.textPrimary)
                            .lineLimit(1)
                        
                        Text(mediaService.currentTrack.artist)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(OpenNotchTheme.textSecondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    VisualizerBarView(
                        levels: mediaService.visualizerLevels,
                        barColor: mediaService.currentTrack.isPlaying ? OpenNotchTheme.accentGreen : Color.white.opacity(0.3)
                    )
                }
                
                // Progress Bar
                ProgressView(value: min(1.0, max(0.0, mediaService.currentTrack.duration > 0 ? mediaService.currentTrack.position / mediaService.currentTrack.duration : 0.3)))
                    .progressViewStyle(.linear)
                    .tint(.purple)
                
                // Controls
                HStack(spacing: 16) {
                    Text(mediaService.currentTrack.sourceApp)
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(OpenNotchTheme.cardBackground))
                        .overlay(Capsule().strokeBorder(OpenNotchTheme.cardBorder, lineWidth: 0.8))
                        .foregroundStyle(OpenNotchTheme.textSecondary)
                    
                    Spacer()
                    
                    Button(action: { mediaService.previousTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(OpenNotchTheme.silverIconGradient)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { mediaService.togglePlayPause() }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: mediaService.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color.black)
                                .offset(x: mediaService.currentTrack.isPlaying ? 0 : 1)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { mediaService.nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(OpenNotchTheme.silverIconGradient)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(OpenNotchTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(OpenNotchTheme.cardBorder, lineWidth: 1)
        )
    }
}
