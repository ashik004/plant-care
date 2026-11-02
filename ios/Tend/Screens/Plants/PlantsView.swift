import SwiftUI

struct PlantsView: View {
    @Environment(AppModel.self) var model

    var body: some View {
        @Bindable var model = model
        let shown = model.plants.filter { model.roomFilter == "All" || $0.room == model.roomFilter }

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .bottom, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow(text: "\(model.plants.count) plants · \(Set(model.plants.map(\.room)).count) rooms")
                        ScreenTitle(text: "Your collection")
                    }
                    Spacer(minLength: 0)
                    SegmentedPicker(options: [(false, "Grid"), (true, "Moisture")], selection: $model.shelfView,
                                    height: 32, radius: 999, innerRadius: 999, fontSize: 13, stretch: false)
                }
                .padding(.horizontal, Tend.S.side)

                ChipRow {
                    ForEach(["All"] + model.rooms, id: \.self) { r in
                        Chip(r, selected: model.roomFilter == r) {
                            withAnimation(Tend.ease) { model.roomFilter = r }
                        }
                    }
                }

                if model.shelfView {
                    ShelfView(plants: shown).entrance().id("shelf")
                } else {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(Array(shown.enumerated()), id: \.element.id) { i, p in
                            PlantCard(plant: p).rise(delay: Double(i) * 0.05)
                        }
                    }
                    .padding(.horizontal, Tend.S.side)
                    .entrance()
                    .id("grid-\(model.roomFilter)")
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 40)
            .entrance()
        }
        .tendScreen(hideTabBar: false)
    }
}

private extension Plant {
    var waterStatus: String {
        let d = waterEvery - daysSinceWater
        return d <= 0 ? "Thirsty now" : d == 1 ? "Water tomorrow" : "Water in \(d) days"
    }
}

private struct PlantCard: View {
    let plant: Plant
    @Environment(AppModel.self) var model

    var body: some View {
        let h = model.health(plant)
        let m = Care.moisture(plant)
        let low = m < 0.25
        let color = low ? Tend.C.clay : Tend.C.accent

        Button { model.push(.detail(plantId: plant.id, tab: .health)) } label: {
            VStack(alignment: .leading, spacing: 10) {
                StripedPlaceholder(label: plant.species, radius: 14, labelSize: 8.5, alignment: .bottomLeading)
                    .frame(height: 150)
                    .overlay(alignment: .topLeading) {
                        HStack(spacing: 5) {
                            Circle().fill(h.color).frame(width: 6, height: 6)
                            Text(h.label).font(Tend.F.sans(11, .semibold))
                        }
                        .foregroundStyle(h.color)
                        .padding(.horizontal, 8).frame(height: 22)
                        .background(Color(lightRGB: 0xF4F0E6, lightAlpha: 0.75, darkRGB: 0x0F140E, darkAlpha: 0.75), in: Capsule())
                        .padding(8)
                    }
                VStack(alignment: .leading, spacing: 6) {
                    Text(plant.name).font(Tend.F.serif(21)).foregroundStyle(Tend.C.text).lineLimit(1)
                    Text(plant.waterStatus).font(Tend.F.sans(12, .semibold)).foregroundStyle(color)
                    BarMeter(fraction: m, color: color, glow: low ? Tend.C.clayTint(0.4) : Tend.C.leaf(0.35))
                }
                .padding(.horizontal, 6)
            }
            .padding(.top, 8).padding(.horizontal, 8).padding(.bottom, 14)
            .card()
            .contentShape(Rectangle())
        }
        .buttonStyle(LiftButtonStyle())
    }
}

/// Moisture shelf: vertical stems whose fill equals soil moisture.
private struct ShelfView: View {
    let plants: [Plant]
    @Environment(AppModel.self) var model
    @State var filled = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 18) {
                    ForEach(plants) { p in
                        let m = Care.moisture(p)
                        let low = m < 0.25
                        let c1 = low ? Tend.C.clay : Tend.C.accent
                        let c2 = low ? Color(hex: 0x9A4A2A) : Tend.C.brandButton
                        Button { model.push(.detail(plantId: p.id, tab: .health)) } label: {
                            VStack(spacing: 10) {
                                Text("\(Int((m * 100).rounded()))%").font(Tend.F.mono(11)).foregroundStyle(c1)
                                ZStack(alignment: .bottom) {
                                    RoundedRectangle(cornerRadius: 23, style: .continuous).fill(Tend.C.surface)
                                        .overlay(RoundedRectangle(cornerRadius: 23, style: .continuous).stroke(Tend.C.ink(0.08), lineWidth: 1))
                                    GeometryReader { g in
                                        VStack {
                                            Spacer(minLength: 0)
                                            RoundedRectangle(cornerRadius: 19, style: .continuous)
                                                .fill(LinearGradient(colors: [c1, c2], startPoint: .bottom, endPoint: .top))
                                                .frame(height: filled ? max(g.size.height * max(0.06, m) - 8, 4) : 4)
                                                .shadow(color: low ? Tend.C.clayTint(0.4) : Tend.C.leaf(0.35), radius: 12)
                                        }
                                        .padding(4)
                                    }
                                }
                                .frame(width: 46, height: 260)
                                Text(p.shortName).font(Tend.F.serif(16)).foregroundStyle(Tend.C.text)
                                    .multilineTextAlignment(.center).lineLimit(2)
                            }
                            .frame(width: 62)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(p.name), soil moisture \(Int(m * 100)) percent")
                    }
                }
                .padding(.horizontal, Tend.S.side).padding(.top, 10).padding(.bottom, 4)
            }
            Text("Live soil moisture from each plant's sensor or schedule. Tap a stem for details.")
                .font(Tend.F.sans(13)).lineSpacing(3).foregroundStyle(Tend.C.text4)
                .padding(.horizontal, Tend.S.side)
        }
        .onAppear { withAnimation(Tend.ease(1)) { filled = true } }
    }
}
