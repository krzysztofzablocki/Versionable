import XCTest
import Versionable

private struct Simple {
    let text: String
    var version: Version = Self.version
}

extension Simple: Versionable {
    enum Version: Int, VersionType {
        case v1 = 1
    }

    static func migrate(to: Version) -> Migration {
        switch to {
        case .v1:
            return .none
        }
    }

    static var mock: Simple {
        .init(text: "mock")
    }
}


private struct Complex {
    let text: String
    let number: Int
    var version: Version = Self.version
}

extension Complex: Versionable {
    enum Version: Int, VersionType {
        case v1 = 1
        case v2 = 2
        case v3 = 3
    }

    static func migrate(to: Version) -> Migration {
        switch to {
        case .v1:
            return .none
        case .v2:
            return .migrate {  payload in
                payload["text"] = "defaultText"
            }
        case .v3:
            return .migrate { payload in
                payload["number"] = (payload["text"] as? String) == "defaultText" ? 1 : 200
            }
        }
    }

    static var mock: Complex {
        .init(text: "mock", number: 0)
    }
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
