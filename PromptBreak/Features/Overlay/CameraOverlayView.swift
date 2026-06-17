import SwiftUI
import AVFoundation
import Vision

struct CameraOverlayView: View {
    @EnvironmentObject private var appState: AppState
    @State private var poseStatus: PoseStatus = .waiting
    @State private var joints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    @State private var repFlash = false

    private var reps: Int { appState.session.reps }
    private var goal: Int { appState.session.goal }

    var body: some View {
        ZStack {
            // Camera preview fills the window
            CameraPreviewView(session: appState.camera.session)

            // Dark scrim for readability
            Color.black.opacity(0.40)

            // Skeleton overlay
            SkeletonOverlayView(joints: joints)

            // HUD
            VStack(spacing: 18) {
                Spacer()

                // Exercise name
                Label(Rules.current.exercise.displayName, systemImage: Rules.current.exercise.systemImage)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))

                // Rep counter
                Text("\(reps) / \(goal)")
                    .font(.system(size: 72, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(radius: 8)
                    .scaleEffect(repFlash ? 1.15 : 1.0)
                    .animation(.spring(duration: 0.15), value: repFlash)

                // Status
                statusLabel

                Spacer()
            }
            .padding(24)
        }
        .frame(width: 440, height: 600)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
        .onReceive(appState.pose.statusPublisher) { status in
            poseStatus = status
        }
        .onReceive(appState.pose.jointsPublisher) { j in
            joints = j
        }
        .onChange(of: appState.session.reps) { _ in
            flashRep()
        }
    }

    @ViewBuilder
    private var statusLabel: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
            Text(statusText)
                .font(.title3.weight(.medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private var statusText: String {
        switch poseStatus {
        case .waiting:           return "Initialising camera…"
        case .noBodyDetected:    return "No body detected"
        case .waitingForBody:    return "Step into frame"
        case .fullBodyVisible:   return "Looking good — keep going"
        case .stepBack:          return "Step back so I can see your knees"
        case .showLegs:          return "Step back — I need to see your legs to count"
        }
    }

    private var statusColor: Color {
        switch poseStatus {
        case .fullBodyVisible:   return .green
        case .stepBack:          return .orange
        case .showLegs:          return .orange
        default:                 return .yellow
        }
    }

    private func flashRep() {
        repFlash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { repFlash = false }
    }
}

// MARK: - Camera preview (NSViewRepresentable)

struct CameraPreviewView: NSViewRepresentable {
    let session: AVCaptureSession

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        view.wantsLayer = true
        view.layer = layer
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let layer = nsView.layer as? AVCaptureVideoPreviewLayer {
            layer.session = session
        }
    }
}

// MARK: - Skeleton

struct SkeletonOverlayView: View {
    let joints: [VNHumanBodyPoseObservation.JointName: CGPoint]

    // Bone connections to draw
    private let connections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        (.leftShoulder, .rightShoulder),
        (.leftShoulder, .leftElbow),
        (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow),
        (.rightElbow, .rightWrist),
        (.leftShoulder, .leftHip),
        (.rightShoulder, .rightHip),
        (.leftHip, .rightHip),
        (.leftHip, .leftKnee),
        (.rightHip, .rightKnee),
        (.leftKnee, .leftAnkle),
        (.rightKnee, .rightAnkle),
        (.leftShoulder, .nose),
        (.rightShoulder, .nose)
    ]

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                // Bones
                for (a, b) in connections {
                    guard let pa = joints[a], let pb = joints[b] else { continue }
                    var path = Path()
                    path.move(to: flip(pa, in: size))
                    path.addLine(to: flip(pb, in: size))
                    ctx.stroke(path, with: .color(.white.opacity(0.7)), lineWidth: 3)
                }
                // Joints
                for (_, pt) in joints {
                    let p = flip(pt, in: size)
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: p.x - 5, y: p.y - 5, width: 10, height: 10)),
                        with: .color(.green)
                    )
                }
            }
        }
        .ignoresSafeArea()
    }

    // Vision coords have y=0 at bottom; flip for screen coords
    private func flip(_ p: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: p.x * size.width, y: (1 - p.y) * size.height)
    }
}
