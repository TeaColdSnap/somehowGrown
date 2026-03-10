import Foundation
import Combine

@MainActor
final class FriendStore: ObservableObject {
    @Published var friends: [Friend] = []

    // Stored in Documents — local only, no cloud sync in v1
    private let saveURL: URL = {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("friends_v1.json")
    }()

    init() {
        load()
    }

    func addOrUpdate(_ friend: Friend) {
        if let i = friends.firstIndex(where: { $0.id == friend.id }) {
            friends[i] = friend
        } else {
            friends.append(friend)
        }
        persist()
    }

    func delete(offsets: IndexSet) {
        friends.remove(atOffsets: offsets)
        persist()
    }

    // MARK: - Private

    private func persist() {
        do {
            let data = try JSONEncoder().encode(friends)
            try data.write(to: saveURL, options: .atomic)
            NotificationManager.shared.scheduleAll(friends: friends)
        } catch {
            print("[FriendStore] Save error:", error)
        }
    }

    private func load() {
        guard
            let data = try? Data(contentsOf: saveURL),
            let decoded = try? JSONDecoder().decode([Friend].self, from: data)
        else { return }
        friends = decoded
    }
}
