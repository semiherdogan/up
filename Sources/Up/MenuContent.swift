import ServiceManagement
import SwiftUI
import UpCore

struct MenuContent: View {
    let controller: SessionController

    @Environment(\.openWindow) private var openWindow
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Text(statusText)
        if let errorMessage = controller.errorMessage {
            Text(errorMessage)
        }
        Divider()
        Section("Keep Awake For") {
            ForEach(SessionPreset.allCases) { preset in
                Button(preset.title) { controller.start(duration: preset.duration) }
            }
        }
        Divider()
        Button("End Session") { controller.end() }
            .disabled(!controller.state.isActive)
        Divider()
        Button("Schedules…") {
            // An accessory app is not frontmost, so its window would open behind others.
            NSApp.activate()
            openWindow(id: UpApp.schedulesWindowID)
        }
        Toggle("Launch at Login", isOn: launchAtLoginBinding)
        Divider()
        Button("Quit Up") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }

    private var statusText: String {
        switch controller.state {
        case .idle:
            "Idle"
        case .manual(until: nil):
            "Awake indefinitely"
        case .manual(until: let end?):
            "Awake until \(Self.format(end))"
        case .scheduled(let name, let end):
            "Awake until \(Self.format(end)) (\(name))"
        }
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { launchAtLogin },
            set: { isEnabled in
                do {
                    if isEnabled {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    // Registration fails outside a signed app bundle; the status read below reflects that.
                }
                launchAtLogin = SMAppService.mainApp.status == .enabled
            }
        )
    }

    private static func format(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }
}
