import SwiftUI

@main
struct SituationRoomApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView()
                .preferredColorScheme(.dark)
        }
    }
}
