import SwiftUI

struct ContentView: View {
    @StateObject private var store = FriendStore()
    @State private var showingAddFriend = false
    @State private var editingFriend: Friend?
    @State private var searchText = ""

    private var upcomingEvents: [LifeEvent] {
        EventsEngine.upcomingEvents(friends: store.friends, lookAheadDays: 60)
    }

    private var filteredFriends: [Friend] {
        guard !searchText.isEmpty else { return store.friends }
        return store.friends.filter { $0.name.localizedStandardContains(searchText) }
    }

    private var groupedFriends: [(key: String, friends: [Friend])] {
        let sorted = filteredFriends.sorted {
            $0.name.compare($1.name, locale: Locale(identifier: "ja")) == .orderedAscending
        }
        let grouped = Dictionary(grouping: sorted) { friend -> String in
            let first = String(friend.name.prefix(1)).uppercased()
            let isASCIILetter = first.unicodeScalars.first.map { $0.value >= 65 && $0.value <= 90 } ?? false
            return isASCIILetter ? first : "#"
        }
        return grouped
            .sorted { a, b in
                if a.key == "#" { return false }
                if b.key == "#" { return true }
                return a.key < b.key
            }
            .map { (key: $0.key, friends: $0.value) }
    }

    private var sectionKeys: [String] { groupedFriends.map(\.key) }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ZStack(alignment: .trailing) {
                    List {
                        // MARK: Upcoming events
                        if !upcomingEvents.isEmpty && searchText.isEmpty {
                            Section {
                                ForEach(upcomingEvents.prefix(5)) { event in
                                    UpcomingEventRow(event: event)
                                }
                            } header: {
                                Label("近日のイベント", systemImage: "calendar")
                            }
                        }

                        // MARK: Friends list
                        if store.friends.isEmpty {
                            Section {
                                ContentUnavailableView(
                                    "友人を追加しましょう",
                                    systemImage: "person.2",
                                    description: Text("右上の + から友人と子供の情報を登録できます")
                                )
                            } header: {
                                Label("友人リスト", systemImage: "person.2.fill")
                            }
                        } else if filteredFriends.isEmpty {
                            Section {
                                ContentUnavailableView(
                                    "該当なし",
                                    systemImage: "magnifyingglass",
                                    description: Text("「\(searchText)」に一致する友人が見つかりません")
                                )
                            }
                        } else {
                            ForEach(groupedFriends, id: \.key) { group in
                                Section {
                                    ForEach(group.friends) { friend in
                                        FriendRowView(
                                            friend: friend,
                                            accentColor: store.resolvedColor(for: friend).color
                                        )
                                        .contentShape(Rectangle())
                                        .onTapGesture { editingFriend = friend }
                                    }
                                    .onDelete { offsets in
                                        let toDelete = offsets.map { group.friends[$0] }
                                        toDelete.forEach { friend in
                                            if let idx = store.friends.firstIndex(where: { $0.id == friend.id }) {
                                                store.delete(offsets: IndexSet([idx]))
                                            }
                                        }
                                    }
                                } header: {
                                    Text(group.key)
                                }
                                .id(group.key)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(Color.appTheme.ignoresSafeArea())
                    .searchable(text: $searchText, prompt: "友人を検索")

                    // Section index scrubber (hidden during search)
                    if searchText.isEmpty && sectionKeys.count > 1 {
                        SectionIndexView(keys: sectionKeys) { key in
                            withAnimation(.none) {
                                proxy.scrollTo(key, anchor: .top)
                            }
                        }
                    }
                }
            }
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

// MARK: - Section index scrubber

private struct SectionIndexView: View {
    let keys: [String]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(spacing: 2) {
            ForEach(keys, id: \.self) { key in
                Button {
                    onSelect(key)
                } label: {
                    Text(key)
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 18)
                }
                .foregroundStyle(.blue)
            }
        }
        .padding(.trailing, 6)
        .padding(.vertical, 8)
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
