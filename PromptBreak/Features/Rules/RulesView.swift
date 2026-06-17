import SwiftUI
import AppKit

struct RulesView: View {
    @EnvironmentObject private var appState: AppState
    @State private var rules = Rules.current
    @State private var cameras: [CameraInfo] = []

    // Available interval options (minutes)
    private let intervals = [15, 20, 30, 45, 60]
    private let goals = [5, 10, 15, 20]

    private let tokenGoals = [200_000, 500_000, 1_000_000, 2_000_000]

    var body: some View {
        Form {
            Section("Break Trigger") {
                Picker("Trigger", selection: $rules.trigger) {
                    ForEach(BreakTrigger.allCases, id: \.self) { t in
                        Text(t.displayName).tag(t)
                    }
                }
                .pickerStyle(.segmented)

                if rules.trigger == .time {
                    Picker("Break every", selection: $rules.intervalMinutes) {
                        ForEach(intervals, id: \.self) { min in
                            Text("\(min) min").tag(min)
                        }
                    }
                    .pickerStyle(.segmented)
                } else {
                    Picker("Break after", selection: $rules.claudeTokenGoal) {
                        ForEach(tokenGoals, id: \.self) { v in
                            Text(formatTokens(v)).tag(v)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Image(systemName: appState.claudeUsage.isInstalled ? "checkmark.circle.fill" : "terminal")
                            .foregroundStyle(appState.claudeUsage.isInstalled ? Color.green : Brand.accent)
                        Text(appState.claudeUsage.isInstalled ? "Claude Code connected" : "Claude Code not connected")
                        Spacer()
                        if appState.claudeUsage.isInstalled {
                            Button("Disconnect") { try? appState.claudeUsage.uninstall(); appState.reconfigureTrigger() }
                        } else {
                            Button("Connect") { try? appState.claudeUsage.install(); appState.reconfigureTrigger() }
                        }
                    }
                    .font(.callout)
                }

                Picker("Goal", selection: $rules.squatGoal) {
                    ForEach(goals, id: \.self) { g in
                        Text("\(g)").tag(g)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Exercise") {
                Picker("Type", selection: $rules.exercise) {
                    ForEach(ExerciseType.allCases, id: \.self) { ex in
                        Label(ex.displayName, systemImage: ex.systemImage).tag(ex)
                    }
                }

                if rules.exercise.usesDepth {
                    Picker("Depth", selection: $rules.depth) {
                        ForEach(ExerciseDepth.allCases, id: \.self) { d in
                            Text(d.displayName).tag(d)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text("Light counts a shallow dip — increase for a deeper squat.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if rules.exercise == .pushup {
                    Label("Beta: place the camera to the side so it sees your whole body.", systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Camera") {
                Picker("Source", selection: Binding(
                    get: { rules.cameraID ?? "" },
                    set: { rules.cameraID = $0.isEmpty ? nil : $0 }
                )) {
                    Text("Default (built-in)").tag("")
                    ForEach(cameras) { cam in
                        Text(cam.name).tag(cam.id)
                    }
                }
                Text("Tip: use your iPhone as a webcam (Continuity Camera) for a full-body view.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Active Hours") {
                HStack {
                    Text("From")
                    Spacer()
                    Picker("", selection: $rules.activeHoursStart) {
                        ForEach(0..<24, id: \.self) { h in
                            Text(hourLabel(h)).tag(h)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 80)

                    Text("to")

                    Picker("", selection: $rules.activeHoursEnd) {
                        ForEach(1..<25, id: \.self) { h in
                            Text(hourLabel(h % 24)).tag(h % 24)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 80)
                }
            }

            Section("Block Intensity") {
                Picker("Intensity", selection: $rules.blockIntensity) {
                    Text("Soft (notification nag)").tag(BlockIntensity.soft)
                    Text("Hard (force-hide apps)").tag(BlockIntensity.hard)
                }
                .pickerStyle(.radioGroup)

                if rules.blockIntensity == .hard && !appState.permissions.accessibilityGranted {
                    Label("Accessibility permission required for Hard mode", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
            }

            Section("Blocked Apps") {
                AppPickerView(selectedBundleIDs: $rules.blockedApps)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .onAppear { cameras = CameraService.availableCameras() }
        .onChange(of: rules) { newRules in
            Rules.current = newRules
            appState.reconfigureTrigger()
        }
    }

    private func hourLabel(_ h: Int) -> String {
        let components = DateComponents(hour: h)
        let date = Calendar.current.date(from: components) ?? Date()
        let f = DateFormatter(); f.dateFormat = "ha"
        return f.string(from: date)
    }
}

// MARK: - App Picker

struct AppEntry: Identifiable {
    let id: String           // bundle identifier
    let name: String
    let icon: NSImage
}

struct AppPickerView: View {
    @Binding var selectedBundleIDs: [String]
    @State private var apps: [AppEntry] = []

    var body: some View {
        VStack(spacing: 8) {
            ForEach(apps) { entry in
                SelectableCard(title: entry.name,
                               appIcon: entry.icon,
                               selected: selectedBundleIDs.contains(entry.id)) {
                    toggle(entry.id)
                }
            }
            if apps.isEmpty {
                Text("Scanning apps…").foregroundStyle(.secondary).font(.caption)
            }
        }
        .onAppear { if apps.isEmpty { apps = AppPickerView.installedApps() } }
    }

    private func toggle(_ id: String) {
        if selectedBundleIDs.contains(id) {
            selectedBundleIDs.removeAll { $0 == id }
        } else {
            selectedBundleIDs.append(id)
        }
    }

    // Scans common application folders for all installed apps (not just running ones).
    static func installedApps() -> [AppEntry] {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser.path
        let dirs = [
            "/Applications", "/Applications/Utilities",
            "\(home)/Applications",
            "/System/Applications", "/System/Applications/Utilities"
        ]
        var byID: [String: AppEntry] = [:]
        for dir in dirs {
            guard let items = try? fm.contentsOfDirectory(atPath: dir) else { continue }
            for item in items where item.hasSuffix(".app") {
                let path = dir + "/" + item
                guard let bundle = Bundle(path: path), let bid = bundle.bundleIdentifier else { continue }
                let name = item.replacingOccurrences(of: ".app", with: "")
                let icon = NSWorkspace.shared.icon(forFile: path)
                icon.size = NSSize(width: 24, height: 24)
                byID[bid] = AppEntry(id: bid, name: name, icon: icon)
            }
        }
        // Dev / AI-coding tools float to the top, then everything else alphabetically.
        let all = Array(byID.values)
        func alpha(_ a: AppEntry, _ b: AppEntry) -> Bool {
            a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
        let dev = all.filter(isDevTool).sorted(by: alpha)
        let rest = all.filter { !isDevTool($0) }.sorted(by: alpha)
        return dev + rest
    }

    private static let devKeywords = [
        "claude", "cursor", "codex", "code", "vscode", "terminal", "ghostty", "iterm",
        "warp", "xcode", "zed", "windsurf", "sublime", "jetbrains", "intellij", "pycharm",
        "webstorm", "goland", "rubymine", "phpstorm", "android studio", "hyper",
        "alacritty", "kitty", "tabby", "fleet", "nova", "wezterm"
    ]

    private static func isDevTool(_ e: AppEntry) -> Bool {
        let hay = (e.name + " " + e.id).lowercased()
        return devKeywords.contains { hay.contains($0) }
    }
}
