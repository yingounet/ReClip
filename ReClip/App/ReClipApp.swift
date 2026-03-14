// MARK: - ReClip/App/ReClipApp.swift
// 应用入口

import SwiftUI

@main
struct ReClipApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}
