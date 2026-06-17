import AppKit
import SwiftUI

final class MainWindow: NSWindow {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 680),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        title = "PromptBreak"
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        isReleasedWhenClosed = false
        appearance = NSAppearance(named: .darkAqua)
        backgroundColor = NSColor(calibratedRed: 0.07, green: 0.07, blue: 0.085, alpha: 1)
        center()

        contentView = NSHostingView(
            rootView: ContentView().environmentObject(AppState.shared)
        )
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
