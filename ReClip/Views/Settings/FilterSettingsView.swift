// MARK: - ReClip/Views/Settings/FilterSettingsView.swift
// 隐私过滤设置页面

import SwiftUI

struct FilterSettingsView: View {
    @ObservedObject var settings = Settings.shared
    @State private var newBundleId: String = ""
    
    var body: some View {
        Form {
            Section("隐私保护") {
                Toggle("忽略隐秘类型（密码等）", isOn: $settings.ignoreConcealedTypes)
                Toggle("启用内容去重", isOn: $settings.deduplicationEnabled)
                Toggle("合并连续相同来源", isOn: $settings.mergeConsecutive)
            }
            
            Section("默认黑名单") {
                Text("以下应用的复制内容将被自动忽略")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Constants.defaultBlacklist, id: \.self) { bundleId in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 12))
                                Text(bundleId)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: 120)
            }
            
            Section("自定义黑名单") {
                Text("添加更多需要忽略的应用")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(settings.customBlacklist, id: \.self) { bundleId in
                    HStack {
                        Text(bundleId)
                            .font(.system(size: 12))
                        Spacer()
                        Button("移除") {
                            settings.customBlacklist.removeAll { $0 == bundleId }
                        }
                        .buttonStyle(.borderless)
                    }
                }
                
                HStack {
                    TextField("Bundle ID (如: com.example.app)", text: $newBundleId)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("添加") {
                        if !newBundleId.isEmpty && !settings.customBlacklist.contains(newBundleId) {
                            settings.customBlacklist.append(newBundleId)
                            newBundleId = ""
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newBundleId.isEmpty)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

#Preview {
    FilterSettingsView()
        .frame(width: 500, height: 500)
}
