// MARK: - ReClip/Utils/HashGenerator.swift
// 内容哈希工具

import Foundation
import CommonCrypto

enum HashGenerator {
    
    static func sha256(_ string: String) -> String {
        let data = string.data(using: .utf8) ?? Data()
        return sha256(data)
    }
    
    static func sha256(_ data: Data) -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    static func md5(_ string: String) -> String {
        let data = string.data(using: .utf8) ?? Data()
        return md5(data)
    }
    
    static func md5(_ data: Data) -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_MD5(buffer.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
