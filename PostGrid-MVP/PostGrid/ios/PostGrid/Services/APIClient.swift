import Foundation

struct MediaUploadResponse: Codable {
    let path: String
    let filename: String
}

final class APIClient {
    static let shared = APIClient()
    let baseURL = URL(string: "http://127.0.0.1:8000")!

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    func fetchPosts() async throws -> [ScheduledPost] {
        let url = baseURL.appending(path: "posts")
        let (data, response) = try await URLSession.shared.data(from: url)
        try validate(response)
        return try decoder.decode([ScheduledPost].self, from: data)
    }

    func createPost(_ post: ScheduledPost) async throws -> ScheduledPost {
        var request = URLRequest(url: baseURL.appending(path: "posts"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(post)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)
        return try decoder.decode(ScheduledPost.self, from: data)
    }

    func updatePost(_ post: ScheduledPost) async throws -> ScheduledPost {
        guard let id = post.id else { throw URLError(.badURL) }
        var request = URLRequest(url: baseURL.appending(path: "posts/\(id)"))
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(post)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)
        return try decoder.decode(ScheduledPost.self, from: data)
    }

    func deletePost(id: Int) async throws {
        var request = URLRequest(url: baseURL.appending(path: "posts/\(id)"))
        request.httpMethod = "DELETE"
        let (_, response) = try await URLSession.shared.data(for: request)
        try validate(response)
    }

    func uploadVideo(localURL: URL) async throws -> MediaUploadResponse {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: baseURL.appending(path: "media"))
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let filename = localURL.lastPathComponent
        let fileData = try Data(contentsOf: localURL)
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: video/mp4\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)
        return try decoder.decode(MediaUploadResponse.self, from: data)
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
