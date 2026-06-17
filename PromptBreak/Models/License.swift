import Foundation

enum LicensePlan: String, Codable {
    case monthly
    case annual
    case lifetime
}

enum LicenseStatus: String, Codable {
    case active
    case canceled
    case expired
    case none
}

struct LicenseState: Codable {
    var plan: LicensePlan?
    var status: LicenseStatus = .none
    var key: String?
    var validUntil: Date?           // nil = lifetime / no license
    var lastValidated: Date?

    var isValid: Bool {
        guard status == .active else { return false }
        if plan == .lifetime { return true }
        guard let until = validUntil else { return false }
        return until > Date()
    }
}
