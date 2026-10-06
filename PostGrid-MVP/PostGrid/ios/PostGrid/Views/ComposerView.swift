import PhotosUI
import SwiftUI

struct ComposerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: PostStore

    @State private var post: ScheduledPost
    @State private var selectedVideoItem: PhotosPickerItem?
    @State private var localVideoURL: URL?
    @State private var sharedScheduleAt: Date
    @State private var isSaving = false
    @State private var validationMessage: String?

    init(initialDate: Date) {
        let fresh = ScheduledPost.fresh(initialDate: initialDate)
        _post = State(initialValue: fresh)
        _sharedScheduleAt = State(initialValue: fresh.destinations.first?.scheduledAt ?? initialDate)
    }

    private var selectedCount: Int {
        post.destinations.filter(\.enabled).count
    }

    private var hasVideo: Bool {
        localVideoURL != nil || !post.mediaPath.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Video") {
                    PhotosPicker(selection: $selectedVideoItem, matching: .videos) {
                        Label(localVideoURL == nil ? "Choose video once" : "Change video", systemImage: "video.badge.plus")
                    }

                    if let localVideoURL {
                        Label(localVideoURL.lastPathComponent, systemImage: "checkmark.circle.fill")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else if !post.mediaPath.isEmpty {
                        Label(URL(fileURLWithPath: post.mediaPath).lastPathComponent, systemImage: "checkmark.circle.fill")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Pick one video, then choose every platform, date, time and caption below.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    TextField("Post name (optional)", text: $post.title)
                }

                Section("Default description") {
                    TextField("Used when a platform description is empty", text: $post.defaultCaption, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Quick schedule") {
                    DatePicker("Set selected to", selection: $sharedScheduleAt)
                    Button("Apply date & time to selected platforms") {
                        applySharedTime()
                    }
                    .disabled(selectedCount == 0)
                }

                Section("Platforms — \(selectedCount) selected") {
                    ForEach(SocialPlatform.all) { platform in
                        PlatformScheduleEditor(
                            platform: platform,
                            destination: destinationBinding(for: platform.id)
                        )
                    }
                }

                Section {
                    Text("Each checked platform is an independent scheduled publication. Leave its description blank to use the default description above.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let validationMessage {
                    Section {
                        Text(validationMessage).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Schedule video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Schedule") {
                        Task { await schedule() }
                    }
                    .disabled(isSaving || selectedCount == 0 || !hasVideo)
                }
            }
            .onChange(of: selectedVideoItem) { _, newItem in
                guard let newItem else { return }
                Task { await loadVideo(newItem) }
            }
        }
    }

    private func destinationBinding(for platformID: String) -> Binding<PlatformDestination> {
        Binding(
            get: {
                post.destinations.first(where: { $0.platform == platformID })
                    ?? .fresh(platform: platformID, date: sharedScheduleAt)
            },
            set: { updated in
                if let index = post.destinations.firstIndex(where: { $0.platform == platformID }) {
                    post.destinations[index] = updated
                } else {
                    post.destinations.append(updated)
                }
            }
        )
    }

    private func applySharedTime() {
        for index in post.destinations.indices where post.destinations[index].enabled {
            post.destinations[index].scheduledAt = sharedScheduleAt
        }
    }

    private func loadVideo(_ item: PhotosPickerItem) async {
        do {
            if let picked = try await item.loadTransferable(type: PickedVideo.self) {
                await MainActor.run {
                    localVideoURL = picked.url
                    post.mediaPath = ""
                    if post.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        post.title = picked.url.deletingPathExtension().lastPathComponent
                    }
                    validationMessage = nil
                }
            }
        } catch {
            await MainActor.run { validationMessage = "Could not load video: \(error.localizedDescription)" }
        }
    }

    @MainActor
    private func schedule() async {
        guard selectedCount > 0 else {
            validationMessage = "Select at least one platform."
            return
        }
        guard hasVideo else {
            validationMessage = "Choose a video first."
            return
        }

        isSaving = true
        validationMessage = nil
        defer { isSaving = false }

        do {
            if let localVideoURL {
                let upload = try await APIClient.shared.uploadVideo(localURL: localVideoURL)
                post.mediaPath = upload.path
            }
            if post.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                post.title = URL(fileURLWithPath: post.mediaPath).deletingPathExtension().lastPathComponent
            }
            let success = await store.save(post)
            if success { dismiss() }
        } catch {
            validationMessage = "Could not upload video: \(error.localizedDescription)"
        }
    }
}

private struct PlatformScheduleEditor: View {
    let platform: SocialPlatform
    @Binding var destination: PlatformDestination

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $destination.enabled) {
                Label(platform.title, systemImage: platform.symbol)
                    .font(.headline)
            }

            if destination.enabled {
                DatePicker(
                    "Date & time",
                    selection: $destination.scheduledAt,
                    displayedComponents: [.date, .hourAndMinute]
                )

                TextField("Description — blank = default", text: $destination.caption, axis: .vertical)
                    .lineLimit(2...5)

                if platform.id == SocialPlatform.youtube.id {
                    TextField("YouTube title", text: $destination.youtubeTitle)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
