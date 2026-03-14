// MARK: - ReClip/Views/Components/EmptyStateView.swift
// 空状态视图

import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clipboard")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("暂无剪贴板历史")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            Text("复制一些内容，它们会自动出现在这里")
                .font(.system(size: 13))
                .foregroundColor(.secondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView()
        .frame(width: 600, height: 400)
}
