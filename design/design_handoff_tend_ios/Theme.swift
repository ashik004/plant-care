import SwiftUI

// Tend design tokens. Values match Tend App v4.dc.html (light) and Tend App v4 Dark.dc.html.
extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
    init(light: UInt32, dark: UInt32) {
        self.init(UIColor { $0.userInterfaceStyle == .dark ? UIColor(Color(hex: dark)) : UIColor(Color(hex: light)) })
    }
}

enum Haptic {
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
    static func impact(_ s: UIImpactFeedbackGenerator.FeedbackStyle) { UIImpactFeedbackGenerator(style: s).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
}

enum Tend {
    // Adaptive: (light, dark). Light is the default "plant" theme; dark follows the system.
    enum C {
        static let bg = Color(light: 0xF4F0E6, dark: 0x0F140E)          // linen
        static let bgDeep = Color(light: 0xE7E1D1, dark: 0x090C09)
        static let surface = Color(light: 0xFFFCF5, dark: 0x172017)     // cards
        static let surfacePressed = Color(light: 0xEDE7D8, dark: 0x1C261B)
        static let brand = Color(light: 0x3A6E33, dark: 0x3E8A3A)       // fern
        static let brandButton = Color(light: 0x2F5D2A, dark: 0x3E8A3A)
        static let brandBright = Color(light: 0x447D3C, dark: 0x49994A)
        static let brandDeep = Color(hex: 0x2A4F25)                      // premium/digest cards (gradient to 0x1C3618)
        static let accent = Color(light: 0x3E7A37, dark: 0x86C98F)      // leaf text, live dots
        static let leafFill = Color(hex: 0x9DBE88)                       // illustration fills
        static let leafFillLight = Color(hex: 0xB7D3A3)
        static let amber = Color(light: 0xA9852B, dark: 0xD8BE73)       // ochre
        static let clay = Color(light: 0xB5603A, dark: 0xE5A47A)        // terracotta
        static let pot = Color(hex: 0xC9774F)
        static let text = Color(light: 0x1F2B1C, dark: 0xEAF0E6)        // moss ink
        static let text2 = Color(light: 0x2E3C2A, dark: 0xD2DAD0)
        static let text3 = Color(light: 0x566551, dark: 0xA1ACA0)
        static let text4 = Color(light: 0x67755F, dark: 0x8C988A)
        static let text5 = Color(light: 0x76826D, dark: 0x7D897B)
        static let muted = Color(light: 0x8E977F, dark: 0x5F6B5E)
        static let ring = Color(light: 0xB8BDA9, dark: 0x465046)
        static let hairline = Color(light: 0x2E3E26, dark: 0xE8F0E6).opacity(0.1)
        static let shadow = Color(hex: 0x2E3E26)
    }

    enum F {
        // Register: Newsreader (variable), Geist-Regular/Medium/SemiBold/Bold, JetBrainsMono-Medium
        static func serif(_ size: CGFloat) -> Font { .custom("Newsreader", size: size) }
        static func serifItalic(_ size: CGFloat) -> Font { .custom("Newsreader-Italic", size: size) }
        static func sans(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font { .custom("Geist", size: size).weight(weight) }
        static func mono(_ size: CGFloat) -> Font { .custom("JetBrainsMono-Medium", size: size) }
    }

    enum R { static let pill: CGFloat = 999, hero: CGFloat = 30, card: CGFloat = 20, button: CGFloat = 18, input: CGFloat = 16, thumb: CGFloat = 14 }
    enum S { static let side: CGFloat = 22, sideWide: CGFloat = 16, section: CGFloat = 20, card: CGFloat = 16 }
}

// Primary button: 56pt, radius 18, brandButton fill, soft shadow.
struct TendPrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Tend.F.sans(16, .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(configuration.isPressed ? Tend.C.brand : Tend.C.brandButton,
                        in: RoundedRectangle(cornerRadius: Tend.R.button, style: .continuous))
            .shadow(color: Tend.C.shadow.opacity(0.18), radius: 12, y: 6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// Card: surface fill, 1pt hairline, radius 20.
struct TendCard: ViewModifier {
    var radius: CGFloat = Tend.R.card
    func body(content: Content) -> some View {
        content
            .background(Tend.C.surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(Tend.C.hairline, lineWidth: 1))
    }
}
extension View { func tendCard(radius: CGFloat = Tend.R.card) -> some View { modifier(TendCard(radius: radius)) } }

// Scanner icon: four corner brackets and a center line, 2.2pt stroke.
struct ScannerIcon: Shape {
    func path(in r: CGRect) -> Path {
        let s = r.width / 26
        var p = Path()
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * s, y: r.minY + y * s) }
        p.move(to: pt(2, 8)); p.addLine(to: pt(2, 5)); p.addQuadCurve(to: pt(5, 2), control: pt(2, 2)); p.addLine(to: pt(8, 2))
        p.move(to: pt(18, 2)); p.addLine(to: pt(21, 2)); p.addQuadCurve(to: pt(24, 5), control: pt(24, 2)); p.addLine(to: pt(24, 8))
        p.move(to: pt(24, 18)); p.addLine(to: pt(24, 21)); p.addQuadCurve(to: pt(21, 24), control: pt(24, 24)); p.addLine(to: pt(18, 24))
        p.move(to: pt(8, 24)); p.addLine(to: pt(5, 24)); p.addQuadCurve(to: pt(2, 21), control: pt(2, 24)); p.addLine(to: pt(2, 18))
        p.move(to: pt(6.5, 13)); p.addLine(to: pt(19.5, 13))
        return p
    }
}
// Usage: ScannerIcon().stroke(.white, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round)).frame(width: 26, height: 26)
