import SwiftUI

struct DayCell: View {
    let date: Date
    let occurrences: [PublicationOccurrence]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(date.formatted(.dateTime.day())).font(.caption.bold())
            ForEach(occurrences.prefix(3)) { item in
                HStack(spacing: 3) {
                    Image(systemName: symbol(for: item.platform))
                        .font(.system(size: 8))
                    Text(item.scheduledAt.formatted(.dateTime.hour().minute()))
                    Text(item.title).lineLimit(1)
                }
                .font(.system(size: 9))
            }
            if occurrences.count > 3 {
                Text("+\(occurrences.count - 3) more")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(6)
        .frame(maxWidth: .infinity, minHeight: 86, alignment: .topLeading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }

    private func symbol(for platformID: String) -> String {
        SocialPlatform.all.first(where: { $0.id == platformID })?.symbol ?? "circle"
    }
}
