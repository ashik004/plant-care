import SwiftUI

// MARK: - Buttons

/// Primary button: 56 pt, radius 18, brandButton fill, white Geist 16/600, scales to 0.98.
struct PrimaryButtonStyle: ButtonStyle {
    enum Kind { case brand, inverse, outline, premium }
    var kind: Kind = .brand
    var height: CGFloat = 56
    var fontSize: CGFloat = 16

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .font(Tend.F.sans(fontSize, kind == .premium ? .bold : .semibold))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(background(pressed), in: RoundedRectangle(cornerRadius: Tend.R.button, style: .continuous))
            .overlay {
                if kind == .outline {
                    RoundedRectangle(cornerRadius: Tend.R.button, style: .continuous).stroke(Tend.C.ink(0.18), lineWidth: 1)
                }
            }
            .shadow(color: kind == .brand || kind == .premium ? Tend.C.leaf(kind == .premium ? 0.18 : 0.10) : .clear, radius: 15)
            .scaleEffect(pressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: pressed)
            .contentShape(Rectangle())
    }

    private var foreground: Color {
        switch kind {
        case .brand, .premium: .white
        case .inverse: Tend.C.onInverse
        case .outline: Tend.C.text
        }
    }

    private func background(_ pressed: Bool) -> Color {
        switch kind {
        case .brand: pressed ? Tend.C.brand : Tend.C.brandButton
        case .premium: pressed ? Tend.C.brandBright : Tend.C.brand
        case .inverse: pressed ? Tend.C.text2 : Tend.C.inverse
        case .outline: pressed ? Tend.C.ink(0.05) : .clear
        }
    }
}

/// Small primary (38 pt, radius 12) used in suggestion cards.
struct SmallButtonStyle: ButtonStyle {
    var filled = true
    var height: CGFloat = 38
    var fontSize: CGFloat = 14
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Tend.F.sans(fontSize, filled ? .semibold : .medium))
            .foregroundStyle(filled ? Color.white : Tend.C.text3)
            .padding(.horizontal, filled ? 16 : 14)
            .frame(height: height)
            .background(filled ? (configuration.isPressed ? Tend.C.brand : Tend.C.brandButton) : .clear,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                if !filled { RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Tend.C.ink(0.16), lineWidth: 1) }
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

/// Lifts cards by 2 pt when pressed.
struct LiftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed ? -2 : 0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Plain text button ("Close", "Not now", "‹ Rescan").
struct TextLinkButton: View {
    let title: String
    var color: Color = Tend.C.text3
    var weight: Font.Weight = .medium
    var size: CGFloat = 15
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(Tend.F.sans(size, weight)).foregroundStyle(color)
                .frame(minHeight: 44).padding(.horizontal, 4).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// "‹ Back" pill: 40 pt, radius 999, translucent surface, 1 pt border.
struct BackPill: View {
    var label = "Back"
    var action: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button { if let action { action() } else { dismiss() } } label: {
            HStack(spacing: 6) {
                Text("‹").font(Tend.F.sans(20)).offset(y: -1)
                Text(label).font(Tend.F.sans(15, .medium))
            }
            .foregroundStyle(Tend.C.text)
            .padding(.leading, 12).padding(.trailing, 16)
            .frame(height: 40)
            .background(Color(lightRGB: 0xFFFCF5, lightAlpha: 0.9, darkRGB: 0x172017, darkAlpha: 0.9), in: Capsule())
            .overlay(Capsule().stroke(Tend.C.ink(0.13), lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// Tinted pill button ("Check health", "Measure a spot…").
struct TintPillButton<Leading: View>: View {
    let title: String
    var height: CGFloat = 40
    var filledSurface = false
    @ViewBuilder var leading: () -> Leading
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                leading()
                Text(title).font(Tend.F.sans(14, .semibold))
            }
            .foregroundStyle(filledSurface ? Tend.C.brandInk : Tend.C.accent)
            .padding(.horizontal, 16)
            .frame(height: height)
            .background(filledSurface ? Tend.C.surface : Tend.C.leaf(0.12), in: Capsule())
            .overlay(Capsule().stroke(Tend.C.leaf(0.3), lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

extension TintPillButton where Leading == EmptyView {
    init(_ title: String, height: CGFloat = 40, action: @escaping () -> Void) {
        self.init(title: title, height: height, filledSurface: false, leading: { EmptyView() }, action: action)
    }
}

// MARK: - Text

/// Uppercase Geist 12/600 eyebrow with 0.12 em tracking.
struct Eyebrow: View {
    let text: String
    var color: Color = Tend.C.text4
    var size: CGFloat = 12
    var dot: Bool = false
    var body: some View {
        HStack(spacing: 8) {
            if dot { StatusDot(color: color, size: 6) }
            Text(text.uppercased())
                .font(Tend.F.sans(size, .semibold))
                .tracking(size * 0.12)
                .foregroundStyle(color)
        }
    }
}

struct ScreenTitle: View {
    let text: String
    var size: CGFloat = 40
    var body: some View {
        Text(text)
            .font(Tend.F.serif(size))
            .foregroundStyle(Tend.C.text)
            .fixedSize(horizontal: false, vertical: true)
            .tracking(-0.2)
    }
}

/// Section header: Newsreader 24 title with an optional trailing note or link.
struct SectionHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: () -> Trailing
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(Tend.F.serif(24)).foregroundStyle(Tend.C.text)
            Spacer()
            trailing()
        }
    }
}

// MARK: - Status

/// A small dot that glows in its own colour.
struct StatusDot: View {
    let color: Color
    var size: CGFloat = 8
    var glow = true
    var body: some View {
        Circle().fill(color).frame(width: size, height: size)
            .shadow(color: glow ? color : .clear, radius: 4)
    }
}

struct HealthPill: View {
    let health: PlantHealth
    var height: CGFloat = 28
    var body: some View {
        HStack(spacing: 6) {
            StatusDot(color: health.color, size: 6)
            Text(health.label).font(Tend.F.sans(12, .semibold))
        }
        .foregroundStyle(health.color)
        .padding(.horizontal, 11)
        .frame(height: height)
        .background(health.tint, in: Capsule())
    }
}

/// A small coloured tag ("87% match").
struct TagPill: View {
    let text: String
    let color: Color
    let fill: Color
    var body: some View {
        Text(text).font(Tend.F.sans(12, .semibold)).foregroundStyle(color)
            .padding(.horizontal, 10).frame(height: 26).background(fill, in: Capsule())
    }
}

// MARK: - Cards & placeholders

struct CardModifier: ViewModifier {
    var radius: CGFloat = Tend.R.card
    var fill: Color = Tend.C.surface
    var border: Color = Tend.C.hairline
    func body(content: Content) -> some View {
        content
            .background(fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(border, lineWidth: 1))
    }
}

extension View {
    func card(radius: CGFloat = Tend.R.card, fill: Color = Tend.C.surface, border: Color = Tend.C.hairline) -> some View {
        modifier(CardModifier(radius: radius, fill: fill, border: border))
    }

    /// The green-tinted card used for suggestions and recommended guides.
    func tintCard(radius: CGFloat = Tend.R.card, from: Double = 0.16, to: Double = 0.04, border: Double = 0.18) -> some View {
        background(LinearGradient.angle(160, [Tend.C.leaf(from), Tend.C.leaf(to)]),
                   in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(Tend.C.leaf(border), lineWidth: 1))
    }
}

/// Diagonal-stripe placeholder (135°) with a mono label. Replace with real photos.
struct StripedPlaceholder: View {
    enum Palette { case standard, wide, clay }
    var label: String = "photo"
    var stripe: CGFloat = 6
    var palette: Palette = .standard
    var radius: CGFloat = Tend.R.thumb
    var labelSize: CGFloat = 8
    var alignment: Alignment = .center
    var circle = false

    var body: some View {
        let (a, b): (Color, Color) = {
            switch palette {
            case .standard: (Tend.C.stripeA, Tend.C.stripeB)
            case .wide: (Tend.C.stripeA, Tend.C.stripeWideB)
            case .clay: (Tend.C.stripeClayA, Tend.C.stripeClayB)
            }
        }()
        Stripes(a: a, b: b, width: stripe)
            .overlay(alignment: alignment) {
                if !label.isEmpty {
                    Text(label.uppercased())
                        .font(Tend.F.mono(labelSize)).tracking(labelSize >= 10 ? 0.6 : 0)
                        .foregroundStyle(palette == .clay ? Tend.C.stripeClayLabel : Tend.C.muted)
                        .multilineTextAlignment(.leading)
                        .padding(alignment == .center ? 0 : 8)
                }
            }
            .clipShape(circle ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: radius, style: .continuous)))
            .accessibilityHidden(true)
    }
}

struct Stripes: View {
    let a: Color, b: Color
    var width: CGFloat = 6
    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(a))
            // 135° stripes: bands perpendicular to the gradient direction (top-left → bottom-right).
            let period = width * 2 * sqrt(2)
            let total = size.width + size.height
            var x: CGFloat = 0
            while x < total {
                var p = Path()
                let w = width * sqrt(2)
                p.move(to: CGPoint(x: x + w, y: 0))
                p.addLine(to: CGPoint(x: x + 2 * w, y: 0))
                p.addLine(to: CGPoint(x: x + 2 * w - size.height, y: size.height))
                p.addLine(to: CGPoint(x: x + w - size.height, y: size.height))
                p.closeSubpath()
                ctx.fill(p, with: .color(b))
                x += period
            }
        }
    }
}

// MARK: - Controls

/// Segmented control: surface track, 1 pt hairline, 3 pt padding; the selected segment fills inverse.
struct SegmentedPicker<T: Hashable>: View {
    let options: [(T, String)]
    @Binding var selection: T
    var height: CGFloat = 38
    var radius: CGFloat = 14
    var innerRadius: CGFloat = 11
    var fontSize: CGFloat = 14
    var stretch = true
    var track: Color = Tend.C.surface
    var onChange: ((T) -> Void)? = nil
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.0) { value, label in
                let on = value == selection
                Button {
                    withAnimation(.easeOut(duration: 0.2)) { selection = value }
                    onChange?(value)
                } label: {
                    Text(label)
                        .font(Tend.F.sans(fontSize, .semibold))
                        .foregroundStyle(on ? Tend.C.onInverse : Tend.C.text3)
                        .padding(.horizontal, stretch ? 0 : 12)
                        .frame(maxWidth: stretch ? .infinity : nil)
                        .frame(height: height)
                        .background {
                            if on {
                                RoundedRectangle(cornerRadius: innerRadius, style: .continuous)
                                    .fill(Tend.C.inverse)
                                    .matchedGeometryEffect(id: "seg", in: ns)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(3)
        .background(track, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(Tend.C.ink(0.1), lineWidth: 1))
    }
}

/// Pill chip: selected fills inverse, unselected is clear with an 18% border.
struct Chip<Trailing: View>: View {
    let label: String
    let selected: Bool
    var height: CGFloat = 36
    var hPad: CGFloat = 15
    @ViewBuilder var trailing: () -> Trailing
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(label).font(Tend.F.sans(14, .medium)).lineLimit(1)
                trailing()
            }
            .foregroundStyle(selected ? Tend.C.onInverse : Tend.C.text)
            .padding(.horizontal, hPad)
            .frame(height: height)
            .background(selected ? Tend.C.inverse : .clear, in: Capsule())
            .overlay(Capsule().stroke(selected ? Tend.C.inverse : Tend.C.ink(0.18), lineWidth: 1))
            .contentShape(Capsule())
            .animation(.easeOut(duration: 0.2), value: selected)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

extension Chip where Trailing == EmptyView {
    init(_ label: String, selected: Bool, height: CGFloat = 36, action: @escaping () -> Void) {
        self.init(label: label, selected: selected, height: height, hPad: 15, trailing: { EmptyView() }, action: action)
    }
}

/// A horizontally scrolling chip row with screen-edge insets.
struct ChipRow<Content: View>: View {
    var inset: CGFloat = Tend.S.side
    @ViewBuilder var content: () -> Content
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) { content() }.padding(.horizontal, inset)
        }
        .scrollClipDisabled()
    }
}

/// 50 × 30 toggle: brand when on (with a glow), ink 21% when off, white knob.
struct TendToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            HStack {
                configuration.label
                Spacer(minLength: 12)
                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    Capsule().fill(configuration.isOn ? Tend.C.brand : Tend.C.ink(0.21))
                        .shadow(color: configuration.isOn ? Tend.C.leaf(0.16) : .clear, radius: 7)
                    Circle().fill(.white).frame(width: 24, height: 24).padding(3)
                        .shadow(color: .black.opacity(0.3), radius: 2, y: 2)
                }
                .frame(width: 50, height: 30)
                .animation(.easeOut(duration: 0.2), value: configuration.isOn)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// − / + stepper card ("Water every 7 days").
struct IntervalStepper: View {
    let every: Int
    let hint: String
    let minus: () -> Void
    let plus: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Water every \(every) days").font(Tend.F.sans(15, .semibold)).foregroundStyle(Tend.C.text)
                    .contentTransition(.numericText()).animation(.snappy, value: every)
                Text(hint).font(Tend.F.sans(12)).foregroundStyle(Tend.C.text4)
            }
            Spacer()
            HStack(spacing: 4) {
                stepButton("−", label: "Fewer days", action: minus)
                stepButton("+", label: "More days", action: plus)
            }
        }
        .padding(.vertical, 16).padding(.horizontal, 18)
        .card()
    }

    private func stepButton(_ s: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(s).font(Tend.F.sans(20)).foregroundStyle(Tend.C.text)
                .frame(width: 40, height: 40)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Tend.C.ink(0.16), lineWidth: 1))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// Numbered / checked circle used by treatment steps and the sitter checklist.
struct StepCheck: View {
    let done: Bool
    var number: String = ""
    var size: CGFloat = 28
    var body: some View {
        ZStack {
            Circle().fill(done ? Tend.C.brand : .clear)
            Circle().strokeBorder(done ? Tend.C.brand : Tend.C.ring, lineWidth: 1.5)
            Text(done ? "✓" : number).font(Tend.F.sans(13, .bold)).foregroundStyle(done ? .white : Tend.C.text)
        }
        .frame(width: size, height: size)
        .shadow(color: done ? Tend.C.leaf(0.2) : .clear, radius: 7)
        .animation(.easeOut(duration: 0.2), value: done)
    }
}

/// Task check: empty 30 pt ring; when done, a 32 pt brand circle pops in (0.4→1.18→1) with a ripple.
struct TaskCheck: View {
    let checking: Bool
    @State private var ripple = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if checking {
                ZStack {
                    Circle().stroke(Tend.C.brand, lineWidth: 2)
                        .scaleEffect(ripple ? 2.4 : 1).opacity(ripple ? 0 : 0.55)
                    Circle().fill(Tend.C.brand)
                    Text("✓").font(Tend.F.sans(16, .bold)).foregroundStyle(.white)
                }
                .frame(width: 32, height: 32)
                .shadow(color: Tend.C.leaf(0.25), radius: 9)
                .transition(reduceMotion ? .opacity : .scale(scale: 0.4).combined(with: .opacity).animation(Tend.pop(0.45)))
                .onAppear { withAnimation(.easeOut(duration: 0.7)) { ripple = true } }
                .onDisappear { ripple = false }
            } else {
                Circle().strokeBorder(Tend.C.ring, lineWidth: 1.5).frame(width: 30, height: 30)
            }
        }
        .frame(width: 44, height: 44)
    }
}

// MARK: - Toast

struct ToastView: View {
    let toast: Toast
    let undo: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            Text(toast.text).font(Tend.F.sans(14)).foregroundStyle(Tend.C.onInverse)
                .frame(maxWidth: .infinity, alignment: .leading)
            if toast.undo != nil {
                Button("Undo", action: undo).font(Tend.F.sans(14, .bold))
                    .foregroundStyle(Color(light: 0xB7D3A3, dark: 0x2F5D2A)).padding(4)
            }
        }
        .padding(.vertical, 14).padding(.horizontal, 16)
        .background(Tend.C.inverse, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Tend.C.shadow.opacity(0.2), radius: 15, y: 12)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
    }
}

struct ToastOverlay: ViewModifier {
    @Environment(AppModel.self) private var model
    var bottom: CGFloat = 100
    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let t = model.toast {
                ToastView(toast: t) { model.undoToast() }
                    .padding(.bottom, bottom)
                    .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.96)),
                                            removal: .opacity))
                    .id(t.id)
            }
        }
    }
}

extension View {
    func toastHost(bottom: CGFloat = 100) -> some View { modifier(ToastOverlay(bottom: bottom)) }
}

// MARK: - Motion

/// Screen entrance: fade + 14 pt rise over 0.45 s. Crossfade only with Reduce Motion.
struct Entrance: ViewModifier {
    var delay: Double = 0
    var rise: CGFloat = 14
    var scale: CGFloat = 1
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : rise)
            .scaleEffect(shown || reduceMotion ? 1 : scale)
            .onAppear {
                withAnimation(Tend.ease(rise > 14 ? 0.5 : 0.45).delay(delay)) { shown = true }
            }
    }
}

extension View {
    func entrance(delay: Double = 0) -> some View { modifier(Entrance(delay: delay)) }
    /// List rows: 18 pt rise with a slight scale, staggered by the caller.
    func rise(delay: Double) -> some View { modifier(Entrance(delay: delay, rise: 18, scale: 0.98)) }
}

/// Screen chrome shared by pushed screens: linen background, ambient glow, hidden nav and tab bars.
struct TendScreen: ViewModifier {
    var hideTabBar = true
    func body(content: Content) -> some View {
        content
            .background { AmbientBackground() }
            .toolbar(.hidden, for: .navigationBar)
            .toolbar(hideTabBar ? .hidden : .automatic, for: .tabBar)
    }
}

extension View {
    func tendScreen(hideTabBar: Bool = true) -> some View { modifier(TendScreen(hideTabBar: hideTabBar)) }
}

/// Linen with a soft radial glow at the top right (460 pt circle at top −150, right −130).
struct AmbientBackground: View {
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                Tend.C.bg
                RadialGradient(colors: [Tend.C.leaf(0.18), .clear], center: .center, startRadius: 0, endRadius: 211)
                    .frame(width: 460, height: 460)
                    .offset(x: geo.size.width + 130 - 460, y: -150)
                    .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Layout

/// Wraps children onto new lines (room chips on Add details).
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, width: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x > 0 && x + sz.width > maxW { x = 0; y += rowH + spacing; rowH = 0 }
            x += sz.width + spacing; rowH = max(rowH, sz.height); width = max(width, x - spacing)
        }
        return CGSize(width: width, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x > bounds.minX && x + sz.width > bounds.maxX { x = bounds.minX; y += rowH + spacing; rowH = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(sz))
            x += sz.width + spacing; rowH = max(rowH, sz.height)
        }
    }
}

/// A thin progress bar (3–8 pt) with a rounded fill.
struct BarMeter: View {
    let fraction: Double
    var color: Color = Tend.C.accent
    var height: CGFloat = 3
    var track: Color = Tend.C.ink(0.1)
    var glow: Color? = nil
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule().fill(color)
                    .frame(width: max(0, min(1, fraction)) * g.size.width)
                    .shadow(color: glow ?? .clear, radius: 4)
            }
        }
        .frame(height: height)
        .animation(Tend.ease(0.6), value: fraction)
    }
}

/// A row divider inside cards.
struct RowDivider: View {
    var opacity = 0.08
    var body: some View { Rectangle().fill(Tend.C.ink(opacity)).frame(height: 1) }
}
