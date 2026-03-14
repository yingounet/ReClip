// MARK: - ReClip/Views/Settings/SettingsView.swift
// 设置主界面

import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("通用", systemImage: "gear")
                }
            
            FilterSettingsView()
                .tabItem {
                    Label("隐私", systemImage: "lock.shield")
                }
            
            StorageSettingsView()
                .tabItem {
                    Label("存储", systemImage: "externaldrive")
                }
            
            HotkeySettingsView()
                .tabItem {
                    Label("快捷键", systemImage: "keyboard")
                }
        }
        .frame(width: 500, height: 400)
    }
}

#Preview {
    SettingsView()
}
