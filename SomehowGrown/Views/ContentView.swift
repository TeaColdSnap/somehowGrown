import SwiftUI

struct ContentView: View {
    @StateObject private var store = FriendStore()
    @State private var showingAddFriend = false
    @State private var editingFriend: Friend?

    private var upcomingEvents: [LifeEvent] {
        EventsEngine.upcomingEvents(friends: store.friends, lookAheadDays: 60)
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: Upcoming events
                if !upcomingEvents.isEmpty {
                    Section {
                        ForEach(upcomingEvents.prefix(5)) { event in
                            UpcomingEventRow(event: event)
                        }
                    } header: {
                        Label("近日のイベント", systemImage: "calendar")
                    }
                }

                // MARK: Friends list
                Section {
                    if store.friends.isEmpty {
                        ContentUnavailableView(
                            "友人を追加しましょう",
                            systemImage: "person.2",
                            description: Text("右上の + から友人と子供の情報を登録できます")
                        )
                    } else {
                        ForEach(store.friends) { friend in
                            FriendRowView(friend: friend)
                                .contentShape(Rectangle())
                                .onTapGesture { editingFriend = friend }
                        }
                        .onDelete { store.delete(offsets: $0) }
                    }
                } header: {
                    Label("友人リスト", systemImage: "person.2.fill")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("SomehowGrown")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddFriend = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddFriend) {
                AddFriendSheet(store: store)
            }
            .sheet(item: $editingFriend) { friend in
                AddFriendSheet(store: store, editingFriend: friend)
            }
            .task {
                await NotificationManager.shared.requestPermission()
                NotificationManager.shared.scheduleAll(friends: store.friends)
            }
        }
    }
}

// MARK: - Upcoming event row

private struct UpcomingEventRow: View {
    let event: LifeEvent

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(event.friendName)
                    .font(.subheadline.weight(.semibold))
                Text("\(event.kidName.isEmpty ? "お子さん" : event.kidName) · \(event.eventLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(event.daysUntil == 0 ? "今日!" : "あと\(event.daysUntil)日")
                .font(.caption.weight(.bold))
                .foregroundStyle(.blue)
        }
    }
}
