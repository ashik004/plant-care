import SwiftUI

// Pure care rules shared by the app and the widgets. Mirrors `health()`, `moist()`,
// `inR`, `near`, `fmtLux` and `listNames` in the prototype.

enum HealthKind: String, Codable { case good, watch, issue }

struct PlantHealth: Equatable {
    var kind: HealthKind
    var label: String
    /// Out-of-range factors: "humidity", "light", "temp", "cold".
    var out: [String] = []

    var color: Color {
        switch kind {
        case .good: Tend.C.accent
        case .watch: Tend.C.amber
        case .issue: Tend.C.clay
        }
    }
    var tint: Color {
        switch kind {
        case .good: Tend.C.leaf(0.12)
        case .watch: Tend.C.amberTint(0.14)
        case .issue: Tend.C.clayTint(0.14)
        }
    }
}

enum Care {
    static func inRange(_ v: Double, _ r: ClosedRange<Double>) -> Bool { r.contains(v) }

    /// Outside the range but within 15% of its span.
    static func near(_ v: Double, _ r: ClosedRange<Double>) -> Bool {
        let span = (r.upperBound - r.lowerBound) * 0.15
        return !inRange(v, r) && v >= r.lowerBound - span && v <= r.upperBound + span
    }

    /// Moisture = 1 − daysSince ÷ interval, clamped to 4…100%.
    static func moisture(_ p: Plant) -> Double {
        max(0.04, min(1, 1 - Double(p.daysSinceWater) / Double(p.waterEvery)))
    }

    static func health(_ p: Plant, treating: Bool) -> PlantHealth {
        if p.pest {
            return treating ? PlantHealth(kind: .watch, label: "Treating") : PlantHealth(kind: .issue, label: "Pest found")
        }
        let e = Room.reading(p.room)
        var out: [String] = []
        if !inRange(e.humidity, p.humidity) { out.append("humidity") }
        if !inRange(e.lux, p.light) { out.append("light") }
        if !inRange(e.temperature, p.temperature) { out.append("temp") }
        if e.temperature - p.temperature.lowerBound < 3 { out.append("cold") }
        return out.isEmpty ? PlantHealth(kind: .good, label: "Thriving") : PlantHealth(kind: .watch, label: "Needs attention", out: out)
    }

    static func fmtLux(_ l: Double) -> String {
        l >= 1000 ? String(format: "%.1fk lux", l / 1000) : "\(Int(l.rounded())) lux"
    }

    static func listNames(_ a: [String]) -> String {
        if a.count <= 1 { return a.first ?? "" }
        return a.dropLast().joined(separator: ", ") + " and " + a.last!
    }

    static let numberWords = ["No", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine"]

    // MARK: Dates

    static let gb = Locale(identifier: "en_GB")

    /// "Sat 31 Oct" for today + offset days.
    static func dayLabel(_ offset: Int, from base: Date = .now) -> String {
        let d = Calendar.current.date(byAdding: .day, value: offset, to: base) ?? base
        return d.formatted(.dateTime.locale(gb).weekday(.abbreviated).day().month(.abbreviated))
    }

    /// "Wednesday, 28 October"
    static func longDate(_ d: Date = .now) -> String {
        let wd = d.formatted(.dateTime.locale(gb).weekday(.wide))
        let dm = d.formatted(.dateTime.locale(gb).day().month(.wide))
        return "\(wd), \(dm)"
    }

    /// "6 Apr 2024"
    static func shortDate(_ d: Date) -> String {
        d.formatted(.dateTime.locale(gb).day().month(.abbreviated).year())
    }

    static func greeting(_ d: Date = .now) -> String {
        switch Calendar.current.component(.hour, from: d) {
        case 5..<12: "Good morning"
        case 12..<18: "Good afternoon"
        default: "Good evening"
        }
    }

    static func parseISODate(_ s: String) -> Date? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: s)
    }
}

/// A compact summary of the collection for widgets and the Live Activity.
struct CollectionSummary: Codable, Hashable {
    var thirsty: [String]
    var tomorrow: [String]
    var thriving: Int
    var total: Int

    var healthPercent: Int { total == 0 ? 0 : Int((Double(thriving) / Double(total) * 100).rounded()) }

    static func from(_ plants: [Plant], treating: Bool) -> CollectionSummary {
        CollectionSummary(
            thirsty: plants.filter { $0.daysSinceWater >= $0.waterEvery }.map(\.name),
            tomorrow: plants.filter { $0.waterEvery - $0.daysSinceWater == 1 }.map(\.name),
            thriving: plants.filter { Care.health($0, treating: treating).kind == .good }.count,
            total: plants.count)
    }

    static let sample = CollectionSummary.from(SampleData.plants, treating: false)
}
