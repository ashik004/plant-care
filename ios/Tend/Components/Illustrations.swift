import SwiftUI

// Animated line-art placeholders for brand art. Geometry is the prototype's SVG; motion
// reproduces its CSS keyframes. Line art: 2 pt moss stroke, leaf fills #9DBE88 / #B7D3A3,
// terracotta pot #C9774F / #B5603A. Swap in Lottie or commissioned art later.

// MARK: - Keyframe helpers

enum KF {
    /// CSS `ease-in-out` style easing applied per keyframe segment.
    static func easeInOut(_ x: Double) -> Double { x < 0.5 ? 2 * x * x : 1 - pow(-2 * x + 2, 2) / 2 }
    static func easeOut(_ x: Double) -> Double { 1 - pow(1 - x, 2) }
    static func easeIn(_ x: Double) -> Double { x * x }

    /// Interpolates `stops` (progress 0…1, value) at `t` (0…1).
    static func value(_ t: Double, _ stops: [(Double, Double)], ease: (Double) -> Double = easeInOut) -> Double {
        guard let first = stops.first else { return 0 }
        if t <= first.0 { return first.1 }
        for i in 1..<stops.count {
            let a = stops[i - 1], b = stops[i]
            if t <= b.0 {
                let span = b.0 - a.0
                let x = span > 0 ? (t - a.0) / span : 1
                return a.1 + (b.1 - a.1) * ease(x)
            }
        }
        return stops.last!.1
    }

    /// Loop progress (0…1) for a looping animation with a period and delay.
    static func loop(_ time: Double, period: Double, delay: Double = 0) -> Double {
        let t = (time - delay).truncatingRemainder(dividingBy: period)
        return t < 0 ? t + period : t / period
    }
}

/// Drives a looping canvas illustration from wall-clock time; static under Reduce Motion.
struct LoopingCanvas: View {
    let viewBox: CGSize
    var stillTime: Double = 1.2
    let draw: (inout GraphicsContext, Double) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { tl in
            let time = reduceMotion ? stillTime : tl.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let s = min(size.width / viewBox.width, size.height / viewBox.height)
                ctx.translateBy(x: (size.width - viewBox.width * s) / 2, y: (size.height - viewBox.height * s) / 2)
                ctx.scaleBy(x: s, y: s)
                draw(&ctx, time)
            }
        }
        .accessibilityHidden(true)
    }
}

extension GraphicsContext {
    mutating func art(_ d: String, fill: Color? = nil, stroke: Color? = Tend.C.lineArt, width: CGFloat = 2,
                      dash: [CGFloat] = [], opacity: Double = 1) {
        let p = SVGPath(d).raw
        var c = self
        c.opacity = opacity
        if let fill { c.fill(p, with: .color(fill)) }
        if let stroke {
            c.stroke(p, with: .color(stroke), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round, dash: dash))
        }
    }

    /// Rotates (degrees) and scales about an origin in viewBox coordinates.
    func around(_ x: CGFloat, _ y: CGFloat, rotate: Double = 0, scaleX: CGFloat = 1, scaleY: CGFloat = 1,
                translate: CGSize = .zero) -> GraphicsContext {
        var c = self
        c.translateBy(x: x + translate.width, y: y + translate.height)
        c.rotate(by: .degrees(rotate))
        c.scaleBy(x: scaleX, y: scaleY)
        c.translateBy(x: -x, y: -y)
        return c
    }
}

// MARK: - Onboarding: watering can tips, drops fall, sprout perks up (2.8 s loop)

struct WateringCanIllustration: View {
    var body: some View {
        LoopingCanvas(viewBox: CGSize(width: 220, height: 120), stillTime: 0) { ctx, time in
            let t = KF.loop(time, period: 2.8)
            ctx.fill(Path(ellipseIn: CGRect(x: 130, y: 110, width: 52, height: 6)), with: .color(Tend.C.ink(0.1)))

            let tilt = KF.value(t, [(0, 0), (0.15, 0), (0.35, 16), (0.75, 16), (0.95, 0), (1, 0)])
            var can = ctx.around(68, 70, rotate: tilt)
            can.art("M50 44c0-18 38-18 38 0", stroke: Tend.C.lineArt, width: 5)
            can.art("M42 46h52a4 4 0 0 1 4 4v32a6 6 0 0 1-6 6H44a6 6 0 0 1-6-6V50a4 4 0 0 1 4-4Z", fill: Tend.C.leafFillDeep)
            can.art("M98 58l34-20 4 6-34 26Z", fill: Tend.C.leafFill)
            can.art("M130 34l9-3 3 10-7 3Z", fill: Tend.C.leafFillDark)
            can.art("M46 58h48", width: 1.4, opacity: 0.4)

            for (i, x) in [139.0, 143.0, 147.0].enumerated() {
                let dt = KF.loop(time, period: 2.8, delay: Double(i) * 0.35)
                let op = KF.value(dt, [(0, 0), (0.30, 0), (0.38, 1), (0.70, 1), (0.74, 0), (1, 0)], ease: { $0 })
                let y = KF.value(dt, [(0, 0), (0.30, 0), (0.70, 34), (0.74, 38), (1, 38)], ease: KF.easeIn)
                var drop = ctx
                drop.translateBy(x: 0, y: y)
                drop.art("M\(x) 50c0 0-3 4-3 6a3 3 0 0 0 6 0c0-2-3-6-3-6Z", fill: Tend.C.water, stroke: nil, opacity: op)
            }

            let perkS = KF.value(t, [(0, 0.86), (0.55, 0.86), (0.80, 1), (1, 1)])
            let perkR = KF.value(t, [(0, -6), (0.55, -6), (0.80, 0), (1, 0)])
            var sprout = ctx.around(156, 92, rotate: perkR, scaleY: perkS)
            sprout.art("M156 92V74")
            sprout.art("M156 82c-8 0-12-6-12-12 7 0 12 5 12 12Z", fill: Tend.C.leafFill)
            sprout.art("M156 78c7-1 11-7 10-13-7 1-10 6-10 13Z", fill: Tend.C.leafFillLight)

            ctx.art("M138 90h36l-4 21h-28Z", fill: Tend.C.pot)
            ctx.art("M135 88h42v5h-42Z", fill: Tend.C.potRim)
        }
        .frame(width: 220, height: 120)
    }
}

// MARK: - Home "All tended": a dozing plant sways while z's float up

struct DozingPlantIllustration: View {
    var body: some View {
        LoopingCanvas(viewBox: CGSize(width: 120, height: 112)) { ctx, time in
            ctx.fill(Path(ellipseIn: CGRect(x: 30, y: 102.5, width: 60, height: 7)), with: .color(Tend.C.ink(0.1)))

            let sway = KF.value(KF.loop(time, period: 4.5), [(0, -4), (0.5, 3), (1, -4)])
            var plant = ctx.around(60, 74, rotate: sway)
            plant.art("M60 74C60 60 58 50 60 36")
            let a = KF.value(KF.loop(time, period: 3.2), [(0, 0), (0.5, -7), (1, 0)])
            var leafA = plant.around(60, 58, rotate: a)
            leafA.art("M60 58C46 57 37 47 39 35C52 37 60 46 60 58Z", fill: Tend.C.leafFill)
            leafA.art("M59 56 45 42", width: 1.2)
            let b = KF.value(KF.loop(time, period: 3.6), [(0, 0), (0.5, 6), (1, 0)])
            var leafB = plant.around(60, 50, rotate: b)
            leafB.art("M60 50C73 47 81 37 79 25C66 27 60 37 60 50Z", fill: Tend.C.leafFillLight)
            leafB.art("M61 48 74 32", width: 1.2)
            plant.art("M60 37C54 30 55 20 61 13C67 21 66 30 60 37Z", fill: Tend.C.leafFillDeep)

            ctx.art("M34 72h52a3 3 0 0 1 3 3v4a3 3 0 0 1-3 3H34a3 3 0 0 1-3-3v-4a3 3 0 0 1 3-3Z", fill: Tend.C.potRim)
            ctx.art("M36 82h48l-5 22H41Z", fill: Tend.C.pot)

            for (x, y, size, delay) in [(84.0, 34.0, 13.0, 0.0), (92.0, 22.0, 10.0, 1.5)] {
                let zt = KF.loop(time, period: 3, delay: delay)
                let op = KF.value(zt, [(0, 0), (0.3, 1), (1, 0)], ease: KF.easeOut)
                let dx = KF.value(zt, [(0, 0), (1, 14)], ease: KF.easeOut)
                let dy = KF.value(zt, [(0, 0), (1, -26)], ease: KF.easeOut)
                let sc = KF.value(zt, [(0, 0.7), (1, 1.1)], ease: KF.easeOut)
                var z = ctx.around(x, y, scaleX: sc, scaleY: sc, translate: CGSize(width: dx, height: dy))
                z.opacity = op
                z.draw(Text("z").font(Tend.F.serifMediumItalic(size)).foregroundStyle(Tend.C.text4),
                       at: CGPoint(x: x, y: y), anchor: .bottomLeading)
            }
        }
        .frame(width: 130, height: 112)
    }
}

// MARK: - Scanner: a leaf outline draws itself, then its veins fade in (3.6 s loop)

struct LeafDrawIllustration: View {
    var color: Color = Tend.C.accent
    var body: some View {
        LoopingCanvas(viewBox: CGSize(width: 120, height: 140), stillTime: 2.4) { ctx, time in
            let t = KF.loop(time, period: 3.6)
            let outline = SVGPath("M60 132V108M60 108C26 100 14 66 26 34 34 14 50 8 60 6c10 2 26 8 34 28 12 32 0 66-34 74Z").raw
            let from: CGFloat, to: CGFloat
            if t < 0.55 { from = 0; to = CGFloat(KF.easeInOut(t / 0.55)) }
            else if t < 0.8 { from = 0; to = 1 }
            else { from = CGFloat(KF.easeInOut((t - 0.8) / 0.2)); to = 1 }
            ctx.stroke(outline.trimmedPath(from: from, to: to), with: .color(color),
                       style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))

            let vein = KF.value(t, [(0, 0), (0.4, 0), (0.6, 1), (0.85, 1), (1, 0)])
            ctx.art("M60 106V14", stroke: color, width: 1.6, opacity: vein)
            ctx.art("M60 40 42 28M60 40l18-12M60 62 36 48M60 62l24-14M60 84 40 74M60 84l20-10",
                    stroke: color, width: 1.3, opacity: vein * 0.7)
        }
        .frame(width: 120, height: 140)
    }
}

// MARK: - Empty shelf: a seed bobs above an empty pot

struct EmptyPotIllustration: View {
    var body: some View {
        LoopingCanvas(viewBox: CGSize(width: 170, height: 160)) { ctx, time in
            ctx.fill(Path(ellipseIn: CGRect(x: 39, y: 146, width: 92, height: 8)), with: .color(Tend.C.ink(0.1)))
            ctx.art("M85 92V62", stroke: Tend.C.accent, width: 2, dash: [4, 5])
            ctx.art("M85 74c-12 0-19-8-19-18 11 0 19 7 19 18Z", fill: Tend.C.leafFill.opacity(0.15), stroke: Tend.C.accent, width: 1.6, dash: [4, 4])
            ctx.art("M85 68c11-1 18-9 17-20-11 1-17 9-17 20Z", fill: Tend.C.leafFill.opacity(0.15), stroke: Tend.C.accent, width: 1.6, dash: [4, 4])

            let bob = KF.value(KF.loop(time, period: 2.2), [(0, 0), (0.5, -6), (1, 0)])
            var seed = ctx.around(85, 40, rotate: 20, translate: CGSize(width: 0, height: bob))
            let e = Path(ellipseIn: CGRect(x: 78, y: 30.5, width: 14, height: 19))
            seed.fill(e, with: .color(Tend.C.seed))
            seed.stroke(e, with: .color(Tend.C.lineArt), lineWidth: 2)

            ctx.art("M44 96h82a4 4 0 0 1 4 4v8a4 4 0 0 1-4 4H44a4 4 0 0 1-4-4v-8a4 4 0 0 1 4-4Z", fill: Tend.C.potRim)
            ctx.art("M46 112h78l-8 36H54Z", fill: Tend.C.pot)
            ctx.art("M48 100c12-3 62-3 74 0", stroke: Color(hex: 0x5E4030), width: 2, opacity: 0.5)
        }
        .frame(width: 170, height: 160)
    }
}

// MARK: - Premium success: a seedling grows inside the check circle, with two bursting rings

struct SeedlingSuccess: View {
    @State private var popped = false
    @State private var sprout = false
    @State private var leafA = false
    @State private var leafB = false
    @State private var burst1 = false
    @State private var burst2 = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let box = CGSize(width: 64, height: 64)

    var body: some View {
        ZStack {
            Circle().stroke(Tend.C.accent, lineWidth: 2)
                .scaleEffect(burst1 ? 2.6 : 0.6).opacity(burst1 ? 0 : 0.7)
            Circle().stroke(Tend.C.amber, lineWidth: 2)
                .scaleEffect(burst2 ? 2.6 : 0.6).opacity(burst2 ? 0 : 0.7)
            Circle().fill(Tend.C.brand).shadow(color: Tend.C.leaf(0.27), radius: 35)
            ZStack {
                SVGShape("M18 52h28", viewBox: box).stroke(.white.opacity(0.6), style: stroke)
                SVGShape("M32 52V26", viewBox: box).stroke(.white, style: stroke)
                    .scaleEffect(x: 1, y: sprout ? 1 : 0, anchor: UnitPoint(x: 0.5, y: 52 / 64))
                leaf("M32 36c-10 0-16-7-16-15 9 0 16 6 16 15Z", on: leafA, anchor: UnitPoint(x: 0.5, y: 36 / 64))
                leaf("M32 30c9-1 15-8 14-17-9 1-14 8-14 17Z", on: leafB, anchor: UnitPoint(x: 0.5, y: 30 / 64))
            }
            .frame(width: 64, height: 64)
        }
        .frame(width: 96, height: 96)
        .scaleEffect(popped ? 1 : 0.4)
        .onAppear {
            if reduceMotion { popped = true; sprout = true; leafA = true; leafB = true; burst1 = true; burst2 = true; return }
            withAnimation(Tend.pop(0.6)) { popped = true }
            withAnimation(.easeOut(duration: 1.1).delay(0.15)) { burst1 = true }
            withAnimation(.easeOut(duration: 1.1).delay(0.35)) { burst2 = true }
            withAnimation(Tend.ease(0.6).delay(0.35)) { sprout = true }
            withAnimation(Tend.pop(0.55).delay(0.8)) { leafA = true }
            withAnimation(Tend.pop(0.55).delay(1.0)) { leafB = true }
        }
        .accessibilityHidden(true)
    }

    private var stroke: StrokeStyle { StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round) }

    private func leaf(_ d: String, on: Bool, anchor: UnitPoint) -> some View {
        ZStack {
            SVGShape(d, viewBox: box).fill(.white.opacity(0.22))
            SVGShape(d, viewBox: box).stroke(.white, style: stroke)
        }
        .scaleEffect(on ? 1 : 0, anchor: anchor)
        .rotationEffect(.degrees(on ? 0 : -30), anchor: anchor)
    }
}

// MARK: - Growth timelapse plant (driven by the current frame)

struct TimelapsePlant: View {
    /// 0…7 (W37…W44)
    let frame: Int
    private let box = CGSize(width: 200, height: 260)

    private var stemTop: CGFloat { (160 - CGFloat(frame) / 7 * 116).rounded() }

    private static let leaves: [(d: String, y: CGFloat, fill: Color, right: Bool)] = [
        ("M100 190C80 190 66 178 66 162C84 162 100 172 100 190Z", 190, Tend.C.leafFill, true),
        ("M100 172C120 172 134 160 134 144C116 144 100 154 100 172Z", 172, Tend.C.leafFillLight, false),
        ("M100 150C78 150 62 136 62 118C84 118 100 130 100 150Z", 150, Tend.C.leafFill, true),
        ("M100 128C122 128 138 112 138 94C116 94 100 108 100 128Z", 128, Tend.C.leafFillLight, false),
        ("M100 106C80 106 66 92 66 76C86 76 100 88 100 106Z", 106, Tend.C.leafFill, true),
        ("M100 86C118 86 130 72 130 58C112 58 100 68 100 86Z", 86, Tend.C.leafFillLight, false),
    ]

    var body: some View {
        ZStack {
            Ellipse().fill(Tend.C.ink(0.12)).frame(width: 88, height: 8).position(x: 100, y: 255)
            StemShape(top: stemTop)
                .stroke(Tend.C.lineArt, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .animation(Tend.ease(0.55), value: stemTop)
            ForEach(0..<Self.leaves.count, id: \.self) { i in
                let leaf = Self.leaves[i]
                let shown = stemTop <= leaf.y - 8
                ZStack {
                    SVGShape(leaf.d, viewBox: box).fill(leaf.fill)
                    SVGShape(leaf.d, viewBox: box).stroke(Tend.C.lineArt, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                }
                .scaleEffect(shown ? 1 : 0.001, anchor: UnitPoint(x: 100 / 200, y: leaf.y / 260))
                .opacity(shown ? 1 : 0)
                .animation(.timingCurve(0.34, 1.4, 0.64, 1, duration: 0.6), value: shown)
            }
            ZStack {
                SVGShape("M100 66C94 58 95 48 101 40C107 48 106 58 100 66Z", viewBox: box).fill(Tend.C.leafFillDeep)
                SVGShape("M100 66C94 58 95 48 101 40C107 48 106 58 100 66Z", viewBox: box)
                    .stroke(Tend.C.lineArt, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
            .offset(y: stemTop - 66)
            .animation(Tend.ease(0.55), value: stemTop)
            SVGShape("M62 212h76a4 4 0 0 1 4 4v6a4 4 0 0 1-4 4H62a4 4 0 0 1-4-4v-6a4 4 0 0 1 4-4Z", viewBox: box).fill(Tend.C.potRim)
                .overlay(SVGShape("M62 212h76a4 4 0 0 1 4 4v6a4 4 0 0 1-4 4H62a4 4 0 0 1-4-4v-6a4 4 0 0 1 4-4Z", viewBox: box).stroke(Tend.C.lineArt, lineWidth: 2))
            SVGShape("M64 226h72l-7 28H71Z", viewBox: box).fill(Tend.C.pot)
                .overlay(SVGShape("M64 226h72l-7 28H71Z", viewBox: box).stroke(Tend.C.lineArt, style: StrokeStyle(lineWidth: 2, lineJoin: .round)))
        }
        .frame(width: 200, height: 260)
        .accessibilityHidden(true)
    }
}

/// "M100 212V{top}" with an animatable top.
struct StemShape: Shape {
    var top: CGFloat
    var animatableData: CGFloat { get { top } set { top = newValue } }
    func path(in r: CGRect) -> Path {
        let s = r.width / 200
        var p = Path()
        p.move(to: CGPoint(x: r.minX + 100 * s, y: r.minY + 212 * s))
        p.addLine(to: CGPoint(x: r.minX + 100 * s, y: r.minY + top * s))
        return p
    }
}

// MARK: - Small icons from the prototype

enum Icon {
    static let ask = "M4 19.5V7a3 3 0 0 1 3-3h10a3 3 0 0 1 3 3v6a3 3 0 0 1-3 3H8Z M12 13.5c0-2.6 1.6-4.2 4.2-4.2 0 2.6-1.6 4.2-4.2 4.2Z"
    static let sun = "M12 2.5v2M12 19.5v2M2.5 12h2M19.5 12h2M5.3 5.3l1.4 1.4M17.3 17.3l1.4 1.4M5.3 18.7l1.4-1.4M17.3 6.7l1.4-1.4"
    static let offline = "M7 18h10.5a4 4 0 0 0 .6-7.95A6 6 0 0 0 7.2 8.3 4.9 4.9 0 0 0 7 18Z M3 3l18 18"
    static let send = "M12 19V5M5.5 11.5 12 5l6.5 6.5"
    static let play = "M3.5 1.5v11L12.5 7Z"
    static let playSmall = "M3 1.8v10.4L12 7Z"
}

struct LineIcon: View {
    let d: String
    var color: Color = Tend.C.text
    var size: CGFloat = 18
    var lineWidth: CGFloat = 1.9
    var viewBox: CGFloat = 24
    var body: some View {
        SVGShape(d, viewBox: CGSize(width: viewBox, height: viewBox))
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth * size / viewBox, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
    }
}

struct SunIcon: View {
    var color: Color = Tend.C.brandInk
    var body: some View {
        ZStack {
            Circle().stroke(color, lineWidth: 1.9 * 18 / 24).frame(width: 6, height: 6)
            LineIcon(d: Icon.sun, color: color)
        }
        .frame(width: 18, height: 18)
    }
}
