// MARK: - ReClip/Views/Components/FooterBar.swift
// 底部提示栏

import SwiftUI

struct FooterBar: View {
    var body: some View {
        HStack(spacing: 16) {
            ShortcutHint(key: "⌘1-9", description: "快速选择")
            ShortcutHint(key: "↵", description: "粘贴")
            ShortcutHint(key: "⌫", description: "删除")
            ShortcutHint(key: "⌘S", description: "收藏")
            ShortcutHint(key: "Esc", description: "关闭")
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .font(.system(size: 11))
    }
}

struct ShortcutHint: View {
    let key: String
    let description: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text(key)
                .foregroundColor(.secondary)
            Text(description)
                .foregroundColor(.secondary.opacity(0.7))
        }
    }
}

#Preview {
    FooterBar()
        .frame(width: 600)
}
