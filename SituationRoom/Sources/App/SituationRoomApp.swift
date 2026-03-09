import SwiftUI
import UIKit

@main
struct SituationRoomApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var sleepTimer: Timer?

    private let stayAwakeSeconds: TimeInterval = 4 * 60 * 60 // 4 hours

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .preferredColorScheme(.dark)
                .onAppear { startStayAwake() }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                startStayAwake()
            } else {
                cancelStayAwake()
            }
        }
    }

    private func startStayAwake() {
        UIApplication.shared.isIdleTimerDisabled = true
        sleepTimer?.invalidate()
        sleepTimer = Timer.scheduledTimer(withTimeInterval: stayAwakeSeconds, repeats: false) { _ in
            Task { @MainActor in
                UIApplication.shared.isIdleTimerDisabled = false
            }
        }
    }

    private func cancelStayAwake() {
        sleepTimer?.invalidate()
        sleepTimer = nil
        UIApplication.shared.isIdleTimerDisabled = false
    }
}
