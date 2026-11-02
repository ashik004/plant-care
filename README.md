# plant-care

**Tend** is a premium plant-care app for iPhone, built natively in SwiftUI for iOS 26. It identifies plants with AI, watches their health from room and sensor data, diagnoses pests, schedules care reminders, teaches care step by step and hands plants off to a sitter during trips.

- `ios/`: the Xcode project (app + widget extension)
- `design/`: the Claude Design handoff this was built from (prototypes, chats and spec). `design/Tend App v4.dc.html` is the source of truth for look and behaviour.

## Open and run

Requires **Xcode 26** (iOS 26 SDK).

1. Open `ios/Tend.xcodeproj`.
2. Select the **Tend** target, then *Signing & Capabilities*, and pick your team. Do the same for **TendWidgetsExtension**. The bundle IDs are `app.tend.Tend` and `app.tend.Tend.TendWidgets`; change them if they clash with yours.
3. Run the **Tend** scheme on an iPhone simulator or device.

The project uses folder-synchronized groups, so any file you add under `ios/Tend`, `ios/Shared` or `ios/TendWidgets` is picked up automatically.

> This code was written in a Linux sandbox without Xcode. Every file passes a Swift syntax check, but the project has **not been compiled yet**, so expect a few small compile fixes on the first build.

## What's in the app

| Area | Where |
|---|---|
| Onboarding (welcome, level, reminders) | `Screens/Onboarding` |
| Home: health ring, pest alert, Today tasks with tick/later/undo, rooms, suggestion, weekly digest card, sitter row | `Screens/Home/HomeView.swift` |
| Plants grid and moisture shelf, plant detail (Health / Growth / Care / Story passport), growth timelapse | `Screens/Plants` |
| AI scanner (Identify / Diagnose), ID result with confidence and botanist check, add details, diagnosis and treatment | `Screens/Scan` |
| Environment room by room, light meter | `Screens/Environment` |
| Care guides and step-by-step guide | `Screens/Guides` |
| Plant-sitter plan, hand-off, sitter preview | `Screens/Away` |
| Ask Tend chat | `Screens/Home/AskView.swift` |
| Weekly digest | `Screens/Home/DigestView.swift` |
| Settings, Terms & Privacy, widgets preview, empty/error states | `Screens/Settings` |
| Premium paywall (StoreKit 2) | `Screens/Premium`, `Services/Store.swift` |
| Widgets (thirsty, health), Lock Screen widgets, treatment Live Activity + Dynamic Island | `TendWidgets/` |

Other notes:

- **Tab bar:** the native iOS 26 `TabView` with Liquid Glass. Scan is the trailing `Tab(role: .search)` and opens the scanner full-screen. The bar minimises on scroll.
- **Theme:** light "plant" palette by default; dark follows the system (`Shared/Theme.swift`).
- **Fonts:** Newsreader, Geist and JetBrains Mono are bundled (`Shared/Fonts`, OFL licensed).
- **Motion and haptics:** these follow the README in `design/design_handoff_tend_ios`. Reduce Motion swaps movement for fades.
- **Illustrations:** drawn from the prototype's SVG paths (`Components/Illustrations.swift`). They're placeholders for brand art.

## Still needed before launch

- **Real data.** Sensor readings drift on a timer (`RootView` and `AppModel.env`). Hook up HomeKit / Matter or a sensor SDK.
- **AI backends.** Plant identification and diagnosis are mocked in `ScannerView.capture()`. Ask Tend posts to the URL in `TendAskEndpoint` in `ios/Config/Tend-Info.plist`; it expects `POST {"prompt": "…"}` and returns `{"answer": "…"}`. Keep model API keys on the server. With no endpoint set, the app shows a built-in fallback answer.
- **Purchases.** Create the products in App Store Connect: `app.tend.premium.lifetime` (non-consumable) and `app.tend.premium.monthly` (auto-renewing, 7-day free trial). For local testing, `ios/Config/Tend.storekit` is linked from the scheme; if Xcode doesn't pick it up, choose it under *Scheme → Run → Options → StoreKit Configuration*. Debug builds simulate a purchase when no products load.
- **Widgets with live data.** Add the **App Groups** capability with `group.app.tend` to both targets. Until then the widgets show sample data.
- **Photos.** Plant, guide and diagnosis photos are striped placeholders.
- **Legal.** Terms, Privacy and the company details are drafts and need review by counsel.
- **Light meter.** The lux estimate from camera exposure is rough; calibrate it against a real lux meter.
