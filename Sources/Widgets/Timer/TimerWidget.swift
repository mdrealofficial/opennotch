import SwiftUI
import Combine

public enum TimerMode: String, CaseIterable, Identifiable {
    case countdown = "Timer"
    case stopwatch = "Stopwatch"
    
    public var id: String { rawValue }
}

public final class NotchTimerService: ObservableObject {
    public static let shared = NotchTimerService()
    
    @Published public var mode: TimerMode = .countdown
    @Published public var isRunning: Bool = false
    @Published public var totalSeconds: Int = 1500 // default 25 min Pomodoro
    @Published public var remainingSeconds: Int = 1500
    @Published public var stopwatchElapsed: Int = 0
    
    private var timerCancellable: AnyCancellable?
    
    private init() {}
    
    public var displayString: String {
        if mode == .countdown {
            let m = remainingSeconds / 60
            let s = remainingSeconds % 60
            return String(format: "%02d:%02d", m, s)
        } else {
            let m = stopwatchElapsed / 60
            let s = stopwatchElapsed % 60
            return String(format: "%02d:%02d", m, s)
        }
    }
    
    public func start() {
        guard !isRunning else { return }
        isRunning = true
        
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.mode == .countdown {
                    if self.remainingSeconds > 0 {
                        self.remainingSeconds -= 1
                    } else {
                        self.pause()
                        NSSound.beep()
                    }
                } else {
                    self.stopwatchElapsed += 1
                }
            }
    }
    
    public func pause() {
        isRunning = false
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
    public func reset() {
        pause()
        if mode == .countdown {
            remainingSeconds = totalSeconds
        } else {
            stopwatchElapsed = 0
        }
    }
    
    public func setCountdown(minutes: Int) {
        pause()
        totalSeconds = minutes * 60
        remainingSeconds = totalSeconds
    }
}

public struct TimerWidgetView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var timerService = NotchTimerService.shared
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 20) {
            // Main Timer Display
            VStack(alignment: .leading, spacing: 8) {
                Picker("", selection: $timerService.mode) {
                    ForEach(TimerMode.allCases) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
                
                Text(timerService.displayString)
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.primary)
                
                // Play / Pause / Reset Buttons
                HStack(spacing: 12) {
                    Button(action: {
                        if timerService.isRunning {
                            timerService.pause()
                        } else {
                            timerService.start()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: timerService.isRunning ? "pause.fill" : "play.fill")
                            Text(timerService.isRunning ? "Pause" : "Start")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(timerService.isRunning ? OpenNotchTheme.accentOrange : OpenNotchTheme.accentGreen)
                        )
                        .foregroundStyle(Color.white)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        timerService.reset()
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 13, weight: .bold))
                            .padding(7)
                            .background(Circle().fill(OpenNotchTheme.cardFill(for: colorScheme)))
                            .overlay(Circle().strokeBorder(OpenNotchTheme.cardBorder(for: colorScheme), lineWidth: 1))
                            .foregroundStyle(Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
                .background(OpenNotchTheme.dividerColor(for: colorScheme))
            
            // Preset Quick Buttons
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Presets")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.secondary)
                
                HStack(spacing: 8) {
                    PresetButton(title: "Pomodoro", duration: "25m", minutes: 25)
                    PresetButton(title: "Short Break", duration: "5m", minutes: 5)
                }
                
                HStack(spacing: 8) {
                    PresetButton(title: "Long Break", duration: "15m", minutes: 15)
                    PresetButton(title: "Quick Focus", duration: "10m", minutes: 10)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

public struct PresetButton: View {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let duration: String
    let minutes: Int
    
    public var body: some View {
        Button(action: {
            NotchTimerService.shared.setCountdown(minutes: minutes)
        }) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.secondary)
                
                Text(duration)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(OpenNotchTheme.accentPurple)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(OpenNotchTheme.cardFill(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(OpenNotchTheme.cardBorder(for: colorScheme), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 4, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}
