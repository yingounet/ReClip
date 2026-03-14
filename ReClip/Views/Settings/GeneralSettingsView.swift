// MARK: - ReClip/Views/Settings/GeneralSettingsView.swift
// 通用设置页面

import SwiftUI
import LaunchAtLogin

struct GeneralSettingsView: View {
    @ObservedObject var settings = Settings.shared
    
    var body: some View {
        Form {
            Section("启动") {
                LaunchAtLogin.Toggle("开机自动启动")
                
                Toggle("显示在 Dock", isOn: $settings.showInDock)
                    .onChange(of: settings.showInDock) { _, newValue in
                        if newValue {
                            NSApp.setActivationPolicy(.regular)
                        } else {
                            NSApp.setActivationPolicy(.accessory)
                        }
                    }
            }
            
            Section("行为") {
                Toggle("选中后自动粘贴", isOn: $settings.autoPaste)
                Toggle("复制时播放声音", isOn: $settings.soundOnCopy)
                
                Picker("轮询间隔", selection: $settings.pollingInterval) {
                    Text("快速 (0.3s)").tag(0.3)
                    Text("标准 (0.5s)").tag(0.5)
                    Text("省电 (0.8s)").tag(0.8)
                }
            }
            
            Section("显示") {
                Stepper("字体大小: \(settings.fontSize)", value: $settings.fontSize, in: 12...20)
                Stepper("预览长度: \(settings.previewLength)", value: $settings.previewLength, in: 50...500)
                Toggle("显示来源应用", isOn: $settings.showAppName)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

#Preview {
    GeneralSettingsView()
        .frame(width: 500, height: 400)
}
