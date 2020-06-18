import XCTest
import Versionable

private struct Simple: Versionable {
    static let version: Version = 1
    static var migrations = [Migration]()

    let text: String
    let version: Version = Self.version
}

private struct Complex: Versionable {
    static let version: Version = 3
    static let migrations = [
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

    func testPerformanceOfHappyPathUsingNaiveDecoding() {
        let data = encode([
            "version": 1,
            "text": "payloadText",
        ])

        let decoder = JSONDecoder()
        measure {
            for _ in 0...10_000 {
                _ = try! sut?.decode(Simple.self, from: data, usingDecoder: .data(decoder))
            }
        }
    }

    func testPerformanceOfMigrationPathUsingNaiveDecoding() {
        let data = encode([
            "version": 1,
        ])

        let decoder = JSONDecoder()
        measure {
            for _ in 0...10_000 {
                _ = try! sut?.decode(Complex.self, from: data, usingDecoder: .data(decoder))
            }
        }
    }

    func testPerformanceOfHappyPathUsingDictionaryDecoding() {
        let data = encode([
            "version": 1,
            "text": "payloadText",
        ])

        let decoder = DictionaryDecoder()
        measure {
            for _ in 0...10_000 {
                _ = try! sut?.decode(Simple.self, from: data, usingDecoder: .dictionary(decoder))
            }
        }
    }

    func testPerformanceOfMigrationPathUsingDictionaryDecoding() {
        let data = encode([
            "version": 1,
        ])

        let decoder = DictionaryDecoder()
        measure {
            for _ in 0...10_000 {
                _ = try! sut?.decode(Complex.self, from: data, usingDecoder: .dictionary(decoder))
            }
        }
    }

    private func encode(_ content: [String: Any]) -> Data {
        return try! JSONSerialization.data(withJSONObject: content, options: [])
    }
}
