import SwiftUI

@main
struct SpottedApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            FeedView()
                .environmentObject(appState)
        }
    }
}
