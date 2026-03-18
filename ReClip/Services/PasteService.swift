// MARK: - ReClip/Services/PasteService.swift
// 粘贴服务

import Foundation
import AppKit
@preconcurrency import ApplicationServices
import CoreGraphics

@MainActor
final class PasteService {
    private let pasteboard = NSPasteboard.general
    
    // MARK: - Singleton
    static let shared = PasteService()
    
    private init() {}
    
    // MARK: - Copy to Clipboard
    
    func copyToClipboard(_ item: ClipboardItem) {
        pasteboard.clearContents()
        
        switch item.dataType {
        case .text:
            if let text = item.textContent {
                pasteboard.setString(text, forType: .string)
                Logger.debug("Copied text to clipboard")
            }
            
        case .image:
            if let imagePath = item.imagePath {
                let fullPath = Constants.applicationSupportURL().appendingPathComponent(imagePath)
                if let image = NSImage(contentsOfFile: fullPath.path) {
                    pasteboard.writeObjects([image])
                    Logger.debug("Copied image to clipboard")
                }
            }
            
        case .file:
            if let filePaths = item.filePaths {
                let urls = filePaths.compactMap { URL(fileURLWithPath: $0) }
                pasteboard.writeObjects(urls as [NSURL])
                Logger.debug("Copied \(urls.count) files to clipboard")
            }
        }
    }
    
    // MARK: - Simulate Paste
    
    func simulatePaste() {
        guard checkAccessibilityPermission() else {
            Logger.warning("Accessibility permission not granted")
            return
        }
        
        let source = CGEventSource(stateID: .combinedSessionState)
        
        // V key down
        let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        vDown?.flags = .maskCommand
        vDown?.post(tap: .cgAnnotatedSessionEventTap)
        
        // V key up
        let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        vUp?.flags = .maskCommand
        vUp?.post(tap: .cgAnnotatedSessionEventTap)
        
        Logger.debug("Simulated Cmd+V")
    }
    
    func copyAndPaste(_ item: ClipboardItem) {
        copyToClipboard(item)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.simulatePaste()
        }
    }
    
    // MARK: - Permission Check
    
    func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
    
    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}
