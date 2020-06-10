public protocol Versionable: Codable {
    typealias Version = Int

    /// Version of this type
    static var version: Version { get }

    /// Persisted Version of this type
    var version: Version { get }
}

struct VersionContainer: Codable {
    var version: Versionable.Version
}
