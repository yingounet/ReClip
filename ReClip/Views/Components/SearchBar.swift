// MARK: - ReClip/Views/Components/SearchBar.swift
// 搜索框组件

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    @FocusState var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18))
                .foregroundColor(.secondary)
            
            TextField("搜索剪贴板历史...", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .focused($isFocused)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(8)
    }
}

#Preview {
    SearchBar(text: .constant("test"))
        .padding()
        .frame(width: 400)
}
