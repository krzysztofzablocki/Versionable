import XCTest
@testable import Versionable

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
}

final class VersionableTests: XCTestCase {
    func testThatModelVersionCanBeReadWithVersionContainer() {
        let model = TestModel(someData: "Foo", version: .v1)
        let encoded = try! JSONEncoder().encode(model)

        let decoded = try! JSONDecoder().decode(VersionContainer<TestModel.Version>.self, from: encoded)

        XCTAssertEqual(model.version, decoded.version)
    }
}
