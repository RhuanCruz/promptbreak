import AppKit
import SwiftUI

final class OnboardingWindow: NSWindow {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 640),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        title = "Welcome to PromptBreak"
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        isReleasedWhenClosed = false
        appearance = NSAppearance(named: .darkAqua)
        backgroundColor = NSColor(calibratedRed: 0.07, green: 0.07, blue: 0.085, alpha: 1)
        center()

        let appState = AppState.shared
        let view = OnboardingView(
            permissions: appState.permissions,
            license: appState.licenseService,
            claude: appState.claudeUsage,
            onComplete: { [weak self] in self?.close() }
        )
        .environmentObject(appState)

        contentView = NSHostingView(rootView: view)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
