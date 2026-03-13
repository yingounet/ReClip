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
        static let id = Column(CodingKeys.id)
        static let timestamp = Column(CodingKeys.timestamp)
        static let appBundleId = Column(CodingKeys.appBundleId)
        static let appName = Column(CodingKeys.appName)
        static let dataType = Column(CodingKeys.dataType)
        static let contentPreview = Column(CodingKeys.contentPreview)
        static let dataHash = Column(CodingKeys.dataHash)
        static let textContent = Column(CodingKeys.textContent)
        static let imagePath = Column(CodingKeys.imagePath)
        static let filePaths = Column(CodingKeys.filePaths)
        static let isFavorite = Column(CodingKeys.isFavorite)
    }
    
    init(row: Row) {
        id = row[CodingKeys.id]
        timestamp = row[CodingKeys.timestamp]
        appBundleId = row[CodingKeys.appBundleId]
        appName = row[CodingKeys.appName]
        dataType = ContentType(rawValue: row[CodingKeys.dataType]) ?? .text
        contentPreview = row[CodingKeys.contentPreview]
        dataHash = row[CodingKeys.dataHash]
        textContent = row[CodingKeys.textContent]
        imagePath = row[CodingKeys.imagePath]
        isFavorite = row[CodingKeys.isFavorite]
        
        if let filePathsJSON = row[CodingKeys.filePaths] as? String,
           let data = filePathsJSON.data(using: .utf8),
           let paths = try? JSONDecoder().decode([String].self, from: data) {
            filePaths = paths
        }
    }
    
    func encode(to container: inout PersistenceContainer) {
        container[CodingKeys.id] = id
        container[CodingKeys.timestamp] = timestamp
        container[CodingKeys.appBundleId] = appBundleId
        container[CodingKeys.appName] = appName
        container[CodingKeys.dataType] = dataType.rawValue
        container[CodingKeys.contentPreview] = contentPreview
        container[CodingKeys.dataHash] = dataHash
        container[CodingKeys.textContent] = textContent
        container[CodingKeys.imagePath] = imagePath
        container[CodingKeys.isFavorite] = isFavorite
        
        if let filePaths = filePaths,
           let data = try? JSONEncoder().encode(filePaths),
           let json = String(data: data, encoding: .utf8) {
            container[CodingKeys.filePaths] = json
        }
    }
}
