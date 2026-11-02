import SwiftUI

/// Ask Tend: a chat that answers using a plant's own history and room conditions.
struct AskView: View {
    let plantId: String?
    @Environment(AppModel.self) var model
    @State var input = ""
    @FocusState var focused: Bool

    private static let chipIds = ["fig", "mon", "gol", "pin"]

    var body: some View {
        let ap = model.askId == "general" ? nil : model.plant(model.askId)
        var chips: [(String, String)] = Self.chipIds.compactMap { id in model.plant(id).map { (id, $0.name) } } + [("general", "Anything")]
        if let ap, !Self.chipIds.contains(ap.id) { chips.append((ap.id, ap.name)) }

        return ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    BackPill(label: "Home").padding(.horizontal, Tend.S.sideWide)

                    VStack(alignment: .leading, spacing: 6) {
                        Eyebrow(text: "Ask Tend")
                        ScreenTitle(text: "What's on your mind?")
                    }
                    .padding(.horizontal, Tend.S.side)

                    ChipRow {
                        ForEach(chips, id: \.0) { id, label in
                            Chip(label, selected: model.askId == id) {
                                model.askId = id
                                model.chat = []
                                model.askBusy = false
                            }
                        }
                    }

                    HStack(alignment: .top, spacing: 10) {
                        Circle().fill(Tend.C.accent).frame(width: 7, height: 7).padding(.top, 6)
                        Text(ap.map { "Tend knows \($0.name)'s scans, waterings, growth and the \($0.room.lowercased()) climate, and answers with that in mind." }
                             ?? "General plant questions. Pick a plant for answers based on its own history.")
                            .font(Tend.F.sans(13)).lineSpacing(3).foregroundStyle(Tend.C.text2)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 12).padding(.horizontal, 14)
                    .background(Tend.C.leaf(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Tend.C.leaf(0.16), lineWidth: 1))
                    .padding(.horizontal, Tend.S.sideWide)

                    VStack(alignment: .leading, spacing: 10) {
                        if model.chat.isEmpty && !model.askBusy {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Try asking").font(Tend.F.sans(13)).foregroundStyle(Tend.C.text4).padding(.horizontal, 6)
                                ForEach(SampleData.prompts[model.askId] ?? SampleData.prompts["general"]!, id: \.self) { q in
                                    Button { model.send(q) } label: {
                                        Text(q).font(Tend.F.serif(18)).lineSpacing(3).foregroundStyle(Tend.C.text)
                                            .multilineTextAlignment(.leading)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.vertical, 14).padding(.horizontal, 16)
                                            .card(radius: 16)
                                    }
                                    .buttonStyle(LiftButtonStyle())
                                }
                            }
                            .padding(.top, 4)
                        }
                        ForEach(model.chat) { m in
                            Bubble(message: m).id(m.id)
                                .transition(.opacity.combined(with: .offset(y: 18)))
                        }
                        if model.askBusy { TypingDots().id("typing") }
                    }
                    .padding(.horizontal, Tend.S.sideWide)
                }
                .padding(.top, 8).padding(.bottom, 20)
                .entrance()
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: model.chat.count) {
                if let id = model.chat.last?.id { withAnimation { proxy.scrollTo(id, anchor: .bottom) } }
            }
            .onChange(of: model.askBusy) { _, busy in
                if busy { withAnimation { proxy.scrollTo("typing", anchor: .bottom) } }
            }
            .safeAreaInset(edge: .bottom) { inputBar(placeholder: ap.map { "Ask about \($0.name)…" } ?? "Ask anything about plants…") }
        }
        .tendScreen()
        .onAppear {
            if let plantId, model.askId != plantId { model.askId = plantId; model.chat = [] }
        }
    }

    private func inputBar(placeholder: String) -> some View {
        HStack(spacing: 8) {
            TextField(placeholder, text: $input)
                .font(Tend.F.sans(15)).foregroundStyle(Tend.C.text)
                .focused($focused)
                .submitLabel(.send)
                .onSubmit(send)
                .padding(.horizontal, 18).frame(height: 52)
                .background(Tend.C.surface, in: Capsule())
                .overlay(Capsule().stroke(Tend.C.ink(0.16), lineWidth: 1))
                .shadow(color: Tend.C.shadow.opacity(0.25), radius: 12, y: 8)
            Button(action: send) {
                LineIcon(d: Icon.send, color: .white, size: 20, lineWidth: 2.2)
                    .frame(width: 52, height: 52)
                    .background(Tend.C.brandButton, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Send")
        }
        .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 8)
        .background(LinearGradient(stops: [.init(color: Tend.C.bg.opacity(0), location: 0), .init(color: Tend.C.bg, location: 0.3)],
                                   startPoint: .top, endPoint: .bottom))
    }

    private func send() {
        let q = input
        input = ""
        withAnimation(Tend.ease(0.3)) { model.send(q) }
    }
}

private struct Bubble: View {
    let message: ChatMessage
    var body: some View {
        if message.fromUser {
            HStack {
                Spacer(minLength: 60)
                Text(message.text).font(Tend.F.sans(15)).lineSpacing(3).foregroundStyle(Tend.C.onInverse)
                    .padding(.vertical, 11).padding(.horizontal, 15)
                    .background(Tend.C.inverse, in: UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 20, bottomTrailingRadius: 6, topTrailingRadius: 20, style: .continuous))
            }
        } else {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 5, style: .continuous).fill(Tend.C.brand).frame(width: 16, height: 16)
                        Text("TEND").font(Tend.F.sans(11, .bold)).tracking(1.1).foregroundStyle(Tend.C.accent)
                    }
                    Text(message.text).font(Tend.F.sans(15)).lineSpacing(4).foregroundStyle(Tend.C.text)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 13).padding(.horizontal, 15)
                        .background(Tend.C.surface, in: UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 20, bottomTrailingRadius: 20, topTrailingRadius: 20, style: .continuous))
                        .overlay(UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 20, bottomTrailingRadius: 20, topTrailingRadius: 20, style: .continuous)
                            .stroke(Tend.C.hairline, lineWidth: 1))
                }
                Spacer(minLength: 40)
            }
        }
    }
}

private struct TypingDots: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    var body: some View {
        HStack {
            TimelineView(.animation(paused: reduceMotion)) { tl in
                let t = tl.date.timeIntervalSinceReferenceDate
                HStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { i in
                        let p = KF.loop(t, period: 1.1, delay: Double(i) * 0.15)
                        let up = KF.value(p, [(0, 0), (0.4, 1), (0.8, 0), (1, 0)])
                        Circle().fill(Tend.C.accent).frame(width: 7, height: 7)
                            .opacity(0.25 + 0.75 * up).offset(y: -3 * up)
                    }
                }
            }
            .padding(.vertical, 14).padding(.horizontal, 16)
            .background(Tend.C.surface, in: UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 20, bottomTrailingRadius: 20, topTrailingRadius: 20, style: .continuous))
            .overlay(UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 20, bottomTrailingRadius: 20, topTrailingRadius: 20, style: .continuous).stroke(Tend.C.hairline, lineWidth: 1))
            .accessibilityLabel("Tend is typing")
            Spacer()
        }
    }
}
