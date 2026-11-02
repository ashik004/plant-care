import SwiftUI

@main
struct TendApp: App {
    @State private var model = AppModel()
    @State private var store = Store()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .environment(store)
                .tint(Tend.C.brand)
                .task {
                    store.start(model: model)
                    await Notifications.schedule(model)
                }
        }
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Group {
            if model.onboarded {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: model.onboarded)
        // Simulated live sensor drift every 2.5 s. Replace with HomeKit / Matter or a vendor SDK.
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2.5))
                model.tick += 1
            }
        }
    }
}

// Re-enable the edge swipe-back gesture on screens that hide the navigation bar.
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
