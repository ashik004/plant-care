import SwiftUI

struct DiagnosisView: View {
    @Environment(AppModel.self) var model

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    BackPill()
                    Spacer()
                    Text("DIAGNOSIS · FIGGY").font(Tend.F.mono(11)).foregroundStyle(Tend.C.clay)
                }
                .padding(.horizontal, Tend.S.sideWide)

                GeometryReader { g in
                    let w = g.size.width - 8
                    HStack(spacing: 8) {
                        StripedPlaceholder(label: "your photo", stripe: 7, palette: .wide, radius: 22, labelSize: 9, alignment: .bottomLeading)
                            .overlay(alignment: .topLeading) {
                                Circle().stroke(Tend.C.clay, lineWidth: 1.5).frame(width: 54, height: 54)
                                    .shadow(color: Tend.C.clayTint(0.5), radius: 9)
                                    .offset(x: 60, y: 44)
                            }
                            .frame(width: w * 1.4 / 2.4)
                        StripedPlaceholder(label: "close-up · underside", stripe: 7, palette: .clay, radius: 22, labelSize: 9, alignment: .bottomLeading)
                            .frame(width: w / 2.4)
                    }
                }
                .frame(height: 200)
                .padding(.horizontal, Tend.S.sideWide)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Spider mites").font(Tend.F.serif(42)).foregroundStyle(Tend.C.text)
                    FlowLayout(spacing: 8) {
                        TagPill(text: "87% match", color: Tend.C.clay, fill: Tend.C.clayTint(0.14))
                        TagPill(text: "Moderate · caught early", color: Tend.C.amber, fill: Tend.C.amberTint(0.14))
                        TagPill(text: "Contagious", color: Tend.C.text3, fill: Tend.C.ink(0.08))
                    }
                }
                .padding(.horizontal, Tend.S.side)

                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow(text: "What Tend saw")
                    VStack(alignment: .leading, spacing: 8) {
                        Text("· Fine webbing where leaves meet the stem")
                        Text("· Pale speckling across the upper surface")
                        Text("· Mostly the lower leaves. New growth looks clean")
                    }
                    .font(Tend.F.sans(14)).lineSpacing(2).foregroundStyle(Tend.C.text2)
                    Text("Likely cause: dry air. Living room humidity has stayed under 45% for 9 days.")
                        .font(Tend.F.sans(13)).lineSpacing(3).foregroundStyle(Tend.C.text4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 16).padding(.horizontal, 18)
                .card()
                .padding(.horizontal, Tend.S.side)

                VStack(alignment: .leading, spacing: 4) {
                    SectionHeader(title: "Treatment") {
                        Text("\(model.treatDone.count) of 4 done").font(Tend.F.sans(12)).foregroundStyle(Tend.C.text4)
                    }
                    .padding(.bottom, 6)
                    ForEach(Array(SampleData.treatment.enumerated()), id: \.offset) { i, step in
                        let done = model.treatDone.contains(i)
                        Button { model.toggleTreatStep(i) } label: {
                            HStack(alignment: .top, spacing: 14) {
                                StepCheck(done: done, number: "\(i + 1)")
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(step.title).font(Tend.F.sans(15, .semibold)).foregroundStyle(done ? Tend.C.text5 : Tend.C.text)
                                    Text(step.body).font(Tend.F.sans(13)).lineSpacing(2).foregroundStyle(Tend.C.text4)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 14)
                            .overlay(alignment: .top) { RowDivider(opacity: 0.1) }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(done ? .isSelected : [])
                    }
                }
                .padding(.horizontal, Tend.S.side)

                Group {
                    if model.treatActive {
                        Text("✓ Neem reminders every 5 days, for 3 weeks")
                            .font(Tend.F.sans(15, .semibold)).foregroundStyle(Tend.C.accent)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(Tend.C.leaf(0.1), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .transition(.opacity)
                    } else {
                        Button("Add treatment reminders") { model.startTreatment() }
                            .buttonStyle(PrimaryButtonStyle())
                    }
                }
                .padding(.horizontal, Tend.S.side)
            }
            .padding(.top, 8).padding(.bottom, 40)
            .entrance()
        }
        .tendScreen()
    }
}
