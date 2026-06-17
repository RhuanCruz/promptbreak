import SwiftUI
import AppKit

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var permissions: PermissionsService
    @ObservedObject var license: LicenseService
    @ObservedObject var claude: ClaudeUsageService
    let onComplete: () -> Void

    enum Step: Int, CaseIterable {
        case welcome, exercise, goal, trigger, amount, camera, apps, permissions, activate
    }

    @State private var step: Step = .welcome
    @State private var name = ""
    @State private var emailInput = ""
    @State private var activating = false
    @State private var activationError: String?
    @State private var rules = Rules.current
    @State private var cameras: [CameraInfo] = []

    private let pollTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let tokenGoals = [200_000, 500_000, 1_000_000, 2_000_000]

    var body: some View {
        ZStack {
            GlassBackground()
            VStack(spacing: 0) {
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 36)
                    .padding(.top, 36)
                footer
            }
        }
        .tint(Brand.accent)
        .frame(width: 520, height: 640)
        .onAppear { cameras = CameraService.availableCameras() }
        .onReceive(pollTimer) { _ in if step == .permissions { permissions.checkAll() } }
        .onChange(of: rules) { newRules in
            Rules.current = newRules
            appState.reconfigureTrigger()
        }
        .animation(.smooth(duration: 0.3), value: step)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome:     welcomeStep
        case .exercise:    exerciseStep
        case .goal:        goalStep
        case .trigger:     triggerStep
        case .amount:      amountStep
        case .camera:      cameraStep
        case .apps:        appsStep
        case .permissions: permissionsStep
        case .activate:    activateStep
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "figure.run")
                .font(.system(size: 50, weight: .semibold))
                .foregroundStyle(Brand.gradient)
                .frame(width: 104, height: 104)
                .pbGlass(in: Circle())

            VStack(spacing: 10) {
                Text("Welcome to PromptBreak")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("Move your body between coding sessions.\nWe lock your tools until you finish your reps.")
                    .font(.system(size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }

            glassField("Your name", text: $name)
                .frame(maxWidth: 280)
                .onSubmit { if canContinueWelcome { goNext() } }
            Spacer(); Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var exerciseStep: some View {
        centeredStep(title: "Pick your exercise", subtitle: "What you'll do during each break.") {
            GlassChips(options: ExerciseType.allCases.map { ($0, $0.shortName) }, selection: $rules.exercise)
            if rules.exercise.usesDepth {
                Text("Depth")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                GlassChips(options: ExerciseDepth.allCases.map { ($0, $0.displayName) }, selection: $rules.depth)
            }
        }
    }

    private var goalStep: some View {
        centeredStep(title: "Reps per break", subtitle: "How many before your tools unlock.") {
            GlassChips(options: [5, 10, 15, 20].map { ($0, "\($0)") }, selection: $rules.squatGoal)
        }
    }

    private var triggerStep: some View {
        centeredStep(title: "When to break",
                     subtitle: "Trigger breaks by time, or by how many tokens you use in Claude Code.") {
            GlassChips(options: BreakTrigger.allCases.map { ($0, $0.displayName) }, selection: $rules.trigger)

            if rules.trigger == .claudeSpend {
                claudeConnectRow.frame(maxWidth: 360).padding(.top, 8)
            }
        }
    }

    private var amountStep: some View {
        if rules.trigger == .time {
            return AnyView(centeredStep(title: "How often", subtitle: "Take a break every…") {
                GlassChips(options: [15, 20, 30, 45, 60].map { ($0, "\($0)m") }, selection: $rules.intervalMinutes)
            })
        } else {
            return AnyView(centeredStep(title: "How many tokens", subtitle: "Break after using this many tokens in Claude Code.") {
                GlassChips(options: tokenGoals.map { ($0, formatTokens($0)) }, selection: $rules.claudeTokenGoal)
            })
        }
    }

    private var claudeConnectRow: some View {
        HStack(spacing: 10) {
            Image(systemName: claude.isInstalled ? "checkmark.circle.fill" : "terminal")
                .foregroundStyle(claude.isInstalled ? AnyShapeStyle(.green) : AnyShapeStyle(Brand.accent))
            VStack(alignment: .leading, spacing: 1) {
                Text(claude.isInstalled ? "Claude Code connected" : "Connect Claude Code")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Text(claude.isInstalled ? "Tracking your tokens via status line."
                                        : "Adds a status line to ~/.claude/settings.json.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if claude.isInstalled {
                PBSecondaryButton(title: "Disconnect") { try? claude.uninstall(); appState.reconfigureTrigger() }
            } else {
                PBSecondaryButton(title: "Connect") { try? claude.install(); appState.reconfigureTrigger() }
            }
        }
        .padding(14)
        .pbGlass(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var cameraStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            stepHeader(title: "Camera", subtitle: "Tip: use your iPhone for a full-body view.")
            ScrollView {
                VStack(spacing: 8) {
                    SelectableCard(title: "Default (built-in)", systemIcon: "camera.fill",
                                   selected: rules.cameraID == nil) { rules.cameraID = nil }
                    ForEach(cameras) { cam in
                        SelectableCard(title: cam.name, systemIcon: "video.fill",
                                       selected: rules.cameraID == cam.id) { rules.cameraID = cam.id }
                    }
                }
            }
            .frame(maxHeight: 360)
            Spacer()
        }
    }

    private var appsStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            stepHeader(title: "Apps to block", subtitle: "These lose focus during a break until you finish.")
            ScrollView {
                AppPickerView(selectedBundleIDs: $rules.blockedApps)
            }
            .frame(maxHeight: 360)
            Spacer()
        }
    }

    private var permissionsStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            stepHeader(title: "Grant permissions", subtitle: "PromptBreak needs a few permissions to work.")
            VStack(spacing: 10) {
                permissionCard(icon: "camera.fill", title: "Camera",
                               subtitle: "Counts your reps during breaks.",
                               granted: permissions.cameraGranted, required: true,
                               action: { permissions.requestCamera() })
                permissionCard(icon: "accessibility", title: "Accessibility",
                               subtitle: "Lets PromptBreak hide blocked apps.",
                               granted: permissions.accessibilityGranted, required: false,
                               action: { permissions.requestAccessibility() })
                permissionCard(icon: "bell.fill", title: "Notifications",
                               subtitle: "Gentle nudges when a break is due.",
                               granted: permissions.notificationsGranted, required: false,
                               action: { permissions.requestNotifications() })
            }
            Spacer()
        }
    }

    private var activateStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(title: "Activate your license", subtitle: "A one-time purchase — pay once, use forever.")
            if license.state.isValid {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill").font(.title).foregroundStyle(Brand.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("You're all set!").font(.headline)
                        Text("Lifetime access unlocked.").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(16)
                .pbGlass(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("1. Get lifetime access")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                            Text("Opens secure Stripe checkout.").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        PBPrimaryButton(title: "Buy now") { NSWorkspace.shared.open(stripeLifetimeURL) }
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("2. Activate with your email")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                        HStack(spacing: 10) {
                            glassField("Email used at checkout", text: $emailInput)
                                .onSubmit { activate() }
                            PBSecondaryButton(title: activating ? "…" : "Activate",
                                              enabled: !emailInput.isEmpty && !activating) { activate() }
                        }
                        if let err = activationError {
                            Text(err).font(.caption).foregroundStyle(.red)
                        }
                    }
                }
                .padding(18)
                .pbGlass(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            Spacer()
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            if step != .welcome {
                PBSecondaryButton(title: "Back") { goBack() }
            }
            Spacer()
            HStack(spacing: 6) {
                ForEach(Step.allCases, id: \.rawValue) { s in
                    Capsule()
                        .fill(s == step ? AnyShapeStyle(Brand.accent) : AnyShapeStyle(Color.secondary.opacity(0.3)))
                        .frame(width: s == step ? 16 : 6, height: 6)
                        .animation(.smooth, value: step)
                }
            }
            Spacer()
            PBPrimaryButton(title: primaryLabel, enabled: primaryEnabled) { goNext() }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 18)
    }

    // MARK: - Logic

    private var canContinueWelcome: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var primaryLabel: String {
        step == .activate ? "Start using PromptBreak" : "Continue"
    }

    private var primaryEnabled: Bool {
        switch step {
        case .welcome:     return canContinueWelcome
        case .permissions: return permissions.cameraGranted
        case .activate:    return license.state.isValid
        default:           return true
        }
    }

    private func goNext() {
        if step == .activate {
            appState.completeOnboarding(name: name)
            onComplete()
        } else if let next = Step(rawValue: step.rawValue + 1) {
            step = next
        }
    }

    private func goBack() {
        if let prev = Step(rawValue: step.rawValue - 1) { step = prev }
    }

    private func activate() {
        let email = emailInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty else { return }
        activating = true
        activationError = nil
        Task {
            let error = await license.activateByEmail(email: email)
            activating = false
            activationError = error
        }
    }

    // MARK: - Components

    private func centeredStep<C: View>(title: String, subtitle: String, @ViewBuilder content: () -> C) -> some View {
        VStack(spacing: 26) {
            Spacer()
            VStack(spacing: 8) {
                Text(title).font(.system(size: 26, weight: .bold, design: .rounded))
                Text(subtitle).font(.system(size: 14)).foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            VStack(spacing: 14) { content() }
            Spacer(); Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func stepHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 24, weight: .bold, design: .rounded))
            Text(subtitle).font(.system(size: 13)).foregroundStyle(.secondary)
        }
    }

    private func glassField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .textFieldStyle(.plain)
            .font(.system(size: 14))
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(.white.opacity(0.08), lineWidth: 1))
    }

    private func permissionCard(icon: String, title: String, subtitle: String, granted: Bool, required: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Brand.accent)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title).font(.system(size: 14, weight: .semibold, design: .rounded))
                    if required {
                        Text("REQUIRED")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Brand.accent.opacity(0.18), in: Capsule())
                            .foregroundStyle(Brand.accent)
                    }
                }
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if granted {
                Image(systemName: "checkmark").font(.system(size: 13, weight: .bold)).foregroundStyle(.secondary)
            } else {
                PBSecondaryButton(title: "Grant") { action() }
            }
        }
        .padding(14)
        .pbGlass(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
