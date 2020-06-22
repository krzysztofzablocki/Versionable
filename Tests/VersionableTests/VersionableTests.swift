import XCTest
@testable import Versionable

public extension Versionable {
    static func testMigrationPaths() throws {
        let files = try FileManager.default.contentsOfDirectory(atPath: mockDirectoryPath)

        let decoder = VersionableDecoder()
        files.forEach { mock in
            do {
                _ = try decoder.decode(self, from: Data(contentsOf: URL(fileURLWithPath: "\(mockDirectoryPath)/\(mock)")))
            }
            catch {
                XCTFail("Unable to migrate from version \((mock as NSString).lastPathComponent), error \(error)")
            }
        }
    }
}

private struct TestModel {
    var someData: String
    var version: Version = Self.version
}

extension TestModel: Versionable {
    enum Version: Int, VersionType {
        case v1 = 1
    }

    static func migrate(to: Version) -> Migration {
        switch to {
        case .v1:
            return .none
        }
    }

    static var mock: TestModel {
        .init(someData: "mock")
    }
}

final class VersionableTests: XCTestCase {
    func testThatModelVersionCanBeReadWithVersionContainer() {
        let model = TestModel(someData: "Foo", version: .v1)
        let encoded = try! JSONEncoder().encode(model)

        let decoded = try! JSONDecoder().decode(VersionContainer<TestModel.Version>.self, from: encoded)

        XCTAssertEqual(model.version, decoded.version)
    }
}
