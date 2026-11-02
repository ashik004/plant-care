import SwiftUI

// Tend design tokens. Light values come from `Tend App v4.dc.html`, dark values
// from `Tend App v4 Dark.dc.html`. Light is the default; dark follows the system.

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }

    init(light: UInt32, dark: UInt32, opacity: Double = 1) {
        self.init(UIColor { trait in
            let hex = trait.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255,
                           green: CGFloat((hex >> 8) & 0xFF) / 255,
                           blue: CGFloat(hex & 0xFF) / 255,
                           alpha: opacity)
        })
    }

    /// An adaptive colour where light and dark use different RGB and alpha.
    init(lightRGB: UInt32, lightAlpha: Double, darkRGB: UInt32, darkAlpha: Double) {
        self.init(UIColor { trait in
            let dark = trait.userInterfaceStyle == .dark
            let hex = dark ? darkRGB : lightRGB
            return UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255,
                           green: CGFloat((hex >> 8) & 0xFF) / 255,
                           blue: CGFloat(hex & 0xFF) / 255,
                           alpha: dark ? darkAlpha : lightAlpha)
        })
    }
}

enum Tend {
    enum C {
        static let bg = Color(light: 0xF4F0E6, dark: 0x0F140E)              // linen
        static let bgDeep = Color(light: 0xE7E1D1, dark: 0x090C09)
        static let surface = Color(light: 0xFFFCF5, dark: 0x172017)         // cards
        static let surfacePressed = Color(light: 0xEDE7D8, dark: 0x1C261B)
        static let brand = Color(light: 0x3A6E33, dark: 0x3E8A3A)           // toggles, checks, scan
        static let brandButton = Color(light: 0x2F5D2A, dark: 0x3E8A3A)     // primary buttons
        static let brandBright = Color(light: 0x447D3C, dark: 0x49994A)
        static let brandInk = Color(light: 0x2F5D2A, dark: 0x86C98F)        // green text on light fills
        static let accent = Color(light: 0x3E7A37, dark: 0x86C98F)          // leaf-green text, live dots
        static let amber = Color(light: 0xA9852B, dark: 0xD8BE73)           // needs attention
        static let clay = Color(light: 0xB5603A, dark: 0xE5A47A)            // pests, thirsty, badges
        static let text = Color(light: 0x1F2B1C, dark: 0xEAF0E6)            // moss ink
        static let text2 = Color(light: 0x2E3C2A, dark: 0xD2DAD0)
        static let text3 = Color(light: 0x566551, dark: 0xA1ACA0)
        static let text4 = Color(light: 0x67755F, dark: 0x8C988A)
        static let text5 = Color(light: 0x76826D, dark: 0x7D897B)
        static let muted = Color(light: 0x8E977F, dark: 0x5F6B5E)
        static let legalBody = Color(light: 0x43523E, dark: 0xB9C2B8)
        static let ring = Color(light: 0xB8BDA9, dark: 0x465046)

        /// Inverse fill used for selected chips, segments, toasts and dark buttons.
        static let inverse = text
        /// Label on an inverse fill.
        static let onInverse = bg

        // Illustration palette (same in both themes)
        static let leafFill = Color(hex: 0x9DBE88)
        static let leafFillLight = Color(hex: 0xB7D3A3)
        static let leafFillDeep = Color(hex: 0x8DB07A)
        static let leafFillDark = Color(hex: 0x7A9F66)
        static let pot = Color(hex: 0xC9774F)
        static let potRim = Color(hex: 0xB5603A)
        static let water = Color(hex: 0x6FA0C8)
        static let seed = Color(hex: 0xA9852B)
        static let lineArt = Color(light: 0x2F5D2A, dark: 0x2F5D2A)
        static let cream = Color(hex: 0xFFFCF5)
        static let creamSoft = Color(hex: 0xCFE3C2)
        static let creamLabel = Color(hex: 0xE3F0D9)

        /// Moss ink at an alpha. Hairlines, borders, tracks.
        static func ink(_ a: Double) -> Color {
            Color(lightRGB: 0x2E3E26, lightAlpha: a, darkRGB: 0xE8F0E6, darkAlpha: a * 0.8)
        }
        /// Leaf-green tint at an alpha. Selected fills, tinted cards.
        static func leaf(_ a: Double) -> Color {
            Color(lightRGB: 0x4A7C3F, lightAlpha: a, darkRGB: 0x7BD88F, darkAlpha: a)
        }
        static func clayTint(_ a: Double) -> Color {
            Color(lightRGB: 0xB5603A, lightAlpha: a, darkRGB: 0xE5A47A, darkAlpha: a)
        }
        static func amberTint(_ a: Double) -> Color {
            Color(lightRGB: 0xA9852B, lightAlpha: a, darkRGB: 0xD8BE73, darkAlpha: a)
        }
        static let hairline = ink(0.09)
        static let shadow = Color(light: 0x2E3E26, dark: 0x000000)

        // Gradients
        static let deepStart = Color(light: 0x2A4F25, dark: 0x244A21)
        static let deepEnd = Color(light: 0x1C3618, dark: 0x15301A)
        static var deepGradient: LinearGradient {
            LinearGradient.angle(150, [deepStart, deepEnd])
        }
        static let illoTop = Color(light: 0xEAF1E0, dark: 0x1A2619)
        static let illoBottom = Color(light: 0xF7F2E6, dark: 0x121A11)

        // Placeholder stripes
        static let stripeA = Color(light: 0xEDE7D8, dark: 0x1C261B)
        static let stripeB = Color(light: 0xE4DDCB, dark: 0x222D21)
        static let stripeWideB = Color(light: 0xFFFCF5, dark: 0x172017)
        static let stripeClayA = Color(light: 0xEFE3D6, dark: 0x2A221C)
        static let stripeClayB = Color(light: 0xE8DACB, dark: 0x231C17)
        static let stripeClayLabel = Color(hex: 0x8A6A58)
    }

    enum F {
        // PostScript names of the bundled fonts (see Shared/Fonts).
        static func serif(_ size: CGFloat) -> Font { .custom("Newsreader-Regular", size: size) }
        static func serifItalic(_ size: CGFloat) -> Font { .custom("Newsreader-Italic", size: size) }
        static func serifMediumItalic(_ size: CGFloat) -> Font { .custom("Newsreader-MediumItalic", size: size) }
        static func sans(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
            let name: String
            switch weight {
            case .medium: name = "Geist-Medium"
            case .semibold: name = "Geist-SemiBold"
            case .bold, .heavy, .black: name = "Geist-Bold"
            default: name = "Geist-Regular"
            }
            return .custom(name, size: size)
        }
        static func mono(_ size: CGFloat) -> Font { .custom("JetBrainsMono-Medium", size: size) }
    }

    enum R {
        static let pill: CGFloat = 999, hero: CGFloat = 30, photo: CGFloat = 26, card: CGFloat = 20
        static let button: CGFloat = 18, input: CGFloat = 16, thumb: CGFloat = 14
    }

    enum S {
        static let side: CGFloat = 22, sideWide: CGFloat = 16, section: CGFloat = 20
        static let top: CGFloat = 62, topTab: CGFloat = 70, tabBottom: CGFloat = 150
    }

    /// The prototype's standard ease, `cubic-bezier(.2,.8,.2,1)`.
    static let ease = Animation.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.45)
    static func ease(_ duration: Double) -> Animation { .timingCurve(0.2, 0.8, 0.2, 1, duration: duration) }
    /// Overshooting pop, `cubic-bezier(.34,1.56,.64,1)`.
    static func pop(_ duration: Double) -> Animation { .timingCurve(0.34, 1.56, 0.64, 1, duration: duration) }
}

extension LinearGradient {
    /// A CSS-style angled gradient (`linear-gradient(<deg>, …)`).
    static func angle(_ degrees: Double, _ colors: [Color]) -> LinearGradient {
        let r = (degrees - 90) * .pi / 180
        let dx = cos(r) / 2, dy = sin(r) / 2
        return LinearGradient(colors: colors,
                              startPoint: UnitPoint(x: 0.5 - dx, y: 0.5 - dy),
                              endPoint: UnitPoint(x: 0.5 + dx, y: 0.5 + dy))
    }

    static func angle(_ degrees: Double, stops: [Gradient.Stop]) -> LinearGradient {
        let r = (degrees - 90) * .pi / 180
        let dx = cos(r) / 2, dy = sin(r) / 2
        return LinearGradient(stops: stops,
                              startPoint: UnitPoint(x: 0.5 - dx, y: 0.5 - dy),
                              endPoint: UnitPoint(x: 0.5 + dx, y: 0.5 + dy))
    }
}

// MARK: - Scanner icon: four corner brackets and a centre line, 2.2 pt stroke.

struct ScannerIcon: Shape {
    func path(in r: CGRect) -> Path {
        SVGPath("M2 8V5a3 3 0 0 1 3-3h3 M18 2h3a3 3 0 0 1 3 3v3 M24 18v3a3 3 0 0 1-3 3h-3 M8 24H5a3 3 0 0 1-3-3v-3 M6.5 13h13")
            .path(in: r, viewBox: CGSize(width: 26, height: 26))
    }
}

/// The small leaf glyph used in the Live Activity and widgets.
struct SproutGlyph: Shape {
    func path(in r: CGRect) -> Path {
        SVGPath("M12 20V9 M12 11c0-4 2.6-7 7-7 0 4.4-3 7-7 7Z M12 14c0-3-2-5-5.5-5 0 3.4 2.2 5 5.5 5Z")
            .path(in: r, viewBox: CGSize(width: 24, height: 24))
    }
}
