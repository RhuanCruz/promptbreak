import AppKit

final class BlockerService {
    private var isActive = false
    private var blockedApps: Set<String> = []
    private var intensity: BlockIntensity = .hard
    private var observer: NSObjectProtocol?

    func activate(blockedApps: [String], intensity: BlockIntensity) {
        self.blockedApps = Set(blockedApps)
        self.intensity = intensity
        self.isActive = true

        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self, self.isActive else { return }
            guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let bundleID = app.bundleIdentifier,
                  self.blockedApps.contains(bundleID) else { return }
            self.handleBlockedAppActivation(app)
        }
    }

    func deactivate() {
        isActive = false
        if let obs = observer {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
            observer = nil
        }
    }

    private func handleBlockedAppActivation(_ app: NSRunningApplication) {
        switch intensity {
        case .soft:
            sendNagNotification(appName: app.localizedName ?? "that app")
        case .hard:
            guard AXIsProcessTrusted() else {
                // Accessibility not granted — fall back to soft
                sendNagNotification(appName: app.localizedName ?? "that app")
                return
            }
            app.hide()
            // Bring the overlay back to front
            NSApp.windows
                .filter { $0 is CameraOverlayWindow }
                .forEach { $0.makeKeyAndOrderFront(nil) }
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
