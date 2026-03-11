import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private let notifyBeforeDays = 30

    // MARK: - Permission

    func requestPermission() async {
        try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }

    // MARK: - Schedule

    /// Clears all pending notifications and reschedules based on current friends list.
    func scheduleAll(friends: [Friend]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let events = EventsEngine.upcomingEvents(friends: friends, lookAheadDays: 120)
        let cal = Calendar.current
        let now = Date()

        for event in events where event.daysUntil >= notifyBeforeDays {
            guard
                let notifyDate = cal.date(byAdding: .day, value: -notifyBeforeDays, to: event.date),
                notifyDate > now
            else { continue }

            let content = UNMutableNotificationContent()
            content.title = "SomehowGrown 🎉"
            let kidLabel = event.kidName.isEmpty ? "お子さん" : "\(event.kidName)ちゃん"
            content.body  = "\(event.friendName)さんの\(kidLabel)が来月\(event.eventLabel)を迎えます"
            content.sound = .default

            let triggerComps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: notifyDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComps, repeats: false)

            let request = UNNotificationRequest(
                identifier: event.id.uuidString,
                content: content,
                trigger: trigger
            )
            center.add(request) { error in
                if let error { print("[Notifications] Error:", error) }
            }
        }
    }
}
