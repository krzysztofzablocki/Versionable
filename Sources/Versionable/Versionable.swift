import Foundation

public protocol VersionType: CaseIterable, Codable, Comparable, RawRepresentable {}

public extension VersionType where RawValue: Comparable {
    static func < (a: Self, b: Self) -> Bool {
        return a.rawValue < b.rawValue
    }
}

public protocol Versionable: Codable {
    associatedtype Version: VersionType
    typealias MigrationClosure = (inout [String: Any]) -> Void

    static func migrate(to: Version) -> Migration
    static var version: Version { get }

    /// Persisted Version of this type
    var version: Version { get }

    static var mock: Self { get }
}

public extension Versionable {
    static var version: Version {
        let allCases = Version.allCases
        return allCases[allCases.index(allCases.endIndex, offsetBy: -1)]
    }
}

public enum Migration {
    case none
    case migrate(Versionable.MigrationClosure)

    func callAsFunction(_ payload: inout [String: Any]) {
        switch self {
        case .none:
            return
        case let .migrate(closure):
            closure(&payload)
        }
    }
}

struct VersionContainer<Version: VersionType>: Codable {
    var version: Version
}

public extension Versionable {
    static var mockDirectoryRootPath: String {
        func simulatorOwnerUsername() -> String {
            //! running on simulator so just grab the name from home dir /Users/{username}/Library...
            let usernameComponents = NSHomeDirectory().components(separatedBy: "/")
            guard usernameComponents.count > 2 else { fatalError() }
            return usernameComponents[2]
        }
        return "/Users/\(simulatorOwnerUsername())/Desktop"
    }

    static var mockDirectoryPath: String {
        return "\(mockDirectoryRootPath)/\(self)/"
    }

    #if targetEnvironment(simulator)
    static func saveMockToFile() throws {
        let encoded = try JSONEncoder().encode(mock)
        if !FileManager.default.fileExists(atPath: mockDirectoryPath) {
            try FileManager.default.createDirectory(atPath: mockDirectoryPath, withIntermediateDirectories: true, attributes: nil)
        }

        try encoded.write(to: URL(fileURLWithPath: "\(mockDirectoryPath)/\(version).json"), options: .atomicWrite)
    }
    #endif
}
