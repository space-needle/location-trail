import SwiftUI
import Firebase

@main
struct LocationTrackerApp: App {
    @StateObject private var dataController = DataController()
    @StateObject private var authManager = AuthManager()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(dataController)
                .environmentObject(authManager)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        if authManager.currentUser != nil {
            ContentView()
        } else {
            LoginView()
        }
    }
}
