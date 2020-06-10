import Foundation

public final class VersionableDecoder {
    public init() {
    }

    public func decode<T>(_ type: T.Type, from data: Data, usingDecoder decoder: JSONDecoder = .init()) throws -> T where T: Versionable {
        let serializedVersion = try decoder.decode(VersionContainer.self, from: data)

        if serializedVersion.version == type.version {
            return try decoder.decode(T.self, from: data)
        }

        var payload = try require(try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any])

#if DEBUG
        let originalList = type.migrations
        let sorted = type.migrations.sorted(by: { $0.to < $1.to })
        assert(originalList.map { $0.to } == sorted.map { $0.to }, "\(type) migrations should be sorted by version")
#endif

        type
            .migrations
            .filter { serializedVersion.version < $0.to }
            .forEach {
                $0.migration(&payload)
                payload["version"] = $0.to
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
