import SwiftUI

/// The native iOS 26 TabView renders the Liquid Glass floating bar. Home, Plants and
/// Guides are tabs; Scan is the trailing glass button (`Tab(role: .search)`), which opens
/// the scanner as a full-screen cover instead of switching tabs.
struct MainTabView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        let selection = Binding<AppTab>(
            get: { model.selectedTab },
            set: { model.selectTab($0) })

        TabView(selection: selection) {
            Tab("Home", systemImage: "house", value: AppTab.home) {
                NavigationStack(path: $model.homePath) {
                    HomeView().routes()
                }
            }
            .badge(model.tasks.count)

            Tab("Plants", systemImage: "leaf", value: AppTab.plants) {
                NavigationStack(path: $model.plantsPath) {
                    PlantsView().routes()
                }
            }

            Tab("Guides", systemImage: "book", value: AppTab.guides) {
                NavigationStack(path: $model.guidesPath) {
                    GuidesView().routes()
                }
            }

            Tab("Scan", systemImage: "viewfinder", value: AppTab.scan, role: .search) {
                Color.clear
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(Tend.C.brand)
        .toastHost(bottom: 100)
        .fullScreenCover(item: $model.cover) { cover in
            CoverView(cover: cover)
        }
        .fullScreenCover(isPresented: premiumBindingFor(model, level: 0)) {
            PremiumView()
        }
    }
}

/// Paywall presentation: level 0 sits over the tabs, level 1 over a cover.
@MainActor
func premiumBindingFor(_ model: AppModel, level: Int) -> Binding<Bool> {
    Binding(get: { model.premiumHost == level },
            set: { if !$0, model.premiumHost == level { model.premiumHost = nil } })
}

/// Content of a full-screen cover: the scanner flow or a guide.
struct CoverView: View {
    let cover: Cover
    @Environment(AppModel.self) private var model

    var body: some View {
        Group {
            switch cover {
            case .scan(let mode): ScanFlowView(initialMode: mode)
            case .guide(let id, let context): GuideStepView(guide: SampleData.guide(id), context: context)
            }
        }
        .toastHost(bottom: 40)
        .fullScreenCover(isPresented: premiumBindingFor(model, level: 1)) {
            PremiumView()
        }
    }
}

extension View {
    /// Registers every pushable screen on a tab's NavigationStack.
    func routes() -> some View {
        navigationDestination(for: Route.self) { route in
            switch route {
            case .detail(let id, let tab): PlantDetailView(plantId: id, initialTab: tab)
            case .diagnosis: DiagnosisView()
            case .environment: EnvironmentView()
            case .lightMeter: LightMeterView()
            case .away: AwayPlanView()
            case .handoff: HandoffView()
            case .sitterPreview: SitterPreviewView()
            case .settings: SettingsView()
            case .legal(let kind): LegalView(initial: kind)
            case .widgets: WidgetsGalleryView()
            case .digest: DigestView()
            case .ask(let id): AskView(plantId: id)
            case .timelapse(let id): TimelapseView(plantId: id)
            case .states: StatesView()
            }
        }
    }
}
