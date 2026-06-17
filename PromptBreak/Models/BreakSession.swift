import Foundation

enum BreakSession: Equatable {
    case idle
    case active(reps: Int, goal: Int)

    var isActive: Bool {
        if case .active = self { return true }
        return false
    }

    var reps: Int {
        if case .active(let r, _) = self { return r }
        return 0
    }

    var goal: Int {
        if case .active(_, let g) = self { return g }
        return 0
    }
}
