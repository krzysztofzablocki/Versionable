import XCTest
import Versionable

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

        let foo = try! sut?.decode(Simple.self, from: data)

        XCTAssertEqual(foo?.text, "payloadText")
    }

    func testThrowsGivenIncorrectData() {
        let data = encode([
            "version": 1,
            "wrong": "payloadText",
        ])

        XCTAssertThrowsError(try sut?.decode(Simple.self, from: data))
    }

    func testDecodingAutomaticallyMigratesWhenNeeded() {
        let complex = try! sut?.decode(Complex.self, from: encode(["version": 1]))

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
                _ = try! sut?.decode(Simple.self, from: data)
            }
        }
    }

    func testPerformanceOfMigrationPath() {
        let data = encode([
            "version": 1,
        ])

        measure {
            for _ in 0...1_000 {
                _ = try! sut?.decode(Complex.self, from: data)
            }
        }
    }

    private func encode(_ content: [String: Any]) -> Data {
        return try! JSONSerialization.data(withJSONObject: content, options: [])
    }
}
