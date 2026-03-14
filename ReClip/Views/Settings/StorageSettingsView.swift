// MARK: - ReClip/Views/Settings/StorageSettingsView.swift
// 存储设置页面

import SwiftUI

struct StorageSettingsView: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject var storage = ClipboardStorage.shared
    
    @State private var showClearConfirmation = false
    
    var body: some View {
        Form {
            Section("保留策略") {
                Picker("历史保留时长", selection: $settings.retentionDays) {
                    ForEach(settings.retentionOptions, id: \.1) { option in
                        Text(option.0).tag(option.1)
                    }
                }
                
                Stepper("最大条目数: \(settings.maxHistoryItems)", value: $settings.maxHistoryItems, in: 100...10000)
            }
            
            Section("大小限制") {
                HStack {
                    Text("文本大小限制")
                    Spacer()
                    Text("\(settings.maxTextSize / 1024 / 1024) MB")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("图片大小限制")
                    Spacer()
                    Text("\(settings.maxImageSize / 1024 / 1024) MB")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("存储信息") {
                LabeledContent("总条目数", value: "\(storage.totalCount)")
                LabeledContent("数据库大小", value: storage.databaseSize)
                LabeledContent("图片占用", value: storage.imagesSize)
            }
            
            Section("操作") {
                Button("立即清理") {
                    storage.cleanup()
                }
                
                Button("导出历史...") {
                    if let url = storage.exportToJSON() {
                        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
                    }
                }
                
                Button("导入历史...") {
                    let panel = NSOpenPanel()
                    panel.allowedContentTypes = [.json]
                    panel.allowsMultipleSelection = false
                    
                    if panel.runModal() == .OK, let url = panel.url {
                        let count = storage.importFromJSON(url)
                        // Show result
                    }
                }
                
                Button("清除所有数据", role: .destructive) {
                    showClearConfirmation = true
                }
                .confirmationDialog("确认清除所有数据？", isPresented: $showClearConfirmation) {
                    Button("清除所有数据", role: .destructive) {
                        storage.clearAll()
                    }
                    Button("取消", role: .cancel) {}
                } message: {
                    Text("此操作不可恢复，所有剪贴板历史将被永久删除。")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

#Preview {
    StorageSettingsView()
        .frame(width: 500, height: 500)
}
