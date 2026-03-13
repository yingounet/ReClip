// MARK: - ReClip/Services/HotkeyManager.swift
// 热键管理服务

import Foundation
import KeyboardShortcuts

final class HotkeyManager {
    var onShowMainWindow: (() -> Void)?
    
    // MARK: - Singleton
    static let shared = HotkeyManager()
    
    private init() {
        setupHotkeys()
    }
    
    private func setupHotkeys() {
        KeyboardShortcuts.onKeyUp(for: .showMainWindow) { [weak self] in
            self?.onShowMainWindow?()
        }
        
        Logger.info("Hotkey manager initialized")
    }
}

// MARK: - KeyboardShortcuts Extension

extension KeyboardShortcuts.Name {
    static let showMainWindow = Self("showMainWindow", default: .init(.c, modifiers: [.option, .command]))
}
