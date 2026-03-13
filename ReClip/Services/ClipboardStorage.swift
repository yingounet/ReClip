// MARK: - ReClip/Services/ClipboardStorage.swift
// SQLite 存储服务 (GRDB)

import Foundation
import GRDB
import Combine

final class ClipboardStorage: ObservableObject {
    @Published private(set) var items: [ClipboardItem] = []
    @Published private(set) var totalCount: Int = 0
    
    private var dbQueue: DatabaseQueue?
    private let settings: Settings
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Singleton
    static let shared = ClipboardStorage()
    
    private init() {
        self.settings = .shared
        setupDatabase()
        loadItems()
    }
    
    // MARK: - Setup
    
    private func setupDatabase() {
        do {
            let fileManager = FileManager.default
            let appSupportURL = Constants.applicationSupportURL()
            
            if !fileManager.fileExists(atPath: appSupportURL.path) {
                try fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
            }
            
            let dbURL = Constants.databaseURL()
            dbQueue = try DatabaseQueue(path: dbURL.path)
            
            try dbQueue?.write { db in
                try createSchema(db)
            }
            
            Logger.info("Database initialized at: \(dbURL.path)")
        } catch {
            Logger.error("Failed to initialize database: \(error)")
        }
    }
    
    private func createSchema(_ db: Database) throws {
        try db.create(table: "clipboard_items", ifNotExists: true) { table in
            table.column("id", .text).primaryKey()
            table.column("timestamp", .datetime).notNull()
            table.column("appBundleId", .text)
            table.column("appName", .text)
            table.column("dataType", .text).notNull()
            table.column("contentPreview", .text).notNull()
            table.column("dataHash", .text).notNull()
            table.column("textContent", .text)
            table.column("imagePath", .text)
            table.column("filePaths", .text)
            table.column("isFavorite", .boolean).notNull().defaults(to: false)
        }
        
        try db.create(index: "idx_timestamp", on: "clipboard_items", columns: ["timestamp"])
        try db.create(index: "idx_hash", on: "clipboard_items", columns: ["dataHash"])
        try db.create(index: "idx_favorite", on: "clipboard_items", columns: ["isFavorite"])
        try db.create(index: "idx_app", on: "clipboard_items", columns: ["appBundleId"])
    }
    
    // MARK: - CRUD
    
    func insert(_ item: ClipboardItem) {
        do {
            try dbQueue?.write { db in
                try item.insert(db)
            }
            loadItems()
            Logger.debug("Inserted item: \(item.id)")
        } catch {
            Logger.error("Failed to insert item: \(error)")
        }
    }
    
    func delete(_ item: ClipboardItem) {
        do {
            // 删除关联图片
            if let imagePath = item.imagePath {
                let fullPath = Constants.applicationSupportURL().appendingPathComponent(imagePath).path
                try? FileManager.default.removeItem(atPath: fullPath)
            }
            
            try dbQueue?.write { db in
                _ = try item.delete(db)
            }
            loadItems()
            Logger.debug("Deleted item: \(item.id)")
        } catch {
            Logger.error("Failed to delete item: \(error)")
        }
    }
    
    func toggleFavorite(_ item: ClipboardItem) {
        do {
            var updatedItem = item
            updatedItem.isFavorite = !item.isFavorite
            
            try dbQueue?.write { db in
                try updatedItem.update(db)
            }
            loadItems()
        } catch {
            Logger.error("Failed to toggle favorite: \(error)")
        }
    }
    
    func exists(hash: String) -> Bool {
        do {
            return try dbQueue?.read { db in
                try ClipboardItem
                    .filter(ClipboardItem.Columns.dataHash == hash)
                    .fetchCount(db) > 0
            } ?? false
        } catch {
            return false
        }
    }
    
    func updateTimestamp(hash: String) {
        do {
            try dbQueue?.write { db in
                if var item = try ClipboardItem
                    .filter(ClipboardItem.Columns.dataHash == hash)
                    .fetchOne(db) {
                    item.timestamp = Date()
                    try item.update(db)
                }
            }
        } catch {
            Logger.error("Failed to update timestamp: \(error)")
        }
    }
    
    // MARK: - Query
    
    private func loadItems() {
        do {
            items = try dbQueue?.read { db in
                try ClipboardItem
                    .order(ClipboardItem.Columns.timestamp.desc)
                    .limit(settings.maxHistoryItems)
                    .fetchAll(db)
            } ?? []
            
            totalCount = try dbQueue?.read { db in
                try ClipboardItem.fetchCount(db)
            } ?? 0
        } catch {
            Logger.error("Failed to load items: \(error)")
            items = []
        }
    }
    
    func search(query: String) -> [ClipboardItem] {
        guard !query.isEmpty else {
            return items
        }
        
        let pattern = "%\(query)%"
        
        do {
            return try dbQueue?.read { db in
                try ClipboardItem
                    .filter(
                        ClipboardItem.Columns.contentPreview.like(pattern) ||
                        ClipboardItem.Columns.appName.like(pattern) ||
                        ClipboardItem.Columns.textContent.like(pattern)
                    )
                    .order(ClipboardItem.Columns.timestamp.desc)
                    .limit(100)
                    .fetchAll(db)
            } ?? []
        } catch {
            Logger.error("Search failed: \(error)")
            return []
        }
    }
    
    func fetchFavorites() -> [ClipboardItem] {
        do {
            return try dbQueue?.read { db in
                try ClipboardItem
                    .filter(ClipboardItem.Columns.isFavorite == true)
                    .order(ClipboardItem.Columns.timestamp.desc)
                    .fetchAll(db)
            } ?? []
        } catch {
            Logger.error("Failed to fetch favorites: \(error)")
            return []
        }
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        do {
            try dbQueue?.write { db in
                // 1. 按时间清理（非收藏）
                if settings.retentionDays > 0 {
                    let cutoff = Date().addingTimeInterval(-Double(settings.retentionDays) * 86400)
                    let oldItems = try ClipboardItem
                        .filter(ClipboardItem.Columns.timestamp < cutoff)
                        .filter(ClipboardItem.Columns.isFavorite == false)
                        .fetchAll(db)
                    
                    for item in oldItems {
                        try item.delete(db)
                        deleteImageFile(for: item)
                    }
                    
                    Logger.info("Cleaned up \(oldItems.count) old items")
                }
                
                // 2. 按数量清理（非收藏）
                let total = try ClipboardItem
                    .filter(ClipboardItem.Columns.isFavorite == false)
                    .fetchCount(db)
                
                if total > settings.maxHistoryItems {
                    let toDelete = total - settings.maxHistoryItems
                    let oldItems = try ClipboardItem
                        .filter(ClipboardItem.Columns.isFavorite == false)
                        .order(ClipboardItem.Columns.timestamp.asc)
                        .limit(toDelete)
                        .fetchAll(db)
                    
                    for item in oldItems {
                        try item.delete(db)
                        deleteImageFile(for: item)
                    }
                    
                    Logger.info("Cleaned up \(oldItems.count) excess items")
                }
            }
            
            loadItems()
        } catch {
            Logger.error("Cleanup failed: \(error)")
        }
    }
    
    private func deleteImageFile(for item: ClipboardItem) {
        guard let imagePath = item.imagePath else { return }
        let fullPath = Constants.applicationSupportURL().appendingPathComponent(imagePath).path
        try? FileManager.default.removeItem(atPath: fullPath)
    }
    
    func clearAll() {
        do {
            try dbQueue?.write { db in
                _ = try ClipboardItem.deleteAll(db)
            }
            
            // 删除所有图片
            let imagesDir = Constants.imagesDirectoryURL()
            if FileManager.default.fileExists(atPath: imagesDir.path) {
                try FileManager.default.removeItem(at: imagesDir)
            }
            
            loadItems()
            Logger.info("Cleared all items")
        } catch {
            Logger.error("Failed to clear all: \(error)")
        }
    }
    
    // MARK: - Export/Import
    
    func exportToJSON() -> URL? {
        do {
            let allItems = items
            let data = try JSONEncoder().encode(allItems)
            
            let backupDir = Constants.backupsDirectoryURL()
            try FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy_MM_dd_HH_mm_ss"
            let filename = "reclip_backup_\(formatter.string(from: Date())).json"
            let url = backupDir.appendingPathComponent(filename)
            
            try data.write(to: url)
            Logger.info("Exported to: \(url.path)")
            return url
        } catch {
            Logger.error("Export failed: \(error)")
            return nil
        }
    }
    
    func importFromJSON(_ url: URL) -> Int {
        do {
            let data = try Data(contentsOf: url)
            let importedItems = try JSONDecoder().decode([ClipboardItem].self, from: data)
            
            try dbQueue?.write { db in
                for item in importedItems {
                    try item.insert(db)
                }
            }
            
            loadItems()
            Logger.info("Imported \(importedItems.count) items")
            return importedItems.count
        } catch {
            Logger.error("Import failed: \(error)")
            return 0
        }
    }
    
    // MARK: - Stats
    
    var databaseSize: String {
        let dbURL = Constants.databaseURL()
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: dbURL.path),
              let size = attributes[.size] as? Int64 else {
            return "0 KB"
        }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var imagesSize: String {
        let imagesDir = Constants.imagesDirectoryURL()
        guard let enumerator = FileManager.default.enumerator(at: imagesDir, includingPropertiesForKeys: [.fileSizeKey]),
              let files = enumerator.allObjects as? [URL] else {
            return "0 KB"
        }
        
        let totalSize = files.reduce(Int64(0)) { result, url in
            guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                  let size = attributes[.size] as? Int64 else {
                return result
            }
            return result + size
        }
        
        return ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
}
