import SwiftUI

struct BlockOverlayView: View {
    @EnvironmentObject private var appState: AppState

    private var reps: Int {
        guard case .active(let r, _) = appState.session else { return 0 }
        return r
    }
    private var goal: Int {
        guard case .active(_, let g) = appState.session else { return 0 }
        return g
    }
    private var remaining: Int { max(goal - reps, 0) }

    var body: some View {
        ZStack {
            Color.black.opacity(0.88)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Image("LogoTransparent")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)

                VStack(spacing: 10) {
                    Text("Finish your exercise")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("\(remaining) rep\(remaining == 1 ? "" : "s") to go")
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                }

                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<goal, id: \.self) { i in
                        Circle()
                            .fill(i < reps ? Color.orange : Color.white.opacity(0.2))
                            .frame(width: 10, height: 10)
                            .animation(.spring(duration: 0.2), value: reps)
                    }
                }
                .padding(.vertical, 4)

                Button(action: { appState.bringExerciseWindowToFront() }) {
                    Label("Back to exercise", systemImage: "figure.walk")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color.orange, in: Capsule())
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.return, modifiers: [])
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
