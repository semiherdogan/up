import Foundation

public enum SessionEvent: Equatable, Sendable {
    case scheduleStarted(name: String, until: Date)
    // scheduleName is nil when a manual session ended.
    case sessionEnded(scheduleName: String?)

    public init?(from previous: KeepAwakeState, to current: KeepAwakeState) {
        switch (previous, current) {
        case (.scheduled, .scheduled):
            return nil
        case (_, .scheduled(let name, let until)):
            self = .scheduleStarted(name: name, until: until)
        case (.scheduled(let name, _), .idle):
            self = .sessionEnded(scheduleName: name)
        case (.manual, .idle):
            self = .sessionEnded(scheduleName: nil)
        default:
            return nil
        }
    }
}
