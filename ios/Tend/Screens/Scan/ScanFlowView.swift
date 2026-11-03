import SwiftUI
import PhotosUI

enum ScanRoute: Hashable { case idResult, addDetails, diagnosis, noMatch }

/// What a scan produced.
enum ScanOutcome {
    case identified([ScanCandidate], photo: UIImage?)
    case noMatch(photo: UIImage?)
    case diagnosed
}

/// The scanner, presented as a full-screen cover with its own navigation stack.
struct ScanFlowView: View {
    @State var mode: ScanMode
    @State var path: [ScanRoute] = []
    @State var candidates: [ScanCandidate] = SampleData.candidates
    @State var photo: UIImage?
    /// Index of the picked candidate and the details being added.
    @State var pick = 0
    @State var nickname = ""
    @State var room = "Living room"
    @State var every = 7

    init(initialMode: ScanMode) { _mode = State(initialValue: initialMode) }

    var body: some View {
        NavigationStack(path: $path) {
            ScannerView(mode: $mode) { outcome in
                switch outcome {
                case .identified(let found, let shot):
                    candidates = found; photo = shot
                    pick = 0; nickname = ""; every = found.first?.waterEvery ?? 7
                    path.append(.idResult)
                case .noMatch(let shot):
                    photo = shot
                    path.append(.noMatch)
                case .diagnosed:
                    path.append(.diagnosis)
                }
            }
            .navigationDestination(for: ScanRoute.self) { r in
                switch r {
                case .idResult:
                    IdResultView(candidates: candidates, photo: photo, pick: $pick, every: $every) {
                        room = bestRoom(for: candidates[pick])
                        path.append(.addDetails)
                    }
                case .addDetails:
                    AddDetailsView(candidate: candidates[min(pick, candidates.count - 1)], nickname: $nickname, room: $room, every: $every)
                case .diagnosis:
                    DiagnosisView()
                case .noMatch:
                    NoMatchView(photo: photo)
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
    let onResult: (ScanOutcome) -> Void
    @Environment(AppModel.self) var model
    @State var camera = CameraController()
    @State var analyzing = false
    @State var breathe = false
    /// The frozen frame shown while Tend analyses it.
    @State var still: UIImage?
    @State var showPicker = false
    @State var pickerItem: PhotosPickerItem?
    var identifier: PlantIdentifier = PlantIdentifiers.current

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

            HStack(spacing: 16) {
                if mode == .identify {
                    Button { showPicker = true } label: {
                        Label("Choose a photo", systemImage: "photo.on.rectangle")
                            .font(Tend.F.sans(13, .semibold)).foregroundStyle(Tend.C.accent)
                    }
                    .buttonStyle(.plain)
                    .disabled(analyzing)
                }
                if !model.isPremium {
                    HStack(spacing: 8) {
                        Text("\(model.scansLeft) of 3 free scans left").foregroundStyle(Tend.C.text4)
                        Button("Go unlimited ›") { model.openPremium() }.foregroundStyle(Tend.C.accent).fontWeight(.semibold)
                    }
                    .font(Tend.F.sans(13))
                    .buttonStyle(.plain)
                }
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
        .photosPicker(isPresented: $showPicker, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            pickerItem = nil
            Task {
                guard let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else {
                    model.showToast(IdentifyError.unreadablePhoto.localizedDescription)
                    return
                }
                identify(image)
            }
        }
        .task { await camera.start() }
        .onAppear { still = nil }
        .onDisappear { camera.stop() }
    }

    private var viewfinder: some View {
        ZStack {
            StripedPlaceholder(label: "", stripe: 7, palette: .wide, radius: 0)
            if camera.status == .running {
                CameraPreview(session: camera.session)
            }
            if let still {
                Image(uiImage: still).resizable().scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity).clipped()
                    .transition(.opacity)
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

            if camera.status != .running && still == nil {
                VStack(spacing: 14) {
                    LeafDrawIllustration()
                    Text(placeholderText.uppercased())
                        .font(Tend.F.mono(10)).tracking(0.6).foregroundStyle(Tend.C.text5)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 70)
            }

            if identifier.isDemo && mode == .identify {
                VStack {
                    Spacer()
                    Text("DEMO · NO IDENTIFICATION SERVICE SET UP").font(Tend.F.mono(9)).tracking(0.5)
                        .foregroundStyle(Tend.C.clay)
                        .padding(.horizontal, 10).frame(height: 24)
                        .background(Color(lightRGB: 0xFFFCF5, lightAlpha: 0.9, darkRGB: 0x172017, darkAlpha: 0.9), in: Capsule())
                        .padding(.bottom, 16)
                }
            }
        }
        .frame(height: 440)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .animation(.easeOut(duration: 0.25), value: still != nil)
        .onAppear { breathe = true }
    }

    private var placeholderText: String {
        if analyzing { return mode == .identify ? "Matching species…" : "Checking for pests & diseases…" }
        if camera.status == .denied { return "camera access is off · choose a photo instead" }
        if camera.status == .unavailable { return "no camera here · choose a photo instead" }
        return mode == .identify ? "camera · frame a few leaves" : "camera · get close to the problem"
    }

    private func capture() {
        guard !analyzing else { return }
        guard model.canScan else { model.openPremium(); return }

        if mode == .diagnose {
            // Diagnosis is still a placeholder: wire a disease model or API here.
            analyzing = true
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(1600))
                model.consumeScan()
                model.buzz(.medium)
                analyzing = false
                onResult(.diagnosed)
            }
            return
        }

        guard camera.status == .running else { showPicker = true; return }
        Task { @MainActor in
            do {
                let data = try await camera.capturePhoto()
                guard let image = UIImage(data: data) else { throw CameraController.CaptureError.failed }
                identify(image)
            } catch {
                model.showToast("Couldn't take the photo. Try again.")
            }
        }
    }

    /// Sends the photo for identification. A scan is only used up when it succeeds.
    private func identify(_ image: UIImage) {
        guard !analyzing else { return }
        guard model.canScan else { model.openPremium(); return }
        guard let jpeg = PhotoPrep.jpeg(image) else { model.showToast(IdentifyError.unreadablePhoto.localizedDescription); return }
        withAnimation { still = image }
        analyzing = true
        let identifier = self.identifier
        Task { @MainActor in
            defer { analyzing = false }
            do {
                let found = try await identifier.identify(photos: [jpeg])
                model.consumeScan()
                model.buzz(.medium)
                onResult(.identified(found, photo: image))
            } catch IdentifyError.noMatch {
                model.buzz(.warning)
                onResult(.noMatch(photo: image))
            } catch {
                withAnimation { still = nil }
                model.buzz(.warning)
                model.showToast((error as? LocalizedError)?.errorDescription ?? "Identification is unavailable right now.")
            }
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
    let candidates: [ScanCandidate]
    let photo: UIImage?
    @Binding var pick: Int
    @Binding var every: Int
    let onAdd: () -> Void
    @Environment(AppModel.self) var model

    var body: some View {
        let c = candidates[min(pick, candidates.count - 1)]
        let word = c.confidence >= 85 ? "Very likely" : c.confidence >= 50 ? "Likely" : "Possible"
        let others = candidates.count - 1

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    BackPillText(title: "‹ Rescan")
                    Spacer()
                    Text(c.isDemo ? "DEMO RESULT" : "IDENTIFIED").font(Tend.F.mono(11))
                        .foregroundStyle(c.isDemo ? Tend.C.clay : Tend.C.accent)
                }

                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        ScreenTitle(text: c.hasCommonName ? "It's a \(c.species.lowercased())." : "It's \(c.species).")
                        if c.hasCommonName {
                            Text(c.latin).font(Tend.F.serifItalic(17)).foregroundStyle(Tend.C.text4)
                        }
                    }
                    Spacer(minLength: 0)
                    if let photo {
                        Image(uiImage: photo).resizable().scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .accessibilityLabel("Your photo")
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("How sure Tend is").foregroundStyle(Tend.C.text3)
                        Spacer()
                        Text(word).fontWeight(.semibold).foregroundStyle(Tend.C.brandInk)
                    }
                    .font(Tend.F.sans(13))
                    BarMeter(fraction: Double(c.confidence) / 100, color: Tend.C.brand, height: 6)
                    Text(confidenceLine(top: candidates[0], others: others))
                        .font(Tend.F.sans(13)).lineSpacing(2).foregroundStyle(Tend.C.text4)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 10) {
                    ForEach(Array(candidates.enumerated()), id: \.offset) { i, cand in
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

                VStack(alignment: .leading, spacing: 10) {
                    if let toxic = c.toxicToPets {
                        TagPill(text: toxic ? "Toxic to cats and dogs" : "Safe for cats and dogs",
                                color: toxic ? Tend.C.clay : Tend.C.accent,
                                fill: toxic ? Tend.C.clayTint(0.12) : Tend.C.leaf(0.12))
                    }
                    Text(c.care).font(Tend.F.sans(14)).lineSpacing(3).foregroundStyle(Tend.C.text3)
                        .fixedSize(horizontal: false, vertical: true)
                    if let note = careSourceNote(c) {
                        Text(note).font(Tend.F.sans(12)).foregroundStyle(Tend.C.text5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

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

                Text(c.isDemo ? "DEMO RESULT · SET TendAPIBaseURL TO IDENTIFY REAL PLANTS" : "IDENTIFICATION BY PL@NTNET")
                    .font(Tend.F.mono(9)).tracking(0.5).foregroundStyle(Tend.C.muted)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, Tend.S.side)
            .padding(.top, 8).padding(.bottom, 30)
            .entrance()
        }
        .background { AmbientBackground() }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func confidenceLine(top: ScanCandidate, others: Int) -> String {
        let lookalikes = others == 0 ? "" : others == 1 ? " A lookalike is listed below if yours seems different."
            : " \(Care.numberWords[min(others, 9)]) lookalikes are listed below if yours seems different."
        if top.isDemo {
            return "Matched on leaf shape, vein pattern and the flower spathe." + lookalikes
        }
        if top.confidence < 50 {
            return "Tend isn't certain. Compare the options below, or rescan with a clear photo of a single leaf or flower."
        }
        return "Matched from your photo against Pl@ntNet's plant database." + lookalikes
    }

    private func careSourceNote(_ c: ScanCandidate) -> String? {
        switch c.careSource {
        case .species: nil
        case .genus: "Care advice covers the \(c.genus ?? "same") genus. Tend fine-tunes it as it learns your plant."
        case .family: "Care advice covers the \(c.family ?? "same") family. Tend fine-tunes it as it learns your plant."
        case .general: "Tend starts this one on a general schedule. Check the soil before watering for the first couple of weeks."
        }
    }

    private func candidateRow(_ i: Int, _ cand: ScanCandidate) -> some View {
        let on = pick == i
        return Button {
            withAnimation(.easeOut(duration: 0.2)) { pick = i; every = cand.waterEvery }
        } label: {
            HStack(spacing: 14) {
                ReferenceThumb(url: cand.referenceImageURL).frame(width: 60, height: 60)
                VStack(alignment: .leading, spacing: 2) {
                    Text(cand.species).font(Tend.F.serif(21)).foregroundStyle(Tend.C.text).lineLimit(1).minimumScaleFactor(0.8)
                    if cand.hasCommonName {
                        Text(cand.latin).font(Tend.F.serifItalic(14)).foregroundStyle(Tend.C.text4).lineLimit(1)
                    }
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
        .accessibilityLabel("\(cand.species), \(cand.confidence) percent")
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

/// A reference photo of the species, or the striped placeholder while it loads.
struct ReferenceThumb: View {
    let url: URL?
    var radius: CGFloat = 14
    var body: some View {
        AsyncImage(url: url) { phase in
            if let image = phase.image {
                image.resizable().scaledToFill()
            } else {
                StripedPlaceholder(label: "photo", radius: 0, labelSize: 7)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .accessibilityHidden(true)
    }
}

/// Shown when Tend couldn't recognise the photo. It doesn't use a scan.
struct NoMatchView: View {
    let photo: UIImage?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                BackPillText(title: "‹ Back")
                Spacer()
            }
            BlurryScanCard(photo: photo, title: "Couldn't identify this one", subtitle: "This one didn't use a scan.")
            ScanTipsCard()
            Spacer(minLength: 20)
            Button("Retake photo") { dismiss() }.buttonStyle(PrimaryButtonStyle())
        }
        .padding(.horizontal, Tend.S.sideWide)
        .padding(.top, 8).padding(.bottom, 16)
        .entrance()
        .background { AmbientBackground() }
        .toolbar(.hidden, for: .navigationBar)
    }
}

/// The blurred photo with a warning banner (no match / blurry scan).
struct BlurryScanCard: View {
    var photo: UIImage?
    var title = "Too blurry to read"
    var subtitle = "This one didn't use a scan."

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if let photo {
                    Image(uiImage: photo).resizable().scaledToFill()
                } else {
                    Stripes(a: Color(light: 0xDCE6CF, dark: 0x1C261B), b: Tend.C.stripeWideB, width: 7)
                }
            }
            .blur(radius: 5).padding(-10)
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Tend.C.clayTint(0.7), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                .padding(.vertical, 50).padding(.horizontal, 40)
            HStack(spacing: 12) {
                Text("!").font(Tend.F.sans(18, .bold)).foregroundStyle(Tend.C.clay)
                    .frame(width: 36, height: 36).background(Tend.C.clayTint(0.14), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(Tend.F.sans(15, .semibold)).foregroundStyle(Tend.C.text)
                    Text(subtitle).font(Tend.F.sans(13)).foregroundStyle(Tend.C.text3)
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
    }
}

struct ScanTipsCard: View {
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(["Hold still for a second before tapping", "Fill the frame with one leaf or flower", "Move nearer a window for softer light"].enumerated()), id: \.offset) { i, t in
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
