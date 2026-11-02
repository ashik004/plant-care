import SwiftUI

/// Growth timelapse: a film frame that steps through the 8 weekly photos (0.65 s per frame).
/// In production, build the film from the weekly photos with AVAssetWriter.
struct TimelapseView: View {
    let plantId: String
    @Environment(AppModel.self) var model
    @State var frame = 0
    @State var playing = false
    @State var player: Task<Void, Never>?

    var body: some View {
        let p = model.plant(plantId) ?? SampleData.plants[3]
        let hs = p.heights
        let mn = hs.min() ?? 0, mx = hs.max() ?? 1

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                BackPill(label: p.name) { stop(); dismissAction() }
                    .padding(.horizontal, Tend.S.sideWide)

                VStack(alignment: .leading, spacing: 6) {
                    Eyebrow(text: "Growth timelapse")
                    ScreenTitle(text: frame == 0 ? "\(hs[0]) cm at week 37" : "+\(hs[frame] - hs[0]) cm in \(frame) week\(frame > 1 ? "s" : "")")
                        .contentTransition(.numericText())
                        .animation(.snappy, value: frame)
                }
                .padding(.horizontal, Tend.S.side)

                filmFrame(height: hs[frame])
                    .padding(.horizontal, Tend.S.sideWide)

                HStack(spacing: 12) {
                    Button(action: toggle) {
                        ZStack {
                            Circle().fill(Tend.C.brandButton)
                            if playing {
                                HStack(spacing: 6 * 18 / 14) {
                                    RoundedRectangle(cornerRadius: 1).fill(.white).frame(width: 3.8, height: 14)
                                    RoundedRectangle(cornerRadius: 1).fill(.white).frame(width: 3.8, height: 14)
                                }
                            } else {
                                SVGShape(Icon.play, viewBox: CGSize(width: 14, height: 14)).fill(.white).frame(width: 18, height: 18)
                            }
                        }
                        .frame(width: 56, height: 56)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(playing ? "Pause" : "Play")

                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(Array(hs.enumerated()), id: \.offset) { i, v in
                            Button {
                                stop()
                                withAnimation { frame = i }
                                model.buzz(.selection)
                            } label: {
                                VStack(spacing: 5) {
                                    GeometryReader { g in
                                        VStack {
                                            Spacer(minLength: 0)
                                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                                .fill(i <= frame ? Tend.C.brand : Tend.C.ink(0.16))
                                                .frame(height: min(34, g.size.height * (0.3 + 0.7 * Double(v - mn) / Double(max(1, mx - mn)))))
                                        }
                                    }
                                    Text("W\(37 + i)").font(Tend.F.mono(9)).foregroundStyle(i == frame ? Tend.C.text : Tend.C.muted)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("W\(37 + i)")
                        }
                    }
                    .frame(height: 56)
                    .animation(.easeOut(duration: 0.3), value: frame)
                }
                .padding(.horizontal, Tend.S.sideWide)

                Text("Built from your weekly photos. Tend lines them up and steadies the framing for you. The illustration stands in for real photos here.")
                    .font(Tend.F.sans(13)).lineSpacing(3).foregroundStyle(Tend.C.text4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Tend.S.side)

                HStack(spacing: 10) {
                    Button("Save film") {
                        guard model.isPremium else { model.openPremium(); return }
                        model.buzz(.success)
                        model.showToast("\(p.name)'s film is saved to Photos.")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    ShareLink(item: "\(p.name) grew \(hs.last! - hs.first!) cm in 8 weeks with Tend.") { Text("Share") }
                        .buttonStyle(PrimaryButtonStyle(kind: .outline))
                }
                .padding(.horizontal, Tend.S.side)
                .padding(.top, 8)
            }
            .padding(.top, 8)
            .padding(.bottom, 40)
            .entrance()
        }
        .tendScreen()
        .onAppear {
            frame = 0
            Task { try? await Task.sleep(for: .milliseconds(500)); if !playing { toggle() } }
        }
        .onDisappear { stop() }
    }

    @Environment(\.dismiss) var dismiss
    private func dismissAction() { dismiss() }

    private func filmFrame(height: Int) -> some View {
        ZStack(alignment: .bottom) {
            LinearGradient.angle(175, stops: [.init(color: Tend.C.illoTop, location: 0),
                                              .init(color: Tend.C.illoBottom, location: 0.7),
                                              .init(color: Color(light: 0xEFE7D6, dark: 0x141C13), location: 1)])
            // Ruler ticks on the left
            VStack(alignment: .leading) {
                ForEach(0..<7, id: \.self) { i in
                    Rectangle().fill(Tend.C.ink(i.isMultiple(of: 2) ? 0.3 : 0.2)).frame(width: i.isMultiple(of: 2) ? 10 : 6, height: 1.5)
                    if i < 6 { Spacer() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.leading, 18).padding(.vertical, 56)

            TimelapsePlant(frame: frame).padding(.bottom, 30)

            HStack {
                Text("WEEK \(37 + frame) PHOTO").font(Tend.F.mono(10)).tracking(0.6).foregroundStyle(Tend.C.text3)
                    .padding(.horizontal, 11).frame(height: 28)
                    .background(Color(lightRGB: 0xFFFCF5, lightAlpha: 0.85, darkRGB: 0x172017, darkAlpha: 0.85), in: Capsule())
                Spacer()
                Text("\(height) cm").font(Tend.F.sans(13, .semibold)).foregroundStyle(Tend.C.onInverse)
                    .padding(.horizontal, 11).frame(height: 28)
                    .background(Tend.C.inverse, in: Capsule())
                    .contentTransition(.numericText())
            }
            .padding(16)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(height: 400)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(Tend.C.ink(0.08), lineWidth: 1))
    }

    private func toggle() {
        if playing { stop(); return }
        model.buzz(.light)
        if frame >= 7 { frame = 0 }
        playing = true
        player = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(650))
                guard !Task.isCancelled else { return }
                if frame >= 7 { playing = false; return }
                withAnimation { frame += 1 }
            }
        }
    }

    private func stop() {
        player?.cancel()
        player = nil
        playing = false
    }
}
