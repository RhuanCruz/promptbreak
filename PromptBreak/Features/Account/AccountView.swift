import SwiftUI
import AppKit

struct AccountView: View {
    @EnvironmentObject private var appState: AppState
    @State private var emailInput = ""
    @State private var activationMessage: String?
    @State private var activationOk = false
    @State private var isActivating = false
    @State private var deactivating = false

    private var license: LicenseState { appState.licenseService.state }

    var body: some View {
        Form {
            // License section
            Section("License") {
                if !appState.userName.isEmpty {
                    LabeledContent("Name", value: appState.userName)
                }
                LabeledContent("Plan", value: planLabel)
                LabeledContent("Status", value: statusLabel)

                if license.isValid {
                    Button(deactivating ? "Releasing…" : "Deactivate on this device") {
                        deactivating = true
                        Task {
                            _ = await appState.licenseService.deactivate()
                            deactivating = false
                        }
                    }
                    .foregroundStyle(.red)
                    .disabled(deactivating)
                    Text("Frees this license so you can activate it on another Mac.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            // Activation (one-time purchase)
            if !license.isValid {
                Section("Activate License") {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Lifetime access")
                                .font(.headline)
                            Text("Pay once. Yours forever.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Buy now →") { NSWorkspace.shared.open(stripeLifetimeURL) }
                            .buttonStyle(.borderedProminent)
                    }

                    Divider()

                    Text("Already paid? Activate with your checkout email:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack {
                        TextField("Email used at checkout", text: $emailInput)
                            .textFieldStyle(.roundedBorder)
                        Button(isActivating ? "…" : "Activate") {
                            let email = emailInput.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !email.isEmpty else { return }
                            isActivating = true
                            Task {
                                let error = await appState.licenseService.activateByEmail(email: email)
                                isActivating = false
                                activationOk = (error == nil)
                                activationMessage = error ?? "License activated — thank you!"
                            }
                        }
                        .disabled(emailInput.isEmpty || isActivating)
                    }
                    if let msg = activationMessage {
                        Text(msg)
                            .font(.caption)
                            .foregroundStyle(activationOk ? .green : .red)
                    }
                }
            }

            // Permissions
            Section("Permissions") {
                permissionRow(
                    label: "Camera",
                    granted: appState.permissions.cameraGranted,
                    action: { appState.permissions.requestCamera() }
                )
                permissionRow(
                    label: "Accessibility (Hard mode)",
                    granted: appState.permissions.accessibilityGranted,
                    action: { appState.permissions.requestAccessibility() }
                )
                permissionRow(
                    label: "Notifications",
                    granted: appState.permissions.notificationsGranted,
                    action: { appState.permissions.requestNotifications() }
                )
            }

            Section("Developer") {
                Button("Reset onboarding") { appState.resetOnboarding() }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }

    private var planLabel: String {
        guard license.isValid, let plan = license.plan else { return "Not activated" }
        switch plan {
        case .lifetime: return "Lifetime"
        case .monthly:  return "Monthly"
        case .annual:   return "Annual"
        }
    }

    private var statusLabel: String {
        license.isValid ? "Active" : "Not activated"
    }

    private func permissionRow(label: String, granted: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: granted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(granted ? .green : .red)
            Text(label)
            Spacer()
            if !granted {
                Button("Grant") { action() }
                    .buttonStyle(.borderless)
                    .foregroundStyle(Color.accentColor)
            }
        }
    }
}
