import Foundation

// Raw values match Calendar's `.weekday` component.
public enum Weekday: Int, Codable, CaseIterable, Sendable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
}

public struct TimeOfDay: Codable, Hashable, Comparable, Sendable {
    public var hour: Int
    public var minute: Int

    public init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }

    public init(date: Date, calendar: Calendar) {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        self.init(hour: components.hour ?? 0, minute: components.minute ?? 0)
    }

    public static func < (lhs: TimeOfDay, rhs: TimeOfDay) -> Bool {
        (lhs.hour, lhs.minute) < (rhs.hour, rhs.minute)
    }

    public func date(on day: Date, calendar: Calendar) -> Date? {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: calendar.startOfDay(for: day))
    }
}

public struct Schedule: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var isEnabled: Bool
    public var weekdays: Set<Weekday>
    public var start: TimeOfDay
    // Exclusive. An end at or before `start` means the window runs into the next day.
    public var end: TimeOfDay

    public init(
        id: UUID = UUID(),
        name: String,
        isEnabled: Bool = true,
        weekdays: Set<Weekday>,
        start: TimeOfDay,
        end: TimeOfDay
    ) {
        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.weekdays = weekdays
        self.start = start
        self.end = end
    }

    public func activeWindow(at date: Date, calendar: Calendar) -> DateInterval? {
        // Yesterday's window can still be open when it crosses midnight.
        for dayOffset in [0, -1] {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: date),
                  let window = window(startingOn: day, calendar: calendar) else { continue }
            if window.start <= date && date < window.end { return window }
        }
        return nil
    }

    public func nextStart(after date: Date, calendar: Calendar) -> Date? {
        // One day more than a week, so today's weekday is found again when today's start has passed.
        for dayOffset in 0...Weekday.allCases.count {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: date),
                  let window = window(startingOn: day, calendar: calendar) else { continue }
            if window.start > date { return window.start }
        }
        return nil
    }

    // Windows belong to the day they start on, so only that day's weekday is checked.
    private func window(startingOn day: Date, calendar: Calendar) -> DateInterval? {
        let dayStart = calendar.startOfDay(for: day)
        guard let weekday = Weekday(rawValue: calendar.component(.weekday, from: dayStart)),
              weekdays.contains(weekday),
              let windowStart = start.date(on: dayStart, calendar: calendar) else { return nil }

        var endDay = dayStart
        if end <= start {
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return nil }
            endDay = nextDay
        }
        guard let windowEnd = end.date(on: endDay, calendar: calendar), windowEnd > windowStart else { return nil }
        return DateInterval(start: windowStart, end: windowEnd)
    }
}
