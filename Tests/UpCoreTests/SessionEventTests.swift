import Foundation
import Testing
@testable import UpCore

@Suite struct SessionEventTests {
    private let x = november(16, 17)
    private let y = november(16, 12)
    private let z = november(16, 18)

    @Test func idleToScheduledStartsSchedule() {
        let event = SessionEvent(from: .idle, to: .scheduled(name: "Work", until: x))
        #expect(event == .scheduleStarted(name: "Work", until: x))
    }

    @Test func manualToScheduledStartsSchedule() {
        let event = SessionEvent(from: .manual(until: y), to: .scheduled(name: "Work", until: x))
        #expect(event == .scheduleStarted(name: "Work", until: x))
    }

    @Test func scheduledToScheduledWithDifferentEndIsSilent() {
        let event = SessionEvent(from: .scheduled(name: "Work", until: x), to: .scheduled(name: "Work", until: z))
        #expect(event == nil)
    }

    @Test func scheduledToIdleEndsSchedule() {
        let event = SessionEvent(from: .scheduled(name: "Work", until: x), to: .idle)
        #expect(event == .sessionEnded(scheduleName: "Work"))
    }

    @Test func timedManualToIdleEndsSession() {
        let event = SessionEvent(from: .manual(until: y), to: .idle)
        #expect(event == .sessionEnded(scheduleName: nil))
    }

    @Test func indefiniteManualToIdleEndsSession() {
        let event = SessionEvent(from: .manual(until: nil), to: .idle)
        #expect(event == .sessionEnded(scheduleName: nil))
    }

    @Test func idleToIdleIsSilent() {
        #expect(SessionEvent(from: .idle, to: .idle) == nil)
    }

    @Test func idleToManualIsSilent() {
        #expect(SessionEvent(from: .idle, to: .manual(until: y)) == nil)
    }

    @Test func scheduledToScheduledWithDifferentNameIsSilent() {
        let event = SessionEvent(from: .scheduled(name: "Work", until: x), to: .scheduled(name: "Other", until: z))
        #expect(event == nil)
    }

    @Test func indefiniteManualToScheduledStartsSchedule() {
        let event = SessionEvent(from: .manual(until: nil), to: .scheduled(name: "Work", until: x))
        #expect(event == .scheduleStarted(name: "Work", until: x))
    }

    @Test func scheduledToTimedManualIsSilent() {
        let event = SessionEvent(from: .scheduled(name: "Work", until: x), to: .manual(until: y))
        #expect(event == nil)
    }

    @Test func scheduledToIndefiniteManualIsSilent() {
        let event = SessionEvent(from: .scheduled(name: "Work", until: x), to: .manual(until: nil))
        #expect(event == nil)
    }
}
