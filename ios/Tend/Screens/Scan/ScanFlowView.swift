import SwiftUI

enum ScanRoute: Hashable { case idResult, addDetails, diagnosis }

/// The scanner, presented as a full-screen cover with its own navigation stack.
struct ScanFlowView: View {
    @State var mode: ScanMode
    @State var path: [ScanRoute] = []
    /// Index of the picked candidate and the details being added.
    @State var pick = 0
    @State var nickname = ""
    @State var room = "Living room"
    @State var every = SampleData.candidates[0].waterEvery

    init(initialMode: ScanMode) { _mode = State(initialValue: initialMode) }

    var body: some View {
        NavigationStack(path: $path) {
            ScannerView(mode: $mode) { finishedMode in
                pick = 0; nickname = ""; every = SampleData.candidates[0].waterEvery
                path.append(finishedMode == .identify ? .idResult : .diagnosis)
            }
            .navigationDestination(for: ScanRoute.self) { r in
                switch r {
                case .idResult:
                    IdResultView(pick: $pick, every: $every) {
                        room = bestRoom(for: SampleData.candidates[pick])
                        path.append(.addDetails)
                    }
                case .addDetails:
                    AddDetailsView(candidate: SampleData.candidates[pick], nickname: $nickname, room: $room, every: $every)
                case .diagnosis:
                    DiagnosisView()
                }
            }
        }
    }
}

/// The room matching the most of a species' ideal ranges.
func roomScore(_ room: String, _ c: ScanCandidate) -> Int {
    let r = Room.reading(room)
    return [Care.inRange(r.humidity, c.humidity), Care.inRange(r.lux, c.lightRange), Care.inRange(r.temperature, c.temperature)]
        .filter { $0 }.count
}

func bestRoom(for c: ScanCandidate) -> String {
    Room.order.max { roomScore($0, c) < roomScore($1, c) } ?? "Living room"
}

// MARK: Scanner

struct ScannerView: View {
    @Binding var mode: ScanMode
    let onResult: (ScanMode) -> Void
    @Environment(AppModel.self) var model
    @State var camera = CameraController()
    @State var analyzing = false
    @State var breathe = false

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                TextLinkButton(title: "Close") { model.cover = nil }
                Spacer()
                Text("AI scanner").font(Tend.F.sans(15, .semibold)).foregroundStyle(Tend.C.text)
                Spacer()
                Color.clear.frame(width: 44, height: 1)
            }

            SegmentedPicker(options: [(ScanMode.identify, "Identify"), (.diagnose, "Diagnose")], selection: $mode, height: 40)
                .disabled(analyzing)

            viewfinder

            Text(mode == .identify
                 ? "Point at a few leaves in soft light. Tend identifies the plant and suggests a care plan."
                 : "Get close to spots, webbing or discoloration. Underside of leaves helps most.")
                .font(Tend.F.sans(14)).lineSpacing(3).foregroundStyle(Tend.C.text3)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if !model.isPremium {
                HStack(spacing: 8) {
                    Text("\(model.scansLeft) of 3 free scans left this month").foregroundStyle(Tend.C.text4)
                    Button("Go unlimited ›") { model.openPremium() }.foregroundStyle(Tend.C.accent).fontWeight(.semibold)
                }
                .font(Tend.F.sans(13))
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)

            Button(analyzing ? "Analyzing…" : (mode == .identify ? "Identify plant" : "Check health"), action: capture)
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.horizontal, Tend.S.side)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .entrance()
        .background { AmbientBackground() }
        .toolbar(.hidden, for: .navigationBar)
        .task { await camera.start() }
        .onDisappear { camera.stop() }
    }

    private var viewfinder: some View {
        ZStack {
            StripedPlaceholder(label: "", stripe: 7, palette: .wide, radius: 0)
            if camera.status == .running {
                CameraPreview(session: camera.session)
            }

            // Inset frame: breathes while aiming; glows green while analysing.
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(analyzing ? Tend.C.accent : Tend.C.ink(0.45), lineWidth: 1.5)
                .shadow(color: analyzing ? Tend.C.leaf(0.14) : .clear, radius: 20)
                .padding(.vertical, 56).padding(.horizontal, 46)
                .opacity(breathe ? 1 : 0.55)
                .scaleEffect(breathe ? 1.015 : 1)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: breathe)
                .animation(.easeOut(duration: 0.4), value: analyzing)

            if analyzing { ScanLine().padding(.horizontal, 46) }

            if camera.status != .running {
                VStack(spacing: 14) {
                    LeafDrawIllustration()
                    Text((analyzing ? (mode == .identify ? "Matching 30,000 species…" : "Checking for 120 pests & diseases…")
                          : (mode == .identify ? "camera · frame a few leaves" : "camera · get close to the problem")).uppercased())
                        .font(Tend.F.mono(10)).tracking(0.6).foregroundStyle(Tend.C.text5)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 70)
            }
        }
        .frame(height: 440)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .onAppear { breathe = true }
    }

    private func capture() {
        guard !analyzing else { return }
        guard model.canScan else { model.openPremium(); return }
        analyzing = true
        model.consumeScan()
        let m = mode
        Task { @MainActor in
            // Placeholder for the plant-ID API / Core ML diagnosis call.
            try? await Task.sleep(for: .milliseconds(1600))
            model.buzz(.medium)
            analyzing = false
            onResult(m)
        }
    }
}

/// A green line sweeping between 12% and 84% of the frame (1.6 s, ease-in-out).
private struct ScanLine: View {
    @State var down = false
    var body: some View {
        GeometryReader { g in
            LinearGradient(colors: [.clear, Tend.C.accent, .clear], startPoint: .leading, endPoint: .trailing)
                .frame(height: 2)
                .shadow(color: Tend.C.accent, radius: 7)
                .offset(y: g.size.height * (down ? 0.84 : 0.12))
                .onAppear { withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { down = true } }
        }
        .transition(.opacity)
    }
}

// MARK: Identify result

struct IdResultView: View {
    @Binding var pick: Int
    @Binding var every: Int
    let onAdd: () -> Void
    @Environment(AppModel.self) var model

    var body: some View {
        let c = SampleData.candidates[pick]
        let word = c.confidence >= 85 ? "Very likely" : c.confidence >= 50 ? "Likely" : "Possible"

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    BackPillText(title: "‹ Rescan")
                    Spacer()
                    Text("IDENTIFIED").font(Tend.F.mono(11)).foregroundStyle(Tend.C.accent)
                }

                ScreenTitle(text: "It's a \(c.species.lowercased()).")

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("How sure Tend is").foregroundStyle(Tend.C.text3)
                        Spacer()
                        Text(word).fontWeight(.semibold).foregroundStyle(Tend.C.brandInk)
                    }
                    .font(Tend.F.sans(13))
                    BarMeter(fraction: Double(c.confidence) / 100, color: Tend.C.brand, height: 6)
                    Text("Matched on leaf shape, vein pattern and the flower spathe. Two lookalikes are listed below if yours seems different.")
                        .font(Tend.F.sans(13)).lineSpacing(2).foregroundStyle(Tend.C.text4)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 10) {
                    ForEach(Array(SampleData.candidates.enumerated()), id: \.offset) { i, cand in
                        candidateRow(i, cand)
                    }
                }

                HStack(spacing: 0) {
                    careCell("Water", "Every \(c.waterEvery) days", leading: 0)
                    Rectangle().fill(Tend.C.ink(0.13)).frame(width: 1)
                    careCell("Light", c.light, leading: 8)
                    Rectangle().fill(Tend.C.ink(0.13)).frame(width: 1)
                    careCell("Humidity", c.humidityText, leading: 8)
                }
                .fixedSize(horizontal: false, vertical: true)
                .overlay(alignment: .top) { RowDivider(opacity: 0.13) }
                .overlay(alignment: .bottom) { RowDivider(opacity: 0.13) }

                Text(c.care).font(Tend.F.sans(14)).lineSpacing(3).foregroundStyle(Tend.C.text3)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Not sure it's right?").font(Tend.F.sans(14, .semibold)).foregroundStyle(Tend.C.text)
                        Text("A botanist checks your photo within 24 hours.").font(Tend.F.sans(12.5)).foregroundStyle(Tend.C.text3)
                    }
                    Spacer(minLength: 0)
                    Button(model.expertSent ? "Sent ✓" : "Ask") { model.askExpert() }
                        .font(Tend.F.sans(13, .semibold)).foregroundStyle(Tend.C.text)
                        .padding(.horizontal, 14).frame(height: 36)
                        .background(Tend.C.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Tend.C.ink(0.2), lineWidth: 1))
                        .buttonStyle(.plain)
                }
                .padding(.vertical, 12).padding(.leading, 16).padding(.trailing, 12)
                .background(Tend.C.amberTint(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Tend.C.amberTint(0.22), lineWidth: 1))

                Button("Add to my plants", action: onAdd).buttonStyle(PrimaryButtonStyle()).padding(.top, 6)
            }
            .padding(.horizontal, Tend.S.side)
            .padding(.top, 8).padding(.bottom, 30)
            .entrance()
        }
        .background { AmbientBackground() }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func candidateRow(_ i: Int, _ cand: ScanCandidate) -> some View {
        let on = pick == i
        return Button {
            withAnimation(.easeOut(duration: 0.2)) { pick = i; every = cand.waterEvery }
        } label: {
            HStack(spacing: 14) {
                StripedPlaceholder(label: "photo", radius: 14, labelSize: 7).frame(width: 60, height: 60)
                VStack(alignment: .leading, spacing: 2) {
                    Text(cand.species).font(Tend.F.serif(21)).foregroundStyle(Tend.C.text)
                    Text(cand.latin).font(Tend.F.serifItalic(14)).foregroundStyle(Tend.C.text4)
                }
                Spacer(minLength: 0)
                Text("\(cand.confidence)%").font(Tend.F.mono(12)).foregroundStyle(i == 0 ? Tend.C.accent : Tend.C.text5)
            }
            .padding(.vertical, 10).padding(.leading, 10).padding(.trailing, 16)
            .background(on ? Tend.C.leaf(0.14) : Tend.C.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(on ? Tend.C.accent : Tend.C.ink(0.1), lineWidth: 1.5))
            .shadow(color: on ? Tend.C.leaf(0.07) : .clear, radius: 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func careCell(_ k: String, _ v: String, leading: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(k.uppercased()).font(Tend.F.sans(11, .semibold)).tracking(1.1).foregroundStyle(Tend.C.text5)
            Text(v).font(Tend.F.sans(14, .medium)).foregroundStyle(Tend.C.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12).padding(.leading, leading).padding(.trailing, 8)
    }
}

/// "‹ Rescan" / "‹ Back" text button that pops the current screen.
struct BackPillText: View {
    let title: String
    @Environment(\.dismiss) var dismiss
    var body: some View { TextLinkButton(title: title) { dismiss() } }
}

// MARK: Add details

struct AddDetailsView: View {
    let candidate: ScanCandidate
    @Binding var nickname: String
    @Binding var room: String
    @Binding var every: Int
    @Environment(AppModel.self) var model
    @FocusState var focused: Bool

    var body: some View {
        let best = bestRoom(for: candidate)
        let r = Room.reading(room)
        let score = roomScore(room, candidate)

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    BackPillText(title: "‹ Back")
                    Spacer()
                    Text("New plant").font(Tend.F.sans(15, .semibold)).foregroundStyle(Tend.C.text)
                    Spacer()
                    Color.clear.frame(width: 44, height: 1)
                }
                ScreenTitle(text: "Make it yours.")

                VStack(alignment: .leading, spacing: 10) {
                    Text("Name").font(Tend.F.sans(13, .semibold)).foregroundStyle(Tend.C.text)
                    TextField("e.g. \(candidate.species.split(separator: " ").first ?? "")", text: $nickname)
                        .font(Tend.F.sans(16)).foregroundStyle(Tend.C.text)
                        .focused($focused)
                        .submitLabel(.done)
                        .padding(.horizontal, 16).frame(height: 52)
                        .background(Tend.C.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(focused ? Tend.C.accent : Tend.C.ink(0.18), lineWidth: 1))
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(focused ? Tend.C.leaf(0.15) : .clear, lineWidth: 6))
                        .animation(.easeOut(duration: 0.2), value: focused)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Where it lives").font(Tend.F.sans(13, .semibold)).foregroundStyle(Tend.C.text)
                    FlowLayout(spacing: 8) {
                        ForEach(Room.order, id: \.self) { rn in
                            Chip(label: rn, selected: room == rn, height: 38, hPad: 14, trailing: {
                                if rn == best {
                                    Text("BEST").font(Tend.F.sans(10, .bold)).tracking(0.4)
                                        .foregroundStyle(room == rn ? Tend.C.leafFillLight : Tend.C.accent)
                                }
                            }) { room = rn; model.buzz(.selection) }
                        }
                    }
                    Text("\(room): \(Int(r.humidity))% humidity, \(Care.fmtLux(r.lux)), \(model.temp(r.temperature, decimals: 1)). "
                         + (score == 3 ? "A great match." : score == 2 ? "A decent match. Tend will keep an eye on it." : "Not ideal for this plant."))
                        .font(Tend.F.sans(13)).lineSpacing(3).foregroundStyle(Tend.C.text4)
                        .fixedSize(horizontal: false, vertical: true)
                }

                IntervalStepper(every: every,
                                hint: every == candidate.waterEvery ? "Recommended starting point" : "We suggest \(candidate.waterEvery) days",
                                minus: { every = max(1, every - 1) },
                                plus: { every = min(45, every + 1) })

                Button("Add to collection") {
                    model.addPlant(candidate: candidate, nickname: nickname, room: room, every: every)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 10)
            }
            .padding(.horizontal, Tend.S.side)
            .padding(.top, 8).padding(.bottom, 30)
            .entrance()
        }
        .scrollDismissesKeyboard(.interactively)
        .background { AmbientBackground() }
        .toolbar(.hidden, for: .navigationBar)
    }
}
