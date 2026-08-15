import SwiftUI
import UniformTypeIdentifiers

public struct StashedFile: Identifiable, Equatable {
    public let id = UUID()
    public let url: URL
    public let name: String
    public let sizeString: String
    
    public init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        
        if let resources = try? url.resourceValues(forKeys: [.fileSizeKey]),
           let size = resources.fileSize {
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useAll]
            formatter.countStyle = .file
            self.sizeString = formatter.string(fromByteCount: Int64(size))
        } else {
            self.sizeString = "Unknown size"
        }
    }
}

public final class DropShelfManager: ObservableObject {
    public static let shared = DropShelfManager()
    @Published public var files: [StashedFile] = []
    
    private init() {}
    
    public func addFile(url: URL) {
        if !files.contains(where: { $0.url == url }) {
            files.append(StashedFile(url: url))
        }
    }
    
    public func removeFile(id: UUID) {
        files.removeAll { $0.id == id }
    }
    
    public func clearAll() {
        files.removeAll()
    }
}

public struct DropShelfWidgetView: View {
    @ObservedObject var shelfManager = DropShelfManager.shared
    @State private var isTargeted: Bool = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 10) {
            HStack {
                Label("Drop Shelf & File Stash", systemImage: "tray.and.arrow.down.fill")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
                
                if !shelfManager.files.isEmpty {
                    Text("\(shelfManager.files.count) files")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                    
                    Button("Clear") {
                        shelfManager.clearAll()
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.red.opacity(0.8))
                    .buttonStyle(.plain)
                }
            }
            
            if shelfManager.files.isEmpty {
                // Drop Target Prompt
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            isTargeted ? Color.cyan : Color.white.opacity(0.2),
                            style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(isTargeted ? Color.cyan.opacity(0.12) : Color.white.opacity(0.04))
                        )
                    
                    VStack(spacing: 6) {
                        Image(systemName: isTargeted ? "arrow.down.circle.fill" : "plus.rectangle.on.folder")
                            .font(.system(size: 24))
                            .foregroundStyle(isTargeted ? .cyan : .white.opacity(0.6))
                        
                        Text(isTargeted ? "Drop to stash file" : "Drag & drop files here to hold or share")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.vertical, 16)
                }
                .frame(maxHeight: 110)
                .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted) { providers in
                    handleDrop(providers: providers)
                }
            } else {
                // Files List
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(shelfManager.files) { item in
                            StashedFileCard(file: item) {
                                shelfManager.removeFile(id: item.id)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 110)
                .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted) { providers in
                    handleDrop(providers: providers)
                }
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url = url {
                    DispatchQueue.main.async {
                        shelfManager.addFile(url: url)
                    }
                }
            }
        }
        return true
    }
}

public struct StashedFileCard: View {
    let file: StashedFile
    let onRemove: () -> Void
    
    public var body: some View {
        VStack(spacing: 4) {
            HStack {
                Spacer()
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            
            Image(nsImage: NSWorkspace.shared.icon(forFile: file.url.path))
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
            
            Text(file.name)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
                .frame(maxWidth: 80)
            
            Text(file.sizeString)
                .font(.system(size: 9, weight: .regular))
                .foregroundStyle(.white.opacity(0.5))
            
            HStack(spacing: 6) {
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(file.url.path, forType: .string)
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
                .help("Copy Path")
                
                Button(action: {
                    NSWorkspace.shared.selectFile(file.url.path, inFileViewerRootedAtPath: file.url.deletingLastPathComponent().path)
                }) {
                    Image(systemName: "folder")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
                .help("Reveal in Finder")
            }
            .padding(.top, 2)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
        .onDrag {
            NSItemProvider(object: file.url as NSURL)
        }
    }
}
