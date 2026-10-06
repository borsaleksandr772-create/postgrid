import SwiftUI

struct AccountsView: View {
    @State private var infoPlatform: SocialPlatform?

    var body: some View {
        NavigationStack {
            List {
                Section("Connections") {
                    ForEach(SocialPlatform.all) { platform in
                        HStack {
                            Label(platform.title, systemImage: platform.symbol)
                            Spacer()
                            Text("Not connected")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Button("Connect") { infoPlatform = platform }
                                .buttonStyle(.bordered)
                        }
                    }
                }

                Section("How it will work") {
                    Text("You sign in once with each platform using its official OAuth screen. PostGrid never asks for or stores your social-network password. Real OAuth switches on after developer credentials are added to the backend.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Accounts")
            .alert(item: $infoPlatform) { platform in
                Alert(
                    title: Text("\(platform.title) setup"),
                    message: Text("The UI is ready. Add the platform developer app credentials on the backend to enable the official OAuth login."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}
