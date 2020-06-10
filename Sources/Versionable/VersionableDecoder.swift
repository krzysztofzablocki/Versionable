import Foundation

public final class VersionableDecoder {
    private var migrations = [String: [(version: Versionable.Version, migration: (inout [String: Any]) -> Void)]]()

    public init() {
    }

    public func registerMigration<T>(to version: Versionable.Version, forType type: T.Type, migration: @escaping (inout [String: Any]) -> Void) where T: Versionable {
        let name = "\(type)"
        var versions = migrations[name] ?? []
        versions.append((version, migration))
        versions = versions.sorted { $0.version < $1.version }
        migrations[name] = versions
    }

    public func decode<T>(_ data: Data, type: T.Type) throws -> T where T: Versionable {
        let decoder = JSONDecoder()
        let serializedVersion = try decoder.decode(VersionContainer.self, from: data)

        if serializedVersion.version == type.version {
            return try decoder.decode(T.self, from: data)
        }

        var payload = try require(try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any])

        migrations["\(type)"]?
            .filter { serializedVersion.version < $0.version }
            .forEach {
                $0.migration(&payload)
                payload["version"] = $0.version
            }

        let data = try JSONSerialization.data(withJSONObject: payload as Any, options: [])
        return try decoder.decode(T.self, from: data)
    }
}

internal enum RequireError: Error {
    case isNil
}

/// Lifts optional or throws requested error if its nil
internal func require<T>(_ optional: T?, or error: Error = RequireError.isNil) throws -> T {
    guard let value = optional else {
        throw error
    }
    return value
}
