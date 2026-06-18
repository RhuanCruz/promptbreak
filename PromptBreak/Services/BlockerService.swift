import AppKit

@MainActor
final class BlockerService {
    private var isActive = false
    private var blockedApps: Set<String> = []
    private var intensity: BlockIntensity = .hard
    private var observer: NSObjectProtocol?
    private var enforceTimer: Timer?

    var onBlockTriggered: ((String) -> Void)?

    func activate(blockedApps: [String], intensity: BlockIntensity) {
        self.blockedApps = Set(blockedApps)
        self.intensity = intensity
        self.isActive = true

        // Immediately enforce if a blocked app is already frontmost
        enforceBlocking()

        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            Task { @MainActor [weak self] in
                guard let self, self.isActive,
                      let bundleID = app.bundleIdentifier,
                      self.blockedApps.contains(bundleID) else { return }
                self.handleBlockedAppActivation(app)
            }
        }

        // Poll every 1.5s to re-enforce in case the user switches back
        enforceTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.enforceBlocking() }
        }
    }

    func deactivate() {
        isActive = false
        enforceTimer?.invalidate()
        enforceTimer = nil
        if let obs = observer {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
            observer = nil
        }
    }

    private func enforceBlocking() {
        guard isActive else { return }
        guard let app = NSWorkspace.shared.frontmostApplication,
              let bundleID = app.bundleIdentifier,
              blockedApps.contains(bundleID) else { return }
        handleBlockedAppActivation(app)
    }

    private func handleBlockedAppActivation(_ app: NSRunningApplication) {
        let appName = app.localizedName ?? "that app"
        switch intensity {
        case .soft:
            sendNagNotification(appName: appName)
        case .hard:
            // Always show the overlay — accessibility is only needed for app.hide()
            onBlockTriggered?(appName)
            if AXIsProcessTrusted() {
                app.hide()
            }
        }
    }

    private func sendNagNotification(appName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Complete your squats first!"
        content.body = "Finish your break before opening \(appName)."
        content.sound = .default
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }
}

import UserNotifications
