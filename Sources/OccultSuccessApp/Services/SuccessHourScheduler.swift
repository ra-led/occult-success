import Foundation
import UserNotifications

struct SuccessHourScheduler {
    func scheduleRandomWindow(now: Date = .now) async throws -> SuccessHour {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        guard granted else {
            throw NSError(domain: "SuccessHour", code: 1, userInfo: [NSLocalizedDescriptionKey: "Разрешите уведомления, чтобы получать час успеха."])
        }

        let offset = TimeInterval(Int.random(in: 20 * 60...8 * 60 * 60))
        let startsAt = now.addingTimeInterval(offset)
        let endsAt = startsAt.addingTimeInterval(60 * 60)
        let content = UNMutableNotificationContent()
        content.title = "Открывается окно успеха"
        content.body = "Это лучший момент дня для действия: сделайте звонок, отправьте заявку или начните то, что откладывали."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: offset, repeats: false)
        let request = UNNotificationRequest(identifier: "success-hour-\(startsAt.timeIntervalSince1970)", content: content, trigger: trigger)
        try await center.add(request)
        return SuccessHour(startsAt: startsAt, endsAt: endsAt)
    }
}
