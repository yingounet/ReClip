// MARK: - ReClip/App/ReClipApp.swift
// 应用入口

import SwiftUI
import KeyboardShortcuts
import LaunchAtLogin

@main
struct ReClipApp: App {
    @StateObject private var viewModel = MainViewModel()
    @StateObject private var settings = Settings.shared
    
    var body: some Scene {
        MenuBarExtra("ReClip", systemImage: "clipboard.on.clipboard") {
            MenuBarView(viewModel: viewModel)
        }
        
        Settings {
            SettingsView()
        }
    }
    
    init() {
        setupApp()
    }
    
    private func setupApp() {
        if !settings.showInDock {
            NSApp.setActivationPolicy(.accessory)
        }
        
        ClipboardMonitor.shared.startMonitoring()
        
        let _ = ClipboardStorage.shared
        
        checkPermissions()
    }
    
    private func checkPermissions() {
        if !PasteService.shared.checkAccessibilityPermission() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                showPermissionAlert()
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
}

struct MenuBarView: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        Button("打开 ReClip") {
            viewModel.showWindow()
        }
        .keyboardShortcut("c", modifiers: [.option, .command])
        
        Divider()
        
        if let lastApp = ClipboardMonitor.shared.lastCopiedApp {
            Text("最近复制: \(lastApp)")
        }
        
        Divider()
        
        Button("设置...") {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
        .keyboardShortcut(",", modifiers: .command)
        
        Divider()
        
        Button("退出 ReClip") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
