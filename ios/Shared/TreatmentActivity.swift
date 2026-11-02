import ActivityKit
import Foundation

/// Live Activity for a treatment course, e.g. "Figgy · neem treatment, round 2 of 5".
struct TreatmentActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var round: Int
        var totalRounds: Int
        var nextRound: String   // "Mon 2 Nov"

        var progress: Double { Double(round) / Double(max(1, totalRounds)) }
    }

    var plantName: String
    var treatment: String       // "neem treatment"
}
