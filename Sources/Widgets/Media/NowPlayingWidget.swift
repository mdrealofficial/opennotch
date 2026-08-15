import SwiftUI

public struct NowPlayingWidgetView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var mediaService = MediaRemoteService.shared
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 16) {
            // Album Art / Music Icon
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        colorScheme == .dark
                            ? LinearGradient(colors: [Color(red: 45/255, green: 25/255, blue: 65/255), Color(red: 25/255, green: 25/255, blue: 40/255)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color(red: 235/255, green: 225/255, blue: 250/255), Color(red: 220/255, green: 230/255, blue: 255/255)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 72, height: 72)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(OpenNotchTheme.cardBorder(for: colorScheme), lineWidth: 1)
                    )
                    .shadow(color: Color.purple.opacity(colorScheme == .dark ? 0.25 : 0.12), radius: 8, x: 0, y: 3)
                
                Image(systemName: mediaService.currentTrack.isPlaying ? "music.note" : "waveform")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(OpenNotchTheme.iconGradient(for: colorScheme))
            }
            
            // Track Info & Progress
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(mediaService.currentTrack.title)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.primary)
                            .lineLimit(1)
                        
                        Text(mediaService.currentTrack.artist)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    VisualizerBarView(
                        levels: mediaService.visualizerLevels,
                        barColor: mediaService.currentTrack.isPlaying ? OpenNotchTheme.accentGreen : Color.secondary.opacity(0.4)
                    )
                }
                
                // Progress Bar
                ProgressView(value: min(1.0, max(0.0, mediaService.currentTrack.duration > 0 ? mediaService.currentTrack.position / mediaService.currentTrack.duration : 0.3)))
                    .progressViewStyle(.linear)
                    .tint(OpenNotchTheme.accentPurple)
                
                // Controls
                HStack(spacing: 16) {
                    Text(mediaService.currentTrack.sourceApp)
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(OpenNotchTheme.tabSelectedFill(for: colorScheme)))
                        .overlay(Capsule().strokeBorder(OpenNotchTheme.cardBorder(for: colorScheme), lineWidth: 0.8))
                        .foregroundStyle(Color.secondary)
                    
                    Spacer()
                    
                    Button(action: { mediaService.previousTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.primary)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { mediaService.togglePlayPause() }) {
                        ZStack {
                            Circle()
                                .fill(Color.primary)
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: mediaService.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
                                .offset(x: mediaService.currentTrack.isPlaying ? 0 : 1)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { mediaService.nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(OpenNotchTheme.cardFill(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(OpenNotchTheme.cardBorder(for: colorScheme), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 6, x: 0, y: 2)
    }
}
