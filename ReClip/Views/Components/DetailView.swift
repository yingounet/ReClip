// MARK: - ReClip/Views/Components/DetailView.swift
// 详情预览视图

import SwiftUI

struct DetailView: View {
    let item: ClipboardItem
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 头部信息
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.dataType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let appName = item.appName {
                        Text("来源: \(appName)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(item.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("关闭") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
            
            Divider()
            
            // 内容
            ScrollView {
                switch item.dataType {
                case .text:
                    TextDetailView(text: item.textContent ?? "")
                    
                case .image:
                    ImageDetailView(imagePath: item.imagePath)
                    
                case .file:
                    FileDetailView(filePaths: item.filePaths ?? [])
                }
            }
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
}

// MARK: - Text Detail View

struct TextDetailView: View {
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("文本内容")
                    .font(.headline)
                
                Spacer()
                
                Button("复制") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                }
                .buttonStyle(.bordered)
            }
            
            Text(text)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .padding()
                .background(Color.primary.opacity(0.05))
                .cornerRadius(8)
        }
    }
}

// MARK: - Image Detail View

struct ImageDetailView: View {
    let imagePath: String?
    @State private var image: NSImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("图片预览")
                    .font(.headline)
                
                Spacer()
                
                if let image = image {
                    Text("\(Int(image.size.width)) × \(Int(image.size.height))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("复制") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.writeObjects([image])
                    }
                    .buttonStyle(.bordered)
                    
                    Button("保存...") {
                        saveImage()
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(8)
            } else {
                Text("无法加载图片")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let imagePath = imagePath else { return }
        let fullPath = Constants.applicationSupportURL().appendingPathComponent(imagePath)
        image = NSImage(contentsOfFile: fullPath.path)
    }
    
    private func saveImage() {
        guard let image = image else { return }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "reclip_image.png"
        
        if panel.runModal() == .OK, let url = panel.url {
            if let tiffData = image.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiffData),
               let pngData = bitmap.representation(using: .png, properties: [:]) {
                try? pngData.write(to: url)
            }
        }
    }
}

// MARK: - File Detail View

struct FileDetailView: View {
    let filePaths: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("文件列表 (\(filePaths.count) 个)")
                    .font(.headline)
                
                Spacer()
                
                Button("在 Finder 中显示") {
                    if let firstPath = filePaths.first {
                        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: firstPath)])
                    }
                }
                .buttonStyle(.bordered)
            }
            
            ForEach(filePaths, id: \.self) { path in
                HStack(spacing: 12) {
                    Image(nsImage: PreviewGenerator.shared.iconForFile(path))
                        .resizable()
                        .frame(width: 24, height: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(URL(fileURLWithPath: path).lastPathComponent)
                            .font(.body)
                        
                        Text(path)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("打开") {
                        NSWorkspace.shared.open(URL(fileURLWithPath: path))
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.vertical, 4)
            }
        }
    }
}

#Preview {
    DetailView(item: ClipboardItem(
        appBundleId: "com.apple.Safari",
        appName: "Safari",
        dataType: .text,
        contentPreview: "Test",
        dataHash: "abc",
        textContent: "This is a long text content that should be displayed in the detail view..."
    ))
}
