import Foundation
import Combine
import AppKit

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    // Services
    let scheduler = SchedulerService()
    let camera = CameraService()
    let pose = PoseService()
    let blocker = BlockerService()
    let permissions = PermissionsService()
    let licenseService = LicenseService()
    let claudeUsage = ClaudeUsageService()

    // Session
    @Published var session: BreakSession = .idle
    @Published var dailyReps: Int = 0
    @Published var streak: Int = 0

    // Derived
    @Published var nextBreakDate: Date = .distantFuture

    // Onboarding / profile
    @Published var hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: "onboarding_completed")
    @Published var userName: String = UserDefaults.standard.string(forKey: "user_name") ?? ""

    private var overlayWindow: CameraOverlayWindow?
    private var blockOverlayWindow: BlockOverlayWindow?
    private var onboardingWindow: OnboardingWindow?
    private var mainWindow: MainWindow?
    private var cancellables = Set<AnyCancellable>()

    private init() {}

    func completeOnboarding(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        userName = trimmed
        UserDefaults.standard.set(trimmed, forKey: "user_name")
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "onboarding_completed")
        reconfigureTrigger()
        showMainWindow()
    }

    func presentOnboarding() {
        let win = OnboardingWindow()
        onboardingWindow = win
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // Debug helper — re-run the onboarding flow.
    func resetOnboarding() {
        hasCompletedOnboarding = false
        UserDefaults.standard.set(false, forKey: "onboarding_completed")
        presentOnboarding()
    }

    func onLaunch() {
        loadStats()
        licenseService.revalidateIfNeeded()
        permissions.checkAll()
        scheduler.onBreakDue = { [weak self] in
            await self?.startBreak()
        }
        scheduler.nextBreakPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$nextBreakDate)
        claudeUsage.onGoalReached = { [weak self] in
            await self?.startBreak()
        }
        claudeUsage.refreshScriptIfInstalled()
        reconfigureTrigger()
    }

    // Starts the right break trigger based on the user's Rules (time vs Claude spend).
    func reconfigureTrigger() {
        let rules = Rules.current
        if rules.trigger == .claudeSpend && claudeUsage.isInstalled {
            scheduler.stop()
            nextBreakDate = .distantFuture
            claudeUsage.resetSpend()
            claudeUsage.startMonitoring(goal: rules.claudeTokenGoal)
        } else {
            claudeUsage.stopMonitoring()
            scheduler.start(interval: rules.intervalMinutes)
        }
    }

    func showMainWindow() {
        if mainWindow == nil { mainWindow = MainWindow() }
        mainWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func startBreak() {
        guard session == .idle else { return }
        // No license = no access. Send the user to the paywall instead of running a break.
        guard licenseService.state.isValid else {
            presentOnboarding()
            return
        }
        session = .active(reps: 0, goal: Rules.current.squatGoal)
        blocker.onBlockTriggered = { [weak self] _ in
            self?.showBlockOverlay()
        }
        blocker.activate(blockedApps: Rules.current.blockedApps, intensity: Rules.current.blockIntensity)
        showOverlay()
    }

    func recordRep() {
        guard case .active(let reps, let goal) = session else { return }
        let newCount = reps + 1
        dailyReps += 1
        saveStats()
        if newCount >= goal {
            endBreak()
        } else {
            session = .active(reps: newCount, goal: goal)
        }
    }

    func endBreak() {
        session = .idle
        blocker.onBlockTriggered = nil
        blocker.deactivate()
        dismissBlockOverlay()
        dismissOverlay()
        if Rules.current.trigger == .claudeSpend && claudeUsage.isInstalled {
            claudeUsage.resetSpend()
        } else {
            scheduler.reset()
        }
        updateStreak()
    }

    // MARK: - Block overlay (shown when user tries to open a blocked app mid-break)

    private func showBlockOverlay() {
        guard blockOverlayWindow == nil else {
            blockOverlayWindow?.makeKeyAndOrderFront(nil)
            return
        }
        let win = BlockOverlayWindow()
        blockOverlayWindow = win
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func dismissBlockOverlay() {
        blockOverlayWindow?.close()
        blockOverlayWindow = nil
    }

    func bringExerciseWindowToFront() {
        dismissBlockOverlay()
        overlayWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Exercise overlay

    private func showOverlay() {
        let win = CameraOverlayWindow()
        overlayWindow = win
        win.makeKeyAndOrderFront(nil)
        camera.start()
        pose.start(camera: camera) { [weak self] in
            await self?.recordRep()
        }
    }

    private func dismissOverlay() {
        pose.stop()
        camera.stop()
        overlayWindow?.close()
        overlayWindow = nil
    }

    // MARK: - Persistence

    private func loadStats() {
        dailyReps = UserDefaults.standard.integer(forKey: "daily_reps_\(today())")
        streak = UserDefaults.standard.integer(forKey: "streak")
    }

    private func saveStats() {
        UserDefaults.standard.set(dailyReps, forKey: "daily_reps_\(today())")
    }

    private func updateStreak() {
        let key = "last_break_day"
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let lastDay = UserDefaults.standard.string(forKey: key) ?? ""
        if lastDay == dayString(yesterday) || lastDay == today() {
            if lastDay != today() { streak += 1 }
        } else {
            streak = 1
        }
        UserDefaults.standard.set(today(), forKey: key)
        UserDefaults.standard.set(streak, forKey: "streak")
    }

    private func today() -> String { dayString(Date()) }
    private func dayString(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: d)
    }
}

extension Notification.Name {
    static let showMainWindow = Notification.Name("com.promptbreak.showMainWindow")
}
