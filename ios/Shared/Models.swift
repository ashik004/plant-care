import Foundation

// Data types and preview data, ported from the `<script>` block of `Tend App v4.dc.html`
// (PLANTS, ROOMS, SUGG, GUIDES, TREAT, LEGAL, ORIGIN, PROMPTS, RANGES).

struct Plant: Identifiable, Hashable, Codable {
    var id: String
    var name: String
    var species: String
    var room: String
    var spot: String
    /// Water every n days.
    var waterEvery: Int
    /// Days since last watered.
    var daysSinceWater: Int
    var amount: String
    var humidity: ClosedRange<Double>
    var light: ClosedRange<Double>
    var temperature: ClosedRange<Double>
    var feedEvery: Int
    var daysSinceFeed: Int
    var repot: String
    /// Weekly heights in cm for weeks W37–W44.
    var heights: [Int]
    var newLeaves: Int
    var trailing: Bool = false
    var pest: Bool = false
    var photos: Int = 4

    var shortName: String { name.replacingOccurrences(of: "Big ", with: "") }
}

struct RoomReading: Hashable, Codable {
    var temperature: Double
    var humidity: Double
    var lux: Double
}

enum Room {
    static let order = ["Living room", "Bedroom", "Kitchen", "Bathroom", "Balcony"]
    static let baseline: [String: RoomReading] = [
        "Living room": .init(temperature: 21.5, humidity: 44, lux: 8200),
        "Bedroom": .init(temperature: 19.0, humidity: 52, lux: 2400),
        "Kitchen": .init(temperature: 22.5, humidity: 48, lux: 3600),
        "Bathroom": .init(temperature: 22.0, humidity: 68, lux: 1800),
        "Balcony": .init(temperature: 9.0, humidity: 71, lux: 24000),
    ]
    static func reading(_ room: String) -> RoomReading { baseline[room] ?? baseline["Living room"]! }
}

struct ScanCandidate: Hashable {
    let species: String
    let latin: String
    let confidence: Int
    let waterEvery: Int
    let light: String
    let humidityText: String
    let humidity: ClosedRange<Double>
    let lightRange: ClosedRange<Double>
    let temperature: ClosedRange<Double>
    let amount: String
    let care: String
}

struct Guide: Identifiable, Hashable {
    let id: String
    let title: String
    let image: String
    let meta: String
    let steps: [(title: String, body: String)]

    static func == (a: Guide, b: Guide) -> Bool { a.id == b.id }
    func hash(into h: inout Hasher) { h.combine(id) }
}

struct LegalDoc {
    let title: String
    let updated: String
    let email: String
    let intro: String
    let glance: [(key: String, value: String)]
    let sections: [(heading: String, paragraphs: [String])]
    let hasActions: Bool
}

struct AwayRange: Identifiable, Hashable {
    let id: String
    let label: String
    let sub: String
    /// Days from today until departure.
    let start: Int
    let days: Int
}

struct PlantOrigin {
    let nativeTo: String
    let cameHome: String // yyyy-MM-dd
    let source: String
}

enum SampleData {
    static let plants: [Plant] = [
        Plant(id: "ott", name: "Ottoline", species: "Boston fern", room: "Bedroom", spot: "Bedroom, on the dresser", waterEvery: 3, daysSinceWater: 4, amount: "200 ml", humidity: 50...80, light: 1000...5000, temperature: 16...24, feedEvery: 30, daysSinceFeed: 12, repot: "Spring 2027", heights: [38, 39, 39, 40, 41, 41, 42, 43], newLeaves: 6),
        Plant(id: "mon", name: "Big Monstera", species: "Monstera deliciosa", room: "Living room", spot: "Living room, by the big window", waterEvery: 7, daysSinceWater: 7, amount: "400 ml", humidity: 40...70, light: 3000...15000, temperature: 18...27, feedEvery: 14, daysSinceFeed: 9, repot: "Due spring 2027 · roots at drainage", heights: [62, 63, 65, 66, 68, 70, 71, 74], newLeaves: 3),
        Plant(id: "fig", name: "Figgy", species: "Fiddle-leaf fig", room: "Living room", spot: "Living room, corner by the sofa", waterEvery: 9, daysSinceWater: 6, amount: "350 ml", humidity: 45...65, light: 5000...20000, temperature: 16...26, feedEvery: 21, daysSinceFeed: 18, repot: "Autumn 2027", heights: [110, 110, 111, 111, 112, 112, 112, 113], newLeaves: 1, pest: true),
        Plant(id: "gol", name: "Goldie", species: "Golden pothos", room: "Kitchen", spot: "Kitchen, top shelf", waterEvery: 7, daysSinceWater: 3, amount: "250 ml", humidity: 40...70, light: 1000...10000, temperature: 15...29, feedEvery: 14, daysSinceFeed: 15, repot: "Spring 2027", heights: [80, 84, 88, 91, 95, 99, 102, 106], newLeaves: 9, trailing: true),
        Plant(id: "pin", name: "Pinstripe", species: "Calathea ornata", room: "Bedroom", spot: "Bedroom, by the bed", waterEvery: 5, daysSinceWater: 2, amount: "200 ml", humidity: 60...80, light: 1000...5000, temperature: 18...26, feedEvery: 30, daysSinceFeed: 10, repot: "Not needed this year", heights: [30, 30, 31, 31, 32, 32, 33, 33], newLeaves: 2),
        Plant(id: "ros", name: "Rosemary", species: "Salvia rosmarinus", room: "Balcony", spot: "Balcony, left planter", waterEvery: 4, daysSinceWater: 2, amount: "300 ml", humidity: 30...60, light: 10000...50000, temperature: 7...27, feedEvery: 30, daysSinceFeed: 20, repot: "Spring 2027", heights: [41, 42, 42, 43, 43, 44, 44, 44], newLeaves: 0),
        Plant(id: "sgt", name: "Sergeant", species: "Snake plant", room: "Living room", spot: "Living room, by the door", waterEvery: 21, daysSinceWater: 6, amount: "200 ml", humidity: 30...60, light: 500...20000, temperature: 15...29, feedEvery: 45, daysSinceFeed: 20, repot: "Not needed this year", heights: [55, 55, 55, 56, 56, 56, 57, 57], newLeaves: 1),
        Plant(id: "zed", name: "Zed", species: "ZZ plant", room: "Bedroom", spot: "Bedroom, floor by the wardrobe", waterEvery: 18, daysSinceWater: 12, amount: "250 ml", humidity: 30...60, light: 300...8000, temperature: 15...26, feedEvery: 45, daysSinceFeed: 30, repot: "Not needed this year", heights: [46, 46, 47, 47, 48, 48, 49, 49], newLeaves: 2),
    ]

    static let ranges: [AwayRange] = [
        .init(id: "wkd", label: "Weekend", sub: "4 days", start: 2, days: 4),
        .init(id: "1w", label: "A week", sub: "7 days", start: 3, days: 7),
        .init(id: "2w", label: "Two weeks", sub: "14 days", start: 3, days: 14),
    ]

    static let candidates: [ScanCandidate] = [
        .init(species: "Peace lily", latin: "Spathiphyllum wallisii", confidence: 92, waterEvery: 6, light: "Medium", humidityText: "50–70%", humidity: 50...70, lightRange: 1000...6000, temperature: 18...27, amount: "300 ml", care: "Droops dramatically when thirsty and perks up within hours. Keep it away from cold draughts and wipe the leaves monthly."),
        .init(species: "Chinese evergreen", latin: "Aglaonema commutatum", confidence: 5, waterEvery: 10, light: "Low", humidityText: "40–60%", humidity: 40...60, lightRange: 300...4000, temperature: 18...27, amount: "250 ml", care: "Slow and forgiving. Let the top half of the soil dry out between drinks."),
        .init(species: "Dumb cane", latin: "Dieffenbachia seguine", confidence: 3, waterEvery: 7, light: "Bright", humidityText: "50–65%", humidity: 50...65, lightRange: 3000...10000, temperature: 18...27, amount: "300 ml", care: "Its sap irritates skin, so wear gloves when pruning. Keep it out of reach of pets."),
    ]

    static let guides: [Guide] = [
        Guide(id: "water", title: "Watering", image: "watering can at soil", meta: "4 steps · 2 min", steps: [
            ("Check before you pour", "Push a finger 2 cm into the soil. Dry means water. Damp means wait a day or two. This one habit prevents most houseplant deaths."),
            ("Use room-temperature water", "Cold water shocks roots. Fill your can the night before so it sits at room temperature, and chlorine has time to evaporate."),
            ("Pour slowly at the base", "Water the soil, not the leaves. Keep going until water runs from the drainage hole so the whole root ball gets wet."),
            ("Empty the saucer", "After 15 minutes, tip away anything left in the saucer. Roots sitting in water rot quietly."),
        ]),
        Guide(id: "feed", title: "Fertilizing", image: "liquid feed and measuring cap", meta: "4 steps · 3 min", steps: [
            ("Feed in the growing season", "March to September is when plants put on new growth. In winter most rest, so skip feeding or halve it."),
            ("Dilute to half strength", "Houseplants need far less than the bottle suggests. Half strength every two to four weeks is plenty."),
            ("Water first, then feed", "Never fertilize dry soil, which can scorch the roots. Give a normal drink, then apply the diluted feed."),
            ("Watch the response", "Deeper green and steady new leaves mean it's working. Crispy leaf edges mean too much, so flush with plain water."),
        ]),
        Guide(id: "repot", title: "Repotting", image: "root ball out of pot", meta: "5 steps · 20 min", steps: [
            ("Know when it's time", "Roots circling the pot or poking from the drainage hole, or water rushing straight through, all mean it's ready."),
            ("Go only one size up", "Pick a pot 2–5 cm wider than the current one. Too big a pot holds excess water and invites rot."),
            ("Loosen the root ball", "Tip the plant out and gently tease circling roots outward with your fingers. Trim any that are black and mushy."),
            ("Settle into fresh mix", "Add fresh potting mix, set the plant at the same depth as before and firm lightly. Don't pack it down hard."),
            ("Water and rest", "Water thoroughly, then keep it out of direct sun for a week while the roots recover."),
        ]),
        Guide(id: "prune", title: "Pruning", image: "clean scissors at a node", meta: "4 steps · 5 min", steps: [
            ("Start with clean, sharp scissors", "Wipe the blades with alcohol. A clean cut heals fast, while a crushed stem invites disease."),
            ("Remove what's spent", "Cut yellow, brown or damaged leaves at the base of their stem. The plant stops spending energy on them."),
            ("Cut just above a node", "A node is the bump where a leaf meets the stem. Cutting just above it encourages two new shoots and fuller growth."),
            ("Never take more than a quarter", "Remove at most 25% at once. If you need more, spread it over a few weeks."),
        ]),
    ]
    static func guide(_ id: String) -> Guide { guides.first { $0.id == id } ?? guides[0] }

    static let treatment: [(title: String, body: String)] = [
        ("Isolate Figgy", "Move it at least a metre from other plants. Mites travel on air currents and sleeves."),
        ("Rinse in the shower", "Lukewarm water over tops and undersides knocks off most mites and webbing."),
        ("Wipe with neem solution", "5 ml neem oil and a drop of soap per litre. Repeat every 5 days for 3 weeks."),
        ("Raise the humidity", "Mites thrive in dry air. Group plants together or add a humidifier to keep it above 50%."),
    ]

    // Placeholder legal copy. Must be reviewed by counsel before launch.
    static let terms = LegalDoc(
        title: "Terms of Service", updated: "LAST UPDATED · 1 OCTOBER 2026", email: "legal@tend.app",
        intro: "These terms cover your use of Tend: the app, the AI scanner, connected sensors and Premium. Plain language where we can, precise where we must.",
        glance: [],
        sections: [
            ("Using Tend", ["You need to be 13 or older to create an account. You're responsible for keeping your login secure and for activity on your account."]),
            ("AI advice is guidance, not a guarantee", ["Plant identification, health scores and diagnoses are generated by machine-learning models. They are usually right, but not always. Use your judgement, especially with treatments involving chemicals, pets or children.", "Tend is not liable for loss of plants, property or crops resulting from following in-app recommendations."]),
            ("Premium subscriptions", ["Monthly plans renew automatically each month until cancelled. Free trials convert to a paid plan unless you cancel at least 24 hours before the trial ends.", "Manage or cancel anytime in your Apple ID settings. Payment is charged to your Apple ID at confirmation of purchase."]),
            ("Lifetime purchase", ["Lifetime is a one-time purchase that unlocks all current and future Premium features for as long as Tend operates. It is tied to your Apple ID and can be restored on any device signed in to that ID."]),
            ("Refunds", ["Purchases are processed by Apple, and refund requests are handled through Apple's standard process at reportaproblem.apple.com."]),
            ("Your content", ["Photos, notes and plant data you add remain yours. You grant Tend a limited licence to store and process them solely to provide the service to you."]),
            ("Sensors and third-party hardware", ["Readings from connected sensors depend on the hardware. Tend isn't responsible for inaccurate data caused by faulty, misplaced or uncalibrated devices."]),
            ("Ending your account", ["You can delete your account at any time from Settings. We may suspend accounts that abuse the service, such as by automated scraping of the scanner."]),
            ("Changes to these terms", ["If we make material changes, we'll tell you in the app at least 14 days before they take effect."]),
        ],
        hasActions: false)

    static let privacy = LegalDoc(
        title: "Privacy Policy", updated: "LAST UPDATED · 1 OCTOBER 2026", email: "privacy@tend.app",
        intro: "Tend exists to keep your plants alive, not to sell your data. Here's exactly what we collect, why, and how to take it back.",
        glance: [
            ("We collect", "Plant photos, care logs, sensor readings, rough location for weather."),
            ("We never", "Sell your data, show ads, or share photos with advertisers."),
            ("Stored", "Encrypted in EU data centres. Photos deleted 30 days after you remove them."),
            ("You control", "Export everything or delete your account in two taps, below."),
        ],
        sections: [
            ("What we collect", ["Account details (name, email), plants you add, photos you take with the scanner, care history, and readings from sensors you connect.", "Approximate location (city level) for frost and heat alerts, only if you enable weather alerts."]),
            ("How AI scanning uses your photos", ["Photos are sent to our servers for identification and diagnosis, then stored with your plant's history. We don't use your photos to train models unless you opt in under Settings › Privacy."]),
            ("Sharing with plant-sitters", ["A hand-off link shares only the plants, photos and instructions in that plan. Links expire automatically when your trip ends."]),
            ("Service providers", ["We use a small number of processors for hosting, crash reporting and payments (Apple). Each is bound by a data-processing agreement and may only act on our instructions."]),
            ("Your rights", ["You can access, correct, export or delete your data at any time. If you're in the UK or EU you also have the right to object to processing and to complain to your data protection authority."]),
            ("Retention", ["We keep your data while your account is active. After you delete your account, everything is erased within 30 days, except records we must keep for tax purposes."]),
            ("Children", ["Tend isn't directed at children under 13, and we don't knowingly collect their data."]),
        ],
        hasActions: true)

    static let origins: [String: PlantOrigin] = [
        "ott": .init(nativeTo: "Tropical Americas", cameHome: "2024-04-06", source: "Columbia Road flower market"),
        "mon": .init(nativeTo: "Southern Mexico", cameHome: "2022-09-17", source: "A cutting from Mum"),
        "fig": .init(nativeTo: "West Africa", cameHome: "2023-05-02", source: "The garden centre on Hale Lane"),
        "gol": .init(nativeTo: "French Polynesia", cameHome: "2021-11-20", source: "A housewarming gift from Priya"),
        "pin": .init(nativeTo: "Colombia", cameHome: "2025-02-14", source: "Valentine's Day, from Sam"),
        "ros": .init(nativeTo: "Mediterranean", cameHome: "2025-06-01", source: "Saturday farmers' market"),
        "sgt": .init(nativeTo: "West Africa", cameHome: "2020-08-08", source: "Your first flat"),
        "zed": .init(nativeTo: "East Africa", cameHome: "2024-01-10", source: "Office clear-out rescue"),
    ]

    static let prompts: [String: [String]] = [
        "fig": ["Why are Figgy's lower leaves speckled?", "Is it safe to move Figgy during treatment?", "How do I stop mites coming back?"],
        "mon": ["Should I repot Big Monstera now or wait?", "Why are new leaves not splitting?", "How big will it get by spring?"],
        "gol": ["Goldie is getting leggy. Should I prune?", "Can I propagate the cuttings?", "How often in winter?"],
        "pin": ["Why do Pinstripe's edges go crispy?", "Is tap water okay for calatheas?", "Why do the leaves fold up at night?"],
        "general": ["Which plants are safe for cats?", "What does bright indirect light mean?", "How do I know if I'm overwatering?"],
    ]

    static let premiumFeatures: [(title: String, sub: String)] = [
        ("Unlimited AI scans & diagnoses", "Free includes 3 a month"),
        ("Live sensor monitoring", "Instant alerts when conditions drift"),
        ("Growth timelapse", "Weekly photos turned into a growth film"),
        ("Room-by-room advice", "Placement tips for every plant you own"),
        ("Unlimited plants & sitter hand-offs", "Free covers up to 10 plants"),
    ]
}
