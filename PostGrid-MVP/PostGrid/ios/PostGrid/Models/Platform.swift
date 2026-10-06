import Foundation

struct SocialPlatform: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let symbol: String

    static let instagram = SocialPlatform(id: "instagram", title: "Instagram", symbol: "camera")
    static let tiktok = SocialPlatform(id: "tiktok", title: "TikTok", symbol: "music.note")
    static let youtube = SocialPlatform(id: "youtube", title: "YouTube", symbol: "play.rectangle")
    static let x = SocialPlatform(id: "x", title: "X", symbol: "text.bubble")

    static let all: [SocialPlatform] = [.instagram, .tiktok, .youtube, .x]
}
