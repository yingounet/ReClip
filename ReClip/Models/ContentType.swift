// MARK: - ReClip/Models/ContentType.swift
// 内容类型枚举

import Foundation

enum ContentType: String, Codable, CaseIterable {
    case text = "text"
    case image = "image"
    case file = "file"
    
    var icon: String {
        switch self {
        case .text: return "doc.text"
        case .image: return "photo"
        case .file: return "folder"
        }
    }
    
    var displayName: String {
        switch self {
        case .text: return "文本"
        case .image: return "图片"
        case .file: return "文件"
        }
    }
    
    var color: String {
        switch self {
        case .text: return "blue"
        case .image: return "green"
        case .file: return "orange"
        }
    }
}
