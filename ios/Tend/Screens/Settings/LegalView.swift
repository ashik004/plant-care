import SwiftUI

/// Terms & Privacy. All copy is placeholder and must be reviewed by counsel.
struct LegalView: View {
    @State var kind: LegalKind
    @Environment(AppModel.self) var model

    init(initial: LegalKind) { _kind = State(initialValue: initial) }

    var body: some View {
        let doc = kind == .terms ? SampleData.terms : SampleData.privacy

        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        BackPill()
                        Spacer()
                        SegmentedPicker(options: [(LegalKind.terms, "Terms"), (.privacy, "Privacy")], selection: $kind,
                                        height: 32, radius: 12, innerRadius: 9, fontSize: 13, stretch: false) { _ in
                            withAnimation { proxy.scrollTo("top", anchor: .top) }
                        }
                    }
                    .padding(.horizontal, Tend.S.sideWide)
                    .id("top")

                    VStack(alignment: .leading, spacing: 10) {
                        Text(doc.updated).font(Tend.F.mono(11)).tracking(0.44).foregroundStyle(Tend.C.text5)
                        ScreenTitle(text: doc.title)
                        Text(doc.intro).font(Tend.F.sans(15)).lineSpacing(5).foregroundStyle(Tend.C.text3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, Tend.S.side)

                    if !doc.glance.isEmpty {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                            ForEach(doc.glance, id: \.key) { g in
                                let never = g.key == "We never"
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(g.key.uppercased()).font(Tend.F.sans(11, .bold)).tracking(1.1)
                                        .foregroundStyle(never ? Tend.C.clay : Tend.C.accent)
                                    Text(g.value).font(Tend.F.sans(13)).lineSpacing(3).foregroundStyle(Tend.C.text2)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer(minLength: 0)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                .padding(14)
                                .background(never ? Tend.C.clayTint(0.08) : Tend.C.leaf(0.1), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(never ? Tend.C.clayTint(0.2) : Tend.C.leaf(0.16), lineWidth: 1))
                            }
                        }
                        .padding(.horizontal, Tend.S.sideWide)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Eyebrow(text: "Contents", size: 11).padding(.bottom, 6)
                        ForEach(Array(doc.sections.enumerated()), id: \.offset) { i, s in
                            Button { withAnimation { proxy.scrollTo("s\(i)", anchor: .top) } } label: {
                                HStack(alignment: .firstTextBaseline, spacing: 10) {
                                    Text(String(format: "%02d", i + 1)).font(Tend.F.mono(12)).foregroundStyle(Tend.C.muted).frame(width: 18, alignment: .leading)
                                    Text(s.heading).font(Tend.F.sans(14)).foregroundStyle(Tend.C.text3).multilineTextAlignment(.leading)
                                    Spacer(minLength: 0)
                                }
                                .padding(.vertical, 5)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 14).padding(.horizontal, 16)
                    .card(radius: 18)
                    .padding(.horizontal, Tend.S.sideWide)

                    VStack(alignment: .leading, spacing: 22) {
                        ForEach(Array(doc.sections.enumerated()), id: \.offset) { i, s in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .firstTextBaseline, spacing: 10) {
                                    Text(String(format: "%02d", i + 1)).font(Tend.F.mono(12)).foregroundStyle(Tend.C.accent)
                                    Text(s.heading).font(Tend.F.serif(24)).foregroundStyle(Tend.C.text)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                ForEach(s.paragraphs, id: \.self) { para in
                                    Text(para).font(Tend.F.sans(15)).lineSpacing(6).foregroundStyle(Tend.C.legalBody)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .id("s\(i)")
                        }
                    }
                    .padding(.horizontal, Tend.S.side)

                    if doc.hasActions {
                        VStack(spacing: 8) {
                            Button(["Download my data", "Preparing export…", "✓ Sent to alex@moreno.co"][model.exportState], action: exportData)
                                .font(Tend.F.sans(15, .semibold)).foregroundStyle(Tend.C.text)
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .background(Tend.C.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Tend.C.ink(0.18), lineWidth: 1))
                            Button(model.deleteArmed ? "Tap again to permanently delete" : "Delete my account", action: deleteAccount)
                                .font(Tend.F.sans(15, .semibold)).foregroundStyle(Tend.C.clay)
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Tend.C.clayTint(0.3), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, Tend.S.sideWide)
                    }

                    (Text("Questions? Write to ") + Text(doc.email).foregroundColor(Tend.C.accent) + Text(". Tend Labs Ltd., 12 Greenhouse Lane, London."))
                        .font(Tend.F.sans(13)).lineSpacing(4).foregroundStyle(Tend.C.text4)
                        .padding(.top, 16)
                        .overlay(alignment: .top) { RowDivider(opacity: 0.1) }
                        .padding(.horizontal, Tend.S.side)
                }
                .padding(.top, 8).padding(.bottom, 40)
                .entrance()
            }
        }
        .tendScreen()
    }

    private func exportData() {
        guard model.exportState == 0 else { return }
        model.exportState = 1
        Task { try? await Task.sleep(for: .milliseconds(1200)); model.exportState = 2 }
    }

    /// Needs a second tap within 3 s.
    private func deleteAccount() {
        if !model.deleteArmed {
            model.deleteArmed = true
            Task { try? await Task.sleep(for: .seconds(3)); model.deleteArmed = false }
        } else {
            model.deleteArmed = false
            model.signOut()
        }
    }
}
