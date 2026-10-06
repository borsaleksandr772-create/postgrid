import SwiftUI

struct QueueView: View {
    @EnvironmentObject var store: PostStore

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.posts) { post in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(post.displayTitle).font(.headline)
                                if !post.mediaPath.isEmpty {
                                    Text(URL(fileURLWithPath: post.mediaPath).lastPathComponent)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            Spacer()
                            Text("\(post.enabledDestinations.count) destinations")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        ForEach(post.enabledDestinations) { destination in
                            HStack(spacing: 8) {
                                Image(systemName: symbol(for: destination.platform))
                                    .frame(width: 18)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(title(for: destination.platform)).font(.subheadline.weight(.medium))
                                    Text(destination.scheduledAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(destination.status.rawValue.capitalized)
                                    .font(.caption2)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(.quaternary, in: Capsule())
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let post = store.posts[index]
                        Task { await store.delete(post) }
                    }
                }
            }
            .navigationTitle("Queue")
            .refreshable { await store.refresh() }
        }
    }

    private func symbol(for id: String) -> String {
        SocialPlatform.all.first(where: { $0.id == id })?.symbol ?? "circle"
    }

    private func title(for id: String) -> String {
        SocialPlatform.all.first(where: { $0.id == id })?.title ?? id.capitalized
    }
}
