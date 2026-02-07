import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var isAuthenticated: Bool

    init() {
        self.isAuthenticated = UserDefaults.standard.string(forKey: "access_token") != nil
    }

    func refreshAuth() {
        isAuthenticated = UserDefaults.standard.string(forKey: "access_token") != nil
    }

    func signOut() {
        UserDefaults.standard.removeObject(forKey: "access_token")
        refreshAuth()
    }
}
