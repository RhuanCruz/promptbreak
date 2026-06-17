import Vision
import AVFoundation
import Combine
import CoreGraphics

// MARK: - Helpers

// Angle (degrees) at vertex `b` formed by points a-b-c.
private func angleDeg(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> Double {
    let v1 = CGVector(dx: a.x - b.x, dy: a.y - b.y)
    let v2 = CGVector(dx: c.x - b.x, dy: c.y - b.y)
    let dot = v1.dx * v2.dx + v1.dy * v2.dy
    let m1 = (v1.dx * v1.dx + v1.dy * v1.dy).squareRoot()
    let m2 = (v2.dx * v2.dx + v2.dy * v2.dy).squareRoot()
    guard m1 > 0, m2 > 0 else { return 180 }
    let cosA = max(-1, min(1, dot / (m1 * m2)))
    return acos(cosA) * 180 / .pi
}

private func clamp01(_ x: Double) -> Double { max(0, min(1, x)) }

// Exponential moving average to smooth jittery signals.
private struct EMA {
    private var value: Double?
    let alpha: Double
    init(alpha: Double = 0.4) { self.alpha = alpha }
    mutating func update(_ x: Double) -> Double {
        let v = value.map { alpha * x + (1 - alpha) * $0 } ?? x
        value = v
        return v
    }
    mutating func reset() { value = nil }
}

// Fixed-threshold rep counter (used where we have a semantic threshold, e.g. knee angle).
private final class RepCounter {
    private enum Phase { case top, bottom }
    private var phase: Phase = .top
    private var candidate: Phase = .top
    private var framesInCandidate = 0
    private let minFrames: Int

    init(minFrames: Int = 3) { self.minFrames = minFrames }

    func update(value: Double, topThreshold: Double, bottomThreshold: Double) -> Bool {
        let target: Phase?
        if value >= topThreshold { target = .top }
        else if value <= bottomThreshold { target = .bottom }
        else { target = nil }

        guard let target else { framesInCandidate = 0; return false }
        if target == candidate { framesInCandidate += 1 }
        else { candidate = target; framesInCandidate = 1 }
        guard framesInCandidate >= minFrames else { return false }

        if target != phase {
            let wasBottom = (phase == .bottom)
            phase = target
            return target == .top && wasBottom
        }
        return false
    }

    func reset() { phase = .top; candidate = .top; framesInCandidate = 0 }
}

// Adaptive rep counter — learns the user's range of motion automatically.
// No fixed thresholds: it tracks the running min/max of the signal and counts
// a rep on a full high→low→high swing, as long as the range exceeds `minAmplitude`.
// Robust to camera distance/angle — ideal for push-ups seen head-on.
private final class AdaptiveRepCounter {
    private enum Phase { case high, low }
    private var phase: Phase = .high
    private var candidate: Phase = .high
    private var framesInCandidate = 0
    private var minV: Double?
    private var maxV: Double?
    private let minAmplitude: Double
    private let minFrames: Int
    private let decay: Double

    init(minAmplitude: Double, minFrames: Int = 2, decay: Double = 0.01) {
        self.minAmplitude = minAmplitude
        self.minFrames = minFrames
        self.decay = decay
    }

    /// `value`: high = rest position, low = effort position. Returns true on a completed rep.
    func update(_ value: Double) -> Bool {
        if minV == nil { minV = value; maxV = value }
        minV = Swift.min(minV!, value)
        maxV = Swift.max(maxV!, value)
        // Slowly shrink the band back toward the middle so it re-adapts if posture shifts.
        let mid = (minV! + maxV!) / 2
        minV! += (mid - minV!) * decay
        maxV! -= (maxV! - mid) * decay

        let range = maxV! - minV!
        guard range >= minAmplitude else { return false }

        let highThreshold = minV! + range * 0.70
        let lowThreshold = minV! + range * 0.30

        let target: Phase?
        if value >= highThreshold { target = .high }
        else if value <= lowThreshold { target = .low }
        else { target = nil }

        guard let target else { framesInCandidate = 0; return false }
        if target == candidate { framesInCandidate += 1 }
        else { candidate = target; framesInCandidate = 1 }
        guard framesInCandidate >= minFrames else { return false }

        if target != phase {
            let wasLow = (phase == .low)
            phase = target
            return target == .high && wasLow
        }
        return false
    }

    func reset() { phase = .high; candidate = .high; framesInCandidate = 0; minV = nil; maxV = nil }
}

// MARK: - PoseService

final class PoseService {
    private var cancellables = Set<AnyCancellable>()
    private var onRep: (() async -> Void)?

    private var exercise: ExerciseType = .squat
    private var depth: ExerciseDepth = .light

    private let counter = RepCounter(minFrames: 3)
    private let pushupCounter = AdaptiveRepCounter(minAmplitude: 0.03, minFrames: 2)
    private var signalEMA = EMA(alpha: 0.45)

    private var fallbackBaseline: CGFloat?
    private enum SquatMode { case angle, fallback, none }
    private var lastSquatMode: SquatMode = .none

    let statusPublisher = CurrentValueSubject<PoseStatus, Never>(.waiting)
    let jointsPublisher = CurrentValueSubject<[VNHumanBodyPoseObservation.JointName: CGPoint], Never>([:])

    func start(camera: CameraService, onRep: @escaping () async -> Void) {
        self.onRep = onRep
        self.exercise = Rules.current.exercise
        self.depth = Rules.current.depth
        counter.reset()
        pushupCounter.reset()
        signalEMA.reset()
        fallbackBaseline = nil
        lastSquatMode = .none

        camera.framePublisher
            .sink { [weak self] buffer in self?.process(buffer: buffer) }
            .store(in: &cancellables)
    }

    func stop() {
        cancellables.removeAll()
        onRep = nil
        statusPublisher.send(.waiting)
        jointsPublisher.send([:])
    }

    private func fire() { Task { await onRep?() } }

    private func process(buffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else { return }
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        try? handler.perform([request])

        guard let observation = request.results?.first else {
            statusPublisher.send(.noBodyDetected)
            return
        }

        let joints = extractJoints(from: observation)
        jointsPublisher.send(joints)

        switch exercise {
        case .squat:       processSquat(joints: joints)
        case .jumpingJack: processJumpingJack(joints: joints)
        case .pushup:      processPushup(joints: joints)
        }
    }

    // MARK: - Squat (knee angle when legs visible, shoulder-drop fallback otherwise)

    private func processSquat(joints: [VNHumanBodyPoseObservation.JointName: CGPoint]) {
        guard joints[.leftHip] != nil || joints[.rightHip] != nil else {
            statusPublisher.send(.waitingForBody); return
        }

        var kneeAngles: [Double] = []
        if let h = joints[.leftHip], let k = joints[.leftKnee], let a = joints[.leftAnkle] {
            kneeAngles.append(angleDeg(h, k, a))
        }
        if let h = joints[.rightHip], let k = joints[.rightKnee], let a = joints[.rightAnkle] {
            kneeAngles.append(angleDeg(h, k, a))
        }

        if !kneeAngles.isEmpty {
            switchSquatMode(.angle)
            let raw = kneeAngles.reduce(0, +) / Double(kneeAngles.count)
            let v = signalEMA.update(raw)
            statusPublisher.send(.fullBodyVisible)
            if counter.update(value: v, topThreshold: 158, bottomThreshold: depth.kneeBottomAngle) { fire() }
            return
        }

        let hasShoulders = joints[.leftShoulder] != nil && joints[.rightShoulder] != nil
        guard hasShoulders else { statusPublisher.send(.waitingForBody); return }
        switchSquatMode(.fallback)

        let shoulderY = (joints[.leftShoulder]!.y + joints[.rightShoulder]!.y) / 2
        if fallbackBaseline == nil { fallbackBaseline = shoulderY }
        if shoulderY > fallbackBaseline! { fallbackBaseline = shoulderY }
        guard let baseline = fallbackBaseline, baseline > 0 else { return }

        let drop = Double((baseline - shoulderY) / baseline)
        let value = signalEMA.update(clamp01(1.0 - drop / depth.fallbackDropNeeded))
        statusPublisher.send(.stepBack)
        if counter.update(value: value, topThreshold: 0.8, bottomThreshold: 0.25) { fire() }
    }

    private func switchSquatMode(_ mode: SquatMode) {
        if mode != lastSquatMode {
            counter.reset(); signalEMA.reset()
            lastSquatMode = mode
        }
    }

    // MARK: - Jumping Jack (requires BOTH arms raised AND legs spread)

    private func processJumpingJack(joints: [VNHumanBodyPoseObservation.JointName: CGPoint]) {
        guard let lw = joints[.leftWrist], let rw = joints[.rightWrist],
              let ls = joints[.leftShoulder], let rs = joints[.rightShoulder] else {
            statusPublisher.send(.waitingForBody); return
        }
        guard let la = joints[.leftAnkle], let ra = joints[.rightAnkle] else {
            statusPublisher.send(.showLegs); return
        }
        statusPublisher.send(.fullBodyVisible)

        let shoulderY = (ls.y + rs.y) / 2
        let shoulderWidth = abs(ls.x - rs.x)
        guard shoulderWidth > 0.02 else { return }

        let wristY = (lw.y + rw.y) / 2
        let armOpen = clamp01((Double(wristY - shoulderY) + 0.05) / 0.20)

        let ankleSpread = Double(abs(la.x - ra.x) / shoulderWidth)
        let legOpen = clamp01((ankleSpread - 0.9) / 0.9)

        let openness = min(armOpen, legOpen)
        let value = signalEMA.update(1.0 - openness)
        if counter.update(value: value, topThreshold: 0.7, bottomThreshold: 0.3) { fire() }
    }

    // MARK: - Push-up (phone in front; head/shoulder height with auto-calibrated amplitude)

    private func processPushup(joints: [VNHumanBodyPoseObservation.JointName: CGPoint]) {
        // Signal = average vertical position of head + shoulders. As you lower into the
        // push-up, this drops; pushing back up raises it. The adaptive counter learns
        // your range, so it works regardless of distance or camera angle.
        var ys: [Double] = []
        if let n = joints[.nose] { ys.append(Double(n.y)) }
        if let s = joints[.leftShoulder] { ys.append(Double(s.y)) }
        if let s = joints[.rightShoulder] { ys.append(Double(s.y)) }

        guard !ys.isEmpty else { statusPublisher.send(.waitingForBody); return }

        let raw = ys.reduce(0, +) / Double(ys.count)
        let v = signalEMA.update(raw)
        statusPublisher.send(.fullBodyVisible)
        if pushupCounter.update(v) { fire() }
    }

    // MARK: - Joint extraction

    private func extractJoints(from obs: VNHumanBodyPoseObservation) -> [VNHumanBodyPoseObservation.JointName: CGPoint] {
        let names: [VNHumanBodyPoseObservation.JointName] = [
            .leftShoulder, .rightShoulder,
            .leftElbow, .rightElbow,
            .leftWrist, .rightWrist,
            .leftHip, .rightHip,
            .leftKnee, .rightKnee,
            .leftAnkle, .rightAnkle,
            .nose
        ]
        var result: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        for name in names {
            if let point = try? obs.recognizedPoint(name), point.confidence > 0.4 {
                result[name] = CGPoint(x: point.x, y: point.y)
            }
        }
        return result
    }
}

enum PoseStatus {
    case waiting
    case noBodyDetected
    case waitingForBody
    case fullBodyVisible
    case stepBack       // squat fallback (knees not visible)
    case showLegs       // jumping jack needs legs in frame
}
