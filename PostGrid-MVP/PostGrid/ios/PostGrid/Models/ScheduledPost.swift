import Foundation

enum PublishStatus: String, Codable, Hashable {
    case draft, scheduled, publishing, published, failed
}

struct PlatformDestination: Codable, Hashable, Identifiable {
    var platform: String
    var enabled: Bool
    var scheduledAt: Date
    var caption: String
    var youtubeTitle: String
    var status: PublishStatus
    var errorMessage: String?

    var id: String { platform }

    static func fresh(platform: String, date: Date, enabled: Bool = false) -> PlatformDestination {
        PlatformDestination(
            platform: platform,
            enabled: enabled,
            scheduledAt: date,
            caption: "",
            youtubeTitle: "",
            status: .scheduled,
            errorMessage: nil
        )
    }
}

struct ScheduledPost: Identifiable, Codable, Hashable {
    var id: Int?
    var title: String
    var mediaPath: String
    var defaultCaption: String
    var destinations: [PlatformDestination]

    var enabledDestinations: [PlatformDestination] {
        destinations.filter(\.enabled).sorted { $0.scheduledAt < $1.scheduledAt }
    }

    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        if !mediaPath.isEmpty { return URL(fileURLWithPath: mediaPath).deletingPathExtension().lastPathComponent }
        return "Untitled post"
    }

    static func fresh(initialDate: Date) -> ScheduledPost {
        let defaultTime = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: initialDate) ?? initialDate
        return ScheduledPost(
            id: nil,
            title: "",
            mediaPath: "",
            defaultCaption: "",
            destinations: SocialPlatform.all.map {
                .fresh(platform: $0.id, date: defaultTime, enabled: $0.id == SocialPlatform.instagram.id)
            }
        )
    }

    static let sample = ScheduledPost(
        id: nil,
        title: "Paris hopak",
        mediaPath: "ivan_paris.mp4",
        defaultCaption: "Dancing hopak in Paris 🇫🇷",
        destinations: [
            PlatformDestination(platform: "instagram", enabled: true, scheduledAt: Date().addingTimeInterval(3600), caption: "", youtubeTitle: "", status: .scheduled, errorMessage: nil),
            PlatformDestination(platform: "tiktok", enabled: true, scheduledAt: Date().addingTimeInterval(7200), caption: "", youtubeTitle: "", status: .scheduled, errorMessage: nil),
            PlatformDestination(platform: "youtube", enabled: true, scheduledAt: Date().addingTimeInterval(10800), caption: "", youtubeTitle: "Hopak in Paris", status: .scheduled, errorMessage: nil),
            PlatformDestination(platform: "x", enabled: false, scheduledAt: Date().addingTimeInterval(14400), caption: "", youtubeTitle: "", status: .scheduled, errorMessage: nil)
        ]
    )
}

struct PublicationOccurrence: Identifiable, Hashable {
    let postID: Int?
    let title: String
    let platform: String
    let scheduledAt: Date
    let status: PublishStatus

    var id: String {
        "\(postID ?? -1)-\(platform)-\(scheduledAt.timeIntervalSince1970)"
    }
}

extension ScheduledPost {
    var occurrences: [PublicationOccurrence] {
        enabledDestinations.map {
            PublicationOccurrence(postID: id, title: displayTitle, platform: $0.platform, scheduledAt: $0.scheduledAt, status: $0.status)
        }
    }
}
