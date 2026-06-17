import SwiftUI
import AppKit

struct TodayView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var claude = AppState.shared.claudeUsage
    @State private var now = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var isClaudeMode: Bool { Rules.current.trigger == .claudeSpend && claude.isInstalled }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !appState.userName.isEmpty {
                    Text("Hi, \(appState.userName)")
                        .font(.system(size: 19, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                progressRing
                statsCard
                focusRhythm
                protectedApps
                startButton
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .tint(Brand.accent)
        .onReceive(timer) { now = $0 }
    }

    // MARK: - Progress ring

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 6)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Brand.gradient, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.smooth, value: progress)

            VStack(spacing: 6) {
                Image(systemName: Rules.current.exercise.systemImage)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(isClaudeMode ? "TOKENS THIS CYCLE" : "NEXT BREAK IN")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(.secondary)
                Text(isClaudeMode ? formatTokens(claude.tokensSinceLastBreak) : countdown)
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Brand.gradient)
                Label(isClaudeMode ? "Goal \(formatTokens(Rules.current.claudeTokenGoal))"
                                   : Rules.current.exercise.displayName,
                      systemImage: isClaudeMode ? "number" : Rules.current.exercise.systemImage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 200, height: 200)
    }

    // MARK: - Stats

    private var statsCard: some View {
        HStack(spacing: 0) {
            statItem(icon: "waveform.path.ecg", value: "\(appState.dailyReps)", label: "reps today")
            Divider().frame(height: 40).overlay(Color.white.opacity(0.08))
            statItem(icon: "flame.fill", value: "\(appState.streak)",
                     label: appState.streak == 1 ? "day streak" : "days streak")
        }
        .glassCard(padding: 16)
    }

    private func statItem(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Brand.accent)
            VStack(alignment: .leading, spacing: 1) {
                Text(value).font(.system(size: 26, weight: .bold, design: .rounded))
                Text(label).font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Focus rhythm (heatmap)

    private var focusRhythm: some View {
        let weeks = 18
        let gap: CGFloat = 3
        let days = RhythmData.build(weeks: weeks)
        let monthStarts = RhythmData.monthStarts(days: days, weeks: weeks)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Focus rhythm").font(.system(size: 14, weight: .semibold, design: .rounded))
                Spacer()
                Image(systemName: "arrow.right").font(.system(size: 12)).foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                let cell = max((geo.size.width - CGFloat(weeks - 1) * gap) / CGFloat(weeks), 1)
                VStack(alignment: .leading, spacing: 6) {
                    // Month labels aligned to columns
                    ZStack(alignment: .topLeading) {
                        ForEach(monthStarts, id: \.col) { ms in
                            Text(ms.label)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                                .offset(x: CGFloat(ms.col) * (cell + gap))
                        }
                    }
                    .frame(height: 12, alignment: .leading)

                    // Grid: rows = 7 days, columns = weeks (col-major order)
                    LazyHGrid(rows: Array(repeating: GridItem(.fixed(cell), spacing: gap), count: 7), spacing: gap) {
                        ForEach(days) { day in
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(RhythmData.color(reps: day.reps))
                                .frame(width: cell, height: cell)
                        }
                    }
                }
            }
            .frame(height: 7 * 17 + 6 * gap + 18)
        }
        .glassCard(padding: 16)
    }

    // MARK: - Protected apps

    private var protectedApps: some View {
        let apps = Rules.current.blockedApps.compactMap(Self.appInfo).prefix(4)
        return VStack(alignment: .leading, spacing: 10) {
            Text("Protected apps").font(.system(size: 14, weight: .semibold, design: .rounded))
            if apps.isEmpty {
                Text("No apps selected — add some in Rules.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                HStack(spacing: 8) {
                    ForEach(Array(apps), id: \.id) { app in
                        HStack(spacing: 6) {
                            Image(nsImage: app.icon).resizable().frame(width: 16, height: 16)
                            Text(app.name).font(.system(size: 12, weight: .medium)).lineLimit(1)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .pbGlassCapsule(interactive: false)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var startButton: some View {
        PBPrimaryButton(title: "Start break", systemImage: "figure.run", trailing: "⌘B",
                        fullWidth: true, enabled: !appState.session.isActive, key: "b") {
            Task { await appState.startBreak() }
        }
    }

    // MARK: - Helpers

    private var progress: CGFloat {
        if isClaudeMode {
            let goal = max(Rules.current.claudeTokenGoal, 1)
            return min(CGFloat(claude.tokensSinceLastBreak) / CGFloat(goal), 1)
        }
        let total = TimeInterval(Rules.current.intervalMinutes * 60)
        let remaining = max(appState.nextBreakDate.timeIntervalSinceNow, 0)
        guard total > 0 else { return 0 }
        return min(max(1 - CGFloat(remaining / total), 0), 1)
    }

    private var countdown: String {
        let interval = max(appState.nextBreakDate.timeIntervalSinceNow, 0)
        let h = Int(interval) / 3600
        let m = (Int(interval) % 3600) / 60
        let s = Int(interval) % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }

    struct AppInfo: Identifiable { let id: String; let name: String; let icon: NSImage }

    static func appInfo(_ bundleID: String) -> AppInfo? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return nil }
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 16, height: 16)
        let name = FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
        return AppInfo(id: bundleID, name: name, icon: icon)
    }
}

// MARK: - Heatmap data

enum RhythmData {
    struct Day: Identifiable { let id = UUID(); let date: Date; let reps: Int }

    static func build(weeks: Int) -> [Day] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekdayToday = cal.component(.weekday, from: today) - 1   // 0 = Sunday
        let endOfWeek = cal.date(byAdding: .day, value: 6 - weekdayToday, to: today)!
        let start = cal.date(byAdding: .day, value: -(weeks * 7 - 1), to: endOfWeek)!

        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        var days: [Day] = []
        for i in 0..<(weeks * 7) {
            let d = cal.date(byAdding: .day, value: i, to: start)!
            let reps = d <= today ? UserDefaults.standard.integer(forKey: "daily_reps_\(f.string(from: d))") : 0
            days.append(Day(date: d, reps: reps))
        }
        return days
    }

    static func monthStarts(days: [Day], weeks: Int) -> [(col: Int, label: String)] {
        let cal = Calendar.current
        let f = DateFormatter(); f.dateFormat = "MMM"
        var result: [(col: Int, label: String)] = []
        var lastMonth = -1
        for col in 0..<weeks {
            let d = days[col * 7].date
            let m = cal.component(.month, from: d)
            if m != lastMonth {
                // Skip labels that would overlap the previous one.
                if let last = result.last, col - last.col < 3 { lastMonth = m; continue }
                result.append((col, f.string(from: d)))
                lastMonth = m
            }
        }
        return result
    }

    static func color(reps: Int) -> Color {
        switch reps {
        case 0:      return Color.white.opacity(0.06)
        case 1...4:  return Brand.accent.opacity(0.30)
        case 5...9:  return Brand.accent.opacity(0.50)
        case 10...19: return Brand.accent.opacity(0.75)
        default:     return Brand.accent
        }
    }
}
