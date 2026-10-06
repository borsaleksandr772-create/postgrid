import SwiftUI

@main
struct PostGridApp: App {
    @StateObject private var store = PostStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .task { await store.refresh() }
        }
    }
}
