import XCTest
import Versionable

private struct Simple: Versionable {
    static let version: Version = 1
    static var migrations = [Migration]()

    let text: String
    var version: Version
}

private struct Complex: Versionable {
    static let version: Version = 3
    static var migrations = [
        Migration(to: 2, migration: { payload in
            payload["text"] = "defaultText"
        }),
        Migration(to: 3, migration: { payload in
            payload["number"] = (payload["text"] as? String) == "defaultText" ? 1 : 200
        }),
    ]


    let text: String
    let number: Int
    var version: Version
}

final class VersionableDecoderTests: XCTestCase {
    var sut: VersionableDecoder?

    override func setUp() {
        super.setUp()
        sut = VersionableDecoder()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testCanDecodeGivenCorrectData() {
        let data = encode([
            "version": 1,
            "text": "payloadText",
        ])

        let foo = try! sut?.decode(data, type: Simple.self)

        XCTAssertEqual(foo?.text, "payloadText")
    }

    func testThrowsGivenIncorrectData() {
        let data = encode([
            "version": 1,
            "wrong": "payloadText",
        ])

        XCTAssertThrowsError(try sut?.decode(data, type: Simple.self))
    }

    func testDecodingAutomaticallyMigratesWhenNeeded() {
        let complex = try! sut?.decode(encode(["version": 1]), type: Complex.self)

        XCTAssertEqual(complex?.version, Complex.version)
        XCTAssertEqual(complex?.text, "defaultText")
        XCTAssertEqual(complex?.number, 1)
    }

    func testPerformanceOfHappyPath() {
        let data = encode([
            "version": 1,
            "text": "payloadText",
        ])

        measure {
            for _ in 0...1_000 {
                _ = try! sut?.decode(data, type: Simple.self)
            }
        }
    }

    func testPerformanceOfMigrationPath() {
        let data = encode([
            "version": 1,
        ])

        measure {
            for _ in 0...1_000 {
                _ = try! sut?.decode(data, type: Complex.self)
            }
        }
    }

    private func encode(_ content: [String: Any]) -> Data {
        return try! JSONSerialization.data(withJSONObject: content, options: [])
    }
}
