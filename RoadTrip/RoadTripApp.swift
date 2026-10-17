import SwiftUI
import FirebaseCore

@main
struct RoadTripApp: App {

    init() {
        FirebaseApp.configure()
        testFirebaseConnection()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
