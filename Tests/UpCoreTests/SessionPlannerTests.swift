import Foundation
import Testing
import UpCore

@Suite struct SessionPlannerTests {
    private let noon = november(16, 12)
    private let windowEnd = november(16, 19)

    private func plan(
        at now: Date,
        manual: ManualSession? = nil,
        schedules: [Schedule] = [],
        suppressedUntil: [Schedule.ID: Date] = [:]
    ) -> SessionPlan {
        SessionPlanner.plan(
            at: now,
            manual: manual,
            schedules: schedules,
            suppressedUntil: suppressedUntil,
            calendar: testCalendar
        )
    }

    @Test func idleWithoutSessions() {
        let result = plan(at: noon)
        #expect(result.state == .idle)
        #expect(result.nextEvaluation == nil)
    }

    @Test func scheduleKeepsAwakeUntilWindowEnd() {
        let result = plan(at: noon, schedules: [makeSchedule()])
        #expect(result.state == .scheduled(name: "Work", until: windowEnd))
        #expect(result.nextEvaluation == windowEnd)
    }

    @Test func idleBeforeWindowReevaluatesAtStart() {
        let result = plan(at: november(16, 7), schedules: [makeSchedule()])
        #expect(result.state == .idle)
        #expect(result.nextEvaluation == november(16, 8, 30))
    }

    @Test func disabledScheduleIsIgnored() {
        let result = plan(at: noon, schedules: [makeSchedule(isEnabled: false)])
        #expect(result.state == .idle)
        #expect(result.nextEvaluation == nil)
    }

    @Test func suppressedScheduleStaysIdleUntilWindowEnds() {
        let schedule = makeSchedule()
        let result = plan(at: noon, schedules: [schedule], suppressedUntil: [schedule.id: windowEnd])
        #expect(result.state == .idle)
        #expect(result.nextEvaluation == windowEnd)
    }

    @Test func suppressionDoesNotOutliveItsWindow() {
        let schedule = makeSchedule()
        let result = plan(at: november(17, 12), schedules: [schedule], suppressedUntil: [schedule.id: windowEnd])
        #expect(result.state == .scheduled(name: "Work", until: november(17, 19)))
    }

    @Test func manualSessionOutlastingScheduleIsReported() {
        let manualEnd = november(16, 20)
        let result = plan(at: noon, manual: .until(manualEnd), schedules: [makeSchedule()])
        #expect(result.state == .manual(until: manualEnd))
        #expect(result.nextEvaluation == windowEnd)
    }

    @Test func scheduleOutlastingManualSessionIsReported() {
        let manualEnd = november(16, 13)
        let result = plan(at: noon, manual: .until(manualEnd), schedules: [makeSchedule()])
        #expect(result.state == .scheduled(name: "Work", until: windowEnd))
        #expect(result.nextEvaluation == manualEnd)
    }

    @Test func indefiniteManualSessionWins() {
        let result = plan(at: noon, manual: .indefinite, schedules: [makeSchedule()])
        #expect(result.state == .manual(until: nil))
    }

    @Test func expiredManualSessionIsIgnored() {
        let result = plan(at: noon, manual: .until(november(16, 11)))
        #expect(result.state == .idle)
        #expect(result.nextEvaluation == nil)
    }

    @Test func activeWindowEndsCoverOnlyEnabledActiveSchedules() {
        let active = makeSchedule()
        let disabled = makeSchedule(isEnabled: false)
        let weekend = makeSchedule(weekdays: [.saturday])
        let ends = SessionPlanner.activeWindowEnds(
            at: noon, schedules: [active, disabled, weekend], calendar: testCalendar
        )
        #expect(ends == [active.id: windowEnd])
    }
}
