import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) var model
    @Environment(\.openURL) var openURL

    var body: some View {
        @Bindable var model = model

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                BackPill(label: "Home").padding(.horizontal, Tend.S.sideWide)
                ScreenTitle(text: "Settings").padding(.horizontal, Tend.S.side)

                // Profile
                HStack(spacing: 14) {
                    StripedPlaceholder(label: "photo", stripe: 5, labelSize: 7, circle: true).frame(width: 54, height: 54)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Alex Moreno").font(Tend.F.serif(22)).foregroundStyle(Tend.C.text)
                        Text(planLine).font(Tend.F.sans(13)).foregroundStyle(Tend.C.text4)
                    }
                    Spacer(minLength: 0)
                    Text(model.isPremium ? "PREMIUM" : "FREE").font(Tend.F.sans(12, .bold))
                        .foregroundStyle(model.isPremium ? Tend.C.brandInk : Tend.C.text3)
                        .padding(.horizontal, 10).frame(height: 26)
                        .background(model.isPremium ? Tend.C.leaf(0.24) : Tend.C.ink(0.1), in: Capsule())
                }
                .padding(16)
                .card(radius: 22)
                .padding(.horizontal, Tend.S.sideWide)

                if !model.isPremium { upsell.padding(.horizontal, Tend.S.sideWide) }

                group("Reminders") {
                    toggle("Daily care reminder", "One notification, only when something is due", $model.prefs.daily)
                    linkRow("Reminder time", value: model.remind.time) { model.remind = model.remind.next }
                    toggle("Weather alerts", "Frost and heat warnings for outdoor plants", $model.prefs.weather)
                    toggle("Pause while I'm away", "Your sitter gets the reminders instead", $model.prefs.smartPause, last: true)
                }

                group("Plant care") {
                    segRow("Experience", [(Level.new, "Learning"), (.mid, "Confident")], $model.level)
                    toggle("Sensor alerts", "When moisture, light or humidity leaves range", $model.prefs.sensorAlerts)
                    linkRow("Connected sensors", value: "3 active") {}
                    linkRow("Rooms", value: "5 rooms", last: true) {}
                }

                group("Experience") {
                    toggle("Haptic feedback", "Subtle taps when you finish care or switch tabs", $model.prefs.haptics)
                    linkRow("Appearance", value: "Light · Dark") { model.showToast("Tend follows your iPhone's appearance.") }
                    linkRow("Widgets & Live Activities", value: "") { model.push(.widgets) }
                    linkRow("Weekly digest", value: "Sundays") { model.push(.digest) }
                    linkRow("Empty & error states", value: "", last: true) { model.push(.states) }
                }

                group("Units") {
                    segRow("Temperature", [(false, "°C"), (true, "°F")], $model.prefs.fahrenheit)
                    segRow("Water", [(false, "ml"), (true, "fl oz")], $model.prefs.fluidOunces, last: true)
                }

                group("Account") {
                    linkRow("Subscription", value: model.premium == .lifetime ? "Lifetime" : model.premium == .monthly ? "Monthly" : "Free") {
                        if model.premium == .monthly, let url = URL(string: "https://apps.apple.com/account/subscriptions") { openURL(url) }
                        else { model.openPremium() }
                    }
                    toggle("Sitter check-ins", "Notify me when a sitter ticks off a plant", $model.prefs.sitterUpdates)
                    linkRow("Export plant data", value: "CSV") {}
                    linkRow("Help & support", value: "") {}
                    linkRow("Terms of service", value: "") { model.push(.legal(.terms)) }
                    linkRow("Privacy policy", value: "", last: true) { model.push(.legal(.privacy)) }
                }

                VStack(spacing: 6) {
                    TextLinkButton(title: "Sign out", color: Tend.C.clay, weight: .semibold) { model.signOut() }
                    Text("TEND 2.0.1 · BUILD 418").font(Tend.F.mono(10)).foregroundStyle(Tend.C.muted)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 8).padding(.bottom, 40)
            .entrance()
        }
        .tendScreen()
        .onChange(of: model.prefs.daily) { Task { await Notifications.schedule(model) } }
    }

    private var planLine: String {
        switch model.premium {
        case .lifetime: "Premium · Lifetime access"
        case .monthly: "Premium · Renews monthly"
        case nil: "Free plan · \(model.scansLeft) of 3 scans left"
        }
    }

    private var upsell: some View {
        Button { model.openPremium() } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text("TEND PREMIUM").font(Tend.F.sans(11, .bold)).tracking(1.5).foregroundStyle(Tend.C.creamLabel)
                Text("Unlimited scans, live sensors and growth timelapses.").font(Tend.F.serif(24)).lineSpacing(2)
                    .foregroundStyle(Tend.C.cream).multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Text("From $4.99 a month").font(Tend.F.sans(14)).foregroundStyle(Color(hex: 0xE8F1E0))
                    Spacer()
                    Text("See plans").font(Tend.F.sans(14, .bold)).foregroundStyle(Color(hex: 0x1F2B1C))
                        .padding(.horizontal, 14).frame(height: 34)
                        .background(Color(hex: 0xF4F0E6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(alignment: .topTrailing) {
                ZStack(alignment: .topTrailing) {
                    Tend.C.deepGradient
                    RadialGradient(colors: [Tend.C.leaf(0.35), .clear], center: .center, startRadius: 0, endRadius: 83)
                        .frame(width: 180, height: 180).offset(x: 40, y: -60)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Tend.C.leaf(0.3), lineWidth: 1))
            .shadow(color: Tend.C.leaf(0.18), radius: 20)
            .contentShape(Rectangle())
        }
        .buttonStyle(LiftButtonStyle())
    }

    // MARK: Row builders

    private func group<Content: View>(_ title: String, @ViewBuilder _ rows: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: title).padding(.horizontal, 28)
            VStack(spacing: 0) { rows() }
                .card()
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, Tend.S.sideWide)
        }
    }

    private func label(_ title: String, _ sub: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(Tend.F.sans(15, .medium)).foregroundStyle(Tend.C.text)
            if let sub { Text(sub).font(Tend.F.sans(12)).foregroundStyle(Tend.C.text4) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row<Content: View>(last: Bool, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
                .padding(.vertical, 10).padding(.horizontal, 16)
                .frame(minHeight: 56)
            if !last { RowDivider() }
        }
    }

    private func toggle(_ title: String, _ sub: String, _ on: Binding<Bool>, last: Bool = false) -> some View {
        row(last: last) {
            Toggle(isOn: Binding(get: { on.wrappedValue }, set: { on.wrappedValue = $0; model.buzz(.light) })) {
                label(title, sub)
            }
            .toggleStyle(TendToggleStyle())
        }
    }

    private func linkRow(_ title: String, value: String, last: Bool = false, action: @escaping () -> Void) -> some View {
        row(last: last) {
            Button(action: action) {
                HStack(spacing: 12) {
                    label(title, nil)
                    HStack(spacing: 8) {
                        if !value.isEmpty { Text(value) }
                        Text("›").font(Tend.F.sans(18))
                    }
                    .font(Tend.F.sans(14)).foregroundStyle(Tend.C.text4)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func segRow<T: Hashable>(_ title: String, _ opts: [(T, String)], _ sel: Binding<T>, last: Bool = false) -> some View {
        row(last: last) {
            HStack(spacing: 12) {
                label(title, nil)
                SegmentedPicker(options: opts, selection: sel, height: 28, radius: 10, innerRadius: 8, fontSize: 13,
                                stretch: false, track: Tend.C.bg)
            }
        }
    }
}
