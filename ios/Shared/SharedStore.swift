import Foundation

/// Data the app shares with the widget extension.
/// Turn on the App Groups capability for both targets with this identifier so the
/// widgets show live data; until then they fall back to sample data.
enum SharedStore {
    static let appGroup = "group.app.tend"
    static let summaryKey = "collectionSummary"

    static func summary() -> CollectionSummary {
        guard let data = UserDefaults(suiteName: appGroup)?.data(forKey: summaryKey),
              let s = try? JSONDecoder().decode(CollectionSummary.self, from: data) else { return .sample }
        return s
    }
}
