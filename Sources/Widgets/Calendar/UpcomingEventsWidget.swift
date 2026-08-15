import SwiftUI

public struct UpcomingEventsWidgetView: View {
    @AppStorage("quickScratchpadNote") private var quickNote: String = ""
    
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f
    }()
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 16) {
            // Calendar Left Section
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.pink)
                    
                    Text(dateFormatter.string(from: Date()))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(OpenNotchTheme.textPrimary)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    EventRow(
                        title: "Team Standup & Sprint Sync",
                        time: "10:30 AM",
                        tagColor: Color.purple
                    )
                    EventRow(
                        title: "OpenNotch Architecture Review",
                        time: "2:00 PM",
                        tagColor: OpenNotchTheme.accentCyan
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
                .background(OpenNotchTheme.subtleDivider)
            
            // Quick Scratchpad Note
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "note.text")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.yellow)
                    
                    Text("Quick Scratchpad")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(OpenNotchTheme.textPrimary)
                    
                    Spacer()
                    
                    if !quickNote.isEmpty {
                        Button("Clear") {
                            quickNote = ""
                        }
                        .font(.system(size: 10))
                        .foregroundStyle(OpenNotchTheme.textTertiary)
                        .buttonStyle(.plain)
                    }
                }
                
                TextField("Type temporary notes, keys, or links...", text: $quickNote)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(OpenNotchTheme.inputBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(OpenNotchTheme.cardBorder, lineWidth: 1)
                    )
                    .foregroundStyle(OpenNotchTheme.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

public struct EventRow: View {
    let title: String
    let time: String
    let tagColor: Color
    
    public var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(tagColor)
                .frame(width: 7, height: 7)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(OpenNotchTheme.textPrimary)
                .lineLimit(1)
            
            Spacer()
            
            Text(time)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(OpenNotchTheme.textSecondary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(OpenNotchTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(OpenNotchTheme.cardBorder, lineWidth: 1)
        )
    }
}
