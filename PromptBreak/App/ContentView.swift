import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selection: Tab = .today

    enum Tab: String, CaseIterable, Identifiable {
        case today = "Today"
        case rules = "Rules"
        case account = "Account"

        var id: String { rawValue }
        var icon: String {
            switch self {
            case .today:   return "bolt.heart.fill"
            case .rules:   return "slider.horizontal.3"
            case .account: return "person.crop.circle.fill"
            }
        }
    }

    var body: some View {
        ZStack {
            GlassBackground()

            VStack(spacing: 0) {
                // Custom glass segmented control
                HStack(spacing: 6) {
                    ForEach(Tab.allCases) { tab in
                        tabButton(tab)
                    }
                }
                .padding(5)
                .pbGlassCapsule(interactive: false)
                .padding(.top, 18)
                .padding(.bottom, 8)

                Group {
                    switch selection {
                    case .today:   TodayView()
                    case .rules:   RulesView()
                    case .account: AccountView()
                    }
                }
                .environmentObject(appState)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .tint(Brand.accent)
        .frame(width: 460, height: 680)
    }

    private func tabButton(_ tab: Tab) -> some View {
        let active = selection == tab
        return Button {
            withAnimation(.smooth(duration: 0.25)) { selection = tab }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(tab.rawValue)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
            }
            .foregroundStyle(active ? AnyShapeStyle(.white) : AnyShapeStyle(.secondary))
            .padding(.horizontal, 16)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(active ? AnyShapeStyle(Brand.accent) : AnyShapeStyle(Color.clear))
            )
        }
        .buttonStyle(.plain)
    }
}
