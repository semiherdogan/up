import Foundation

public enum ManualSession: Equatable, Sendable {
    case indefinite
    case until(Date)
}

public enum KeepAwakeState: Equatable, Sendable {
    case idle
    case manual(until: Date?)
    case scheduled(name: String, until: Date)

    public var isActive: Bool { self != .idle }
}

public struct SessionPlan: Equatable, Sendable {
    public let state: KeepAwakeState
    // The earliest moment the state can change without user input.
    public let nextEvaluation: Date?
}

public enum SessionPlanner {
    public static func plan(
        at now: Date,
        manual: ManualSession?,
        schedules: [Schedule],
        suppressedUntil: [Schedule.ID: Date],
        calendar: Calendar
    ) -> SessionPlan {
        var transitions: [Date] = []
        var scheduled: (name: String, until: Date)?

        for schedule in schedules where schedule.isEnabled {
            if let window = schedule.activeWindow(at: now, calendar: calendar) {
                transitions.append(window.end)
                let isSuppressed = suppressedUntil[schedule.id].map { now < $0 } ?? false
                if !isSuppressed, window.end > (scheduled?.until ?? .distantPast) {
                    scheduled = (schedule.name, window.end)
                }
            }
            if let nextStart = schedule.nextStart(after: now, calendar: calendar) {
                transitions.append(nextStart)
            }
        }

        let scheduledState = scheduled.map { KeepAwakeState.scheduled(name: $0.name, until: $0.until) }
        let state: KeepAwakeState
        switch manual {
        case .indefinite?:
            state = .manual(until: nil)
        case .until(let end)? where end > now:
            transitions.append(end)
            // Report whichever keeps the Mac awake longest.
            if let scheduled, let scheduledState, scheduled.until > end {
                state = scheduledState
            } else {
                state = .manual(until: end)
            }
        default:
            state = scheduledState ?? .idle
        }
        return SessionPlan(state: state, nextEvaluation: transitions.min())
    }

    public static func activeWindowEnds(
        at now: Date,
        schedules: [Schedule],
        calendar: Calendar
    ) -> [Schedule.ID: Date] {
        var ends: [Schedule.ID: Date] = [:]
        for schedule in schedules where schedule.isEnabled {
            if let window = schedule.activeWindow(at: now, calendar: calendar) {
                ends[schedule.id] = window.end
            }
        }
        return ends
    }
}
