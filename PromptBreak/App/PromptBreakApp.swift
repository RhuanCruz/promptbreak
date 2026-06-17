import SwiftUI
import AppKit

@main
struct PromptBreakApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Menu bar only. Main/onboarding windows are managed manually (AppState)
        // so nothing auto-opens at launch.
        MenuBarExtra {
            MenuBarMenuView()
                .environmentObject(AppState.shared)
        } label: {
            Image("MenuBarIcon")
                .renderingMode(.original)
        }
        .menuBarExtraStyle(.menu)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        AppState.shared.onLaunch()

        if !AppState.shared.hasCompletedOnboarding || !AppState.shared.licenseService.state.isValid {
            AppState.shared.presentOnboarding()
        } else {
            AppState.shared.showMainWindow()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { AppState.shared.showMainWindow() }
        return true
    }

    // Deep link: promptbreak://activate?key=<key>
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls where url.scheme == "promptbreak" {
            if url.host == "activate",
               let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let key = components.queryItems?.first(where: { $0.name == "key" })?.value {
                Task { await AppState.shared.licenseService.activate(key: key) }
            }
        }
    }
}
