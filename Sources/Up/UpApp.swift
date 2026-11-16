import SwiftUI
import UpCore

@main
struct UpApp: App {
    static let schedulesWindowID = "schedules"

    @State private var controller = SessionController()

    var body: some Scene {
        MenuBarExtra {
            MenuContent(controller: controller)
        } label: {
            Image(systemName: controller.state.isActive ? "arrowshape.up.fill" : "arrowshape.up")
        }

        Window("Schedules", id: Self.schedulesWindowID) {
            SchedulesView(controller: controller)
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)
    }
}
