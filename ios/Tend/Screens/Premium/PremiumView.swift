import SwiftUI

struct PremiumView: View {
    @Environment(AppModel.self) var model
    @Environment(Store.self) var store
    @Environment(\.dismiss) var dismiss
    @State var plan: PremiumPlan = .lifetime
    @State var bought = false
    @State var legal: LegalKind?

    var body: some View {
        ZStack {
            Tend.C.bg.ignoresSafeArea()
            RadialGradient(colors: [Tend.C.leaf(0.28), .clear], center: .top, startRadius: 0, endRadius: 360)
                .scaleEffect(x: 1.2, y: 0.6, anchor: .top)
                .ignoresSafeArea()
            if bought { success.transition(.opacity) } else { paywall.transition(.opacity) }
        }
        .animation(.easeInOut(duration: 0.3), value: bought)
        .sheet(item: $legal) { kind in
            NavigationStack { LegalView(initial: kind) }
        }
    }

    private var paywall: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                HStack {
                    Button { dismiss() } label: {
                        Text("✕").font(Tend.F.sans(18)).foregroundStyle(Tend.C.text)
                            .frame(width: 40, height: 40)
                            .background(Color(lightRGB: 0xF4F0E6, lightAlpha: 0.5, darkRGB: 0x0F140E, darkAlpha: 0.5), in: Circle())
                            .overlay(Circle().stroke(Tend.C.ink(0.16), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close")
                    Spacer()
                    TextLinkButton(title: store.restoring ? "Checking…" : "Restore", size: 14, action: restore)
                }

                VStack(spacing: 14) {
                    AppMark()
                    Text("TEND PREMIUM").font(Tend.F.sans(12, .bold)).tracking(1.9).foregroundStyle(Tend.C.accent)
                    ScreenTitle(text: "Grow with an expert beside you.").multilineTextAlignment(.center)
                }
                .padding(.top, 4)

                VStack(alignment: .leading, spacing: 2) {
                    ForEach(SampleData.premiumFeatures, id: \.title) { f in
                        HStack(alignment: .top, spacing: 14) {
                            Text("✓").font(Tend.F.sans(12, .bold)).foregroundStyle(Tend.C.brandInk)
                                .frame(width: 22, height: 22)
                                .background(Tend.C.leaf(0.28), in: Circle())
                                .shadow(color: Tend.C.leaf(0.16), radius: 5)
                                .padding(.top, 2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(f.title).font(Tend.F.sans(15, .semibold)).foregroundStyle(Tend.C.text)
                                Text(f.sub).font(Tend.F.sans(13)).foregroundStyle(Tend.C.text4)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 9)
                    }
                }
                .padding(.vertical, 6).padding(.horizontal, 4)

                VStack(spacing: 10) {
                    planCard(.lifetime, name: "Lifetime", sub: "Pay once. Yours forever.", per: "one-time", badge: "BEST VALUE")
                    planCard(.monthly, name: "Monthly", sub: "7-day free trial, cancel anytime", per: "per month", badge: nil)
                }
                .padding(.top, 11)

                VStack(spacing: 10) {
                    Button(store.purchasing ? "Confirming…" : plan == .lifetime ? "Unlock Lifetime · \(store.price(.lifetime))" : "Start 7-day free trial", action: buy)
                        .buttonStyle(PrimaryButtonStyle(kind: .premium, height: 58, fontSize: 17))
                    Text(plan == .lifetime
                         ? "One payment of \(store.price(.lifetime)). No subscription, no renewals. Includes every future Premium feature."
                         : "Free for 7 days, then \(store.price(.monthly)) a month. Cancel anytime in Settings at least 24 hours before renewal.")
                        .font(Tend.F.sans(12)).lineSpacing(3).foregroundStyle(Tend.C.text5).multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 18) {
                        Button("Terms") { legal = .terms }.underline()
                        Button("Privacy") { legal = .privacy }.underline()
                        Button("Restore purchase", action: restore)
                    }
                    .font(Tend.F.sans(12)).foregroundStyle(Tend.C.text4).buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8).padding(.bottom, 30)
            .entrance()
        }
        .toastHost(bottom: 30)
    }

    private func planCard(_ p: PremiumPlan, name: String, sub: String, per: String, badge: String?) -> some View {
        let on = plan == p
        return Button { withAnimation(.easeOut(duration: 0.2)) { plan = p } } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().strokeBorder(on ? Tend.C.accent : Tend.C.ring, lineWidth: 2)
                    Circle().fill(on ? Tend.C.accent : .clear).frame(width: 12, height: 12)
                        .shadow(color: on ? Tend.C.leaf(0.7) : .clear, radius: 4)
                }
                .frame(width: 24, height: 24)
                VStack(alignment: .leading, spacing: 3) {
                    Text(name).font(Tend.F.sans(17, .bold)).foregroundStyle(Tend.C.text)
                    Text(sub).font(Tend.F.sans(13)).foregroundStyle(Tend.C.text3)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(store.price(p)).font(Tend.F.serif(26)).foregroundStyle(Tend.C.text)
                    Text(per).font(Tend.F.sans(12)).foregroundStyle(Tend.C.text4)
                }
            }
            .padding(18)
            .background(on ? Tend.C.leaf(0.14) : Tend.C.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(on ? Tend.C.accent : Tend.C.ink(0.13), lineWidth: 1.5))
            .shadow(color: on ? Tend.C.leaf(0.1) : .clear, radius: 15)
            .overlay(alignment: .topTrailing) {
                if let badge {
                    Text(badge).font(Tend.F.sans(11, .heavy)).tracking(0.66).foregroundStyle(Tend.C.cream)
                        .padding(.horizontal, 10).frame(height: 22)
                        .background(Color(hex: 0xA9852B), in: Capsule())
                        .offset(x: -18, y: -11)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private var success: some View {
        VStack(spacing: 18) {
            Spacer()
            SeedlingSuccess()
            ScreenTitle(text: "Welcome to Premium.", size: 42).multilineTextAlignment(.center)
            Text(plan == .lifetime
                 ? "Lifetime access is unlocked. Every scan, sensor and growth feature is yours to keep."
                 : "Your 7-day trial has started. We'll remind you 2 days before it ends.")
                .font(Tend.F.sans(16)).lineSpacing(4).foregroundStyle(Tend.C.text3).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button("Start exploring") {
                model.cover = nil
                model.premiumHost = nil
                model.selectedTab = .home
                model.homePath = []
                model.showToast("Premium unlocked. Unlimited scans are on.")
            }
            .buttonStyle(PrimaryButtonStyle(kind: .inverse))
            .padding(.top, 12)
            Spacer()
        }
        .padding(.horizontal, 30)
    }

    private func buy() {
        guard !store.purchasing else { return }
        store.purchasing = true
        Task {
            let ok = await store.purchase(plan)
            store.purchasing = false
            if ok {
                model.premium = plan
                model.buzz(.success)
                bought = true
            } else if let err = store.lastError {
                model.showToast(err)
                store.lastError = nil
            }
        }
    }

    private func restore() {
        guard !store.restoring else { return }
        store.restoring = true
        Task {
            let found = await store.restore()
            store.restoring = false
            model.showToast(found ? "Purchase restored. Premium is on." : "No previous purchase found on this Apple ID.")
            if found { dismiss() }
        }
    }
}

extension LegalKind: Identifiable { var id: String { rawValue } }

/// The 76 pt app-mark tile.
struct AppMark: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(LinearGradient.angle(150, [Color(hex: 0x5A9450), Color(hex: 0x24441F)]))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(.white.opacity(0.25), lineWidth: 1).blendMode(.overlay))
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous).strokeBorder(.white, lineWidth: 2.5)
                    .frame(width: 30, height: 30)
                    .overlay(Circle().fill(.white).frame(width: 8, height: 8))
            }
            .frame(width: 76, height: 76)
            .shadow(color: Tend.C.leaf(0.25), radius: 25)
            .accessibilityHidden(true)
    }
}
