import XCTest
@testable import ReClip

final class ReClipTests: XCTestCase {
    
    func testHashGenerator() {
        let text = "Hello, World!"
        let hash = HashGenerator.sha256(text)
        
        XCTAssertFalse(hash.isEmpty)
        XCTAssertEqual(hash.count, 64)  // SHA256 produces 64 hex characters
    }
    
    func testContentType() {
        XCTAssertEqual(ContentType.text.icon, "doc.text")
        XCTAssertEqual(ContentType.image.icon, "photo")
        XCTAssertEqual(ContentType.file.icon, "folder")
    }
}
