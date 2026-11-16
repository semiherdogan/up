import Foundation

@MainActor
final class Caffeinate {
    private static let executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
    // d: display, i: idle system, m: disk, s: system sleep on AC power.
    private static let sleepFlags = "-dims"

    // Receives how long the process lived when it exits without stop() being called.
    var onUnexpectedExit: (@MainActor (TimeInterval) -> Void)?

    private var process: Process?
    private var runID: UUID?

    func setRunning(_ shouldRun: Bool) throws {
        if shouldRun {
            try start()
        } else {
            stop()
        }
    }

    private func start() throws {
        guard process?.isRunning != true else { return }
        let process = Process()
        process.executableURL = Self.executableURL
        // -w ties caffeinate to this app, so it exits even if the app crashes.
        process.arguments = [Self.sleepFlags, "-w", String(ProcessInfo.processInfo.processIdentifier)]
        let runID = UUID()
        let startedAt = Date()
        process.terminationHandler = { [weak self] _ in
            Task { @MainActor in self?.handleExit(of: runID, startedAt: startedAt) }
        }
        try process.run()
        self.process = process
        self.runID = runID
    }

    private func stop() {
        runID = nil
        process?.terminate()
        process = nil
    }

    private func handleExit(of exitedRunID: UUID, startedAt: Date) {
        // stop() clears runID first, so a match means nobody asked for this exit.
        guard exitedRunID == runID else { return }
        runID = nil
        process = nil
        onUnexpectedExit?(Date().timeIntervalSince(startedAt))
    }
}
