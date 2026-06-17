import AppKit
import SwiftUI

final class BlockOverlayWindow: NSWindow {
    init() {
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        super.init(
            contentRect: screenFrame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        isOpaque = false
        backgroundColor = .clear
        ignoresMouseEvents = false
        isReleasedWhenClosed = false
        appearance = NSAppearance(named: .darkAqua)

        let view = BlockOverlayView()
            .environmentObject(AppState.shared)
        contentView = NSHostingView(rootView: view)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
