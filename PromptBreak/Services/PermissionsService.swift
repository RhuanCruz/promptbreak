import AVFoundation
import AppKit
import UserNotifications
import Combine

final class PermissionsService: ObservableObject {
    @Published var cameraGranted: Bool = false
    @Published var accessibilityGranted: Bool = false
    @Published var notificationsGranted: Bool = false

    func checkAll() {
        checkCamera()
        checkAccessibility()
        checkNotifications()
    }

    // MARK: - Camera

    func checkCamera() {
        cameraGranted = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    func requestCamera() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async { self?.cameraGranted = granted }
        }
    }

    // MARK: - Accessibility

    func checkAccessibility() {
        accessibilityGranted = AXIsProcessTrusted()
    }

    func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    // MARK: - Notifications

    func checkNotifications() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.notificationsGranted = settings.authorizationStatus == .authorized
            }
        }
    }

    func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            DispatchQueue.main.async { self?.notificationsGranted = granted }
        }
    }
}
