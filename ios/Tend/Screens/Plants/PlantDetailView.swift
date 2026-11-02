import SwiftUI

struct PlantDetailView: View {
    let plantId: String
    @State var tab: DetailTab
    @Environment(AppModel.self) var model

    init(plantId: String, initialTab: DetailTab) {
        self.plantId = plantId
        _tab = State(initialValue: initialTab)
    }

    var body: some View {
        Group {
            if let p = model.plant(plantId) {
                content(p)
            } else {
                VStack { BackPill(); Spacer() }.padding()
            }
        }
        .tendScreen()
    }

    private func content(_ p: Plant) -> some View {
        let h = model.health(p)
        return ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    BackPill()
                    Spacer()
                    TintPillButton("Check health") { model.openScan(.diagnose) }
                }
                .padding(.horizontal, Tend.S.sideWide)

                StripedPlaceholder(label: "photo · \(p.species)", stripe: 7, palette: .wide, radius: Tend.R.photo, labelSize: 10)
                    .frame(height: 260)
                    .padding(.horizontal, Tend.S.sideWide)

                HStack(alignment: .bottom, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Eyebrow(text: p.room)
                        Text(p.name).font(Tend.F.serif(44)).foregroundStyle(Tend.C.text)
                        Text(p.species).font(Tend.F.serifItalic(18)).foregroundStyle(Tend.C.text4)
                    }
                    Spacer(minLength: 0)
                    HealthPill(health: h)
                }
                .padding(.horizontal, Tend.S.side)

                SegmentedPicker(options: DetailTab.allCases.map { ($0, $0.label) }, selection: $tab)
                    .padding(.horizontal, Tend.S.side)

                Group {
                    switch tab {
                    case .health: HealthTab(plant: p, health: h)
                    case .growth: GrowthTab(plant: p)
                    case .care: CareTab(plant: p)
                    case .story: StoryTab(plant: p)
                    }
                }
                .id(tab)
                .entrance()
            }
            .padding(.top, 8)
            .padding(.bottom, 40)
            .entrance()
        }
    }
}

// MARK: Health

private struct Sensor {
    let label: String
    let value: String
    let color: Color
    let pos: Double
    let idealLo: Double
    let idealHi: Double
    let note: String
    let noteColor: Color
}

private struct HealthTab: View {
    let plant: Plant
    let health: PlantHealth
    @Environment(AppModel.self) var model

    var body: some View {
        let e = model.env(plant.room)
        let m = Care.moisture(plant)
        let left = plant.waterEvery - plant.daysSinceWater
        let sensors = [
            sensor("Soil moisture", (m * 100).rounded(), 25...80, "\(Int((m * 100).rounded()))%", 0, 100,
                   left <= 0 ? "Dry · water today" : "Water in \(left) day\(left == 1 ? "" : "s")"),
            sensor("Light", e.lux, plant.light, Care.fmtLux(e.lux), 0, max(plant.light.upperBound * 1.4, e.lux * 1.1), "In the ideal range"),
            sensor("Humidity", e.humidity, plant.humidity, "\(Int(e.humidity))%", 20, 90, "Comfortable"),
            sensor("Temperature", (e.temperature * 10).rounded() / 10, plant.temperature, model.temp(e.temperature, decimals: 1), 0, 35, "Comfortable"),
        ]

        VStack(alignment: .leading, spacing: 18) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(sensors, id: \.label) { SensorTile(s: $0) }
            }
            .padding(.horizontal, Tend.S.side)

            Group {
                if plant.daysSinceWater > 0 {
                    Button(left <= 0 ? "Water \(plant.name) now" : "Watered early? Log it") {
                        model.buzz(.success)
                        withAnimation(Tend.ease) { model.water(plant.id) }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                } else {
                    Text("✓ Watered. Next drink \(Care.dayLabel(plant.waterEvery))")
                        .font(Tend.F.sans(16, .semibold)).foregroundStyle(Tend.C.accent)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(Tend.C.leaf(0.1), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }
            .padding(.horizontal, Tend.S.side)

            VStack(alignment: .leading, spacing: 8) {
                Eyebrow(text: "Tend's read")
                Text(insight(e: e, left: left)).font(Tend.F.serif(20)).lineSpacing(5).foregroundStyle(Tend.C.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Tend.S.side)
        }
    }

    private func sensor(_ label: String, _ v: Double, _ r: ClosedRange<Double>, _ disp: String,
                        _ lo: Double, _ hi: Double, _ okNote: String) -> Sensor {
        let ok = Care.inRange(v, r), near = Care.near(v, r)
        let color = ok ? Tend.C.accent : near ? Tend.C.amber : Tend.C.clay
        func pos(_ x: Double) -> Double { max(0.02, min(0.98, (x - lo) / (hi - lo))) }
        let rangeText = "\(Int(r.lowerBound))–\(Int(r.upperBound))"
        return Sensor(label: label, value: disp, color: color, pos: pos(v), idealLo: pos(r.lowerBound), idealHi: pos(r.upperBound),
                      note: ok ? okNote : (v < r.lowerBound ? "Low · ideal \(rangeText)" : "High · ideal \(rangeText)"),
                      noteColor: ok ? Tend.C.text4 : color)
    }

    private func insight(e: RoomReading, left: Int) -> String {
        if plant.pest {
            return model.treatActive
                ? "Treatment is under way. New leaves look clean, which is a good sign. Keep humidity above 50% while it recovers."
                : "Spider mites spotted on the lower leaves, likely from dry air. Caught early. The treatment plan takes about three weeks."
        }
        if health.kind == .watch {
            if health.out.contains("humidity") {
                return "Everything is fine except the air. At \(Int(e.humidity))% humidity, expect crispy leaf edges. A move to the bathroom would fix it."
            }
            return "Nights are getting cold for \(plant.name). Bring it indoors when it drops below \(model.temp(plant.temperature.lowerBound))."
        }
        if left <= 0 { return "\(plant.name) is healthy, just thirsty. Water today and it'll be back in range by morning." }
        return "\(plant.name) is thriving. Light, humidity and temperature are all where it likes them."
    }
}

private struct SensorTile: View {
    let s: Sensor
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(s.label).font(Tend.F.sans(12)).foregroundStyle(Tend.C.text4)
                Spacer()
                StatusDot(color: s.color, size: 6)
            }
            Text(s.value).font(Tend.F.serif(30)).foregroundStyle(Tend.C.text)
                .contentTransition(.numericText()).lineLimit(1).minimumScaleFactor(0.7)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Tend.C.ink(0.09)).frame(height: 4)
                    Capsule().fill(Tend.C.leaf(0.22)).frame(width: max(0, (s.idealHi - s.idealLo) * g.size.width), height: 4)
                        .offset(x: s.idealLo * g.size.width)
                    Circle().fill(s.color).frame(width: 10, height: 10)
                        .shadow(color: s.color, radius: 4)
                        .offset(x: s.pos * g.size.width - 5)
                        .animation(Tend.ease(0.8), value: s.pos)
                }
                .frame(height: 10)
            }
            .frame(height: 10)
            Text(s.note).font(Tend.F.sans(11)).foregroundStyle(s.noteColor)
        }
        .padding(14)
        .card(radius: 18)
        .accessibilityElement(children: .combine)
    }
}

// MARK: Growth

private struct GrowthTab: View {
    let plant: Plant
    @Environment(AppModel.self) var model
    @State var grown = false

    var body: some View {
        let hs = plant.heights
        let mn = hs.min() ?? 0, mx = hs.max() ?? 1
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text("+\((hs.last ?? 0) - (hs.first ?? 0)) cm").font(Tend.F.serif(30)).foregroundStyle(Tend.C.text)
                    Spacer()
                    Text("over 8 weeks").font(Tend.F.sans(12)).foregroundStyle(Tend.C.text4)
                }
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(Array(hs.enumerated()), id: \.offset) { i, v in
                        let last = i == hs.count - 1
                        let frac = 0.25 + 0.75 * Double(v - mn) / Double(max(1, mx - mn))
                        VStack(spacing: 6) {
                            GeometryReader { g in
                                VStack {
                                    Spacer(minLength: 0)
                                    UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 3, bottomTrailingRadius: 3, topTrailingRadius: 6, style: .continuous)
                                        .fill(last ? Tend.C.accent : Tend.C.leaf(0.28))
                                        .frame(height: g.size.height * frac)
                                        .shadow(color: last ? Tend.C.leaf(0.5) : .clear, radius: 7)
                                        .scaleEffect(x: 1, y: grown ? 1 : 0, anchor: .bottom)
                                        .animation(Tend.ease(0.7).delay(Double(i) * 0.06), value: grown)
                                }
                            }
                            Text("W\(37 + i)").font(Tend.F.mono(9)).foregroundStyle(Tend.C.muted)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 120)
                HStack(spacing: 16) {
                    Text("\(plant.trailing ? "Longest vine" : "Height") \(hs.last ?? 0) cm")
                    Text("\(plant.newLeaves) new leaves")
                }
                .font(Tend.F.sans(13)).foregroundStyle(Tend.C.text3)
                Button { model.push(.timelapse(plantId: plant.id)) } label: {
                    HStack(spacing: 9) {
                        SVGShape(Icon.playSmall, viewBox: CGSize(width: 14, height: 14)).fill(Tend.C.onInverse).frame(width: 14, height: 14)
                        Text("Play 8-week timelapse").font(Tend.F.sans(14, .semibold))
                    }
                    .foregroundStyle(Tend.C.onInverse)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Tend.C.inverse, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(LiftButtonStyle())
            }
            .padding(18)
            .card()
            .padding(.horizontal, Tend.S.side)

            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "Weekly photos").padding(.horizontal, Tend.S.side)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 10) {
                        Button { withAnimation(Tend.ease) { model.addGrowthPhoto(plant.id) } } label: {
                            VStack(spacing: 6) {
                                Text("+").font(Tend.F.sans(24)).fontWeight(.light)
                                Text("This week").font(Tend.F.sans(13, .semibold))
                            }
                            .foregroundStyle(Tend.C.accent)
                            .frame(width: 110, height: 146)
                            .background(Tend.C.leaf(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Tend.C.leaf(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])))
                        }
                        .buttonStyle(.plain)
                        ForEach(0..<plant.photos, id: \.self) { i in
                            VStack(alignment: .leading, spacing: 6) {
                                StripedPlaceholder(label: "photo", radius: 16).frame(width: 110, height: 120)
                                Text(i == 0 && plant.photos > 4 ? "Week 44 · now" : "Week \(44 - i - (plant.photos > 4 ? 0 : 1))")
                                    .font(Tend.F.sans(12)).foregroundStyle(Tend.C.text4)
                            }
                        }
                    }
                    .padding(.horizontal, Tend.S.side)
                }
            }
        }
        .onAppear { grown = true }
    }
}

// MARK: Care

private struct CareTab: View {
    let plant: Plant
    @Environment(AppModel.self) var model

    var body: some View {
        let left = plant.waterEvery - plant.daysSinceWater
        let feedDue = plant.daysSinceFeed >= plant.feedEvery
        let rows: [(String, String, Color, String)] = [
            ("Fertilize", feedDue ? "Due now · half-strength" : "Next \(Care.dayLabel(plant.feedEvery - plant.daysSinceFeed)) · every \(plant.feedEvery) days", feedDue ? Tend.C.amber : Tend.C.text4, "feed"),
            ("Repot", plant.repot, plant.repot.contains("roots") ? Tend.C.amber : Tend.C.text4, "repot"),
            ("Prune", plant.newLeaves > 4 ? "Trim leggy growth this month" : "Only as needed", Tend.C.text4, "prune"),
            ("Watering technique", "\(model.volume(plant.amount)) at the base", Tend.C.text4, "water"),
        ]
        let log: [(String, String)] = plant.pest
            ? [("Scan · spider mites detected", "Mon 26 Oct"), ("Watered · \(model.volume(plant.amount))", Care.dayLabel(-plant.daysSinceWater)), ("Scan · healthy", "Mon 12 Oct")]
            : [("Watered · \(model.volume(plant.amount))", Care.dayLabel(-plant.daysSinceWater)), ("Fed · half-strength", Care.dayLabel(-plant.daysSinceFeed)), ("Scan · healthy", "Mon 19 Oct")]

        VStack(alignment: .leading, spacing: 14) {
            IntervalStepper(every: plant.waterEvery,
                            hint: model.level == .new ? "Tuned by Tend for this species and room" : "Next drink \(Care.dayLabel(max(0, left)))",
                            minus: { model.setWaterEvery(plant.id, -1) },
                            plus: { model.setWaterEvery(plant.id, 1) })
                .padding(.horizontal, Tend.S.side)

            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { i, r in
                    Button { model.openGuide(r.3, context: plant.name) } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(r.0).font(Tend.F.sans(15, .semibold)).foregroundStyle(Tend.C.text)
                                Text(r.1).font(Tend.F.sans(12)).foregroundStyle(r.2)
                            }
                            Spacer()
                            Text("Guide ›").font(Tend.F.sans(13, .semibold)).foregroundStyle(Tend.C.accent)
                        }
                        .padding(.vertical, 14).padding(.horizontal, 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if i < rows.count - 1 { RowDivider() }
                }
            }
            .card()
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, Tend.S.side)

            VStack(alignment: .leading, spacing: 0) {
                Eyebrow(text: "Health history").padding(.top, 6).padding(.bottom, 8)
                ForEach(Array(log.enumerated()), id: \.offset) { _, l in
                    VStack(spacing: 0) {
                        RowDivider(opacity: 0.1)
                        HStack(spacing: 12) {
                            Text(l.0).foregroundStyle(Tend.C.text)
                            Spacer()
                            Text(l.1).foregroundStyle(Tend.C.text4)
                        }
                        .font(Tend.F.sans(14))
                        .padding(.vertical, 12)
                    }
                }
            }
            .padding(.horizontal, Tend.S.side)
        }
    }
}

// MARK: Story (plant passport)

private struct StoryTab: View {
    let plant: Plant
    @Environment(AppModel.self) var model

    private var origin: PlantOrigin {
        SampleData.origins[plant.id] ?? PlantOrigin(nativeTo: "Unknown", cameHome: ISO8601DateFormatter().string(from: .now).prefix(10).description, source: "Added with the scanner")
    }

    var body: some View {
        let o = origin
        let came = Care.parseISODate(o.cameHome) ?? .now
        let days = max(0, Calendar.current.dateComponents([.day], from: came, to: .now).day ?? 0)
        let miles = milestones(came: came, source: o.source)
        let number = 1000 + abs(plant.id.unicodeScalars.reduce(7) { ($0 &* 31 &+ Int($1.value)) }) % 9000

        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PLANT PASSPORT · NO. \(String(number))").font(Tend.F.mono(10)).tracking(0.6).foregroundStyle(Tend.C.text5)
                        Text(plant.name).font(Tend.F.serif(30)).foregroundStyle(Tend.C.text)
                        Text(plant.species).font(Tend.F.serifItalic(15)).foregroundStyle(Tend.C.text4)
                    }
                    Spacer(minLength: 0)
                    VStack(spacing: 2) {
                        Text(days.formatted(.number.locale(Care.gb))).font(Tend.F.serif(23))
                        Text("DAYS TOGETHER").font(Tend.F.sans(8, .bold)).tracking(1)
                    }
                    .foregroundStyle(Tend.C.brandInk)
                    .frame(width: 72, height: 72)
                    .overlay(Circle().strokeBorder(Tend.C.leaf(0.55), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])))
                    .rotationEffect(.degrees(-8))
                }
                Rectangle().fill(.clear).frame(height: 1)
                    .overlay(Line().stroke(Tend.C.ink(0.18), style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16, alignment: .topLeading), GridItem(.flexible(), alignment: .topLeading)],
                          alignment: .leading, spacing: 14) {
                    fact("Native to", o.nativeTo)
                    fact("Came home", Care.shortDate(came))
                    fact("From", o.source)
                    fact("Lives", plant.spot)
                }
            }
            .padding(20)
            .card(radius: 24)
            .padding(.horizontal, Tend.S.sideWide)

            Eyebrow(text: "Milestones").padding(.horizontal, Tend.S.side)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(miles.enumerated()), id: \.offset) { i, m in
                    let last = i == miles.count - 1
                    HStack(alignment: .top, spacing: 14) {
                        VStack(spacing: 6) {
                            Circle().fill(last ? Tend.C.brand : Tend.C.surface).frame(width: 11, height: 11)
                                .background(Circle().fill(last ? Tend.C.leaf(0.18) : Tend.C.ink(0.18)).frame(width: 19, height: 19))
                                .padding(.top, 4)
                            Rectangle().fill(Tend.C.ink(0.14)).frame(width: 1.5).opacity(last ? 0 : 1)
                        }
                        .frame(width: 14)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(m.0).font(Tend.F.mono(11)).foregroundStyle(Tend.C.text5)
                            Text(m.1).font(Tend.F.sans(15, .semibold)).foregroundStyle(Tend.C.text)
                            Text(m.2).font(Tend.F.sans(13)).lineSpacing(2).foregroundStyle(Tend.C.text4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.bottom, 20)
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(.horizontal, Tend.S.side)

            HStack(spacing: 10) {
                ShareLink(item: "\(plant.name)'s plant passport: \(plant.species), \(days) days together.") {
                    Text("Share passport")
                }
                .buttonStyle(PrimaryButtonStyle(kind: .outline, height: 50, fontSize: 15))
                Button("Ask about \(plant.name)") { model.push(.ask(plantId: plant.id)) }
                    .buttonStyle(PrimaryButtonStyle(height: 50, fontSize: 15))
            }
            .padding(.horizontal, Tend.S.side)
        }
    }

    private func fact(_ k: String, _ v: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(k.uppercased()).font(Tend.F.sans(11, .semibold)).tracking(1.1).foregroundStyle(Tend.C.text5)
            Text(v).font(Tend.F.sans(14, .medium)).lineSpacing(2).foregroundStyle(Tend.C.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func milestones(came: Date, source: String) -> [(String, String, String)] {
        var m: [(String, String, String)] = [
            (Care.shortDate(came), "Came home", source + "."),
            (Care.shortDate(came.addingTimeInterval(45 * 86400)), "First new leaf", "Settled in within six weeks."),
        ]
        if plant.id == "mon" { m.append(("12 Apr 2025", "Repotted", "Moved up to a 24 cm pot. Roots are reaching the drainage hole again.")) }
        if plant.id == "gol" { m.append(("3 Jun 2025", "Shared three cuttings", "Rooted in water and given to friends.")) }
        if plant.pest { m.append(("26 Oct 2026", "Spider mites caught early", model.treatActive ? "Treatment under way. New growth looks clean." : "Treatment plan ready to start.")) }
        m.append(("Today", "Week 44 photo", "\(plant.heights.last ?? 0) cm tall, \(plant.newLeaves) new leaves this season."))
        return m
    }
}

/// A horizontal line across the frame.
struct Line: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path(); p.move(to: CGPoint(x: r.minX, y: r.midY)); p.addLine(to: CGPoint(x: r.maxX, y: r.midY)); return p
    }
}
