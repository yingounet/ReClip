// MARK: - ReClip/Views/Components/ClipRowView.swift
// 剪贴板条目行视图

import SwiftUI

struct ClipRowView: View {
    let item: ClipboardItem
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            contentTypeIcon
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(displayTitle)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if item.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 12))
                    }
                    
                    Text(formattedTime)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                if let appName = item.appName {
                    Text(appName)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .contentShape(Rectangle())
    }
    
    @ViewBuilder
    private var contentTypeIcon: some View {
        switch item.dataType {
        case .text:
            Image(systemName: "doc.text")
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
            
        case .image:
            if let thumbnail = PreviewGenerator.shared.generateThumbnail(for: item.imagePath ?? "") {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .cornerRadius(6)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
                    .frame(width: 32, height: 32)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(6)
            }
            
        case .file:
            if let filePaths = item.filePaths, let firstPath = filePaths.first {
                Image(nsImage: PreviewGenerator.shared.iconForFile(firstPath))
                    .resizable()
                    .frame(width: 32, height: 32)
            } else {
                Image(systemName: "folder")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
                    .frame(width: 32, height: 32)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
            }
        }
    }
    
    private var displayTitle: String {
        switch item.dataType {
        case .text:
            return item.contentPreview.replacingOccurrences(of: "\n", with: " ")
        case .image, .file:
            return item.contentPreview
        }
    }
    
    private var formattedTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: item.timestamp, relativeTo: Date())
    }
}

#Preview {
    VStack {
        ClipRowView(
            item: ClipboardItem(
                appBundleId: "com.apple.Safari",
                appName: "Safari",
                dataType: .text,
                contentPreview: "Hello World, this is a test text",
                dataHash: "abc123",
                textContent: "Hello World, this is a test text"
            ),
            isSelected: true
        )
        
        ClipRowView(
            item: ClipboardItem(
                appBundleId: "com.apple.Preview",
                appName: "预览",
                dataType: .image,
                contentPreview: "[Image: 1920×1080]",
                dataHash: "def456"
            ),
            isSelected: false
        )
    }
    .frame(width: 500)
}
