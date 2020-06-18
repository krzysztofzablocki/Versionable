import Foundation

public final class VersionableDecoder {
    public enum Decoder {
        case data(JSONDecoder)
        case dictionary(DictionaryDecoder)
    }

    public init() {
    }

    public func decode<T>(_ type: T.Type, from data: Data, usingDecoder decoder: Decoder = .data(JSONDecoder())) throws -> T where T: Versionable {
        var payload: [String: Any]

        switch decoder {
        case let .data(decoder):
            let serializedVersion = try decoder.decode(VersionContainer.self, from: data)

            if serializedVersion.version == type.version {
                return try decoder.decode(T.self, from: data)
            }

            payload = try require(try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any])
            payload = migrate(payload: payload, forType: T.self, serializedVersion: serializedVersion.version)

            let data = try JSONSerialization.data(withJSONObject: payload as Any, options: [])
            return try decoder.decode(T.self, from: data)

        case let .dictionary(decoder):
            payload = try require(try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any])
            let version = try require(payload["version"] as? Int)
            if version == type.version {
                return try decoder.decode(T.self, from: payload)
            }

            payload = migrate(payload: payload, forType: T.self, serializedVersion: version)
            return try decoder.decode(T.self, from: payload)
        }
    }

    private func migrate<T>(payload: [String: Any], forType type: T.Type, serializedVersion: Int) -> [String: Any] where T: Versionable {
        var payload = payload
        #if DEBUG
                let originalList = type.migrations
                let sorted = type.migrations.sorted(by: { $0.to < $1.to })
                assert(originalList.map { $0.to } == sorted.map { $0.to }, "\(type) migrations should be sorted by version")
        #endif

                type
                    .migrations
                    .filter { serializedVersion < $0.to }
                    .forEach {
                        $0.migration(&payload)
                        payload["version"] = $0.to
                    }

        return payload
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
