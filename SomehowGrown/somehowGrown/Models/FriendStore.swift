import Foundation
import SwiftUI
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
        var f = friend
        if let i = friends.firstIndex(where: { $0.id == friend.id }) {
            friends[i] = f
        } else {
            if f.colorTag == nil {
                f.colorTag = nextAutoColor()
            }
            friends.append(f)
        }
        persist()
    }

    /// Returns the resolved color for a friend (stored or index-based fallback).
    func resolvedColor(for friend: Friend) -> FriendColor {
        if let tag = friend.colorTag { return tag }
        let index = friends.firstIndex(where: { $0.id == friend.id }) ?? 0
        return FriendColor.allCases[index % FriendColor.allCases.count]
    }

    // MARK: - Auto-color

    private func nextAutoColor() -> FriendColor {
        var freq: [FriendColor: Int] = Dictionary(uniqueKeysWithValues: FriendColor.allCases.map { ($0, 0) })
        for f in friends { if let t = f.colorTag { freq[t, default: 0] += 1 } }
        return FriendColor.allCases.min(by: { freq[$0]! < freq[$1]! }) ?? .slateBlue
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
