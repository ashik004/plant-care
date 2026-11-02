import SwiftUI

/// Parses SVG path data (M, L, H, V, C, S, Q, A, Z, absolute and relative) so the
/// prototype's line-art illustrations can be drawn with the exact same geometry.
struct SVGPath {
    let d: String

    init(_ d: String) { self.d = d }

    /// The path in its own viewBox coordinates.
    var raw: Path { SVGPath.parse(d) }

    /// The path scaled from `viewBox` into `rect`, preserving aspect ratio and centring.
    func path(in rect: CGRect, viewBox: CGSize) -> Path {
        let s = min(rect.width / viewBox.width, rect.height / viewBox.height)
        let ox = rect.minX + (rect.width - viewBox.width * s) / 2
        let oy = rect.minY + (rect.height - viewBox.height * s) / 2
        return raw.applying(CGAffineTransform(a: s, b: 0, c: 0, d: s, tx: ox, ty: oy))
    }

    // MARK: Parsing

    private enum Token { case cmd(Character), num(CGFloat) }

    private static func tokenize(_ s: String) -> [Token] {
        var out: [Token] = []
        var buf = ""
        var seenDot = false, seenExp = false
        func flush() {
            if !buf.isEmpty, let v = Double(buf) { out.append(.num(CGFloat(v))) }
            buf = ""; seenDot = false; seenExp = false
        }
        for ch in s {
            if ch.isLetter && ch != "e" && ch != "E" {
                flush(); out.append(.cmd(ch))
            } else if ch == "e" || ch == "E" {
                buf.append(ch); seenExp = true
            } else if ch == "-" || ch == "+" {
                if let last = buf.last, last == "e" || last == "E" { buf.append(ch) } else { flush(); buf.append(ch) }
            } else if ch == "." {
                if seenDot || seenExp { flush() }
                buf.append(ch); seenDot = true
            } else if ch.isNumber {
                buf.append(ch)
            } else {
                flush()
            }
        }
        flush()
        return out
    }

    private static func parse(_ d: String) -> Path {
        var path = Path()
        let tokens = tokenize(d)
        var i = 0
        var cmd: Character = "M"
        var cur = CGPoint.zero, start = CGPoint.zero
        var lastCtrl: CGPoint? = nil
        var lastQuad: CGPoint? = nil

        func hasNum() -> Bool { if i < tokens.count, case .num = tokens[i] { return true }; return false }
        func num() -> CGFloat { if i < tokens.count, case .num(let v) = tokens[i] { i += 1; return v }; i += 1; return 0 }

        while i < tokens.count {
            if case .cmd(let c) = tokens[i] { cmd = c; i += 1 }
            let rel = cmd.isLowercase
            let base = rel ? cur : .zero
            switch cmd.uppercased().first! {
            case "M":
                let p = CGPoint(x: num() + base.x, y: num() + base.y)
                path.move(to: p); cur = p; start = p
                cmd = rel ? "l" : "L"   // implicit lineto for following pairs
                lastCtrl = nil; lastQuad = nil
            case "L":
                let p = CGPoint(x: num() + base.x, y: num() + base.y)
                path.addLine(to: p); cur = p; lastCtrl = nil; lastQuad = nil
            case "H":
                let x = num() + (rel ? cur.x : 0)
                cur = CGPoint(x: x, y: cur.y); path.addLine(to: cur); lastCtrl = nil; lastQuad = nil
            case "V":
                let y = num() + (rel ? cur.y : 0)
                cur = CGPoint(x: cur.x, y: y); path.addLine(to: cur); lastCtrl = nil; lastQuad = nil
            case "C":
                let c1 = CGPoint(x: num() + base.x, y: num() + base.y)
                let c2 = CGPoint(x: num() + base.x, y: num() + base.y)
                let p = CGPoint(x: num() + base.x, y: num() + base.y)
                path.addCurve(to: p, control1: c1, control2: c2); cur = p; lastCtrl = c2; lastQuad = nil
            case "S":
                let c1 = lastCtrl.map { CGPoint(x: 2 * cur.x - $0.x, y: 2 * cur.y - $0.y) } ?? cur
                let c2 = CGPoint(x: num() + base.x, y: num() + base.y)
                let p = CGPoint(x: num() + base.x, y: num() + base.y)
                path.addCurve(to: p, control1: c1, control2: c2); cur = p; lastCtrl = c2; lastQuad = nil
            case "Q":
                let c = CGPoint(x: num() + base.x, y: num() + base.y)
                let p = CGPoint(x: num() + base.x, y: num() + base.y)
                path.addQuadCurve(to: p, control: c); cur = p; lastQuad = c; lastCtrl = nil
            case "T":
                let c = lastQuad.map { CGPoint(x: 2 * cur.x - $0.x, y: 2 * cur.y - $0.y) } ?? cur
                let p = CGPoint(x: num() + base.x, y: num() + base.y)
                path.addQuadCurve(to: p, control: c); cur = p; lastQuad = c; lastCtrl = nil
            case "A":
                let rx = num(), ry = num(), rot = num(), large = num() != 0, sweep = num() != 0
                let p = CGPoint(x: num() + base.x, y: num() + base.y)
                addArc(&path, from: cur, to: p, rx: rx, ry: ry, rotation: rot, large: large, sweep: sweep)
                cur = p; lastCtrl = nil; lastQuad = nil
            case "Z":
                path.closeSubpath(); cur = start; lastCtrl = nil; lastQuad = nil
                // Z takes no numbers; if numbers follow, treat them as an implicit lineto.
                if hasNum() { cmd = "L" }
                continue
            default:
                // Unknown command: skip its numbers.
                while hasNum() { i += 1 }
            }
        }
        return path
    }

    /// Converts an SVG endpoint arc into cubic Béziers.
    private static func addArc(_ path: inout Path, from p0: CGPoint, to p1: CGPoint,
                               rx rxIn: CGFloat, ry ryIn: CGFloat, rotation: CGFloat,
                               large: Bool, sweep: Bool) {
        var rx = abs(rxIn), ry = abs(ryIn)
        if rx == 0 || ry == 0 || p0 == p1 { path.addLine(to: p1); return }
        let phi = rotation * .pi / 180
        let cosP = cos(phi), sinP = sin(phi)
        let dx = (p0.x - p1.x) / 2, dy = (p0.y - p1.y) / 2
        let x1 = cosP * dx + sinP * dy
        let y1 = -sinP * dx + cosP * dy
        let lambda = (x1 * x1) / (rx * rx) + (y1 * y1) / (ry * ry)
        if lambda > 1 { let s = sqrt(lambda); rx *= s; ry *= s }
        let num = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1
        let den = rx * rx * y1 * y1 + ry * ry * x1 * x1
        var coef = sqrt(max(0, num / den))
        if large == sweep { coef = -coef }
        let cx1 = coef * (rx * y1 / ry)
        let cy1 = coef * -(ry * x1 / rx)
        let cx = cosP * cx1 - sinP * cy1 + (p0.x + p1.x) / 2
        let cy = sinP * cx1 + cosP * cy1 + (p0.y + p1.y) / 2

        func angle(_ ux: CGFloat, _ uy: CGFloat, _ vx: CGFloat, _ vy: CGFloat) -> CGFloat {
            let a = atan2(ux * vy - uy * vx, ux * vx + uy * vy)
            return a
        }
        let theta1 = angle(1, 0, (x1 - cx1) / rx, (y1 - cy1) / ry)
        var dTheta = angle((x1 - cx1) / rx, (y1 - cy1) / ry, (-x1 - cx1) / rx, (-y1 - cy1) / ry)
        if !sweep && dTheta > 0 { dTheta -= 2 * .pi }
        if sweep && dTheta < 0 { dTheta += 2 * .pi }

        let segments = max(1, Int(ceil(abs(dTheta) / (.pi / 2))))
        let delta = dTheta / CGFloat(segments)
        let t = 4 / 3 * tan(delta / 4)
        var th = theta1
        func point(_ a: CGFloat) -> CGPoint {
            CGPoint(x: cx + rx * cos(a) * cosP - ry * sin(a) * sinP,
                    y: cy + rx * cos(a) * sinP + ry * sin(a) * cosP)
        }
        func deriv(_ a: CGFloat) -> CGPoint {
            CGPoint(x: -rx * sin(a) * cosP - ry * cos(a) * sinP,
                    y: -rx * sin(a) * sinP + ry * cos(a) * cosP)
        }
        for _ in 0..<segments {
            let a1 = th, a2 = th + delta
            let s = point(a1), e = point(a2)
            let d1 = deriv(a1), d2 = deriv(a2)
            path.addCurve(to: e,
                          control1: CGPoint(x: s.x + t * d1.x, y: s.y + t * d1.y),
                          control2: CGPoint(x: e.x - t * d2.x, y: e.y - t * d2.y))
            th = a2
        }
    }
}

/// A `Shape` that draws SVG path data inside a fixed viewBox.
struct SVGShape: Shape {
    let d: String
    let viewBox: CGSize

    init(_ d: String, viewBox: CGSize) { self.d = d; self.viewBox = viewBox }

    func path(in rect: CGRect) -> Path { SVGPath(d).path(in: rect, viewBox: viewBox) }
}
