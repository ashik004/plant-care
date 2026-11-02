import SwiftUI

/// In-app preview of the widgets and Live Activity (the real ones live in TendWidgets).
struct WidgetsGalleryView: View {
    @Environment(AppModel.self) var model

    var body: some View {
        let s = CollectionSummary.from(model.plants, treating: model.treatActive)
        let count = s.thirsty.isEmpty ? "ALL GOOD" : "\(s.thirsty.count) THIRSTY"

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                BackPill(label: "Settings").padding(.horizontal, Tend.S.sideWide)
                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow(text: "Outside the app")
                    ScreenTitle(text: "Widgets & Live Activities.")
                }
                .padding(.horizontal, Tend.S.side)

                Eyebrow(text: "Lock Screen").padding(.horizontal, Tend.S.side)
                VStack(spacing: 14) {
                    VStack(spacing: 0) {
                        Text(Date.now.formatted(.dateTime.locale(Care.gb).weekday(.wide).day().month(.wide)))
                            .font(.system(size: 14, weight: .semibold)).opacity(0.85)
                        Text("9:41").font(.system(size: 76, weight: .semibold)).tracking(-1.5)
                    }
                    HStack(spacing: 10) {
                        ZStack {
                            Circle().fill(.white.opacity(0.14))
                            HealthRing(fraction: Double(s.healthPercent) / 100, size: 62, lineWidth: 5,
                                       track: .white.opacity(0.2), color: Color(hex: 0xF4F0E6), glow: false)
                            Text("\(s.healthPercent)%").font(.system(size: 18, weight: .bold))
                        }
                        .frame(width: 62, height: 62)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TEND · \(count)").font(.system(size: 11, weight: .bold)).tracking(0.9).opacity(0.8)
                            Text(s.thirsty.isEmpty ? "Nothing due today" : Care.listNames(s.thirsty))
                                .font(.system(size: 14, weight: .semibold)).lineLimit(2)
                        }
                        .frame(maxWidth: 220, alignment: .leading)
                        .padding(.vertical, 10).padding(.horizontal, 14)
                        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    TreatmentActivityPreview().padding(.top, 28)
                }
                .foregroundStyle(Color(hex: 0xF4F0E6))
                .padding(.top, 22).padding(.horizontal, 18).padding(.bottom, 18)
                .frame(maxWidth: .infinity)
                .background(LinearGradient.angle(165, stops: [.init(color: Color(light: 0x3A6E33, dark: 0x3E8A3A), location: 0),
                                                              .init(color: Color(light: 0x1C3618, dark: 0x15301A), location: 0.62),
                                                              .init(color: Color(hex: 0x14240F), location: 1)]),
                            in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .padding(.horizontal, Tend.S.sideWide)

                Eyebrow(text: "Dynamic Island").padding(.horizontal, Tend.S.side)
                HStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Tend.C.brand).frame(width: 20, height: 20)
                    Spacer()
                    HStack(spacing: 6) {
                        ProgressCapsule(fraction: 0.4).frame(width: 44, height: 4)
                        Text("2/5").font(.system(size: 13, weight: .semibold))
                    }
                }
                .foregroundStyle(Color(hex: 0xF4F0E6))
                .padding(.leading, 10).padding(.trailing, 14)
                .frame(width: 240, height: 38)
                .background(Color(hex: 0x0B0F0A), in: Capsule())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
                .card()
                .padding(.horizontal, Tend.S.sideWide)

                Eyebrow(text: "Home Screen").padding(.horizontal, Tend.S.side)
                HStack(spacing: 12) {
                    ThirstyWidgetFace(summary: s)
                        .aspectRatio(1, contentMode: .fit)
                        .padding(14)
                        .card(radius: 24)
                        .shadow(color: Tend.C.shadow.opacity(0.35), radius: 12, y: 10)
                    HealthWidgetFace(summary: s)
                        .aspectRatio(1, contentMode: .fit)
                        .padding(14)
                        .background(Tend.C.deepGradient, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(color: Tend.C.shadow.opacity(0.5), radius: 12, y: 10)
                }
                .padding(.horizontal, Tend.S.sideWide)

                Button("Add a widget") {
                    model.showToast("Touch and hold your Home Screen, tap Edit, then Add Widget and search Tend.")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Tend.S.side)
            }
            .padding(.top, 8).padding(.bottom, 40)
            .entrance()
        }
        .tendScreen()
    }
}

// MARK: - States

struct StatesView: View {
    enum Kind: Hashable { case empty, blurry, offline }
    @Environment(AppModel.self) var model
    @State var kind: Kind = .empty

    var body: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    BackPill(label: "Home").padding(.horizontal, Tend.S.sideWide)
                    SegmentedPicker(options: [(Kind.empty, "No plants"), (.blurry, "Blurry scan"), (.offline, "Offline")], selection: $kind)
                        .padding(.horizontal, Tend.S.side)
                    Group {
                        switch kind {
                        case .empty: empty
                        case .blurry: blurry
                        case .offline: offline
                        }
                    }
                    .id(kind)
                    .entrance()
                    .frame(maxHeight: .infinity, alignment: .top)
                }
                .padding(.top, 8).padding(.bottom, 20)
                .frame(minHeight: geo.size.height, alignment: .top)
            }
        }
        .tendScreen()
    }

    private var empty: some View {
        VStack(spacing: 14) {
            EmptyPotIllustration()
            Text("Your shelf is waiting.").font(Tend.F.serif(34)).foregroundStyle(Tend.C.text)
            Text("Scan your first plant and Tend will set up its care plan in under a minute.")
                .font(Tend.F.sans(15)).lineSpacing(4).foregroundStyle(Tend.C.text3)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 20)
            VStack(spacing: 6) {
                Button("Scan your first plant") { model.openScan(.identify) }.buttonStyle(PrimaryButtonStyle())
                TextLinkButton(title: "Add by name instead") { model.showToast("Search by name opens here.") }
            }
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 30).padding(.top, 20)
        .frame(maxHeight: .infinity)
    }

    private var blurry: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottom) {
                Stripes(a: Color(light: 0xDCE6CF, dark: 0x1C261B), b: Tend.C.stripeWideB, width: 7)
                    .blur(radius: 5).padding(-10)
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Tend.C.clayTint(0.7), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .padding(.vertical, 50).padding(.horizontal, 40)
                HStack(spacing: 12) {
                    Text("!").font(Tend.F.sans(18, .bold)).foregroundStyle(Tend.C.clay)
                        .frame(width: 36, height: 36).background(Tend.C.clayTint(0.14), in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Too blurry to read").font(Tend.F.sans(15, .semibold)).foregroundStyle(Tend.C.text)
                        Text("This one didn't use a scan.").font(Tend.F.sans(13)).foregroundStyle(Tend.C.text3)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 14).padding(.horizontal, 16)
                .background(Color(lightRGB: 0xFFFCF5, lightAlpha: 0.92, darkRGB: 0x172017, darkAlpha: 0.92),
                            in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(16)
            }
            .frame(height: 330)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            VStack(spacing: 0) {
                ForEach(Array(["Hold still for a second before tapping", "Tap a leaf on screen to focus", "Move nearer a window for softer light"].enumerated()), id: \.offset) { i, t in
                    VStack(spacing: 0) {
                        if i > 0 { RowDivider(opacity: 0.1) }
                        HStack(spacing: 12) {
                            Text("\(i + 1)").font(Tend.F.sans(12, .bold)).foregroundStyle(Tend.C.brandInk)
                                .frame(width: 24, height: 24).background(Tend.C.leaf(0.14), in: Circle())
                            Text(t).font(Tend.F.sans(14)).foregroundStyle(Tend.C.text)
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 12)
                    }
                }
            }
            .padding(.vertical, 4).padding(.horizontal, 18)
            .card()

            Spacer(minLength: 20)
            Button("Retake photo") { model.openScan(.identify) }.buttonStyle(PrimaryButtonStyle())
        }
        .padding(.horizontal, Tend.S.sideWide)
        .frame(maxHeight: .infinity)
    }

    private var offline: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                LineIcon(d: Icon.offline, color: Tend.C.onInverse, size: 22)
                VStack(alignment: .leading, spacing: 1) {
                    Text("You're offline").font(Tend.F.sans(15, .semibold))
                    Text("Showing readings from 9:12").font(Tend.F.sans(13)).opacity(0.75)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(Tend.C.onInverse)
            .padding(.vertical, 14).padding(.horizontal, 16)
            .background(Tend.C.inverse, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(["Living room", "Bedroom", "Kitchen", "Balcony"], id: \.self) { RoomCard(room: $0, offline: true) }
            }

            Text("Reminders still arrive on time. Scans and Ask Tend need a connection. Anything you log now syncs when you're back.")
                .font(Tend.F.sans(14)).lineSpacing(4).foregroundStyle(Tend.C.text3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 6)

            Spacer(minLength: 20)
            Button("Try again") {
                model.buzz(.warning)
                model.showToast("Still offline. Tend will retry automatically.")
            }
            .buttonStyle(PrimaryButtonStyle(kind: .outline))
        }
        .padding(.horizontal, Tend.S.sideWide)
        .frame(maxHeight: .infinity)
    }
}
