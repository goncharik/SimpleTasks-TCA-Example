import Foundation
import KeychainAccess

extension Keychain {
    static var live: Keychain {
        return Keychain(service: "com.honcharenko.simpletasks")
    }

    static var mock: Keychain {
        return Keychain(service: "com.honcharenko.tests")
    }

    var token: String? {
        get {
            self["token"]
        }
        set {
            self["token"] = newValue
        }
    }
}
