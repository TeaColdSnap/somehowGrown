import SwiftUI

// MARK: - ContentView

struct ContentView: View {
    @StateObject private var store = FriendStore()
    @State private var showingAddFriend = false
    @State private var searchText = ""
    /// true once the brand header row has scrolled off screen
    @State private var navTitleVisible = false
    /// Friend awaiting delete confirmation
    @State private var friendPendingDelete: Friend?

    private var upcomingEvents: [LifeEvent] {
        EventsEngine.upcomingEvents(friends: store.friends, lookAheadDays: 60)
    }

    private var filteredFriends: [Friend] {
        guard !searchText.isEmpty else { return store.friends }
        return store.friends.filter { friend in
            friend.name.localizedStandardContains(searchText) ||
            friend.kids.contains { $0.name.localizedStandardContains(searchText) }
        }
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

    private var groupedUpcomingEvents: [(friendID: String, friendName: String, events: [LifeEvent])] {
        var indexMap: [String: Int] = [:]
        var groups: [(friendID: String, friendName: String, events: [LifeEvent])] = []
        for event in upcomingEvents {
            if let idx = indexMap[event.friendID] {
                groups[idx].events.append(event)
            } else {
                indexMap[event.friendID] = groups.count
                groups.append((friendID: event.friendID, friendName: event.friendName, events: [event]))
            }
        }
        return groups
    }

    private var sectionKeys: [String] { groupedFriends.map(\.key) }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ZStack(alignment: .trailing) {
                    List {

                        // MARK: Brand header row
                        // Logo (71pt) overlaps the title by 10pt to prevent line wrap.
                        // onDisappear → navTitleVisible = true  (compact nav title fades in)
                        // onAppear    → navTitleVisible = false (compact nav title fades out)
                        Section {
                            HStack(alignment: .center, spacing: -10) {
                                Image("SomehowGrownSmallIcon")
                                    .resizable()
                                    .interpolation(.high)
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 71, height: 71)
                                    .clipShape(Circle())
                                Text("SomehowGrown")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundStyle(Color(hex: "a38153"))
                                    .lineLimit(1)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.2)) { navTitleVisible = false }
                            }
                            .onDisappear {
                                withAnimation(.easeInOut(duration: 0.2)) { navTitleVisible = true }
                            }
                        }

                        // MARK: Upcoming events
                        if !groupedUpcomingEvents.isEmpty && searchText.isEmpty {
                            Section {
                                ForEach(groupedUpcomingEvents.prefix(5), id: \.friendID) { group in
                                    NavigationLink(value: group.friendID) {
                                        UpcomingEventRow(friendName: group.friendName, events: group.events)
                                    }
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
                                    description: Text(verbatim: String(format: NSLocalizedString("no_result_format", comment: ""), searchText))
                                )
                            }
                        } else {
                            ForEach(groupedFriends, id: \.key) { group in
                                Section {
                                    ForEach(group.friends) { friend in
                                        NavigationLink(value: friend.id) {
                                            FriendRowView(
                                                friend: friend,
                                                accentColor: store.resolvedColor(for: friend).color
                                            )
                                        }
                                    }
                                    .onDelete { offsets in
                                        if let first = offsets.first {
                                            friendPendingDelete = group.friends[first]
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
                    .searchable(text: $searchText, prompt: "友人・お子さんを検索")
                    .navigationDestination(for: String.self) { friendID in
                        FriendDetailView(friendID: friendID, store: store)
                    }

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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("SomehowGrown")
                        .foregroundStyle(Color(hex: "a38153"))
                        .font(.headline)
                        .opacity(navTitleVisible ? 1 : 0)
                }
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
            .alert(
                Text(verbatim: String(
                    format: NSLocalizedString("friend_delete_alert_title", comment: ""),
                    friendPendingDelete?.name ?? ""
                )),
                isPresented: Binding(
                    get: { friendPendingDelete != nil },
                    set: { if !$0 { friendPendingDelete = nil } }
                ),
                presenting: friendPendingDelete
            ) { friend in
                Button(NSLocalizedString("friend_delete_confirm", comment: ""), role: .destructive) {
                    store.deleteFriend(id: friend.id)
                    friendPendingDelete = nil
                }
                Button("キャンセル", role: .cancel) {
                    friendPendingDelete = nil
                }
            } message: { _ in
                Text(NSLocalizedString("friend_delete_alert_message", comment: ""))
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
    let friendName: String
    let events: [LifeEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(friendName)
                .font(.subheadline.weight(.semibold))
            ForEach(events) { event in
                HStack {
                    Text(verbatim: "\(event.kidName.isEmpty ? NSLocalizedString("child_name_fallback", comment: "") : event.kidName) · \(event.eventLabel)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(verbatim: event.daysUntil == 0
                        ? NSLocalizedString("今日!", comment: "")
                        : String(format: NSLocalizedString("days_until_format", comment: ""), event.daysUntil))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
