// MARK: - ReClip/Views/Settings/HotkeySettingsView.swift
// 快捷键设置页面

import SwiftUI
import KeyboardShortcuts

struct HotkeySettingsView: View {
    var body: some View {
        Form {
            Section("全局快捷键") {
                HStack {
                    Text("打开 ReClip")
                    Spacer()
                    KeyboardShortcuts.Recorder(for: .showMainWindow) {
                        Text("点击设置快捷键")
                    }
                }
            }
            
            Section("快捷键说明") {
                VStack(alignment: .leading, spacing: 8) {
                    ShortcutRow(keys: "⌥⌘C", description: "打开/关闭主窗口")
                    ShortcutRow(keys: "↵", description: "选中并粘贴")
                    ShortcutRow(keys: "⌘↵", description: "仅复制到剪贴板")
                    ShortcutRow(keys: "⌫", description: "删除选中项")
                    ShortcutRow(keys: "⌘S", description: "收藏/取消收藏")
                    ShortcutRow(keys: "↑ ↓", description: "上下导航")
                    ShortcutRow(keys: "j k", description: "Vim 风格导航")
                    ShortcutRow(keys: "⌘1-9", description: "快速选择第 1-9 条")
                    ShortcutRow(keys: "Esc", description: "关闭窗口")
                    ShortcutRow(keys: "⌘F", description: "聚焦搜索框")
                }
                .padding(.vertical, 8)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct ShortcutRow: View {
    let keys: String
    let description: String
    
    var body: some View {
        HStack {
            Text(keys)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(description)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

#Preview {
    HotkeySettingsView()
        .frame(width: 500, height: 400)
}
