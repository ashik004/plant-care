import SwiftUI
import Observation
import WidgetKit

// App state and actions. Ported from the `Component` class in `Tend App v4.dc.html`.

enum Level: String, Codable { case new, mid }

enum ReminderSlot: String, Codable, CaseIterable {
    case morning = "Morning", midday = "Midday", evening = "Evening"
    var time: String {
        switch self { case .morning: "08:00"; case .midday: "12:30"; case .evening: "19:00" }
    }
    var hour: Int { switch self { case .morning: 8; case .midday: 12; case .evening: 19 } }
    var minute: Int { self == .midday ? 30 : 0 }
    var next: ReminderSlot {
        let all = ReminderSlot.allCases
        return all[(all.firstIndex(of: self)! + 1) % all.count]
    }
}

enum PremiumPlan: String, Codable { case lifetime, monthly }

struct Prefs: Codable, Equatable {
    var haptics = true
    var daily = true
    var smartPause = true
    var weather = true
    var sitterUpdates = true
    var sensorAlerts = true
    var fahrenheit = false
    var fluidOunces = false
}

enum AppTab: Hashable { case home, plants, guides, scan }

enum ScanMode: String, Hashable { case identify, diagnose }

enum DetailTab: String, Hashable, CaseIterable {
    case health, growth, care, story
    var label: String { rawValue.capitalized }
}

enum LegalKind: String, Hashable { case terms, privacy }

/// Screens pushed onto a tab's navigation stack.
enum Route: Hashable {
    case detail(plantId: String, tab: DetailTab)
    case diagnosis
    case environment
    case lightMeter
    case away
    case handoff
    case sitterPreview
    case settings
    case legal(LegalKind)
    case widgets
    case digest
    case ask(plantId: String?)
    case timelapse(plantId: String)
    case states
}

/// Full-screen covers presented over the tab bar.
enum Cover: Identifiable, Hashable {
    case scan(ScanMode)
    case guide(id: String, context: String?)
    var id: String {
        switch self {
        case .scan(let m): "scan-\(m.rawValue)"
        case .guide(let id, let c): "guide-\(id)-\(c ?? "")"
        }
    }
}

enum TaskKind { case water, feed, treat, mist }

struct CareTask: Identifiable, Equatable {
    let id: String
    let plantId: String
    let kind: TaskKind
    let title: String
    let meta: String
    let when: String
    let late: Bool
}

struct Suggestion: Identifiable, Equatable {
    let id: String
    let title: String
    let why: String
    let cta: String
    let to: String
}

struct Visit: Identifiable {
    let key: Int
    let date: String
    let plants: [Plant]
    var id: Int { key }
    var names: String { plants.map(\.name).joined(separator: ", ") }
}

struct AwayPlan {
    let range: AwayRange
    let visits: [Visit]
    let need: [String]
    let fine: [String]
}

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let fromUser: Bool
    let text: String
}

struct Toast: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let undo: Snapshot?
    static func == (a: Toast, b: Toast) -> Bool { a.id == b.id }
}

/// What Undo restores.
struct Snapshot {
    var plants: [Plant]
    var mistDone: Bool
    var snoozed: Set<String>
    var treatTaskDone: Bool
}

@MainActor
@Observable
final class AppModel {
    // Onboarding
    var onboarded: Bool { didSet { save() } }
    var onboardingStep = 0
    var level: Level { didSet { save() } }
    var remind: ReminderSlot { didSet { save(); Task { await Notifications.schedule(self) } } }

    // Live data: drives the simulated sensor drift (2.5 s). Replace with a sensor feed.
    var tick = 0

    // Collection
    var plants: [Plant] { didSet { save(); publishWidgetSummary() } }
    var completing: String?
    var snoozed: Set<String> = []
    var mistDone = false
    var dismissedSuggestions: Set<String> = []
    var roomFilter = "All"
    var shelfView = false

    // Treatment
    var treatActive = false
    var treatDone: Set<Int> = []
    var treatTaskDone = false

    // Navigation
    var selectedTab: AppTab = .home
    var homePath: [Route] = []
    var plantsPath: [Route] = []
    var guidesPath: [Route] = []
    var cover: Cover?
    /// Which presentation layer shows the paywall: 0 = over the tabs, 1 = over a cover.
    var premiumHost: Int?

    // Feedback
    var toast: Toast?
    @ObservationIgnored private var toastTask: Task<Void, Never>?

    // Premium & scans
    var premium: PremiumPlan? { didSet { save() } }
    var scansLeft = 2
    var expertSent = false

    // Prefs
    var prefs: Prefs { didSet { save() } }

    // Ask Tend
    var askId = "fig"
    var chat: [ChatMessage] = []
    var askBusy = false
    @ObservationIgnored let askService: AskService = RemoteAskService()

    // Plant-sitter
    var rangeId = "1w"
    var sitter = "Sam"
    var copied = false
    var sitterDone: Set<String> = []

    // Legal
    var exportState = 0
    var deleteArmed = false

    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private var loading = true

    init() {
        let d = UserDefaults.standard
        onboarded = d.bool(forKey: "onboarded")
        level = Level(rawValue: d.string(forKey: "level") ?? "") ?? .new
        remind = ReminderSlot(rawValue: d.string(forKey: "remind") ?? "") ?? .evening
        premium = PremiumPlan(rawValue: d.string(forKey: "premium") ?? "")
        if let data = d.data(forKey: "prefs"), let p = try? JSONDecoder().decode(Prefs.self, from: data) { prefs = p } else { prefs = Prefs() }
        if let data = d.data(forKey: "plants"), let p = try? JSONDecoder().decode([Plant].self, from: data), !p.isEmpty { plants = p } else { plants = SampleData.plants }
        loading = false
        publishWidgetSummary()
    }

    private func save() {
        guard !loading else { return }
        defaults.set(onboarded, forKey: "onboarded")
        defaults.set(level.rawValue, forKey: "level")
        defaults.set(remind.rawValue, forKey: "remind")
        defaults.set(premium?.rawValue, forKey: "premium")
        defaults.set(try? JSONEncoder().encode(prefs), forKey: "prefs")
        defaults.set(try? JSONEncoder().encode(plants), forKey: "plants")
    }

    var isPremium: Bool { premium != nil }

    // MARK: Haptics & toasts

    func buzz(_ kind: HapticKind) {
        guard prefs.haptics else { return }
        Haptics.fire(kind)
    }

    func showToast(_ text: String, undo: Snapshot? = nil) {
        toastTask?.cancel()
        withAnimation(Tend.pop(0.4)) { toast = Toast(text: text, undo: undo) }
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.25)) { self?.toast = nil }
        }
    }

    func undoToast() {
        guard let snap = toast?.undo else { return }
        toastTask?.cancel()
        plants = snap.plants
        mistDone = snap.mistDone
        snoozed = snap.snoozed
        treatTaskDone = snap.treatTaskDone
        withAnimation { toast = nil }
    }

    func snapshot() -> Snapshot {
        Snapshot(plants: plants, mistDone: mistDone, snoozed: snoozed, treatTaskDone: treatTaskDone)
    }

    // MARK: Navigation

    func push(_ r: Route) {
        switch selectedTab {
        case .home, .scan: homePath.append(r)
        case .plants: plantsPath.append(r)
        case .guides: guidesPath.append(r)
        }
    }

    func selectTab(_ t: AppTab) {
        if t == .scan { openScan(.identify); return }
        if t != selectedTab { buzz(.selection) }
        selectedTab = t
    }

    func openScan(_ mode: ScanMode) { cover = .scan(mode) }
    func openGuide(_ id: String, context: String? = nil) { cover = .guide(id: id, context: context) }
    func openPremium() { premiumHost = cover == nil ? 0 : 1 }

    func finishOnboarding() {
        onboarded = true
        onboardingStep = 0
        selectedTab = .home
        homePath = []; plantsPath = []; guidesPath = []
    }

    func signOut() {
        onboarded = false
        onboardingStep = 0
        homePath = []; plantsPath = []; guidesPath = []
    }

    // MARK: Plants

    func plant(_ id: String) -> Plant? { plants.first { $0.id == id } }

    func update(_ id: String, _ change: (inout Plant) -> Void) {
        guard let i = plants.firstIndex(where: { $0.id == id }) else { return }
        change(&plants[i])
    }

    func health(_ p: Plant) -> PlantHealth { Care.health(p, treating: treatActive) }

    /// Simulated live reading with a gentle drift. `offset` de-syncs rooms from each other.
    func env(_ room: String, offset: Int = 0) -> RoomReading {
        let r = Room.reading(room)
        let k = Double(tick + offset)
        return RoomReading(temperature: r.temperature + 0.2 * sin(k * 0.9),
                           humidity: (r.humidity + sin(k * 0.6 + 1)).rounded(),
                           lux: (r.lux * (1 + 0.03 * sin(k * 0.7 + 2))).rounded())
    }

    var rooms: [String] {
        var seen: [String] = []
        for p in plants where !seen.contains(p.room) { seen.append(p.room) }
        return seen
    }

    func water(_ id: String) {
        guard let p = plant(id) else { return }
        let snap = snapshot()
        update(id) { $0.daysSinceWater = 0 }
        showToast("\(p.name) is watered. Next drink \(Care.dayLabel(p.waterEvery)).", undo: snap)
    }

    func setWaterEvery(_ id: String, _ delta: Int) {
        update(id) { $0.waterEvery = min(45, max(1, $0.waterEvery + delta)) }
    }

    func addGrowthPhoto(_ id: String) {
        guard let p = plant(id), p.photos <= 4 else { return }
        update(id) {
            $0.photos += 1
            $0.heights = Array($0.heights.dropFirst()) + [($0.heights.last ?? 0) + 1]
        }
        showToast("Week 44 photo saved. \(p.name) grew 1 cm.")
    }

    // MARK: Tasks

    var tasks: [CareTask] {
        var t: [CareTask] = []
        for p in plants where p.daysSinceWater >= p.waterEvery && !snoozed.contains(p.id) {
            let late = p.daysSinceWater - p.waterEvery
            t.append(CareTask(id: "w-\(p.id)", plantId: p.id, kind: .water, title: p.name,
                              meta: "Water · \(volume(p.amount)) · \(p.room)",
                              when: late <= 0 ? "Due today" : "\(late) day\(late > 1 ? "s" : "") late", late: late > 0))
        }
        for p in plants where p.daysSinceFeed >= p.feedEvery && !snoozed.contains("f" + p.id) {
            t.append(CareTask(id: "f-\(p.id)", plantId: p.id, kind: .feed, title: p.name,
                              meta: "Feed · half-strength · \(p.room)", when: "Growing season", late: false))
        }
        if treatActive && !treatTaskDone {
            t.insert(CareTask(id: "t-fig", plantId: "fig", kind: .treat, title: "Figgy",
                              meta: "Neem treatment · 1 of 5", when: "Today", late: true), at: 0)
        }
        if !mistDone && !snoozed.contains("mist"), let pin = plant("pin") {
            t.append(CareTask(id: "m-pin", plantId: "pin", kind: .mist, title: "Pinstripe",
                              meta: "Mist the leaves · \(pin.room)", when: "This evening", late: false))
        }
        // Late tasks first; stable otherwise.
        return t.enumerated().sorted { a, b in
            a.element.late != b.element.late ? a.element.late : a.offset < b.offset
        }.map(\.element)
    }

    func snooze(_ t: CareTask) {
        let snap = snapshot()
        let key = t.kind == .mist ? "mist" : t.kind == .feed ? "f" + t.plantId : t.plantId
        withAnimation(Tend.ease) { _ = snoozed.insert(key) }
        showToast("\(t.title) can wait until tomorrow.", undo: snap)
    }

    func complete(_ t: CareTask) {
        guard completing == nil else { return }
        buzz(.success)
        completing = t.id
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            withAnimation(Tend.ease) { self.finish(t) }
        }
    }

    private func finish(_ t: CareTask) {
        completing = nil
        if t.kind == .water { water(t.plantId); return }
        let snap = snapshot()
        switch t.kind {
        case .feed:
            update(t.plantId) { $0.daysSinceFeed = 0 }
            showToast("\(t.title) is fed. Next feed in \(plant(t.plantId)?.feedEvery ?? 14) days.", undo: snap)
        case .mist:
            mistDone = true
            showToast("Pinstripe is misted.", undo: snap)
        default:
            treatTaskDone = true
            showToast("Treatment logged. Next round Mon 2 Nov.", undo: snap)
        }
    }

    var tomorrowNames: [String] { plants.filter { $0.waterEvery - $0.daysSinceWater == 1 }.map(\.name) }

    // MARK: Suggestions

    var suggestions: [Suggestion] {
        var out: [Suggestion] = []
        if let pin = plant("pin"), pin.room != "Bathroom", !dismissedSuggestions.contains("pin") {
            out.append(Suggestion(id: "pin", title: "Pinstripe would be happier in the bathroom.",
                                  why: "\(pin.room) humidity is \(Int(Room.reading(pin.room).humidity))%. Calatheas want 60–80%, and the bathroom sits at \(Int(Room.reading("Bathroom").humidity))% with gentle light.",
                                  cta: "Move to bathroom", to: "Bathroom"))
        }
        if let ros = plant("ros"), ros.room == "Balcony", !dismissedSuggestions.contains("ros") {
            out.append(Suggestion(id: "ros", title: "Bring Rosemary in tonight.",
                                  why: "It's \(temp(9)) on the balcony now, with \(temp(4)) forecast overnight. The kitchen windowsill has the most light indoors.",
                                  cta: "Move to kitchen", to: "Kitchen"))
        }
        return out
    }

    func accept(_ s: Suggestion) {
        let snap = snapshot()
        withAnimation(Tend.ease) { update(s.id) { $0.room = s.to; $0.spot = s.to } }
        showToast("Moved. Tend will watch how it settles in.", undo: snap)
    }

    func dismiss(_ s: Suggestion) {
        withAnimation(Tend.ease) { _ = dismissedSuggestions.insert(s.id) }
    }

    // MARK: Treatment

    func toggleTreatStep(_ i: Int) {
        if treatDone.contains(i) { treatDone.remove(i) } else { treatDone.insert(i) }
    }

    func startTreatment() {
        withAnimation(Tend.ease) { treatActive = true }
        showToast("Treatment plan added to Today.")
        LiveActivities.startTreatment(plant: "Figgy")
    }

    // MARK: Scanning

    var canScan: Bool { isPremium || scansLeft > 0 }

    func consumeScan() { if !isPremium { scansLeft = max(0, scansLeft - 1) } }

    func addPlant(candidate c: ScanCandidate, nickname: String, room: String, every: Int) {
        let name = nickname.trimmingCharacters(in: .whitespaces).isEmpty ? c.species : nickname.trimmingCharacters(in: .whitespaces)
        let p = Plant(id: "n\(Int(Date.now.timeIntervalSince1970 * 1000))", name: name, species: c.species, room: room, spot: room,
                      waterEvery: every, daysSinceWater: 0, amount: c.amount, humidity: c.humidity, light: c.lightRange,
                      temperature: c.temperature, feedEvery: 21, daysSinceFeed: 0, repot: "Not needed this year",
                      heights: Array(repeating: 30, count: 8), newLeaves: 0, photos: 1, latin: c.latin)
        plants.append(p)
        roomFilter = "All"
        shelfView = false
        cover = nil
        selectedTab = .plants
        plantsPath = []
        showToast("\(name) joins the collection.")
    }

    func askExpert() {
        guard !expertSent else { return }
        guard isPremium else { openPremium(); return }
        expertSent = true
        buzz(.success)
        showToast("Sent to a botanist. You'll hear back within 24 hours.")
    }

    // MARK: Ask Tend

    func send(_ raw: String) {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !askBusy else { return }
        buzz(.light)
        chat.append(ChatMessage(fromUser: true, text: text))
        askBusy = true
        let p = askId == "general" ? nil : plant(askId)
        let prompt = askPrompt(question: text, plant: p)
        let fallback = askFallback(p)
        let service = askService
        Task { @MainActor in
            var answer: String
            do {
                answer = try await service.answer(prompt: prompt).trimmingCharacters(in: .whitespacesAndNewlines)
                if answer.isEmpty { answer = fallback }
            } catch {
                try? await Task.sleep(for: .milliseconds(900))
                answer = fallback
            }
            withAnimation(Tend.ease(0.35)) {
                self.chat.append(ChatMessage(fromUser: false, text: answer))
                self.askBusy = false
            }
            self.buzz(.soft)
        }
    }

    /// The prompt sent to the LLM backend: the plant's room readings, schedule, health,
    /// growth and pest history.
    func askPrompt(question: String, plant p: Plant?) -> String {
        var ctx = "No specific plant selected."
        if let p {
            let e = env(p.room)
            ctx = "Plant: \(p.name) (\(p.species)), \(p.spot). Waters every \(p.waterEvery) days, last watered \(p.daysSinceWater) days ago, \(p.amount) each time. "
                + "Room right now: \(String(format: "%.1f", e.temperature))°C, \(Int(e.humidity))% humidity, \(Care.fmtLux(e.lux)). "
                + "Ideal: humidity \(Int(p.humidity.lowerBound))–\(Int(p.humidity.upperBound))%, light \(Int(p.light.lowerBound))–\(Int(p.light.upperBound)) lux, \(Int(p.temperature.lowerBound))–\(Int(p.temperature.upperBound))°C. "
                + "Health: \(health(p).label). Height went from \(p.heights.first ?? 0) to \(p.heights.last ?? 0) cm over 8 weeks."
                + (p.pest ? " Spider mites detected on lower leaves on Mon 26 Oct; neem treatment \(treatActive ? "in progress" : "not started yet")." : "")
        }
        return "You are Tend, a warm, expert houseplant assistant inside an iPhone app. The owner is "
            + (level == .new ? "still learning, so explain simply" : "experienced, so be concise and technical")
            + ". Reply in 2 to 4 short sentences of plain text. No markdown, no lists, no greetings. Use the plant data when relevant.\n\n"
            + ctx + "\n\nQuestion: " + question
    }

    private func askFallback(_ p: Plant?) -> String {
        guard let p else {
            return "Good question. Most houseplant trouble comes down to watering too often, so check the soil two knuckles deep first. Pick a plant above and I can answer using its own history."
        }
        let e = env(p.room)
        return "\(p.name) is \(health(p).label.lowercased()) right now. The \(p.room.lowercased()) is at \(Int(e.humidity))% humidity and \(Care.fmtLux(e.lux)), so keep an eye on anything outside its ideal range. If in doubt, check the soil two knuckles deep before watering."
    }

    // MARK: Plant-sitter

    var awayPlan: AwayPlan {
        let r = SampleData.ranges.first { $0.id == rangeId } ?? SampleData.ranges[1]
        var byDay: [Int: [Plant]] = [:]
        var need: [String] = [], fine: [String] = []
        for p in plants {
            let atDeparture = (p.daysSinceWater + r.start) >= p.waterEvery ? 0 : p.daysSinceWater + r.start
            var any = false
            for i in 1...r.days where (atDeparture + i) % p.waterEvery == 0 {
                byDay[i, default: []].append(p); any = true
            }
            if any { need.append(p.name) } else { fine.append(p.name) }
        }
        let visits = byDay.keys.sorted().map { Visit(key: $0, date: Care.dayLabel(r.start + $0), plants: byDay[$0]!) }
        return AwayPlan(range: r, visits: visits, need: need, fine: fine)
    }

    var sitterName: String {
        let s = sitter.trimmingCharacters(in: .whitespaces)
        return s.isEmpty ? "your sitter" : s
    }

    // MARK: Units

    func temp(_ c: Double, decimals: Int = 0) -> String {
        let v = prefs.fahrenheit ? c * 9 / 5 + 32 : c
        return String(format: "%.\(decimals)f°\(prefs.fahrenheit ? "F" : "C")", v)
    }

    /// Converts "200 ml" to fl oz when that unit is selected.
    func volume(_ amount: String) -> String {
        guard prefs.fluidOunces, let ml = Double(amount.split(separator: " ").first ?? "") else { return amount }
        return String(format: "%.1f fl oz", ml / 29.5735)
    }

    // MARK: Widgets

    private func publishWidgetSummary() {
        let summary = CollectionSummary.from(plants, treating: treatActive)
        if let data = try? JSONEncoder().encode(summary) {
            UserDefaults(suiteName: SharedStore.appGroup)?.set(data, forKey: SharedStore.summaryKey)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
