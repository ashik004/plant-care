import SwiftUI
import UIKit
import UserNotifications
import ActivityKit

// MARK: - Haptics

/// The haptics map from the handoff README.
enum HapticKind {
    case selection   // switch tab, timelapse scrub, room chip
    case light       // toggle, play timelapse, send chat
    case soft        // chat reply arrives
    case medium      // scan finished
    case success     // task done, water, purchase, save light reading, expert sent
    case warning     // offline retry fails
}

enum Haptics {
    static func fire(_ kind: HapticKind) {
        switch kind {
        case .selection: UISelectionFeedbackGenerator().selectionChanged()
        case .light: UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .soft: UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        case .medium: UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .success: UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning: UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
    }
}

// MARK: - Reminders

/// One local notification a day at the chosen time, only when something is due.
enum Notifications {
    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    @MainActor
    static func schedule(_ model: AppModel) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily-care"])
        guard model.prefs.daily else { return }
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }

        let due = model.tasks
        guard !due.isEmpty else { return }
        let content = UNMutableNotificationContent()
        content.title = "Tend"
        let water = due.filter { $0.kind == .water }.map(\.title)
        let feed = due.filter { $0.kind == .feed }.map(\.title)
        var parts: [String] = []
        if !water.isEmpty { parts.append("\(Care.listNames(water)) \(water.count > 1 ? "are" : "is") dry") }
        if !feed.isEmpty { parts.append("\(Care.listNames(feed)) \(feed.count > 1 ? "are" : "is") ready for a feed") }
        content.body = parts.isEmpty ? "\(due.count) plant\(due.count == 1 ? "" : "s") could use you today." : parts.joined(separator: " and ") + "."
        content.sound = .default

        var date = DateComponents()
        date.hour = model.remind.hour
        date.minute = model.remind.minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: false)
        try? await center.add(UNNotificationRequest(identifier: "daily-care", content: content, trigger: trigger))
    }
}

// MARK: - Live Activities

enum LiveActivities {
    static func startTreatment(plant: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attrs = TreatmentActivityAttributes(plantName: plant, treatment: "neem treatment")
        let state = TreatmentActivityAttributes.ContentState(round: 1, totalRounds: 5, nextRound: "Mon 2 Nov")
        _ = try? Activity.request(attributes: attrs, content: .init(state: state, staleDate: nil))
    }
}

// MARK: - Ask Tend

protocol AskService: Sendable {
    func answer(prompt: String) async throws -> String
}

/// Sends the prompt to your LLM backend. Set `TendAskEndpoint` in Info.plist to a URL that
/// accepts `POST {"prompt": "…"}` and returns `{"answer": "…"}`. Keep model API keys on the
/// server, never in the app. With no endpoint, the app shows its built-in fallback answer.
struct RemoteAskService: AskService {
    struct NotConfigured: Error {}

    func answer(prompt: String) async throws -> String {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "TendAskEndpoint") as? String,
              !raw.isEmpty, let url = URL(string: raw) else { throw NotConfigured() }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 20
        req.httpBody = try JSONEncoder().encode(["prompt": prompt])
        let (data, response) = try await URLSession.shared.data(for: req)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        struct Reply: Decodable { let answer: String }
        return try JSONDecoder().decode(Reply.self, from: data).answer
    }
}
