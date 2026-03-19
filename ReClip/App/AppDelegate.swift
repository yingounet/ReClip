// MARK: - ReClip/App/AppDelegate.swift
// 应用生命周期管理

import AppKit

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var windowController: MainWindowController?
    private var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupDockIcon()
        setupStatusItem()
        
        // 初始化服务
        _ = ClipboardStorage.shared
        ClipboardMonitor.shared.startMonitoring()
        
        checkPermissions()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        ClipboardMonitor.shared.stopMonitoring()
    }
    
    // MARK: - Setup
    
    private func setupDockIcon() {
        if Settings.shared.showInDock {
            NSApp.setActivationPolicy(.regular)
        } else {
            NSApp.setActivationPolicy(.accessory)
        }
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "clipboard.on.clipboard", accessibilityDescription: "ReClip")
            button.image?.isTemplate = true
        }
        
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "打开 ReClip", action: #selector(showMainWindow), keyEquivalent: "c"))
        menu.items.last?.keyEquivalentModifierMask = [.option, .command]
        
        menu.addItem(NSMenuItem.separator())
        
        if let lastApp = ClipboardMonitor.shared.lastCopiedApp {
            menu.addItem(NSMenuItem(title: "最近复制: \(lastApp)", action: nil, keyEquivalent: ""))
        }
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "设置...", action: #selector(showSettings), keyEquivalent: ","))
        menu.items.last?.keyEquivalentModifierMask = [.command]
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "退出 ReClip", action: #selector(quitApp), keyEquivalent: "q"))
        menu.items.last?.keyEquivalentModifierMask = [.command]
        
        statusItem?.menu = menu
    }
    
    // MARK: - Actions
    
    @objc func showMainWindow() {
        if windowController == nil {
            windowController = MainWindowController()
        }
        windowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func showSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
    
    // MARK: - Permissions
    
    private func checkPermissions() {
        if !PasteService.shared.checkAccessibilityPermission() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.showPermissionAlert()
            }
        }
    }
    
    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "需要辅助功能权限"
        alert.informativeText = "ReClip 需要辅助功能权限来自动粘贴内容到其他应用。\n\n请在系统设置 → 隐私与安全性 → 辅助功能 中启用 ReClip。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "打开系统设置")
        alert.addButton(withTitle: "稍后")
        
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
    }
    
    // MARK: - Dock Icon Toggle
    
    func toggleDockIcon(_ show: Bool) {
        if show {
            NSApp.setActivationPolicy(.regular)
        } else {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
