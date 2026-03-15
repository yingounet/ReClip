// MARK: - ReClip/Models/ClipboardItem.swift
// 剪贴板条目数据模型

import Foundation
import GRDB

struct ClipboardItem: Identifiable, Codable, Equatable {
    var id: UUID
    var timestamp: Date
    var appBundleId: String?
    var appName: String?
    var dataType: ContentType
    var contentPreview: String
    var dataHash: String
    var textContent: String?
    var imagePath: String?
    var filePaths: [String]?
    var isFavorite: Bool
    
    // MARK: - Computed Properties
    
    var displayTitle: String {
        switch dataType {
        case .text:
            return contentPreview.replacingOccurrences(of: "\n", with: " ")
        case .image:
            return contentPreview
        case .file:
            return contentPreview
        }
    }
    
    var isText: Bool { dataType == .text }
    var isImage: Bool { dataType == .image }
    var isFile: Bool { dataType == .file }
    
    // MARK: - Initializers
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        appBundleId: String?,
        appName: String?,
        dataType: ContentType,
        contentPreview: String,
        dataHash: String,
        textContent: String? = nil,
        imagePath: String? = nil,
        filePaths: [String]? = nil,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.timestamp = timestamp
        self.appBundleId = appBundleId
        self.appName = appName
        self.dataType = dataType
        self.contentPreview = contentPreview
        self.dataHash = dataHash
        self.textContent = textContent
        self.imagePath = imagePath
        self.filePaths = filePaths
        self.isFavorite = isFavorite
    }
}

// MARK: - GRDB Record

extension ClipboardItem: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "clipboard_items"
    
    enum Columns {
        static let id = Column("id")
        static let timestamp = Column("timestamp")
        static let appBundleId = Column("appBundleId")
        static let appName = Column("appName")
        static let dataType = Column("dataType")
        static let contentPreview = Column("contentPreview")
        static let dataHash = Column("dataHash")
        static let textContent = Column("textContent")
        static let imagePath = Column("imagePath")
        static let filePaths = Column("filePaths")
        static let isFavorite = Column("isFavorite")
    }
    
    init(row: Row) {
        id = row["id"]
        timestamp = row["timestamp"]
        appBundleId = row["appBundleId"]
        appName = row["appName"]
        dataType = ContentType(rawValue: row["dataType"]) ?? .text
        contentPreview = row["contentPreview"]
        dataHash = row["dataHash"]
        textContent = row["textContent"]
        imagePath = row["imagePath"]
        isFavorite = row["isFavorite"]
        
        if let filePathsJSON: String = row["filePaths"],
           let data = filePathsJSON.data(using: .utf8),
           let paths = try? JSONDecoder().decode([String].self, from: data) {
            filePaths = paths
        }
    }
    
    func encode(to container: inout PersistenceContainer) {
        container["id"] = id
        container["timestamp"] = timestamp
        container["appBundleId"] = appBundleId
        container["appName"] = appName
        container["dataType"] = dataType.rawValue
        container["contentPreview"] = contentPreview
        container["dataHash"] = dataHash
        container["textContent"] = textContent
        container["imagePath"] = imagePath
        container["isFavorite"] = isFavorite
        
        if let filePaths = filePaths,
           let data = try? JSONEncoder().encode(filePaths),
           let json = String(data: data, encoding: .utf8) {
            container["filePaths"] = json
        }
    }
}
