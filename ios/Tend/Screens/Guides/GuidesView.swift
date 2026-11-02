import SwiftUI

struct GuidesView: View {
    @Environment(AppModel.self) var model

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow(text: "Care guides")
                    ScreenTitle(text: "Learn it once, do it well.")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow(text: "For your plants this week", color: Tend.C.accent)
                    recommended("Feed Goldie", "Growing season · fertilizing, 4 steps") { model.openGuide("feed", context: "Goldie") }
                    recommended("Repot Big Monstera", "Roots at the drainage hole · 5 steps") { model.openGuide("repot", context: "Big Monstera") }
                }

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(Array(SampleData.guides.enumerated()), id: \.element.id) { i, g in
                        Button { model.openGuide(g.id) } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                StripedPlaceholder(label: g.image, radius: 14, alignment: .bottomLeading).frame(height: 110)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(g.title).font(Tend.F.serif(21)).foregroundStyle(Tend.C.text)
                                    Text(g.meta).font(Tend.F.sans(12)).foregroundStyle(Tend.C.text4)
                                }
                                .padding(.horizontal, 6)
                            }
                            .padding(.top, 8).padding(.horizontal, 8).padding(.bottom, 14)
                            .card()
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(LiftButtonStyle())
                        .rise(delay: Double(i) * 0.05)
                    }
                }
            }
            .padding(.horizontal, Tend.S.side)
            .padding(.top, 8).padding(.bottom, 40)
            .entrance()
        }
        .tendScreen(hideTabBar: false)
    }

    private func recommended(_ title: String, _ sub: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(Tend.F.serif(20)).foregroundStyle(Tend.C.text)
                    Text(sub).font(Tend.F.sans(13)).foregroundStyle(Tend.C.text3)
                }
                Spacer()
                Text("›").font(Tend.F.sans(20)).foregroundStyle(Tend.C.accent)
            }
            .padding(14)
            .tintCard(from: 0.14, to: 0.03, border: 0.16)
            .contentShape(Rectangle())
        }
        .buttonStyle(LiftButtonStyle())
    }
}

/// Step-by-step guide, presented as a full-screen cover.
struct GuideStepView: View {
    let guide: Guide
    let context: String?
    @Environment(AppModel.self) var model
    @State var step = 0

    var body: some View {
        let s = guide.steps[step]
        let last = step == guide.steps.count - 1

        VStack(alignment: .leading, spacing: 20) {
            HStack {
                TextLinkButton(title: "Close") { model.cover = nil }
                Spacer()
                Text(guide.title).font(Tend.F.sans(15, .semibold)).foregroundStyle(Tend.C.text)
                Spacer()
                Text("\(step + 1)/\(guide.steps.count)").font(Tend.F.mono(11)).foregroundStyle(Tend.C.text5)
                    .frame(width: 44, alignment: .trailing)
            }

            HStack(spacing: 4) {
                ForEach(0..<guide.steps.count, id: \.self) { i in
                    Capsule().fill(i <= step ? Tend.C.accent : Tend.C.ink(0.16)).frame(height: 3)
                        .shadow(color: i == step ? Tend.C.leaf(0.6) : .clear, radius: 4)
                }
            }
            .animation(.easeOut(duration: 0.3), value: step)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    StripedPlaceholder(label: "step photo · \(guide.image)", stripe: 7, palette: .wide, radius: 26, labelSize: 10)
                        .frame(height: 300)
                    VStack(alignment: .leading, spacing: 10) {
                        if let context { Eyebrow(text: "For \(context)", color: Tend.C.accent) }
                        ScreenTitle(text: s.title, size: 36)
                        Text(s.body).font(Tend.F.sans(16)).lineSpacing(5).foregroundStyle(Tend.C.text3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .id(step)
                .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 14)), removal: .opacity))
            }

            // Back : Next = 1 : 1.6
            GeometryReader { g in
                HStack(spacing: 10) {
                    Button("Back") { withAnimation(Tend.ease) { step = max(0, step - 1) } }
                        .buttonStyle(PrimaryButtonStyle(kind: .outline))
                        .opacity(step == 0 ? 0.35 : 1)
                        .disabled(step == 0)
                        .frame(width: (g.size.width - 10) / 2.6)
                    Button(last ? "Done" : "Next step") {
                        if last {
                            model.cover = nil
                            model.buzz(.success)
                            model.showToast(context.map { "Nice work. Logged for \($0)." } ?? "Guide complete.")
                        } else {
                            withAnimation(Tend.ease) { step += 1 }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .frame(height: 56)
        }
        .padding(.horizontal, Tend.S.side)
        .padding(.top, 8).padding(.bottom, 16)
        .background { AmbientBackground() }
    }
}
