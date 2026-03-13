// MARK: - ReClip/Services/ClipboardMonitor.swift
// 剪贴板监控服务

import Foundation
import AppKit
import Combine

final class ClipboardMonitor: ObservableObject {
    @Published private(set) var isMonitoring = false
    @Published private(set) var lastCopiedApp: String?
    
    private var pasteboard = NSPasteboard.general
    private var changeCount: Int = 0
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    private var pollingInterval: TimeInterval = Constants.Monitor.defaultPollingInterval
    private let storage: ClipboardStorage
    private let settings: Settings
    
    var onNewClip: ((ClipboardItem) -> Void)?
    
    // MARK: - Singleton
    static let shared = ClipboardMonitor()
    
    private init() {
        self.storage = .shared
        self.settings = .shared
        self.changeCount = pasteboard.changeCount
        
        setupObservers()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Public Methods
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        changeCount = pasteboard.changeCount
        pollingInterval = settings.pollingInterval
        
        timer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
        
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
        
        Logger.info("Clipboard monitoring started")
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
        Logger.info("Clipboard monitoring stopped")
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        settings.$pollingInterval
            .sink { [weak self] newInterval in
                guard let self = self, self.isMonitoring else { return }
                self.pollingInterval = newInterval
                self.stopMonitoring()
                self.startMonitoring()
            }
            .store(in: &cancellables)
    }
    
    private func checkForChanges() {
        let currentCount = pasteboard.changeCount
        
        guard currentCount != changeCount else { return }
        changeCount = currentCount
        
        let sourceApp = getActiveApplication()
        
        guard !shouldIgnore(sourceApp: sourceApp) else {
            Logger.debug("Ignored copy from: \(sourceApp.bundleId ?? "unknown")")
            return
        }
        
        processClipboardContent(sourceApp: sourceApp)
    }
    
    private func getActiveApplication() -> (bundleId: String?, name: String?) {
        guard let app = NSWorkspace.shared.frontmostApplication else {
            return (nil, nil)
        }
        return (app.bundleIdentifier, app.localizedName)
    }
    
    private func shouldIgnore(sourceApp: (bundleId: String?, name: String?)) -> Bool {
        guard let bundleId = sourceApp.bundleId else { return false }
        
        let blacklist = Constants.defaultBlacklist + settings.customBlacklist
        
        for pattern in blacklist {
            if bundleId.contains(pattern) || bundleId == pattern {
                return true
            }
        }
        
        if settings.ignoreConcealedTypes {
            if let types = pasteboard.types {
                for type in types {
                    let typeString = type.rawValue.lowercased()
                    for ignored in Constants.ignoredUTIs {
                        if typeString.contains(ignored.lowercased()) {
                            return true
                        }
                    }
                }
            }
        }
        
        return false
    }
    
    private func processClipboardContent(sourceApp: (bundleId: String?, name: String?)) {
        if let files = readFiles(), !files.isEmpty {
            handleFiles(files, sourceApp: sourceApp)
        } else if let image = readImage() {
            handleImage(image, sourceApp: sourceApp)
        } else if let text = readText() {
            handleText(text, sourceApp: sourceApp)
        }
    }
    
    // MARK: - Content Readers
    
    private func readText() -> String? {
        guard let types = pasteboard.types else { return nil }
        
        let textTypes: [NSPasteboard.PasteboardType] = [
            .string,
            .init("public.utf8-plain-text"),
            .init("public.plain-text")
        ]
        
        for textType in textTypes {
            if types.contains(textType) {
                if let text = pasteboard.string(forType: .string) {
                    guard text.utf8.count <= settings.maxTextSize else {
                        Logger.warning("Text too large: \(text.utf8.count) bytes")
                        return nil
                    }
                    return text
                }
            }
        }
        
        return nil
    }
    
    private func readImage() -> NSImage? {
        guard let types = pasteboard.types else { return nil }
        
        let imageTypes: [NSPasteboard.PasteboardType] = [
            .tiff,
            .png,
            .fileURL,
            .init("public.image"),
            .init("public.jpeg"),
            .init("public.png"),
            .init("com.compuserve.gif")
        ]
        
        for imageType in imageTypes {
            if types.contains(imageType) {
                if let data = pasteboard.data(forType: imageType),
                   data.count <= settings.maxImageSize,
                   let image = NSImage(data: data) {
                    return image
                }
            }
        }
        
        return nil
    }
    
    private func readFiles() -> [URL]? {
        guard let types = pasteboard.types else { return nil }
        
        let fileTypes: [NSPasteboard.PasteboardType] = [
            .fileURL,
            .init("public.file-url"),
            .init("NSFilenamesPboardType")
        ]
        
        for fileType in fileTypes {
            if types.contains(fileType) {
                if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
                   !urls.isEmpty {
                    return urls
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Content Handlers
    
    private func handleText(_ text: String, sourceApp: (bundleId: String?, name: String?)) {
        let hash = HashGenerator.sha256(text)
        
        if settings.deduplicationEnabled && storage.exists(hash: hash) {
            storage.updateTimestamp(hash: hash)
            Logger.debug("Duplicate text, updated timestamp")
            return
        }
        
        let previewLength = settings.previewLength
        let preview = text.count > previewLength ? String(text.prefix(previewLength)) : text
        
        let item = ClipboardItem(
            appBundleId: sourceApp.bundleId,
            appName: sourceApp.name,
            dataType: .text,
            contentPreview: preview,
            dataHash: hash,
            textContent: text
        )
        
        saveAndNotify(item)
    }
    
    private func handleImage(_ image: NSImage, sourceApp: (bundleId: String?, name: String?)) {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            Logger.error("Failed to convert image to PNG")
            return
        }
        
        let hash = HashGenerator.sha256(pngData)
        
        if settings.deduplicationEnabled && storage.exists(hash: hash) {
            storage.updateTimestamp(hash: hash)
            Logger.debug("Duplicate image, updated timestamp")
            return
        }
        
        let imagePath = saveImageData(pngData, hash: hash)
        
        let item = ClipboardItem(
            appBundleId: sourceApp.bundleId,
            appName: sourceApp.name,
            dataType: .image,
            contentPreview: "[Image: \(Int(image.size.width))×\(Int(image.size.height))]",
            dataHash: hash,
            imagePath: imagePath
        )
        
        saveAndNotify(item)
    }
    
    private func handleFiles(_ urls: [URL], sourceApp: (bundleId: String?, name: String?)) {
        let fileNames = urls.map { $0.lastPathComponent }
        let combinedNames = fileNames.joined(separator: ",")
        let hash = HashGenerator.sha256(combinedNames)
        
        let preview: String
        if fileNames.count == 1 {
            preview = fileNames[0]
        } else {
            let truncated = combinedNames.prefix(100)
            preview = "[\(fileNames.count) files] \(truncated)"
        }
        
        let item = ClipboardItem(
            appBundleId: sourceApp.bundleId,
            appName: sourceApp.name,
            dataType: .file,
            contentPreview: preview,
            dataHash: hash,
            filePaths: urls.map { $0.path }
        )
        
        saveAndNotify(item)
    }
    
    private func saveImageData(_ data: Data, hash: String) -> String {
        let fileManager = FileManager.default
        let imagesDir = Constants.imagesDirectoryURL()
        
        do {
            if !fileManager.fileExists(atPath: imagesDir.path) {
                try fileManager.createDirectory(at: imagesDir, withIntermediateDirectories: true)
            }
            
            let imagePath = imagesDir.appendingPathComponent("\(hash).png")
            try data.write(to: imagePath)
            
            return "Images/\(hash).png"
        } catch {
            Logger.error("Failed to save image: \(error)")
            return ""
        }
    }
    
    private func saveAndNotify(_ item: ClipboardItem) {
        storage.insert(item)
        lastCopiedApp = item.appName
        
        if settings.soundOnCopy {
            NSSound(named: .init("Pop"))?.play()
        }
        
        onNewClip?(item)
        Logger.info("Saved clip: \(item.dataType.rawValue) from \(item.appName ?? "unknown")")
    }
}
