// MARK: - ReClip/Services/PreviewGenerator.swift
// 预览生成服务

import Foundation
import AppKit

@MainActor
final class PreviewGenerator {
    
    private static let thumbnailCache = NSCache<NSString, NSImage>()
    private static let thumbnailCacheLimit = 80
    private static let thumbnailWorker = DispatchQueue(label: "com.reclip.thumbnail", qos: .userInitiated)
    
    // MARK: - Singleton
    static let shared = PreviewGenerator()
    
    private init() {
        Self.thumbnailCache.countLimit = Self.thumbnailCacheLimit
    }
    
    // MARK: - Image Thumbnail
    
    func generateThumbnail(for imagePath: String, maxSize: CGSize = CGSize(width: 40, height: 40)) -> NSImage? {
        guard !imagePath.isEmpty else { return nil }
        if let cached = Self.thumbnailCache.object(forKey: imagePath as NSString) {
            return cached
        }
        let fullPath = Constants.applicationSupportURL().appendingPathComponent(imagePath)
        guard let image = NSImage(contentsOfFile: fullPath.path) else { return nil }
        guard let resized = resizeImage(image, to: maxSize) else { return nil }
        Self.thumbnailCache.setObject(resized, forKey: imagePath as NSString)
        return resized
    }
    
    func generateThumbnailAsync(for imagePath: String, maxSize: CGSize = CGSize(width: 40, height: 40), completion: @escaping (NSImage?) -> Void) {
        guard !imagePath.isEmpty else {
            completion(nil)
            return
        }
        if let cached = Self.thumbnailCache.object(forKey: imagePath as NSString) {
            completion(cached)
            return
        }
        let path = imagePath
        Self.thumbnailWorker.async {
            let fullPath = Constants.applicationSupportURL().appendingPathComponent(path)
            guard let image = NSImage(contentsOfFile: fullPath.path) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            let resized = Self.resizeImageStatic(image, to: maxSize)
            DispatchQueue.main.async {
                if let resized {
                    Self.thumbnailCache.setObject(resized, forKey: path as NSString)
                }
                completion(resized)
            }
        }
    }
    
    private func resizeImage(_ image: NSImage, to maxSize: CGSize) -> NSImage? {
        let ratio = min(maxSize.width / image.size.width, maxSize.height / image.size.height)
        guard ratio < 1 else { return image }
        
        let newSize = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
        
        let resized = NSImage(size: newSize)
        resized.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize))
        resized.unlockFocus()
        
        return resized
    }
    
    private static nonisolated func resizeImageStatic(_ image: NSImage, to maxSize: CGSize) -> NSImage? {
        let ratio = min(maxSize.width / image.size.width, maxSize.height / image.size.height)
        guard ratio < 1 else { return image }
        let newSize = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
        let resized = NSImage(size: newSize)
        resized.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize))
        resized.unlockFocus()
        return resized
    }
    
    // MARK: - File Icon
    
    func iconForFile(_ path: String) -> NSImage {
        let url = URL(fileURLWithPath: path)
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 32, height: 32)
        return icon
    }
    
    func iconForApp(_ bundleId: String) -> NSImage? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
            return NSImage(systemSymbolName: "app", accessibilityDescription: nil)
        }
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 32, height: 32)
        return icon
    }
    
    // MARK: - Text Preview
    
    func previewText(_ text: String, maxLength: Int = 200) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= maxLength {
            return trimmed
        }
        return String(trimmed.prefix(maxLength)) + "..."
    }
    
    // MARK: - Content Type Icon
    
    func iconForContentType(_ type: ContentType) -> NSImage? {
        return NSImage(systemSymbolName: type.icon, accessibilityDescription: type.displayName)
    }
}
