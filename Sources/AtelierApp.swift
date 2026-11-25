import SwiftUI

@main
struct AtelierApp: App {
    @StateObject private var store = WardrobeStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.light)
        }
    }
}
