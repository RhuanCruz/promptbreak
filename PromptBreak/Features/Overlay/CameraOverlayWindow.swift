import AppKit
import SwiftUI

final class CameraOverlayWindow: NSWindow {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 600),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        level = .floating            // stays above normal app windows, but not the whole screen
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = true
        isReleasedWhenClosed = false
        appearance = NSAppearance(named: .darkAqua)
        center()

        let view = CameraOverlayView()
            .environmentObject(AppState.shared)
        contentView = NSHostingView(rootView: view)
    }

    // Prevent closing with Cmd+W / Escape during a break
    override func close() {
        guard !AppState.shared.session.isActive else { return }
        super.close()
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
