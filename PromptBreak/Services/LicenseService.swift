import Foundation

// Edge function base URL — replace with your Supabase project URL
private let edgeFunctionBase = "https://aluynfqekjotcqfzgayr.supabase.co/functions/v1"
// Stripe Payment Link (one-time lifetime purchase)
let stripeLifetimeURL = URL(string: "https://buy.stripe.com/test_eVq6oH5uYgOPfX3fYX4gg00")!

// Grace period (seconds) for offline cache
private let offlineGraceInterval: TimeInterval = 72 * 3600

@MainActor
final class LicenseService: ObservableObject {
    @Published var state: LicenseState = LicenseState()

    private let deviceID: String

    init() {
        if let stored = KeychainStore.load(forKey: "device_id") {
            deviceID = stored
        } else {
            let id = UUID().uuidString
            KeychainStore.save(id, forKey: "device_id")
            deviceID = id
        }
        loadCachedState()
    }

    // MARK: - Activation

    func activate(key: String) async {
        let result = await validateRemote(key: key)
        apply(result: result, key: key)
    }

    /// Activates by the email used at Stripe checkout (no key needed).
    /// Returns nil on success, or a human-readable error message.
    @discardableResult
    func activateByEmail(email: String) async -> String? {
        guard let url = URL(string: "\(edgeFunctionBase)/activate-by-email") else { return "Configuration error." }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["email": email, "device_id": deviceID])

        guard let (data, response) = try? await URLSession.shared.data(for: req),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let decoded = try? JSONDecoder().decode(ValidateResponse.self, from: data) else {
            return "Couldn't reach the server. Check your connection and try again."
        }

        if !decoded.valid {
            return decoded.error ?? "No active license found for this email."
        }

        var s = LicenseState()
        s.key = decoded.licenseKey
        s.plan = decoded.plan.flatMap { LicensePlan(rawValue: $0) } ?? .lifetime
        s.status = .active
        if let until = decoded.validUntil { s.validUntil = ISO8601DateFormatter().date(from: until) }
        s.lastValidated = Date()
        state = s
        saveState()
        return nil
    }

    // MARK: - Deactivation (release this device so the license can move machines)

    @discardableResult
    func deactivate() async -> Bool {
        guard let key = state.key,
              let url = URL(string: "\(edgeFunctionBase)/deactivate-license") else { return false }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["license_key": key, "device_id": deviceID])

        guard let (data, response) = try? await URLSession.shared.data(for: req),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              (obj["ok"] as? Bool) == true else { return false }

        state = LicenseState()
        KeychainStore.delete(forKey: "license_state")
        return true
    }

    // MARK: - Revalidation

    func revalidateIfNeeded() {
        guard let last = state.lastValidated else { return }
        let shouldRefresh = Date().timeIntervalSince(last) > 3600 // every hour
        guard shouldRefresh, let key = state.key else { return }
        Task {
            let result = await validateRemote(key: key)
            await MainActor.run { self.apply(result: result, key: key) }
        }
    }

    // MARK: - Remote call

    private struct ValidateResponse: Codable {
        let valid: Bool
        let plan: String?
        let status: String?
        let validUntil: String?
        let licenseKey: String?
        let error: String?

        enum CodingKeys: String, CodingKey {
            case valid, plan, status, error
            case validUntil = "valid_until"
            case licenseKey = "license_key"
        }
    }

    private func validateRemote(key: String) async -> LicenseState? {
        guard let url = URL(string: "\(edgeFunctionBase)/validate-license") else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["license_key": key, "device_id": deviceID])

        guard let (data, response) = try? await URLSession.shared.data(for: req),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let decoded = try? JSONDecoder().decode(ValidateResponse.self, from: data) else {
            // Network error — honour offline grace
            if let cached = state.lastValidated,
               Date().timeIntervalSince(cached) < offlineGraceInterval {
                return state
            }
            return nil
        }

        var newState = LicenseState()
        newState.key = key
        newState.plan = decoded.plan.flatMap { LicensePlan(rawValue: $0) } ?? .lifetime
        newState.status = decoded.valid ? .active : .expired
        if let until = decoded.validUntil {
            newState.validUntil = ISO8601DateFormatter().date(from: until)
        }
        newState.lastValidated = Date()
        return newState
    }

    // MARK: - Helpers

    private func apply(result: LicenseState?, key: String) {
        guard var s = result else { return }
        s.key = key
        state = s
        saveState()
    }

    private func saveState() {
        if let data = try? JSONEncoder().encode(state) {
            KeychainStore.save(data.base64EncodedString(), forKey: "license_state")
        }
    }

    private func loadCachedState() {
        guard let b64 = KeychainStore.load(forKey: "license_state"),
              let data = Data(base64Encoded: b64),
              let s = try? JSONDecoder().decode(LicenseState.self, from: data) else { return }
        state = s
    }
}
