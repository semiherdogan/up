import Foundation

enum SessionPreset: CaseIterable, Identifiable {
    case fifteenMinutes, thirtyMinutes, oneHour, twoHours, fourHours, indefinite

    private static let minute: TimeInterval = 60
    private static let hour: TimeInterval = 60 * minute

    var id: Self { self }

    // nil means no end time.
    var duration: TimeInterval? {
        switch self {
        case .fifteenMinutes: 15 * Self.minute
        case .thirtyMinutes: 30 * Self.minute
        case .oneHour: Self.hour
        case .twoHours: 2 * Self.hour
        case .fourHours: 4 * Self.hour
        case .indefinite: nil
        }
    }

    var title: String {
        switch self {
        case .fifteenMinutes: "15 Minutes"
        case .thirtyMinutes: "30 Minutes"
        case .oneHour: "1 Hour"
        case .twoHours: "2 Hours"
        case .fourHours: "4 Hours"
        case .indefinite: "Indefinitely"
        }
    }
}
