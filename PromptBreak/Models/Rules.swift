import Foundation

enum BlockIntensity: String, Codable, CaseIterable {
    case soft  // overlay + notification nag
    case hard  // repeated hide() calls
}

enum BreakTrigger: String, Codable, CaseIterable {
    case time          // every N minutes
    case claudeSpend   // after $X spent in Claude Code

    var displayName: String {
        switch self {
        case .time:        return "By time"
        case .claudeSpend: return "By Claude usage"
        }
    }
}

enum ExerciseType: String, Codable, CaseIterable {
    case squat
    case jumpingJack
    case pushup

    var displayName: String {
        switch self {
        case .squat:       return "Squats"
        case .jumpingJack: return "Jumping Jacks"
        case .pushup:      return "Push-ups (beta)"
        }
    }

    var shortName: String {
        switch self {
        case .squat:       return "Squats"
        case .jumpingJack: return "Jacks"
        case .pushup:      return "Push-ups"
        }
    }

    var unitName: String {
        switch self {
        case .squat:       return "squats"
        case .jumpingJack: return "jacks"
        case .pushup:      return "push-ups"
        }
    }

    var systemImage: String {
        switch self {
        case .squat:       return "figure.cross.training"
        case .jumpingJack: return "figure.mixed.cardio"
        case .pushup:      return "figure.strengthtraining.functional"
        }
    }

    // Whether the depth setting is meaningful for this exercise
    var usesDepth: Bool { self == .squat }
}

enum ExerciseDepth: String, Codable, CaseIterable {
    case light
    case medium
    case deep

    var displayName: String {
        switch self {
        case .light:  return "Light"
        case .medium: return "Medium"
        case .deep:   return "Deep"
        }
    }

    // Knee angle (degrees) that must be reached at the bottom of the squat.
    // Standing ≈ 170°; smaller angle = deeper squat.
    var kneeBottomAngle: Double {
        switch self {
        case .light:  return 140   // shallow dip
        case .medium: return 115
        case .deep:   return 95    // thighs ~parallel
        }
    }

    // For squat fallback (knees not visible): shoulder vertical drop needed
    var fallbackDropNeeded: Double {
        switch self {
        case .light:  return 0.05
        case .medium: return 0.09
        case .deep:   return 0.13
        }
    }
}

struct Rules: Codable, Equatable {
    var intervalMinutes: Int = 30
    var squatGoal: Int = 10
    var activeHoursStart: Int = 9   // hour in 24h
    var activeHoursEnd: Int = 18
    var blockedApps: [String] = []  // bundle identifiers
    var blockIntensity: BlockIntensity = .hard
    var exercise: ExerciseType = .squat
    var depth: ExerciseDepth = .light
    var cameraID: String? = nil     // AVCaptureDevice.uniqueID, nil = default front camera
    var trigger: BreakTrigger = .time
    var claudeTokenGoal: Int = 500_000   // tokens used in Claude Code before a break fires

    private static let key = "rules_v1"

    static var current: Rules {
        get {
            guard let data = UserDefaults.standard.data(forKey: key),
                  let rules = try? JSONDecoder().decode(Rules.self, from: data) else {
                return Rules()
            }
            return rules
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: key)
            }
        }
    }
}
