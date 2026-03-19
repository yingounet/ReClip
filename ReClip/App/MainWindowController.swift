// MARK: - ReClip/App/MainWindowController.swift
// 主窗口控制器 - 管理 NSPanel 浮动窗口

import AppKit
import SwiftUI
import Combine

class MainWindowController: NSWindowController {
    
    private var viewModel: MainViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    
    init() {
        self.viewModel = MainViewModel.shared
        
        // 创建 NSPanel
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: Constants.UI.windowWidth, height: Constants.UI.windowHeight),
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )
        
        // 配置窗口属性
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .transient, .fullScreenAuxiliary]
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = false
        panel.acceptsMouseMovedEvents = true
        panel.styleMask.insert(.borderless)
        
        // 设置 SwiftUI 内容
        let contentView = MainWindowView(viewModel: viewModel)
        panel.contentView = NSHostingView(rootView: contentView)
        
        // 设置背景
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        
        super.init(window: panel)
        
        setupBindings()
        setupKeyboardMonitor()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        viewModel.$isWindowVisible
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isVisible in
                if isVisible {
                    self?.window?.makeKeyAndOrderFront(nil)
                    self?.centerWindow()
                } else {
                    self?.window?.orderOut(nil)
                }
            }
            .store(in: &cancellables)
        
        // 监听窗口失去焦点
        NotificationCenter.default.publisher(for: NSWindow.willCloseNotification, object: window)
            .sink { [weak self] _ in
                self?.viewModel.isWindowVisible = false
            }
            .store(in: &cancellables)
    }
    
    private func setupKeyboardMonitor() {
        // 全局键盘监听
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, self.window?.isKeyWindow == true else {
                return event
            }
            
            if self.handleKeyEvent(event) {
                return nil
            }
            
            return event
        }
    }
    
    // MARK: - Window Management
    
    private func centerWindow() {
        guard let window = window,
              let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowFrame = window.frame
        
        let x = (screenFrame.width - windowFrame.width) / 2
        let y = (screenFrame.height - windowFrame.height) / 2 + 100  // 稍微偏上
        
        window.setFrameOrigin(NSPoint(x: x + screenFrame.origin.x, y: y + screenFrame.origin.y))
    }
    
    override func showWindow(_ sender: Any?) {
        viewModel.showWindow()
        super.showWindow(sender)
        window?.makeFirstResponder(window?.contentView)
    }
    
    // MARK: - Keyboard Handling
    
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        
        // ↑ ↓ 方向键选择
        if event.keyCode == 126 {
            viewModel.moveUp()
            return true
        }
        if event.keyCode == 125 {
            viewModel.moveDown()
            return true
        }
        
        // ↵ 回车确认并粘贴
        if event.keyCode == 36, !flags.contains(.command) {
            viewModel.pasteSelected()
            return true
        }
        
        // ⌘1-9 快速选择
        if flags.contains(.command), let number = Int(event.characters ?? ""), (1...9).contains(number) {
            viewModel.selectQuick(number - 1)
            return true
        }
        
        // ⌘S 收藏
        if flags.contains(.command), event.keyCode == 1 {  // S key
            viewModel.toggleFavoriteSelected()
            return true
        }
        
        // ⌘F 聚焦搜索框
        if flags.contains(.command), event.keyCode == 3 {  // F key
            viewModel.focusSearch()
            return true
        }
        
        // ⌘↵ 仅复制
        if flags.contains(.command), event.keyCode == 36 {  // Return key
            viewModel.copySelected()
            viewModel.hideWindow()
            return true
        }
        
        // Esc 关闭
        if event.keyCode == 53 {
            viewModel.hideWindow()
            return true
        }
        
        return false
    }
}
