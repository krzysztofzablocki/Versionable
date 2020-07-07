import Foundation

public struct VersionableContainer<Type: Versionable>: Codable {
    public let instance: Type

    enum CodingKeys: CodingKey {
        case version
        case instance
    }

    public init(instance: Type) {
        self.instance = instance
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(instance.version, forKey: .version)

        let data = try JSONEncoder().encode(instance)
        try container.encode(data, forKey: .instance)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let encodedVersion = try container.decode(Type.Version.self, forKey: .version)
        let data = try container.decode(Data.self, forKey: .instance)
        let freeDecoder = JSONDecoder()

        if encodedVersion == Type.version {
            instance = try freeDecoder.decode(Type.self, from: data)
            return
        }

        var payload = try require(try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any])

        #if DEBUG
        let originalList = Type.Version.allCases
        let sorted = originalList.sorted(by: { $0 < $1 })
        assert(originalList.map { $0 } == sorted.map { $0 }, "\(Type.self) Versions should be sorted by their comparable order")
        #endif

        Type
            .Version
            .allCases
            .filter { encodedVersion < $0 }
            .forEach {
                Type.migrate(to: $0)(&payload)
                payload["version"] = $0.rawValue
            }

        instance = try freeDecoder.decode(Type.self, from: try JSONSerialization.data(withJSONObject: payload as Any, options: []))
    }
}
