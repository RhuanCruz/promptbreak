import SwiftUI

struct MenuBarMenuView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.session.isActive {
                Label("Break in progress…", systemImage: "figure.walk")
                    .foregroundStyle(.secondary)
            } else {
                Button("Open PromptBreak") { appState.showMainWindow() }
                Button("Start break now") { Task { await appState.startBreak() } }
            }
            Divider()
            Button("Quit PromptBreak") { NSApp.terminate(nil) }
        }
    }
}
