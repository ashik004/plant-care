import SwiftUI

// Widget and Live Activity faces. Used by the TendWidgets extension and by the in-app
// Widgets & Live Activities preview.

/// Small Home Screen widget: "THIRSTY TODAY".
struct ThirstyWidgetFace: View {
    let summary: CollectionSummary
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("THIRSTY TODAY").font(Tend.F.sans(10, .bold)).tracking(1).foregroundStyle(Tend.C.clay)
            ForEach(Array((summary.thirsty.isEmpty ? ["All watered"] : summary.thirsty).prefix(3).enumerated()), id: \.offset) { _, n in
                HStack(spacing: 7) {
                    Circle().fill(Tend.C.clay).frame(width: 6, height: 6)
                    Text(n).font(Tend.F.sans(14, .semibold)).foregroundStyle(Tend.C.text).lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            Text("Tomorrow: " + (summary.tomorrow.isEmpty ? "nothing" : Care.listNames(summary.tomorrow)))
                .font(Tend.F.sans(11)).foregroundStyle(Tend.C.text4).lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// Small Home Screen widget: "YOUR PLANTS" health percent on the deep-green gradient.
struct HealthWidgetFace: View {
    let summary: CollectionSummary
    var body: some View {
        VStack(alignment: .leading) {
            Text("YOUR PLANTS").font(Tend.F.sans(10, .bold)).tracking(1).foregroundStyle(Tend.C.creamSoft)
            Spacer(minLength: 0)
            Text("\(summary.healthPercent)%").font(Tend.F.serif(44)).foregroundStyle(Tend.C.cream)
            Spacer(minLength: 0)
            Text("\(summary.thriving) of \(summary.total) thriving").font(Tend.F.sans(12)).foregroundStyle(Tend.C.creamSoft)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// Thin progress capsule used in the Dynamic Island and Live Activity.
struct ProgressCapsule: View {
    let fraction: Double
    var fill: Color = Color(hex: 0xB7D3A3)
    var track: Color = .white.opacity(0.2)
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule().fill(fill).frame(width: g.size.width * max(0, min(1, fraction)))
            }
        }
    }
}

/// Lock Screen Live Activity for a treatment course.
struct TreatmentActivityFace: View {
    let plant: String
    let treatment: String
    let state: TreatmentActivityAttributes.ContentState

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                SproutGlyph().stroke(.white, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                    .frame(width: 20, height: 20)
                    .frame(width: 38, height: 38)
                    .background(Color(hex: 0x3A6E33), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(plant) · \(treatment)").font(.system(size: 15, weight: .semibold))
                    Text("Round \(state.round) of \(state.totalRounds) · next \(state.nextRound)").font(.system(size: 13)).opacity(0.75)
                }
                Spacer(minLength: 0)
                Text("\(Int((state.progress * 100).rounded()))%").font(Tend.F.serif(22))
            }
            ProgressCapsule(fraction: state.progress, track: .white.opacity(0.18)).frame(height: 6)
        }
        .foregroundStyle(Color(hex: 0xF4F0E6))
    }
}

/// The Lock Screen Live Activity as shown in the app's preview.
struct TreatmentActivityPreview: View {
    var body: some View {
        TreatmentActivityFace(plant: "Figgy", treatment: "neem treatment",
                              state: .init(round: 2, totalRounds: 5, nextRound: "Mon 2 Nov"))
            .padding(.vertical, 14).padding(.horizontal, 16)
            .background(Color(hex: 0x141E12, opacity: 0.62), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
