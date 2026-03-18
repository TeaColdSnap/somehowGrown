import SwiftUI

struct FriendDetailView: View {
    let friendID: String
    @ObservedObject var store: FriendStore
    @State private var isEditing = false

    private var friend: Friend? {
        store.friends.first { $0.id == friendID }
    }

    private var friendEvents: [LifeEvent] {
        guard let f = friend else { return [] }
        return EventsEngine.upcomingEvents(friends: [f], lookAheadDays: 365)
    }

    var body: some View {
        Group {
            if let friend {
                List {
                    // MARK: Kids
                    if !friend.kids.isEmpty {
                        Section("お子さん") {
                            ForEach(friend.kids) { kid in
                                KidDetailRow(kid: kid)
                            }
                        }
                    }

                    // MARK: Upcoming events
                    if !friendEvents.isEmpty {
                        Section("今後のイベント（1年以内）") {
                            ForEach(friendEvents) { event in
                                EventDetailRow(event: event)
                            }
                        }
                    }

                    // MARK: Empty state
                    if friend.kids.isEmpty {
                        Section {
                            Text("お子さんの情報を追加すると、イベントが表示されます")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .navigationTitle(friend.name)
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("編集") { isEditing = true }
                    }
                }
                .sheet(isPresented: $isEditing) {
                    AddFriendSheet(store: store, editingFriend: friend)
                }
            }
        }
    }
}

// MARK: - Kid detail row

private struct KidDetailRow: View {
    let kid: Kid

    private var currentGrade: Int {
        GradeSystem.currentGrade(
            gradeWhenAdded: kid.gradeWhenAdded,
            dateRecorded:   kid.dateRecorded,
            cutoff:         kid.cutoff
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(kid.gender.emoji)
                Text(kid.name.isEmpty ? "（名前未設定）" : kid.name)
                    .font(.headline)
                Spacer()
                Text(GradeSystem.label(grade: currentGrade, cutoff: kid.cutoff))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let month = kid.birthdayMonth {
                let day = kid.birthdayDay ?? 1
                Text("誕生日：\(month)月\(day)日")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Event detail row

private struct EventDetailRow: View {
    let event: LifeEvent

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(event.eventLabel)
                    .font(.subheadline.weight(.semibold))
                if !event.kidName.isEmpty {
                    Text(event.kidName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(event.daysUntil == 0 ? "今日!" : "あと\(event.daysUntil)日")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.blue)
                Text(event.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
