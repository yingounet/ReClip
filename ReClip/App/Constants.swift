// MARK: - ReClip/App/Constants.swift
// 全局常量配置

import Foundation

enum Constants {
    // MARK: - App Info
    static let appName = "ReClip"
    static let bundleIdentifier = "net.yingou.reclip"
    
    // MARK: - Clipboard Monitor
    enum Monitor {
        static let defaultPollingInterval: TimeInterval = 0.5
        static let minPollingInterval: TimeInterval = 0.3
        static let maxPollingInterval: TimeInterval = 1.0
    }
    
    // MARK: - Size Limits
    enum SizeLimits {
        static let maxTextSize: Int = 10 * 1024 * 1024  // 10MB
        static let maxImageSize: Int = 5 * 1024 * 1024  // 5MB
        static let maxDatabaseSize: Int = 2 * 1024 * 1024 * 1024  // 2GB
        static let maxFileCount: Int = 100
    }
    
    // MARK: - Storage
    enum Storage {
        static let defaultMaxItems: Int = 1000
        static let defaultRetentionDays: Int = 30
        static let defaultPreviewLength: Int = 200
    }
    
    // MARK: - UI
    enum UI {
        static let windowWidth: CGFloat = 600
        static let windowHeight: CGFloat = 400
        static let rowHeight: CGFloat = 60
        static let cornerRadius: CGFloat = 12
    }
    
    // MARK: - Default Blacklist
    static let defaultBlacklist: [String] = [
        "com.agilebits.onepassword",
        "com.agilebits.onepassword7",
        "com.agilebits.onepassword8",
        "com.bitwarden.desktop",
        "com.lastpass.lastpassmacdesktop",
        "com.apple.KeychainAccess",
        "com.apple.securityserver",
        "org.keepassxc.keepassxc",
        "com.enpass.desktop",
        "com.dashlane.dashlanephonefinal",
        "com.keepersecurity.passwordmanager",
        "com.siber.roboform"
    ]
    
    // MARK: - Ignored UTI Types
    static let ignoredUTIs: Set<String> = [
        "public.password",
        "concealed",
        "org.nspasteboard.ConcealedType",
        "com.apple.security.password",
        "com.apple.finder.file-clipboard-cut"
    ]
    
    // MARK: - File Paths
    static func applicationSupportURL() -> URL {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent(appName)
    }
    
    static func databaseURL() -> URL {
        applicationSupportURL().appendingPathComponent("ReClip.sqlite")
    }
    
    static func imagesDirectoryURL() -> URL {
        applicationSupportURL().appendingPathComponent("Images")
    }
    
    static func backupsDirectoryURL() -> URL {
        applicationSupportURL().appendingPathComponent("Backups")
    }
}
