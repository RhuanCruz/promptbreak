import Foundation
import Combine

final class SchedulerService {
    var onBreakDue: (() async -> Void)?

    private let nextBreakSubject = CurrentValueSubject<Date, Never>(.distantFuture)
    var nextBreakPublisher: AnyPublisher<Date, Never> { nextBreakSubject.eraseToAnyPublisher() }

    private var timer: Timer?
    private var nextBreak: Date = .distantFuture

    func start(interval: Int) {
        scheduleNext(interval: interval)
    }

    func reset() {
        scheduleNext(interval: Rules.current.intervalMinutes)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func scheduleNext(interval: Int) {
        timer?.invalidate()
        let fireDate = Date().addingTimeInterval(TimeInterval(interval * 60))
        nextBreak = fireDate
        nextBreakSubject.send(fireDate)
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(interval * 60), repeats: false) { [weak self] _ in
            guard let self else { return }
            guard self.isWithinActiveHours() else {
                self.reset()
                return
            }
            Task { await self.onBreakDue?() }
        }
    }

    private func isWithinActiveHours() -> Bool {
        let rules = Rules.current
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= rules.activeHoursStart && hour < rules.activeHoursEnd
    }
}
