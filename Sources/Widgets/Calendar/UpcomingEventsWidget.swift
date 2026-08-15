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
                        .foregroundStyle(.pink)
                    
                    Text(dateFormatter.string(from: Date()))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    EventRow(
                        title: "Team Standup & Sprint Sync",
                        time: "10:30 AM",
                        tagColor: .purple
                    )
                    EventRow(
                        title: "OpenNotch Architecture Review",
                        time: "2:00 PM",
                        tagColor: .cyan
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
                .background(Color.white.opacity(0.15))
            
            // Quick Scratchpad Note
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "note.text")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.yellow)
                    
                    Text("Quick Scratchpad")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    if !quickNote.isEmpty {
                        Button("Clear") {
                            quickNote = ""
                        }
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.5))
                        .buttonStyle(.plain)
                    }
                }
                
                TextField("Type temporary notes, keys, or links...", text: $quickNote)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.08))
                    )
                    .foregroundStyle(.white)
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
                .foregroundStyle(.white)
                .lineLimit(1)
            
            Spacer()
            
            Text(time)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.05))
        )
    }
}
