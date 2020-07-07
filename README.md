# Versionable

Example showing 2 ways to implement migrations for `Codable` models.

[Related article](http://merowing.info/2020/06/adding-support-for-versioning-and-migration-to-your-codable-models./)


# Protocol conformance

Migrations in both ways are handled by conforming to `Versionable` protocol like so:

```swift
extension Object: Versionable {
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
}
```

# Method 1

If you are only encoding flat structures you can use provided `VersionableDecoder` to get back your models, in this approach we rely on using a special decoder for the logic, instead of swift standards `JSONDecoder`.

- `+` Good for flat structures
- `+` Faster than container method
- `-` Won't work with composed tree hierarchy

# Method 2

If you want to encode whole tree's of objects (versionable object A containing other versionable objects via composition) then you want to be able to use regular system encoders, for this scenario you can wrap your objects into `VersionableContainer<YourObjectType>`, custom implementation of that container will deal with all migration logic.

- `+` Works with any encoder
- `+` Supports arbitrary model tree setup
- `-` Slower


