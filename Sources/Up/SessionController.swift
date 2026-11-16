import AppKit
import Observation
import UpCore

@MainActor
@Observable
final class SessionController {
    private(set) var state: KeepAwakeState = .idle
    private(set) var schedules: [Schedule]
    private(set) var errorMessage: String?

    private static let minimumHealthyLifetime: TimeInterval = 1

    @ObservationIgnored private var manual: ManualSession?
    @ObservationIgnored private var suppressedUntil: [Schedule.ID: Date] = [:]
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private let caffeinate = Caffeinate()
    @ObservationIgnored private let store: ScheduleStore
    @ObservationIgnored private let notifier = Notifier()

    init(store: ScheduleStore = ScheduleStore()) {
        self.store = store
        schedules = store.load()
        observeSystemEvents()
        caffeinate.onUnexpectedExit = { [weak self] lifetime in self?.caffeinateExited(after: lifetime) }
        evaluate(notify: true)
    }

    func start(duration: TimeInterval?) {
        manual = duration.map { .until(Date().addingTimeInterval($0)) } ?? .indefinite
        evaluate(notify: false)
    }

    func end() {
        manual = nil
        // An ended schedule stays quiet until its current window closes.
        let activeEnds = SessionPlanner.activeWindowEnds(at: Date(), schedules: schedules, calendar: .current)
        suppressedUntil.merge(activeEnds) { _, new in new }
        evaluate(notify: false)
    }

    func setSchedules(_ newValue: [Schedule]) {
        // Editing a schedule re-arms it.
        let previous = schedules
        suppressedUntil = suppressedUntil.filter { id, _ in
            newValue.first { $0.id == id } == previous.first { $0.id == id }
        }
        schedules = newValue
        store.save(newValue)
        evaluate(notify: false)
    }

    private func evaluate(notify: Bool) {
        let now = Date()
        if case .until(let end)? = manual, end <= now { manual = nil }
        suppressedUntil = suppressedUntil.filter { $0.value > now }

        let plan = SessionPlanner.plan(
            at: now,
            manual: manual,
            schedules: schedules,
            suppressedUntil: suppressedUntil,
            calendar: .current
        )
        do {
            try caffeinate.setRunning(plan.state.isActive)
            let previous = state
            state = plan.state
            errorMessage = nil
            if notify, let event = SessionEvent(from: previous, to: plan.state) {
                notifier.post(event)
            }
        } catch {
            fail("Could not start caffeinate: \(error.localizedDescription)")
        }
        scheduleTimer(at: plan.nextEvaluation)
    }

    private func caffeinateExited(after lifetime: TimeInterval) {
        // Restarting a process that dies right away would spin.
        guard lifetime >= Self.minimumHealthyLifetime else {
            fail("caffeinate exited right after starting.")
            return
        }
        evaluate(notify: true)
    }

    private func fail(_ message: String) {
        // Drop the manual session so the menu never hides one the user cannot end.
        manual = nil
        state = .idle
        errorMessage = message
        notifier.postFailure(message)
    }

    private func scheduleTimer(at date: Date?) {
        timer?.invalidate()
        timer = nil
        guard let date else { return }
        let timer = Timer(fire: date, interval: 0, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.evaluate(notify: true) }
        }
        // .common keeps the timer firing while the menu is open.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func observeSystemEvents() {
        let reevaluate: @Sendable (Notification) -> Void = { [weak self] _ in
            MainActor.assumeIsolated { self?.evaluate(notify: true) }
        }
        // Timers do not fire during sleep, and a clock change makes the pending fire date wrong.
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main, using: reevaluate
        )
        for name in [Notification.Name.NSSystemClockDidChange, .NSSystemTimeZoneDidChange] {
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main, using: reevaluate)
        }
    }
}
