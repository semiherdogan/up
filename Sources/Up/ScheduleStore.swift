import Foundation
import UpCore

struct ScheduleStore {
    private static let key = "schedules"

    func load() -> [Schedule] {
        guard let data = UserDefaults.standard.data(forKey: Self.key) else { return [] }
        return (try? JSONDecoder().decode([Schedule].self, from: data)) ?? []
    }

    func save(_ schedules: [Schedule]) {
        guard let data = try? JSONEncoder().encode(schedules) else { return }
        UserDefaults.standard.set(data, forKey: Self.key)
    }
}
