import SwiftUI

/// The Sunday digest, also sent as a Sunday notification.
struct DigestView: View {
    @Environment(AppModel.self) var model
    @Environment(\.dismiss) var dismiss
    @State var grown = false

    var body: some View {
        let grew = model.plants
            .map { (name: $0.name, d: ($0.heights.last ?? 0) - ($0.heights.dropLast().last ?? 0)) }
            .sorted { $0.d > $1.d }
            .prefix(3)
        let gmax = max(1, grew.map(\.d).max() ?? 1)
        let top = grew.first
        let next = (1...3).map { i -> (String, String) in
            let names = model.plants.filter { $0.waterEvery - $0.daysSinceWater == i }.map(\.name)
            let label = Care.dayLabel(i).split(separator: " ").prefix(2).joined(separator: " ")
            return (label, names.isEmpty ? "Nothing due" : Care.listNames(names))
        }

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                BackPill(label: "Home").padding(.horizontal, Tend.S.sideWide)

                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow(text: "Sunday digest · 19 – 25 Oct")
                    ScreenTitle(text: "A good week. Figgy is on the mend.")
                }
                .padding(.horizontal, Tend.S.side)

                HStack(spacing: 8) {
                    stat("14", "drinks given", 0)
                    stat("+\(top?.d ?? 0) cm", "\(top?.name ?? "Goldie")'s growth", 1)
                    stat("1", "pest caught early", 2)
                }
                .padding(.horizontal, Tend.S.sideWide)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Care streak").font(Tend.F.sans(15, .semibold)).foregroundStyle(Tend.C.text)
                        Spacer()
                        Text("12 days").font(Tend.F.sans(13, .semibold)).foregroundStyle(Tend.C.accent)
                    }
                    HStack(spacing: 6) {
                        ForEach(Array(["M", "T", "W", "T", "F", "S", "S"].enumerated()), id: \.offset) { i, d in
                            VStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(i == 3 ? Tend.C.leaf(0.45) : Tend.C.brand)
                                    .frame(height: 30)
                                    .scaleEffect(x: 1, y: grown ? 1 : 0, anchor: .bottom)
                                    .animation(Tend.ease(0.5).delay(Double(i) * 0.05), value: grown)
                                Text(d).font(Tend.F.sans(11)).foregroundStyle(Tend.C.text5)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.vertical, 16).padding(.horizontal, 18)
                .card()
                .padding(.horizontal, Tend.S.sideWide)

                Eyebrow(text: "What grew").padding(.horizontal, Tend.S.side)
                VStack(spacing: 0) {
                    ForEach(Array(grew.enumerated()), id: \.offset) { i, g in
                        VStack(spacing: 0) {
                            if i > 0 { RowDivider(opacity: 0.1) }
                            HStack(spacing: 12) {
                                Text(g.name).font(Tend.F.sans(15, .semibold)).foregroundStyle(Tend.C.text).frame(width: 96, alignment: .leading)
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Tend.C.ink(0.08))
                                        Capsule().fill(Tend.C.brand)
                                            .frame(width: geo.size.width * max(0.08, Double(g.d) / Double(gmax)))
                                            .scaleEffect(x: grown ? 1 : 0, y: 1, anchor: .leading)
                                            .animation(Tend.ease(0.7), value: grown)
                                    }
                                }
                                .frame(height: 8)
                                Text("+\(g.d) cm").font(Tend.F.mono(13)).foregroundStyle(Tend.C.brandInk).frame(width: 48, alignment: .trailing)
                            }
                            .padding(.vertical, 12)
                        }
                    }
                }
                .padding(.vertical, 6).padding(.horizontal, 18)
                .card()
                .padding(.horizontal, Tend.S.sideWide)

                Eyebrow(text: "Saved this week").padding(.horizontal, Tend.S.side)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Figgy · spider mites").font(Tend.F.serif(20)).foregroundStyle(Tend.C.text)
                    Text("Caught on the lower leaves before they spread. New growth looks clean. Next neem round is Monday.")
                        .font(Tend.F.sans(14)).lineSpacing(3).foregroundStyle(Tend.C.text3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 16).padding(.horizontal, 18)
                .background(Tend.C.clayTint(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Tend.C.clayTint(0.2), lineWidth: 1))
                .padding(.horizontal, Tend.S.sideWide)

                Eyebrow(text: "Coming up").padding(.horizontal, Tend.S.side)
                VStack(spacing: 0) {
                    ForEach(Array(next.enumerated()), id: \.offset) { i, n in
                        VStack(spacing: 0) {
                            if i > 0 { RowDivider(opacity: 0.1) }
                            HStack(alignment: .top, spacing: 12) {
                                Text(n.0).font(Tend.F.sans(14, .semibold)).foregroundStyle(Tend.C.text)
                                Spacer()
                                Text(n.1).font(Tend.F.sans(14)).foregroundStyle(Tend.C.text3).multilineTextAlignment(.trailing)
                            }
                            .padding(.vertical, 12)
                        }
                    }
                }
                .padding(.vertical, 4).padding(.horizontal, 18)
                .card()
                .padding(.horizontal, Tend.S.sideWide)

                HStack(spacing: 10) {
                    ShareLink(item: "My week in plants: 14 drinks given, \(top?.name ?? "Goldie") grew \(top?.d ?? 0) cm, Figgy is on the mend.") {
                        Text("Share week")
                    }
                    .buttonStyle(PrimaryButtonStyle(kind: .outline))
                    Button("Done") { dismiss() }.buttonStyle(PrimaryButtonStyle())
                }
                .padding(.horizontal, Tend.S.side)
            }
            .padding(.top, 8).padding(.bottom, 40)
            .entrance()
        }
        .tendScreen()
        .onAppear { grown = true }
    }

    private func stat(_ n: String, _ l: String, _ i: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(n).font(Tend.F.serif(30)).foregroundStyle(Tend.C.text).lineLimit(1).minimumScaleFactor(0.7)
            Text(l).font(Tend.F.sans(12)).lineSpacing(2).foregroundStyle(Tend.C.text4)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14).padding(.horizontal, 12)
        .card(radius: 18)
        .rise(delay: Double(i) * 0.07)
    }
}
