// MARK: - ReClip/Models/Settings.swift
// 用户设置模型

import Foundation
import Combine

final class Settings: ObservableObject {
    // MARK: - General
    @Published var launchAtLogin: Bool = true
    @Published var showInDock: Bool = false
    @Published var pollingInterval: Double = Constants.Monitor.defaultPollingInterval
    @Published var autoPaste: Bool = true
    @Published var maxHistoryItems: Int = Constants.Storage.defaultMaxItems
    
    // MARK: - Storage
    @Published var retentionDays: Int = Constants.Storage.defaultRetentionDays
    @Published var maxTextSize: Int = Constants.SizeLimits.maxTextSize
    @Published var maxImageSize: Int = Constants.SizeLimits.maxImageSize
    
    // MARK: - Privacy
    @Published var ignoreConcealedTypes: Bool = true
    @Published var deduplicationEnabled: Bool = true
    @Published var customBlacklist: [String] = []
    
    // MARK: - UI
    @Published var fontSize: Int = 14
    @Published var previewLength: Int = Constants.Storage.defaultPreviewLength
    @Published var showAppName: Bool = true
    
    // MARK: - Advanced
    @Published var mergeConsecutive: Bool = true
    @Published var soundOnCopy: Bool = false
    
    // MARK: - Computed
    var retentionOptions: [(String, Int)] {
        [
            ("24 小时", 1),
            ("7 天", 7),
            ("30 天", 30),
            ("90 天", 90),
            ("永久", -1)
        ]
    }
    
    // MARK: - Persistence
    private let defaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Singleton
    static let shared = Settings()
    
    private init() {
        load()
        setupAutoSave()
    }
    
    // MARK: - Load & Save
    
    private func load() {
        launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        showInDock = defaults.bool(forKey: Keys.showInDock)
        
        let savedPolling = defaults.double(forKey: Keys.pollingInterval)
        pollingInterval = savedPolling > 0 ? savedPolling : Constants.Monitor.defaultPollingInterval
        
        if defaults.object(forKey: Keys.autoPaste) as? Bool != nil {
            autoPaste = defaults.bool(forKey: Keys.autoPaste)
        }
        
        let savedMaxItems = defaults.integer(forKey: Keys.maxHistoryItems)
        maxHistoryItems = savedMaxItems > 0 ? savedMaxItems : Constants.Storage.defaultMaxItems
        
        let savedRetention = defaults.integer(forKey: Keys.retentionDays)
        retentionDays = savedRetention > 0 ? savedRetention : Constants.Storage.defaultRetentionDays
        
        if defaults.object(forKey: Keys.ignoreConcealedTypes) as? Bool != nil {
            ignoreConcealedTypes = defaults.bool(forKey: Keys.ignoreConcealedTypes)
        }
        
        if defaults.object(forKey: Keys.deduplicationEnabled) as? Bool != nil {
            deduplicationEnabled = defaults.bool(forKey: Keys.deduplicationEnabled)
        }
        
        if let savedBlacklist = defaults.stringArray(forKey: Keys.customBlacklist) {
            customBlacklist = savedBlacklist
        }
        
        let savedFontSize = defaults.integer(forKey: Keys.fontSize)
        fontSize = savedFontSize > 0 ? savedFontSize : 14
        
        let savedPreviewLength = defaults.integer(forKey: Keys.previewLength)
        previewLength = savedPreviewLength > 0 ? savedPreviewLength : Constants.Storage.defaultPreviewLength
        
        if defaults.object(forKey: Keys.showAppName) as? Bool != nil {
            showAppName = defaults.bool(forKey: Keys.showAppName)
        }
        
        if defaults.object(forKey: Keys.mergeConsecutive) as? Bool != nil {
            mergeConsecutive = defaults.bool(forKey: Keys.mergeConsecutive)
        }
        
        if defaults.object(forKey: Keys.soundOnCopy) as? Bool != nil {
            soundOnCopy = defaults.bool(forKey: Keys.soundOnCopy)
        }
    }
    
    private func setupAutoSave() {
        $launchAtLogin.sink { [weak self] in self?.save($0, key: Keys.launchAtLogin) }.store(in: &cancellables)
        $showInDock.sink { [weak self] in self?.save($0, key: Keys.showInDock) }.store(in: &cancellables)
        $pollingInterval.sink { [weak self] in self?.save($0, key: Keys.pollingInterval) }.store(in: &cancellables)
        $autoPaste.sink { [weak self] in self?.save($0, key: Keys.autoPaste) }.store(in: &cancellables)
        $maxHistoryItems.sink { [weak self] in self?.save($0, key: Keys.maxHistoryItems) }.store(in: &cancellables)
        $retentionDays.sink { [weak self] in self?.save($0, key: Keys.retentionDays) }.store(in: &cancellables)
        $ignoreConcealedTypes.sink { [weak self] in self?.save($0, key: Keys.ignoreConcealedTypes) }.store(in: &cancellables)
        $deduplicationEnabled.sink { [weak self] in self?.save($0, key: Keys.deduplicationEnabled) }.store(in: &cancellables)
        $customBlacklist.sink { [weak self] in self?.save($0, key: Keys.customBlacklist) }.store(in: &cancellables)
        $fontSize.sink { [weak self] in self?.save($0, key: Keys.fontSize) }.store(in: &cancellables)
        $previewLength.sink { [weak self] in self?.save($0, key: Keys.previewLength) }.store(in: &cancellables)
        $showAppName.sink { [weak self] in self?.save($0, key: Keys.showAppName) }.store(in: &cancellables)
        $mergeConsecutive.sink { [weak self] in self?.save($0, key: Keys.mergeConsecutive) }.store(in: &cancellables)
        $soundOnCopy.sink { [weak self] in self?.save($0, key: Keys.soundOnCopy) }.store(in: &cancellables)
    }
    
    private func save<T>(_ value: T, key: String) {
        defaults.set(value, forKey: key)
    }
    
    func reset() {
        launchAtLogin = true
        showInDock = false
        pollingInterval = Constants.Monitor.defaultPollingInterval
        autoPaste = true
        maxHistoryItems = Constants.Storage.defaultMaxItems
        retentionDays = Constants.Storage.defaultRetentionDays
        ignoreConcealedTypes = true
        deduplicationEnabled = true
        customBlacklist = []
        fontSize = 14
        previewLength = Constants.Storage.defaultPreviewLength
        showAppName = true
        mergeConsecutive = true
        soundOnCopy = false
    }
}

private enum Keys {
    static let launchAtLogin = "launchAtLogin"
    static let showInDock = "showInDock"
    static let pollingInterval = "pollingInterval"
    static let autoPaste = "autoPaste"
    static let maxHistoryItems = "maxHistoryItems"
    static let retentionDays = "retentionDays"
    static let ignoreConcealedTypes = "ignoreConcealedTypes"
    static let deduplicationEnabled = "deduplicationEnabled"
    static let customBlacklist = "customBlacklist"
    static let fontSize = "fontSize"
    static let previewLength = "previewLength"
    static let showAppName = "showAppName"
    static let mergeConsecutive = "mergeConsecutive"
    static let soundOnCopy = "soundOnCopy"
}
