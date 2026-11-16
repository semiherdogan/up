import Foundation
import Testing
import UpCore

let testCalendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/Istanbul")!
    return calendar
}()

// November 2026: the 16th is a Monday, the 21st a Saturday.
func november(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
    testCalendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
}

func makeSchedule(
    isEnabled: Bool = true,
    weekdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday],
    start: TimeOfDay = TimeOfDay(hour: 8, minute: 30),
    end: TimeOfDay = TimeOfDay(hour: 19, minute: 0)
) -> Schedule {
    Schedule(name: "Work", isEnabled: isEnabled, weekdays: weekdays, start: start, end: end)
}

@Suite struct ScheduleTests {
    @Test func activeInsideWindow() {
        let window = makeSchedule().activeWindow(at: november(16, 12), calendar: testCalendar)
        #expect(window == DateInterval(start: november(16, 8, 30), end: november(16, 19)))
    }

    @Test func startIsInclusiveAndEndIsExclusive() {
        let schedule = makeSchedule()
        #expect(schedule.activeWindow(at: november(16, 8, 29), calendar: testCalendar) == nil)
        #expect(schedule.activeWindow(at: november(16, 8, 30), calendar: testCalendar) != nil)
        #expect(schedule.activeWindow(at: november(16, 19), calendar: testCalendar) == nil)
    }

    @Test func inactiveOnUnselectedWeekday() {
        #expect(makeSchedule().activeWindow(at: november(21, 12), calendar: testCalendar) == nil)
    }

    @Test func overnightWindowBelongsToItsStartDay() {
        let overnight = makeSchedule(
            weekdays: [.friday],
            start: TimeOfDay(hour: 22, minute: 0),
            end: TimeOfDay(hour: 6, minute: 0)
        )
        #expect(
            overnight.activeWindow(at: november(21, 2), calendar: testCalendar)
                == DateInterval(start: november(20, 22), end: november(21, 6))
        )
        #expect(overnight.activeWindow(at: november(20, 2), calendar: testCalendar) == nil)
    }

    @Test func equalStartAndEndCoversFullDay() {
        let midnight = TimeOfDay(hour: 0, minute: 0)
        let allDay = makeSchedule(weekdays: [.monday], start: midnight, end: midnight)
        #expect(
            allDay.activeWindow(at: november(16, 23, 59), calendar: testCalendar)
                == DateInterval(start: november(16, 0), end: november(17, 0))
        )
        #expect(allDay.activeWindow(at: november(17, 0), calendar: testCalendar) == nil)
    }

    @Test func nextStartSkipsToNextSelectedDay() {
        let schedule = makeSchedule()
        #expect(schedule.nextStart(after: november(16, 7), calendar: testCalendar) == november(16, 8, 30))
        #expect(schedule.nextStart(after: november(16, 12), calendar: testCalendar) == november(17, 8, 30))
        #expect(schedule.nextStart(after: november(20, 12), calendar: testCalendar) == november(23, 8, 30))
    }

    @Test func nextStartWrapsToSameWeekdayNextWeek() {
        let mondays = makeSchedule(weekdays: [.monday])
        #expect(mondays.nextStart(after: november(16, 12), calendar: testCalendar) == november(23, 8, 30))
    }

    @Test func noNextStartWithoutWeekdays() {
        #expect(makeSchedule(weekdays: []).nextStart(after: november(16, 12), calendar: testCalendar) == nil)
    }
}
