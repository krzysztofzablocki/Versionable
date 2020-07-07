import Foundation
import Versionable

struct Simple {
    let text: String
    var version: Version = Self.version
}

extension Simple: Versionable {
    enum Version: Int, VersionType {
        case v1 = 1
    }

    static func migrate(to: Version) -> Migration {
        switch to {
        case .v1:
            return .none
        }
    }

    static var mock: Simple {
        .init(text: "mock")
    }
}


struct Complex {
    let text: String
    let number: Int
    var version: Version = Self.version
}

extension Complex: Versionable {
    enum Version: Int, VersionType {
        case v1 = 1
        case v2 = 2
        case v3 = 3
    }

    static func migrate(to: Version) -> Migration {
        switch to {
        case .v1:
            return .none
        case .v2:
            return .migrate {  payload in
                payload["text"] = "defaultText"
            }
        case .v3:
            return .migrate { payload in
                payload["number"] = (payload["text"] as? String) == "defaultText" ? 1 : 200
            }
        }
    }

    static var mock: Complex {
        .init(text: "mock", number: 0)
    }
}

