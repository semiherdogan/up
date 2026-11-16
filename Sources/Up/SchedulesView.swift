import SwiftUI
import UpCore

struct SchedulesView: View {
    let controller: SessionController

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if controller.schedules.isEmpty {
                ContentUnavailableView(
                    "No Schedules",
                    systemImage: "calendar.badge.clock",
                    description: Text("Add a schedule to keep your Mac awake automatically.")
                )
            } else {
                List {
                    ForEach(controller.schedules) { schedule in
                        ScheduleRow(schedule: binding(for: schedule)) {
                            controller.setSchedules(controller.schedules.filter { $0.id != schedule.id })
                        }
                    }
                }
            }
            Button("Add Schedule") {
                controller.setSchedules(controller.schedules + [.template])
            }
        }
        .padding()
        .frame(width: 600, height: 320)
    }

    // Looked up by id so a late write from a deleted row is a no-op instead of an out-of-range index.
    private func binding(for schedule: Schedule) -> Binding<Schedule> {
        Binding(
            get: { controller.schedules.first { $0.id == schedule.id } ?? schedule },
            set: { updated in
                controller.setSchedules(controller.schedules.map { $0.id == updated.id ? updated : $0 })
            }
        )
    }
}

private struct ScheduleRow: View {
    @Binding var schedule: Schedule
    let onDelete: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        HStack(spacing: 10) {
            Toggle("Enabled", isOn: $schedule.isEnabled)
                .labelsHidden()
            TextField("Name", text: $schedule.name)
                .frame(width: 110)
            HStack(spacing: 2) {
                ForEach(orderedWeekdays, id: \.self) { weekday in
                    Toggle(calendar.veryShortWeekdaySymbols[weekday.symbolIndex], isOn: weekdayBinding(weekday))
                        .toggleStyle(.button)
                }
            }
            TimeOfDayPicker(title: "Start", time: $schedule.start)
            Text("to")
            TimeOfDayPicker(title: "End", time: $schedule.end)
            Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
                .labelStyle(.iconOnly)
        }
    }

    private var orderedWeekdays: [Weekday] {
        let all = Weekday.allCases
        let firstIndex = all.firstIndex { $0.rawValue == calendar.firstWeekday } ?? all.startIndex
        return Array(all[firstIndex...] + all[..<firstIndex])
    }

    private func weekdayBinding(_ weekday: Weekday) -> Binding<Bool> {
        Binding(
            get: { schedule.weekdays.contains(weekday) },
            set: { isSelected in
                if isSelected {
                    schedule.weekdays.insert(weekday)
                } else {
                    schedule.weekdays.remove(weekday)
                }
            }
        )
    }
}

private struct TimeOfDayPicker: View {
    let title: String
    @Binding var time: TimeOfDay

    var body: some View {
        DatePicker(title, selection: date, displayedComponents: .hourAndMinute)
            .labelsHidden()
    }

    private var date: Binding<Date> {
        Binding(
            get: { time.date(on: .now, calendar: .current) ?? .now },
            set: { time = TimeOfDay(date: $0, calendar: .current) }
        )
    }
}

private extension Weekday {
    // Calendar symbol arrays are zero-based and start at Sunday.
    var symbolIndex: Int { rawValue - Weekday.sunday.rawValue }
}

private extension Schedule {
    static var template: Schedule {
        Schedule(
            name: "New Schedule",
            weekdays: [.monday, .tuesday, .wednesday, .thursday, .friday],
            start: TimeOfDay(hour: 9, minute: 0),
            end: TimeOfDay(hour: 18, minute: 0)
        )
    }
}
