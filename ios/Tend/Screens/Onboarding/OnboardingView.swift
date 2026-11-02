import SwiftUI

struct OnboardingView: View {
    @Environment(AppModel.self) var model

    var body: some View {
        ZStack {
            AmbientBackground()
            switch model.onboardingStep {
            case 0: WelcomeStep().id(0)
            case 1: LevelStep().id(1)
            default: RemindersStep().id(2)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: model.onboardingStep)
    }
}

// MARK: 1a Welcome

private struct WelcomeStep: View {
    @Environment(AppModel.self) var model
    @State var settled = false

    var body: some View {
        StepScroll {
        VStack(alignment: .leading, spacing: 24) {
            ZStack {
                Color(hex: 0x43523E)
                GeometryReader { g in
                    Image("OnboardPlant")
                        .resizable()
                        .scaledToFill()
                        .frame(width: g.size.width, height: g.size.height)
                        .clipped()
                        .scaleEffect(settled ? 1 : 1.08)
                }
                LinearGradient(stops: [.init(color: .clear, location: 0.55),
                                       .init(color: Tend.C.bg.opacity(0.85), location: 1)],
                               startPoint: .top, endPoint: .bottom)
            }
            .frame(height: 420)
            .clipShape(RoundedRectangle(cornerRadius: Tend.R.hero, style: .continuous))
            .accessibilityLabel("Potted bird of paradise in a terracotta pot")
            .onAppear { withAnimation(Tend.ease(2.4)) { settled = true } }

            VStack(alignment: .leading, spacing: 12) {
                Text("A plant expert in your pocket.")
                    .font(Tend.F.serif(48)).tracking(-0.48)
                    .foregroundStyle(Tend.C.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Identify any plant, catch problems early, and know exactly what each one needs. No gardening experience required.")
                    .font(Tend.F.sans(16)).lineSpacing(4).foregroundStyle(Tend.C.text3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            VStack(spacing: 6) {
                Button("Get started") { model.onboardingStep = 1 }
                    .buttonStyle(PrimaryButtonStyle())
                TextLinkButton(title: "I already have an account") { model.finishOnboarding() }
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, Tend.S.side)
        .padding(.top, 8)
        .padding(.bottom, 20)
        }
        .entrance()
    }
}

// MARK: 1b Level

private struct ProgressPips: View {
    let filled: Int
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<2, id: \.self) { i in
                Capsule().fill(i < filled ? Tend.C.accent : Tend.C.ink(0.2)).frame(width: 22, height: 4)
            }
        }
        .accessibilityLabel("Step \(filled) of 2")
    }
}

private struct LevelStep: View {
    @Environment(AppModel.self) var model

    var body: some View {
        StepScroll {
        VStack(alignment: .leading, spacing: 26) {
            ProgressPips(filled: 1)
            VStack(alignment: .leading, spacing: 10) {
                ScreenTitle(text: "How at home are you with plants?", size: 42)
                Text("This sets how much Tend explains. You can change it later.")
                    .font(Tend.F.sans(15)).foregroundStyle(Tend.C.text3)
            }
            VStack(spacing: 10) {
                option(.new, "Still learning", "Step-by-step guidance and plain-language tips. Reminders explain why.")
                option(.mid, "I know my way around", "Raw sensor data, schedules I can tune and fewer explanations.")
            }
            Spacer(minLength: 0)
            Button("Continue") { model.onboardingStep = 2 }
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.horizontal, Tend.S.side)
        .padding(.top, 20)
        .padding(.bottom, 20)
        }
        .entrance()
    }

    private func option(_ level: Level, _ title: String, _ body: String) -> some View {
        let on = model.level == level
        return Button { withAnimation(.easeOut(duration: 0.2)) { model.level = level } } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(Tend.F.serif(26)).foregroundStyle(Tend.C.text)
                Text(body).font(Tend.F.sans(14)).lineSpacing(2).foregroundStyle(Tend.C.text3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(on ? Tend.C.leaf(0.16) : Tend.C.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(on ? Tend.C.accent : Tend.C.ink(0.13), lineWidth: 1.5))
            .shadow(color: on ? Tend.C.leaf(0.07) : .clear, radius: 15)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

// MARK: 1c Reminders

private struct RemindersStep: View {
    @Environment(AppModel.self) var model

    var body: some View {
        StepScroll {
        VStack(alignment: .leading, spacing: 26) {
            ProgressPips(filled: 2)

            WateringCanIllustration()
                .frame(maxWidth: .infinity)
                .frame(height: 132)
                .background(LinearGradient.angle(170, [Tend.C.illoTop, Tend.C.illoBottom]),
                            in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Tend.C.ink(0.08), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                ScreenTitle(text: "When should we nudge you?", size: 42)
                Text("Reminders adapt to each plant's type and condition. You get one a day, and only when something's due.")
                    .font(Tend.F.sans(15)).lineSpacing(2).foregroundStyle(Tend.C.text3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 8) {
                ForEach(ReminderSlot.allCases, id: \.self) { slot in
                    let on = model.remind == slot
                    Button { withAnimation(.easeOut(duration: 0.2)) { model.remind = slot } } label: {
                        HStack {
                            Text(slot.rawValue).font(Tend.F.sans(16, .semibold)).foregroundStyle(Tend.C.text)
                            Spacer()
                            Text(slot.time).font(Tend.F.mono(13)).foregroundStyle(on ? Tend.C.accent : Tend.C.text5)
                        }
                        .padding(.horizontal, 20)
                        .frame(height: 60)
                        .background(on ? Tend.C.leaf(0.16) : Tend.C.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(on ? Tend.C.accent : Tend.C.ink(0.13), lineWidth: 1.5))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }

            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Tend.C.brand).frame(width: 36, height: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tend · \(model.remind.time)").font(Tend.F.sans(14, .semibold)).foregroundStyle(Tend.C.text)
                    Text("Ottoline is dry and Goldie is ready for a feed.").font(Tend.F.sans(14)).foregroundStyle(Tend.C.text3)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .card(radius: 18)

            Spacer(minLength: 0)

            VStack(spacing: 6) {
                Button("Allow reminders") {
                    Task {
                        _ = await Notifications.requestAuthorization()
                        model.finishOnboarding()
                        await Notifications.schedule(model)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                TextLinkButton(title: "Not now") { model.finishOnboarding() }
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, Tend.S.side)
        .padding(.top, 20)
        .padding(.bottom, 20)
        }
        .entrance()
    }
}

/// Scrolls on small screens; on tall ones the content fills the screen so buttons sit at the bottom.
private struct StepScroll<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                content().frame(minHeight: geo.size.height, alignment: .top)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}
