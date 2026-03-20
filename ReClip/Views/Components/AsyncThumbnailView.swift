// MARK: - ReClip/Views/Components/AsyncThumbnailView.swift
// 异步缩略图视图 - 后台加载，避免阻塞主线程

import SwiftUI

struct AsyncThumbnailView: View {
    let imagePath: String
    let maxSize: CGSize
    
    @State private var thumbnail: NSImage?
    
    init(imagePath: String, maxSize: CGSize = CGSize(width: 40, height: 40)) {
        self.imagePath = imagePath
        self.maxSize = maxSize
    }
    
    var body: some View {
        Group {
            if let thumbnail {
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
        }
        .task {
            guard !imagePath.isEmpty else { return }
            PreviewGenerator.shared.generateThumbnailAsync(for: imagePath, maxSize: maxSize) { image in
                thumbnail = image
            }
        }
        .onChange(of: imagePath) { _ in
            thumbnail = nil
            Task {
                PreviewGenerator.shared.generateThumbnailAsync(for: imagePath, maxSize: maxSize) { image in
                    thumbnail = image
                }
            }
        }
    }
}
