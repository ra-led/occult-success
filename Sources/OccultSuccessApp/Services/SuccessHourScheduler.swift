import Foundation
import UserNotifications

struct SuccessHourScheduler {
    func calculateWindow(natalChart: NatalChart, moonDay: MoonDay, location selectedLocation: BirthLocation? = nil, now: Date = .now) -> SuccessHour {
        let actionLocation = selectedLocation ?? natalChart.location
        let timeZone = actionLocation?.timeZoneIdentifier.flatMap(TimeZone.init(identifier:)) ?? .current
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let birthComponents = calendar.dateComponents([.hour, .minute], from: natalChart.calculatedBirthDate)
        let birthMinuteOfDay = (birthComponents.hour ?? 12) * 60 + (birthComponents.minute ?? 0)
        let moonPulse = Int((moonDay.cycleFraction * 720).rounded())
        let placePulse = Int(((actionLocation?.latitude ?? 0) * 3 + (actionLocation?.longitude ?? 0) * 2).rounded())
        let chartPulse = Int((natalChart.ascendantDegree + natalChart.midheavenDegree + natalChart.sunSign.successOffset + natalChart.moonSign.successOffset).rounded())
        let workingDayStart = 8 * 60
        let workingWindow = 12 * 60
        let minuteInWindow = abs(birthMinuteOfDay + moonPulse + placePulse + chartPulse) % workingWindow
        let targetMinute = workingDayStart + minuteInWindow
        let startOfToday = calendar.startOfDay(for: now)
        var startsAt = calendar.date(byAdding: .minute, value: targetMinute, to: startOfToday) ?? now.addingTimeInterval(60 * 60)
        if startsAt <= now.addingTimeInterval(10 * 60) {
            startsAt = calendar.date(byAdding: .day, value: 1, to: startsAt) ?? startsAt.addingTimeInterval(24 * 60 * 60)
        }
        let endsAt = startsAt.addingTimeInterval(60 * 60)
        let rawScore = 72 + Int(abs(sin(Double(chartPulse + moonPulse))) * 24)
        let locationName = actionLocation?.title ?? "текущему часовому поясу"
        let reason = "Окно собрано по натальной карте: Солнце в знаке \(natalChart.sunSign.rawValue), Луна в знаке \(natalChart.moonSign.rawValue), ASC \(natalChart.ascendant.rawValue). Место действия: \(locationName), \(moonDay.number)-й лунный день."

        return SuccessHour(
            startsAt: startsAt,
            endsAt: endsAt,
            locationName: locationName,
            timeZoneIdentifier: timeZone.identifier,
            reason: reason,
            score: min(99, rawScore)
        )
    }

    func scheduleWindow(_ window: SuccessHour, now: Date = .now) async throws {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        guard granted else {
            throw NSError(domain: "SuccessHour", code: 1, userInfo: [NSLocalizedDescriptionKey: "Разрешите уведомления, чтобы получать час успеха."])
        }

        let offset = max(60, window.startsAt.timeIntervalSince(now))
        let content = UNMutableNotificationContent()
        content.title = "Открывается окно успеха"
        content.body = "Сейчас лучший момент для действия. \(window.locationName): используйте час для звонка, заявки или первого шага."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: offset, repeats: false)
        let request = UNNotificationRequest(identifier: "success-hour-\(window.startsAt.timeIntervalSince1970)", content: content, trigger: trigger)
        try await center.add(request)
    }
}

private extension ZodiacSign {
    var successOffset: Double {
        switch self {
        case .aries: return 17
        case .taurus: return 41
        case .gemini: return 73
        case .cancer: return 109
        case .leo: return 137
        case .virgo: return 163
        case .libra: return 191
        case .scorpio: return 223
        case .sagittarius: return 251
        case .capricorn: return 283
        case .aquarius: return 311
        case .pisces: return 347
        }
    }
}
