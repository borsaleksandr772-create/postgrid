import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            MonthCalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
            QueueView()
                .tabItem { Label("Queue", systemImage: "clock") }
            AccountsView()
                .tabItem { Label("Accounts", systemImage: "person.crop.circle.badge.checkmark") }
        }
    }
}
