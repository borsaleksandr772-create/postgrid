import Foundation

@MainActor
final class PostStore: ObservableObject {
    @Published var posts: [ScheduledPost] = []
    @Published var isLoading = false
    @Published var errorText: String?

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            posts = try await APIClient.shared.fetchPosts().sorted { earliest($0) < earliest($1) }
            errorText = nil
        } catch {
            errorText = "Backend unavailable — showing local demo."
            if posts.isEmpty { posts = [.sample] }
        }
    }

    @discardableResult
    func save(_ post: ScheduledPost) async -> Bool {
        do {
            if post.id == nil {
                let created = try await APIClient.shared.createPost(post)
                posts.append(created)
            } else {
                let updated = try await APIClient.shared.updatePost(post)
                if let index = posts.firstIndex(where: { $0.id == updated.id }) { posts[index] = updated }
            }
            posts.sort { earliest($0) < earliest($1) }
            errorText = nil
            return true
        } catch {
            errorText = "Could not save: \(error.localizedDescription)"
            return false
        }
    }

    func delete(_ post: ScheduledPost) async {
        guard let id = post.id else { return }
        do {
            try await APIClient.shared.deletePost(id: id)
            posts.removeAll { $0.id == id }
        } catch {
            errorText = "Could not delete: \(error.localizedDescription)"
        }
    }

    private func earliest(_ post: ScheduledPost) -> Date {
        post.enabledDestinations.map(\.scheduledAt).min() ?? .distantFuture
    }
}
