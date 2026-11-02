import SwiftUI

struct EnvironmentView: View {
    @Environment(AppModel.self) var model

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                BackPill(label: "Home").padding(.horizontal, Tend.S.sideWide)

                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow(text: "Live · updated just now", color: Tend.C.accent, dot: true)
                    ScreenTitle(text: "Your home, room by room.")
                    TintPillButton(title: "Measure a spot with your camera", height: 42, filledSurface: true, leading: { SunIcon() }) {
                        model.push(.lightMeter)
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal, Tend.S.side)

                ForEach(model.suggestions) { s in
                    SuggestionCard(suggestion: s).padding(.horizontal, Tend.S.sideWide)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }

                ForEach(Array(Room.order.enumerated()), id: \.element) { i, room in
                    RoomDetailCard(room: room, offset: i).padding(.horizontal, Tend.S.sideWide)
                }
            }
            .padding(.top, 8).padding(.bottom, 40)
            .animation(Tend.ease, value: model.suggestions)
            .entrance()
        }
        .tendScreen()
    }
}

private struct RoomDetailCard: View {
    let room: String
    let offset: Int
    @Environment(AppModel.self) var model

    var body: some View {
        let v = model.env(room, offset: offset)
        let ps = model.plants.filter { $0.room == room }
        let issues = ps.filter { model.health($0).kind != .good && !$0.pest }
        let note: String = issues.isEmpty
            ? (ps.isEmpty ? (room == "Bathroom" ? "Best humidity in your home, ideal for ferns and calatheas." : "") : "Everyone here is comfortable.")
            : "\(Care.listNames(issues.map(\.name))) \(issues.count > 1 ? "are" : "is") outside their comfort range here."
        let metrics: [(String, String, Double, Color)] = [
            ("Temp", model.temp(v.temperature, decimals: 1), min(1, v.temperature / 30), v.temperature < 12 ? Tend.C.clay : Tend.C.accent),
            ("Humidity", "\(Int(v.humidity))%", v.humidity / 100, v.humidity < 50 ? Tend.C.amber : Tend.C.accent),
            ("Light", Care.fmtLux(v.lux), min(1, v.lux / 25000), v.lux < 2000 ? Tend.C.amber : Tend.C.accent),
        ]

        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(room).font(Tend.F.serif(22)).foregroundStyle(Tend.C.text)
                Spacer()
                Text(ps.isEmpty ? "No plants yet" : ps.map(\.name).joined(separator: ", "))
                    .font(Tend.F.sans(12)).foregroundStyle(Tend.C.text4).lineLimit(1)
            }
            HStack(alignment: .top, spacing: 10) {
                ForEach(metrics, id: \.0) { m in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(m.0).font(Tend.F.sans(11)).foregroundStyle(Tend.C.text5)
                        Text(m.1).font(Tend.F.mono(15)).foregroundStyle(Tend.C.text)
                            .contentTransition(.numericText()).lineLimit(1).minimumScaleFactor(0.8)
                        BarMeter(fraction: m.2, color: m.3, track: Tend.C.ink(0.09), glow: m.3.opacity(0.8))
                            .animation(Tend.ease(0.8), value: m.2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            if !note.isEmpty {
                Text(note).font(Tend.F.sans(13)).foregroundStyle(issues.isEmpty ? Tend.C.text4 : Tend.C.amber)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 16).padding(.horizontal, 18)
        .card()
    }
}

// MARK: Light meter

struct LightMeterView: View {
    @Environment(AppModel.self) var model
    @State var camera = CameraController()
    @State var room = "Living room"

    var body: some View {
        // Live camera estimate when available; otherwise the room's sensor reading.
        let lux = camera.lux ?? model.env(room, offset: 3).lux
        let tier = lux < 1000 ? "Low light" : lux < 5000 ? "Medium" : lux < 15000 ? "Bright indirect" : "Direct sun"
        let pos = max(0.03, min(0.97, (log10(max(lux, 100)) - 2) / (log10(50000) - 2)))
        let fits = model.plants
            .map { p -> (Plant, Bool) in (p, Care.inRange(lux, p.light)) }
            .sorted { $0.1 && !$1.1 }
            .prefix(5)

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                BackPill(label: "Rooms").padding(.horizontal, Tend.S.sideWide)

                VStack(alignment: .leading, spacing: 6) {
                    Eyebrow(text: "Light meter")
                    ScreenTitle(text: "How bright is this spot?")
                }
                .padding(.horizontal, Tend.S.side)

                ChipRow {
                    ForEach(Room.order, id: \.self) { r in
                        Chip(r, selected: room == r) { room = r; model.buzz(.selection) }
                    }
                }

                ZStack {
                    StripedPlaceholder(label: "", stripe: 7, palette: .wide, radius: 0)
                    if camera.status == .running { CameraPreview(session: camera.session) }
                    RadialGradient(colors: [Color(red: 1, green: 236 / 255, blue: 170 / 255).opacity(min(0.85, lux / 25000)), .clear],
                                   center: UnitPoint(x: 0.7, y: 0.2), startRadius: 0, endRadius: 260)
                        .animation(.easeOut(duration: 0.8), value: lux)
                    Reticle()
                    VStack {
                        HStack {
                            HStack(spacing: 7) {
                                BlinkDot()
                                Text("LIVE · CAMERA").font(Tend.F.mono(10)).tracking(0.6).foregroundStyle(Tend.C.text3)
                            }
                            .padding(.horizontal, 11).frame(height: 28)
                            .background(Color(lightRGB: 0xFFFCF5, lightAlpha: 0.88, darkRGB: 0x172017, darkAlpha: 0.88), in: Capsule())
                            Spacer()
                        }
                        Spacer()
                        HStack(alignment: .bottom) {
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text(Int(lux.rounded()).formatted(.number.locale(Care.gb))).font(Tend.F.serif(48)).foregroundStyle(Tend.C.text)
                                    .contentTransition(.numericText())
                                Text("lux").font(Tend.F.sans(14)).foregroundStyle(Tend.C.text3)
                            }
                            Spacer()
                            Text(tier).font(Tend.F.sans(13, .semibold)).foregroundStyle(Tend.C.onInverse)
                                .padding(.horizontal, 12).frame(height: 30).background(Tend.C.inverse, in: Capsule())
                        }
                    }
                    .padding(16)
                }
                .frame(height: 280)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .padding(.horizontal, Tend.S.sideWide)

                VStack(spacing: 8) {
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule().fill(LinearGradient(stops: [.init(color: Color(hex: 0x4A5944), location: 0),
                                                                  .init(color: Color(hex: 0x8DB07A), location: 0.35),
                                                                  .init(color: Color(hex: 0xD7C27A), location: 0.7),
                                                                  .init(color: Color(hex: 0xE8A15C), location: 1)],
                                                          startPoint: .leading, endPoint: .trailing))
                                .frame(height: 10)
                            Circle().fill(Tend.C.surface).overlay(Circle().strokeBorder(Tend.C.text, lineWidth: 2))
                                .frame(width: 20, height: 20)
                                .offset(x: g.size.width * pos - 10)
                                .animation(Tend.ease(0.8), value: pos)
                        }
                        .frame(height: 20)
                    }
                    .frame(height: 20)
                    HStack {
                        Text("Low"); Spacer(); Text("Medium"); Spacer(); Text("Bright indirect"); Spacer(); Text("Direct sun")
                    }
                    .font(Tend.F.sans(11, .semibold)).foregroundStyle(Tend.C.text5)
                }
                .padding(.horizontal, Tend.S.side)

                Eyebrow(text: "Who'd be happy here").padding(.horizontal, Tend.S.side)

                VStack(spacing: 0) {
                    ForEach(Array(fits.enumerated()), id: \.element.0.id) { i, f in
                        let (p, ok) = f
                        let color = ok ? Tend.C.accent : Tend.C.amber
                        VStack(spacing: 0) {
                            if i > 0 { RowDivider(opacity: 0.1) }
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(p.name).font(Tend.F.sans(15, .semibold)).foregroundStyle(Tend.C.text)
                                    Text(p.species).font(Tend.F.sans(12)).foregroundStyle(Tend.C.text4)
                                }
                                Spacer()
                                HStack(spacing: 6) {
                                    Circle().fill(color).frame(width: 6, height: 6)
                                    Text(ok ? "Thrives here" : lux < p.light.lowerBound ? "Too dim" : "Too bright")
                                }
                                .font(Tend.F.sans(13, .semibold)).foregroundStyle(color)
                            }
                            .padding(.vertical, 12)
                        }
                    }
                }
                .padding(.vertical, 4).padding(.horizontal, 16)
                .card()
                .padding(.horizontal, Tend.S.sideWide)

                Button("Save reading to \(room)") {
                    model.buzz(.success)
                    model.showToast("Saved. \(room) gets about \(Care.fmtLux(lux)) at this spot.")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Tend.S.side)
            }
            .padding(.top, 8).padding(.bottom, 40)
            .entrance()
        }
        .tendScreen()
        .task { await camera.start() }
        .onDisappear { camera.stop() }
    }
}

private struct Reticle: View {
    @State var on = false
    var body: some View {
        Circle().strokeBorder(Tend.C.ink(0.45), lineWidth: 1.5)
            .background(Circle().stroke(.white.opacity(0.6), lineWidth: 1).padding(-1))
            .overlay(Circle().fill(Tend.C.brandButton).frame(width: 6, height: 6))
            .frame(width: 120, height: 120)
            .scaleEffect(on ? 1.06 : 1).opacity(on ? 1 : 0.8)
            .onAppear { withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { on = true } }
    }
}

private struct BlinkDot: View {
    @State var on = false
    var body: some View {
        Circle().fill(Tend.C.clay).frame(width: 6, height: 6)
            .opacity(on ? 1 : 0.55)
            .onAppear { withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { on = true } }
    }
}
