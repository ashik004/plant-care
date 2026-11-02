import WidgetKit
import SwiftUI
import ActivityKit

@main
struct TendWidgetsBundle: WidgetBundle {
    var body: some Widget {
        ThirstyWidget()
        HealthWidget()
        TreatmentLiveActivity()
    }
}

// MARK: Timeline

struct SummaryEntry: TimelineEntry {
    let date: Date
    let summary: CollectionSummary
}

struct SummaryProvider: TimelineProvider {
    func placeholder(in context: Context) -> SummaryEntry { SummaryEntry(date: .now, summary: .sample) }

    func getSnapshot(in context: Context, completion: @escaping (SummaryEntry) -> Void) {
        completion(SummaryEntry(date: .now, summary: context.isPreview ? .sample : SharedStore.summary()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SummaryEntry>) -> Void) {
        let entry = SummaryEntry(date: .now, summary: SharedStore.summary())
        // The app reloads timelines whenever care is logged; refresh hourly as a fallback.
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(3600))))
    }
}

// MARK: Thirsty today (Home Screen small + Lock Screen rectangular)

struct ThirstyWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TendThirsty", provider: SummaryProvider()) { entry in
            ThirstyWidgetView(entry: entry)
        }
        .configurationDisplayName("Thirsty today")
        .description("Which plants need water today.")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

struct ThirstyWidgetView: View {
    let entry: SummaryEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("TEND · \(entry.summary.thirsty.isEmpty ? "ALL GOOD" : "\(entry.summary.thirsty.count) THIRSTY")")
                    .font(.system(size: 11, weight: .bold)).widgetAccentable()
                Text(entry.summary.thirsty.isEmpty ? "Nothing due today" : Care.listNames(entry.summary.thirsty))
                    .font(.system(size: 14, weight: .semibold)).lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .containerBackground(for: .widget) { AccessoryWidgetBackground() }
        default:
            ThirstyWidgetFace(summary: entry.summary)
                .containerBackground(Tend.C.surface, for: .widget)
                .widgetURL(URL(string: "tend://home"))
        }
    }
}

// MARK: Health (Home Screen small + Lock Screen circular gauge)

struct HealthWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TendHealth", provider: SummaryProvider()) { entry in
            HealthWidgetView(entry: entry)
        }
        .configurationDisplayName("Plant health")
        .description("How much of your collection is thriving.")
        .supportedFamilies([.systemSmall, .accessoryCircular])
    }
}

struct HealthWidgetView: View {
    let entry: SummaryEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            Gauge(value: Double(entry.summary.healthPercent), in: 0...100) {
                Text("Health")
            } currentValueLabel: {
                Text("\(entry.summary.healthPercent)%").font(.system(size: 15, weight: .bold))
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .containerBackground(for: .widget) { AccessoryWidgetBackground() }
        default:
            HealthWidgetFace(summary: entry.summary)
                .containerBackground(for: .widget) { Tend.C.deepGradient }
        }
    }
}

// MARK: Treatment Live Activity + Dynamic Island

struct TreatmentLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TreatmentActivityAttributes.self) { context in
            TreatmentActivityFace(plant: context.attributes.plantName, treatment: context.attributes.treatment, state: context.state)
                .padding(.vertical, 14).padding(.horizontal, 16)
                .activityBackgroundTint(Color(hex: 0x141E12, opacity: 0.62))
                .activitySystemActionForegroundColor(Color(hex: 0xF4F0E6))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    SproutGlyph().stroke(.white, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                        .frame(width: 20, height: 20)
                        .frame(width: 34, height: 34)
                        .background(Color(hex: 0x3A6E33), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.round)/\(context.state.totalRounds)").font(.system(size: 17, weight: .semibold))
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("\(context.attributes.plantName) · \(context.attributes.treatment)").font(.system(size: 15, weight: .semibold))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Next round \(context.state.nextRound)").font(.system(size: 13)).opacity(0.75)
                        ProgressCapsule(fraction: context.state.progress).frame(height: 6)
                    }
                }
            } compactLeading: {
                RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color(hex: 0x3A6E33)).frame(width: 20, height: 20)
            } compactTrailing: {
                HStack(spacing: 6) {
                    ProgressCapsule(fraction: context.state.progress).frame(width: 44, height: 4)
                    Text("\(context.state.round)/\(context.state.totalRounds)").font(.system(size: 13, weight: .semibold))
                }
            } minimal: {
                Text("\(context.state.round)").font(.system(size: 13, weight: .semibold))
            }
            .keylineTint(Color(hex: 0xB7D3A3))
        }
    }
}
