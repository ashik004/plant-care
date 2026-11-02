import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) var model

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                header
                HealthCard()
                PestAlertCard()
                TodaySection()
                EnvironmentStrip()
                if let s = model.suggestions.first {
                    SuggestionCard(suggestion: s, compact: true)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                DigestCard()
                AwayRow()
            }
            .padding(.horizontal, Tend.S.side)
            .padding(.top, 8)
            .padding(.bottom, 40)
            .entrance()
        }
        .tendScreen(hideTabBar: false)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Eyebrow(text: Care.longDate())
                ScreenTitle(text: "\(Care.greeting()), Alex.")
            }
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Button { model.push(.ask(plantId: nil)) } label: {
                    HStack(spacing: 7) {
                        LineIcon(d: Icon.ask, color: .white, size: 18)
                        Text("Ask").font(Tend.F.sans(14, .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.leading, 12).padding(.trailing, 14)
                    .frame(height: 44)
                    .background(Tend.C.brandButton, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Ask Tend")

                Button { model.push(.settings) } label: {
                    Text("A").font(Tend.F.serif(20)).foregroundStyle(Tend.C.text)
                        .frame(width: 44, height: 44)
                        .background(Tend.C.surface, in: Circle())
                        .overlay(Circle().stroke(Tend.C.ink(0.16), lineWidth: 1))
                        .overlay(alignment: .bottomTrailing) {
                            if model.isPremium {
                                Circle().fill(Tend.C.brand).frame(width: 16, height: 16)
                                    .overlay(Circle().stroke(Tend.C.bg, lineWidth: 2))
                                    .shadow(color: Tend.C.leaf(0.27), radius: 5)
                                    .offset(x: 2, y: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Settings")
            }
        }
    }
}

// MARK: Health card

struct HealthRing: View {
    let fraction: Double
    var size: CGFloat = 92
    var lineWidth: CGFloat = 8
    var track: Color = Tend.C.ink(0.1)
    var color: Color = Tend.C.accent
    var glow = true
    @State var drawn: Double = 0
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        ZStack {
            Circle().stroke(track, lineWidth: lineWidth)
            Circle().trim(from: 0, to: drawn)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: glow ? Tend.C.leaf(0.6) : .clear, radius: 6)
        }
        .frame(width: size - lineWidth, height: size - lineWidth)
        .frame(width: size, height: size)
        .onAppear {
            if reduceMotion { drawn = fraction; return }
            withAnimation(Tend.ease(1.3).delay(0.15)) { drawn = fraction }
        }
        .onChange(of: fraction) { _, f in withAnimation(Tend.ease(0.8)) { drawn = f } }
    }
}

private struct HealthCard: View {
    @Environment(AppModel.self) var model

    var body: some View {
        let hs = model.plants.map { model.health($0) }
        let good = hs.filter { $0.kind == .good }.count
        let watch = hs.filter { $0.kind == .watch }.count
        let issue = hs.filter { $0.kind == .issue }.count
        let frac = model.plants.isEmpty ? 0 : Double(good) / Double(model.plants.count)

        HStack(spacing: 20) {
            ZStack {
                HealthRing(fraction: frac)
                VStack(spacing: 2) {
                    Text("\(Int((frac * 100).rounded()))%").font(Tend.F.serif(28)).foregroundStyle(Tend.C.text)
                        .contentTransition(.numericText())
                    Text("HEALTHY").font(Tend.F.sans(10)).tracking(0.6).foregroundStyle(Tend.C.text3)
                }
            }
            VStack(spacing: 7) {
                legend("Thriving", good, Tend.C.accent) { model.selectTab(.plants) }
                legend("Needs attention", watch, Tend.C.amber) { model.push(.environment) }
                legend("Pest or disease", issue, Tend.C.clay) { model.push(.diagnosis) }
            }
        }
        .padding(18)
        .background(LinearGradient.angle(160, [Tend.C.leaf(0.18), Tend.C.leaf(0.05)]),
                    in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Tend.C.leaf(0.16), lineWidth: 1))
        .accessibilityElement(children: .contain)
    }

    private func legend(_ label: String, _ n: Int, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                StatusDot(color: color)
                Text(label).font(Tend.F.sans(14)).foregroundStyle(Tend.C.text)
                Spacer()
                Text("\(n)").font(Tend.F.mono(13)).foregroundStyle(color)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: Pest alert

private struct PestAlertCard: View {
    @Environment(AppModel.self) var model

    var body: some View {
        Button { model.push(.diagnosis) } label: {
            HStack(spacing: 14) {
                StripedPlaceholder(label: "scan", stripe: 5, palette: .clay, radius: 14, labelSize: 7)
                    .frame(width: 52, height: 52)
                VStack(alignment: .leading, spacing: 3) {
                    Text((model.treatActive ? "Treatment in progress" : "Detected in Monday's scan").uppercased())
                        .font(Tend.F.sans(12, .semibold)).tracking(0.96).foregroundStyle(Tend.C.clay)
                    Text(model.treatActive ? "Figgy · spider mites" : "Possible spider mites on Figgy")
                        .font(Tend.F.sans(15, .semibold)).foregroundStyle(Tend.C.text)
                    Text(model.treatActive ? "\(model.treatDone.count) of 4 steps done · next neem round Mon 2 Nov" : "87% match · caught early · see treatment")
                        .font(Tend.F.sans(13)).foregroundStyle(Tend.C.text3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text("›").font(Tend.F.sans(20)).foregroundStyle(Tend.C.clay)
            }
            .padding(14)
            .background(Tend.C.clayTint(0.1), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Tend.C.clayTint(0.28), lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(LiftButtonStyle())
    }
}

// MARK: Today

private struct TodaySection: View {
    @Environment(AppModel.self) var model

    var body: some View {
        let tasks = model.tasks
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Today") {
                Text(tasks.isEmpty ? "All done" : "\(tasks.count) to do").font(Tend.F.sans(13)).foregroundStyle(Tend.C.text4)
            }
            ForEach(Array(tasks.enumerated()), id: \.element.id) { i, t in
                TaskRow(task: t)
                    .rise(delay: 0.08 + Double(i) * 0.06)
                    .transition(.asymmetric(insertion: .opacity, removal: .opacity.combined(with: .scale(scale: 0.96))))
            }
            if tasks.isEmpty {
                VStack(spacing: 6) {
                    DozingPlantIllustration()
                    Text("All tended. Enjoy the quiet.").font(Tend.F.serif(24)).foregroundStyle(Tend.C.text)
                    Text("Tomorrow: " + (model.tomorrowNames.isEmpty ? "nothing due" : Care.listNames(model.tomorrowNames)))
                        .font(Tend.F.sans(14)).foregroundStyle(Tend.C.text4)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 22).padding(.bottom, 26).padding(.horizontal, 22)
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Tend.C.ink(0.21), style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
                .rise(delay: 0)
            }
        }
        .animation(Tend.ease, value: tasks.map(\.id))
    }
}

private struct TaskRow: View {
    let task: CareTask
    @Environment(AppModel.self) var model

    var body: some View {
        HStack(spacing: 14) {
            Button(action: open) {
                HStack(spacing: 14) {
                    StripedPlaceholder(label: "photo", radius: 14).frame(width: 52, height: 52)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(task.title).font(Tend.F.serif(21)).foregroundStyle(Tend.C.text)
                        Text(task.meta).font(Tend.F.sans(13)).foregroundStyle(Tend.C.text4).lineLimit(1)
                        HStack(spacing: 10) {
                            HStack(spacing: 6) {
                                StatusDot(color: color, size: 6)
                                Text(task.when).font(Tend.F.sans(12, .semibold)).foregroundStyle(color)
                            }
                            Button { model.snooze(task) } label: {
                                Text("Later").font(Tend.F.sans(12, .medium)).foregroundStyle(Tend.C.text5).underline()
                                    .padding(.vertical, 6).contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button { model.complete(task) } label: {
                TaskCheck(checking: model.completing == task.id)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Mark done")
        }
        .padding(.vertical, 12).padding(.leading, 12).padding(.trailing, 14)
        .card()
    }

    private var color: Color { task.late ? Tend.C.clay : Tend.C.accent }

    private func open() {
        if task.kind == .treat { model.push(.diagnosis) } else { model.push(.detail(plantId: task.plantId, tab: .health)) }
    }
}

// MARK: Environment strip

private struct EnvironmentStrip: View {
    @Environment(AppModel.self) var model

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Environment") {
                Button("All rooms ›") { model.push(.environment) }
                    .font(Tend.F.sans(13, .semibold)).foregroundStyle(Tend.C.accent).buttonStyle(.plain)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(["Living room", "Bedroom", "Kitchen", "Balcony"].enumerated()), id: \.element) { i, room in
                        RoomCard(room: room, offset: i)
                    }
                }
                .padding(.horizontal, Tend.S.side)
            }
            .padding(.horizontal, -Tend.S.side)
        }
    }
}

struct RoomCard: View {
    let room: String
    var offset = 0
    var offline = false
    @Environment(AppModel.self) var model

    var body: some View {
        let v = model.env(room, offset: offset)
        let bad = model.plants.contains { $0.room == room && model.health($0).kind != .good }
        Button { model.push(.environment) } label: {
            VStack(alignment: .leading, spacing: offline ? 8 : 10) {
                HStack {
                    Text(room).font(Tend.F.sans(14, .semibold)).foregroundStyle(Tend.C.text)
                    Spacer()
                    if offline {
                        Text("9:12").font(Tend.F.mono(10)).foregroundStyle(Tend.C.text5)
                    } else {
                        StatusDot(color: bad ? Tend.C.amber : Tend.C.accent, size: 7)
                    }
                }
                VStack(alignment: .leading, spacing: offline ? 3 : 4) {
                    Text(model.temp(v.temperature, decimals: 1))
                    Text("\(Int(v.humidity))% hum")
                    if !offline { Text(Care.fmtLux(v.lux)) }
                }
                .font(Tend.F.mono(12)).foregroundStyle(Tend.C.text3)
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.6), value: v)
            }
            .padding(14)
            .frame(width: offline ? nil : 150, alignment: .leading)
            .frame(maxWidth: offline ? .infinity : nil, alignment: .leading)
            .card()
            .opacity(offline ? 0.6 : 1)
        }
        .buttonStyle(LiftButtonStyle())
        .disabled(offline)
    }
}

// MARK: Suggestion

struct SuggestionCard: View {
    let suggestion: Suggestion
    /// The Home version has an eyebrow and a "Not now" button; Environment's is tinted.
    var compact = false
    @Environment(AppModel.self) var model

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 10 : 8) {
            if compact { Eyebrow(text: "Tend suggests", color: Tend.C.accent, size: 11, dot: true) }
            Text(suggestion.title).font(Tend.F.serif(compact ? 20 : 19)).lineSpacing(3).foregroundStyle(Tend.C.text)
                .fixedSize(horizontal: false, vertical: true)
            Text(suggestion.why).font(Tend.F.sans(13)).lineSpacing(3).foregroundStyle(Tend.C.text3)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Button(suggestion.cta) { model.accept(suggestion) }
                    .buttonStyle(SmallButtonStyle(height: compact ? 38 : 36, fontSize: compact ? 14 : 13))
                if compact {
                    Button("Not now") { model.dismiss(suggestion) }.buttonStyle(SmallButtonStyle(filled: false))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16).padding(.horizontal, 18)
        .modifier(SuggestionBackground(compact: compact))
    }
}

private struct SuggestionBackground: ViewModifier {
    let compact: Bool
    func body(content: Content) -> some View {
        if compact { content.card(border: Tend.C.leaf(0.18)) } else { content.tintCard() }
    }
}

// MARK: Digest & away

private struct DigestCard: View {
    @Environment(AppModel.self) var model

    var body: some View {
        let top = model.plants.map { ($0.name, ($0.heights.last ?? 0) - ($0.heights.dropLast().last ?? 0)) }.max { $0.1 < $1.1 }
        Button { model.push(.digest) } label: {
            HStack(spacing: 14) {
                VStack(spacing: 2) {
                    Text("SUN").font(Tend.F.sans(9, .bold)).tracking(1.1).foregroundStyle(Tend.C.creamSoft)
                    Text("25").font(Tend.F.serif(21)).foregroundStyle(Tend.C.cream)
                }
                .frame(width: 48, height: 48)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Your week in plants").font(Tend.F.sans(15, .semibold)).foregroundStyle(Tend.C.cream)
                    Text("14 drinks given · \(top?.0 ?? "Goldie") grew \(top?.1 ?? 0) cm · Figgy on the mend")
                        .font(Tend.F.sans(13)).lineSpacing(2).foregroundStyle(Tend.C.creamSoft)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text("›").font(Tend.F.sans(22)).foregroundStyle(Tend.C.creamSoft)
            }
            .padding(.vertical, 16).padding(.horizontal, 18)
            .background(Tend.C.deepGradient, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(LiftButtonStyle())
    }
}

private struct AwayRow: View {
    @Environment(AppModel.self) var model

    var body: some View {
        Button { model.push(.away) } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Going away?").font(Tend.F.sans(15, .semibold)).foregroundStyle(Tend.C.text)
                    Text("Brief a plant-sitter in under a minute.").font(Tend.F.sans(13)).foregroundStyle(Tend.C.text4)
                }
                Spacer()
                Text("›").font(Tend.F.sans(20)).foregroundStyle(Tend.C.text4)
            }
            .padding(.vertical, 16).padding(.horizontal, 18)
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Tend.C.ink(0.1), lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(LiftButtonStyle())
    }
}
