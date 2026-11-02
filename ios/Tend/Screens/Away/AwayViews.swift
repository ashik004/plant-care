import SwiftUI

// MARK: 8a Plan

struct AwayPlanView: View {
    @Environment(AppModel.self) var model
    @FocusState var focused: Bool

    var body: some View {
        @Bindable var model = model
        let plan = model.awayPlan
        let r = plan.range

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                BackPill(label: "Home")
                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow(text: "Plant-sitter hand-off")
                    ScreenTitle(text: "Leave them in good hands.")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("How long").font(Tend.F.sans(13, .semibold)).foregroundStyle(Tend.C.text)
                    HStack(spacing: 8) {
                        ForEach(SampleData.ranges) { range in
                            let on = model.rangeId == range.id
                            Button { withAnimation(Tend.ease) { model.rangeId = range.id } } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(range.label).font(Tend.F.sans(14, .semibold))
                                    Text(range.sub).font(Tend.F.sans(12)).opacity(0.75)
                                }
                                .foregroundStyle(on ? Tend.C.onInverse : Tend.C.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 12).padding(.horizontal, 8)
                                .background(on ? Tend.C.inverse : Tend.C.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(on ? Tend.C.inverse : Tend.C.ink(0.13), lineWidth: 1))
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(on ? .isSelected : [])
                        }
                    }
                    Text("\(Care.dayLabel(r.start + 1)) – \(Care.dayLabel(r.start + r.days))").font(Tend.F.sans(13)).foregroundStyle(Tend.C.text4)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Who's looking after them").font(Tend.F.sans(13, .semibold)).foregroundStyle(Tend.C.text)
                    TextField("Sitter's name", text: $model.sitter)
                        .font(Tend.F.sans(16)).foregroundStyle(Tend.C.text)
                        .textContentType(.givenName)
                        .focused($focused)
                        .padding(.horizontal, 16).frame(height: 52)
                        .background(Tend.C.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(focused ? Tend.C.accent : Tend.C.ink(0.18), lineWidth: 1))
                }

                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(plan.visits.count) visit\(plan.visits.count == 1 ? "" : "s")").font(Tend.F.serif(22)).foregroundStyle(Tend.C.text)
                        Spacer()
                        Text("\(plan.need.count) of \(model.plants.count) plants need care").font(Tend.F.sans(12)).foregroundStyle(Tend.C.text4)
                    }
                    .padding(.bottom, 10)
                    ForEach(plan.visits) { v in
                        HStack(alignment: .top, spacing: 12) {
                            Text(v.date).font(Tend.F.sans(14, .semibold)).foregroundStyle(Tend.C.text).frame(width: 88, alignment: .leading)
                            Text(v.names).font(Tend.F.sans(14)).foregroundStyle(Tend.C.text3)
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 10)
                        .overlay(alignment: .top) { RowDivider(opacity: 0.09) }
                    }
                }
                .padding(.top, 16).padding(.horizontal, 16).padding(.bottom, 6)
                .card()

                if !plan.fine.isEmpty {
                    (Text("Fine on their own · ").font(Tend.F.sans(14, .semibold)).foregroundColor(Tend.C.text)
                     + Text(Care.listNames(plan.fine) + ".").font(Tend.F.sans(14)).foregroundColor(Tend.C.text3))
                        .lineSpacing(3)
                }

                Button("Create plan for \(model.sitterName)") { model.copied = false; model.push(.handoff) }
                    .buttonStyle(PrimaryButtonStyle(kind: .inverse))
            }
            .padding(.horizontal, Tend.S.side)
            .padding(.top, 8).padding(.bottom, 40)
            .entrance()
        }
        .scrollDismissesKeyboard(.interactively)
        .tendScreen()
    }
}

// MARK: 8b Hand-off ready

struct HandoffView: View {
    @Environment(AppModel.self) var model

    var body: some View {
        let plan = model.awayPlan
        let r = plan.range
        let link = URL(string: "https://tend.app/s/\(model.sitterName.lowercased().filter(\.isLetter))-\(r.id)")!

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Eyebrow(text: "✓ Hand-off ready", color: Tend.C.accent)
                VStack(alignment: .leading, spacing: 14) {
                    Text("\(model.sitterName), thank you.").font(Tend.F.serif(34)).foregroundStyle(Tend.C.text)
                    Text("\(plan.visits.count) short visits between \(Care.dayLabel(r.start + 1)) and \(Care.dayLabel(r.start + r.days)). Room-temperature water, poured slowly at the base. Each plant's photo and spot are in the link.")
                        .font(Tend.F.sans(14)).lineSpacing(3).foregroundStyle(Tend.C.text3)
                        .fixedSize(horizontal: false, vertical: true)
                    ForEach(plan.visits) { v in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(v.date).font(Tend.F.sans(13, .semibold)).foregroundStyle(Tend.C.text)
                            Text(v.plants.map { "\($0.name) \(model.volume($0.amount))" }.joined(separator: " · "))
                                .font(Tend.F.sans(14)).foregroundStyle(Tend.C.text3)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                        .overlay(alignment: .top) { RowDivider(opacity: 0.1) }
                    }
                }
                .padding(.vertical, 26).padding(.horizontal, 22)
                .card(radius: 24, border: Tend.C.ink(0.1))

                Button(model.copied ? "✓ Link copied" : "Copy link to share") {
                    UIPasteboard.general.url = link
                    model.buzz(.success)
                    withAnimation { model.copied = true }
                }
                .buttonStyle(PrimaryButtonStyle())

                HStack(spacing: 24) {
                    TextLinkButton(title: "Preview as \(model.sitterName)", color: Tend.C.accent, weight: .semibold) { model.push(.sitterPreview) }
                    BackPillText(title: "Edit plan")
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, Tend.S.side)
            .padding(.top, 16).padding(.bottom, 40)
            .entrance()
        }
        .tendScreen()
    }
}

// MARK: 8c Sitter view (shared as a web link in production; previewed here)

struct SitterPreviewView: View {
    @Environment(AppModel.self) var model
    @Environment(\.dismiss) var dismiss

    var body: some View {
        let plan = model.awayPlan
        let r = plan.range
        let total = plan.visits.reduce(0) { $0 + $1.plants.count }
        let done = plan.visits.reduce(0) { n, v in n + v.plants.filter { model.sitterDone.contains("\(v.key)\($0.id)") }.count }

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("Previewing \(model.sitterName)'s link").font(Tend.F.sans(13)).foregroundStyle(Tend.C.clay)
                    Spacer()
                    Button("Done") { dismiss() }
                        .font(Tend.F.sans(13, .bold)).foregroundStyle(Tend.C.bg)
                        .padding(.horizontal, 12).frame(height: 32)
                        .background(Tend.C.clay, in: Capsule())
                        .buttonStyle(.plain)
                }
                .padding(.vertical, 10).padding(.leading, 16).padding(.trailing, 12)
                .background(Tend.C.clayTint(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Tend.C.clayTint(0.25), lineWidth: 1))
                .padding(.horizontal, Tend.S.sideWide)

                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow(text: "\(Care.dayLabel(r.start + 1)) – \(Care.dayLabel(r.start + r.days))")
                    ScreenTitle(text: "Hi \(model.sitterName). Here's everything.")
                    Text("Tick plants off as you go. No app needed.").font(Tend.F.sans(15)).foregroundStyle(Tend.C.text3)
                }
                .padding(.horizontal, Tend.S.side)

                HStack(spacing: 14) {
                    Text("\(done) of \(total) done").font(Tend.F.sans(13)).foregroundStyle(Tend.C.text3)
                        .contentTransition(.numericText())
                    BarMeter(fraction: total == 0 ? 0 : Double(done) / Double(total), color: Tend.C.accent, height: 4,
                             track: Tend.C.surface, glow: Tend.C.leaf(0.5))
                }
                .padding(.horizontal, Tend.S.side)

                ForEach(plan.visits) { v in
                    VStack(alignment: .leading, spacing: 0) {
                        Text(v.date).font(Tend.F.serif(22)).foregroundStyle(Tend.C.text).padding(.bottom, 8)
                        ForEach(v.plants) { p in
                            let key = "\(v.key)\(p.id)"
                            let on = model.sitterDone.contains(key)
                            Button {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    if on { model.sitterDone.remove(key) } else { model.sitterDone.insert(key) }
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    StripedPlaceholder(label: "photo", stripe: 5, radius: 12, labelSize: 7).frame(width: 44, height: 44)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(p.name) · \(model.volume(p.amount))").font(Tend.F.sans(15, .semibold))
                                            .foregroundStyle(on ? Tend.C.text5 : Tend.C.text)
                                        Text(p.spot).font(Tend.F.sans(12)).foregroundStyle(Tend.C.text4)
                                    }
                                    Spacer(minLength: 0)
                                    StepCheck(done: on)
                                }
                                .padding(.vertical, 12)
                                .overlay(alignment: .top) { RowDivider(opacity: 0.09) }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(on ? .isSelected : [])
                        }
                    }
                    .padding(.top, 16).padding(.horizontal, 16).padding(.bottom, 6)
                    .card(radius: 22)
                    .padding(.horizontal, Tend.S.sideWide)
                }
            }
            .padding(.top, 4).padding(.bottom, 40)
            .entrance()
        }
        .tendScreen()
    }
}
