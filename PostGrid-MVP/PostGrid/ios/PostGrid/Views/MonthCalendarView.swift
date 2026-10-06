import SwiftUI

struct MonthCalendarView: View {
    @EnvironmentObject var store: PostStore
    @State private var month = Date()
    @State private var composerDate: Date?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let calendar = Calendar.current

    private var days: [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: month),
              let firstWeekday = calendar.dateComponents([.weekday], from: interval.start).weekday,
              let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        let leading = (firstWeekday + 5) % 7
        var result: [Date?] = Array(repeating: nil, count: leading)
        for day in range {
            var c = calendar.dateComponents([.year, .month], from: month)
            c.day = day
            result.append(calendar.date(from: c))
        }
        return result
    }

    private var title: String {
        month.formatted(.dateTime.month(.wide).year())
    }

    private var occurrences: [PublicationOccurrence] {
        store.posts.flatMap(\.occurrences)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                HStack {
                    Button { changeMonth(-1) } label: { Image(systemName: "chevron.left") }
                    Spacer()
                    Text(title).font(.title2.bold())
                    Spacer()
                    Button { changeMonth(1) } label: { Image(systemName: "chevron.right") }
                }
                .padding(.horizontal)

                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(["Mon","Tue","Wed","Thu","Fri","Sat","Sun"], id: \.self) {
                        Text($0).font(.caption2).foregroundStyle(.secondary)
                    }
                    ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                        if let date {
                            DayCell(date: date, occurrences: occurrences(on: date))
                                .onTapGesture { composerDate = date }
                        } else {
                            Color.clear.frame(height: 86)
                        }
                    }
                }
                .padding(.horizontal, 6)
                Spacer()
            }
            .navigationTitle("PostGrid")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { composerDate = Date() } label: { Image(systemName: "plus.circle.fill") }
                }
            }
            .sheet(isPresented: Binding(
                get: { composerDate != nil },
                set: { if !$0 { composerDate = nil } }
            )) {
                if let date = composerDate { ComposerView(initialDate: date) }
            }
            .overlay(alignment: .bottom) {
                if let error = store.errorText {
                    Text(error).font(.caption).padding(8).background(.thinMaterial).clipShape(Capsule()).padding()
                }
            }
        }
    }

    private func occurrences(on date: Date) -> [PublicationOccurrence] {
        occurrences
            .filter { calendar.isDate($0.scheduledAt, inSameDayAs: date) }
            .sorted { $0.scheduledAt < $1.scheduledAt }
    }

    private func changeMonth(_ delta: Int) {
        month = calendar.date(byAdding: .month, value: delta, to: month) ?? month
    }
}
