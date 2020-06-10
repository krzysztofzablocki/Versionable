import XCTest
@testable import Versionable

private struct TestModel: Versionable {
    static var version: Version = 1
    static var migrations = [Migration]()

    var someData: String
    var version: Version
}

final class VersionableTests: XCTestCase {
    func testThatModelVersionCanBeReadWithVersionContainer() {
        let model = TestModel(someData: "Foo", version: 616)
        let encoded = try! JSONEncoder().encode(model)

        let decoded = try! JSONDecoder().decode(VersionContainer.self, from: encoded)

        XCTAssertEqual(model.version, decoded.version)
    }
}
