public protocol Versionable: Codable {
    typealias Version = Int
    typealias MigrationClosure = (inout [String: Any]) -> Void
    typealias Migration = (to: Version, migration: MigrationClosure)

    /// Version of this type
    static var version: Version { get }

    static var migrations: [Migration] { get }

    /// Persisted Version of this type
    var version: Version { get }
}

struct VersionContainer: Codable {
    var version: Versionable.Version
}
