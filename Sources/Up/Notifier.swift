import Foundation
import UpCore
import UserNotifications

@MainActor
final class Notifier: NSObject, UNUserNotificationCenterDelegate {
    private static let fallbackScheduleName = "Schedule"

    // UNUserNotificationCenter raises without an app bundle, which is the case under `swift run`.
    private let center: UNUserNotificationCenter? = Bundle.main.bundleIdentifier == nil ? nil : .current()

    override init() {
        super.init()
        center?.delegate = self
        // Explicitly @Sendable: the system calls back off the main thread.
        center?.requestAuthorization(options: [.alert, .sound]) { @Sendable _, _ in }
    }

    func post(_ event: SessionEvent) {
        switch event {
        case .scheduleStarted(let name, let until):
            let time = until.formatted(date: .omitted, time: .shortened)
            post(title: "\(displayName(name)) started", body: "Keeping your Mac awake until \(time).")
        case .sessionEnded(let scheduleName):
            let subject = scheduleName.map(displayName) ?? "Session"
            post(title: "\(subject) ended", body: "Your Mac can sleep again.")
        }
    }

    func postFailure(_ message: String) {
        post(title: "Up stopped keeping your Mac awake", body: message)
    }

    private func displayName(_ scheduleName: String) -> String {
        scheduleName.isEmpty ? Self.fallbackScheduleName : scheduleName
    }

    private func post(title: String, body: String) {
        guard let center else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }

    // Without this the banner is dropped while the Schedules window is frontmost.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
