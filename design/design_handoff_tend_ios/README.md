# Handoff: Tend — iOS plant-care app (SwiftUI)

> **v4 update — read this first.** `Tend App v4.dc.html` (light, default) and `Tend App v4 Dark.dc.html` (dark) replace v2 as the source of truth. Where this section conflicts with the older sections below (dark-only colors, tab bar), **this section wins**. Copy and behaviour of the original screens are unchanged.

## v4: Theme
Light "plant" theme by default; dark follows the system (`@Environment(\.colorScheme)`). Adaptive tokens are in `Theme.swift` (`Color(light:dark:)`).

| Token | Light | Dark | Use |
|---|---|---|---|
| bg | #F4F0E6 | #0F140E | Linen background |
| surface | #FFFCF5 | #172017 | Cards |
| surfacePressed | #EDE7D8 | #1C261B | Placeholders, pressed |
| text | #1F2B1C | #EAF0E6 | Moss ink, primary text |
| text3 / text4 | #566551 / #67755F | #A1ACA0 / #8C988A | Secondary / tertiary |
| brandButton | #2F5D2A | #3E8A3A | Primary buttons |
| brand | #3A6E33 | #3E8A3A | Toggles, checks, scan button |
| accent | #3E7A37 | #86C98F | Leaf-green text, live dots |
| brandDeep | #2A4F25 → #1C3618 | same | Premium + digest card gradient (cream text) |
| amber | #A9852B | #D8BE73 | Needs attention |
| clay | #B5603A | #E5A47A | Pests, thirsty, badges |
| hairline | moss @ 10% | mist @ 8% | Borders |

Shadows are soft moss (`#2E3E26` @ 15–30%), not green glows.

## v4: Tab bar (iOS 26)
Use the **native iOS 26 `TabView`** — it renders the Liquid Glass floating bar automatically. Three tabs: Home (`house`), Plants (`leaf`), Guides (`book`). The scanner is the separate trailing glass button: use `Tab(role: .search)` relabelled as Scan, or `.tabViewBottomAccessory`. Tint `brand`. The home badge shows the due-task count in clay (`.badge(n)`). Minimise on scroll: `.tabBarMinimizeBehavior(.onScrollDown)`.

## v4: Motion
- Screen entrance: fade + 14 pt rise, 0.45 s, `.spring(duration: 0.45, bounce: 0)`.
- Lists (tasks, plant grid): stagger 0.05–0.06 s per row.
- Health ring draws from 0 over 1.3 s. Growth bars grow from the bottom, staggered.
- Task check: scale pop 0.4→1.18→1 plus a ripple ring.
- Scanner: frame breathes (2.4 s loop); scan line sweeps while analysing.
- Toast springs up. Purchase success: pop + two expanding rings + a seedling that grows.
- Respect Reduce Motion: replace movement with crossfades.

## v4: Illustrations (placeholders for brand art)
Line art, 2 pt moss stroke, leaf fills #9DBE88 / #B7D3A3, terracotta pot #C9774F / #B5603A. Each one animates on a loop:
- Onboarding reminders: a watering can tips and pours drops, and the sprout perks up.
- Home "All tended": a dozing plant sways while "z"s float up.
- Scanner: a leaf outline draws itself, then its veins fade in.
- Premium success: a seedling grows inside the check circle.
- Empty shelf: a seed bobs above an empty pot.
Recreate them as Lottie or SwiftUI `Shape` + `TimelineView`, or swap in commissioned art.

## v4: New screens
1. **Growth timelapse** (Plant detail → Growth → "Play 8-week timelapse"). A 400 pt film frame, a week chip and a height chip, play/pause, and an 8-bar scrubber (W37–W44). It autoplays at 0.65 s per frame. "Save film" requires Premium. Build it from the weekly photos with `AVAssetWriter`.
2. **Plant passport**: a new 4th detail tab, "Story". A passport card with number, days together, native range, came home, source and spot, plus a milestone timeline and "Share passport" / "Ask about {name}". Data: `ORIGIN` in the HTML.
3. **Ask Tend**: the "Ask" pill on the Home header, or Story → Ask. Plant chips (Figgy, Big Monstera, Goldie, Pinstripe, Anything), a context note, suggested prompts (`PROMPTS`), chat bubbles, a typing dots indicator and a sticky input. The prompt sends the plant's room readings, schedule, health, growth and pest history (see `sendAsk` in the HTML). It runs on an LLM backend.
4. **Light meter**: Environment → "Measure a spot". A camera view with a lux reading, tier chip (Low / Medium / Bright indirect / Direct sun), a log-scale gradient bar, room chips, "Who'd be happy here" and "Save reading". Estimate lux from `AVCaptureDevice` exposure (ISO, shutter, aperture).
5. **Weekly digest**: the dark-green Home card, sent as a Sunday notification. Three stats, a 7-day care streak, what grew, saved this week, and coming up.
6. **Widgets & Live Activities** (Settings → Experience). Lock Screen: a circular health gauge and a rectangular thirsty-plants widget. Live Activity + Dynamic Island for treatment courses (round x of 5). Home Screen: a small "Thirsty today" widget and a small health widget. Build with WidgetKit + ActivityKit.
7. **Empty & error states**: no plants (empty-pot illustration, "Scan your first plant"), blurry scan ("didn't use a scan", 3 tips, Retake), and offline (dark banner, cached room readings at 60% opacity, "Try again").
8. **Scan confidence** (ID result): a "How sure Tend is" bar with a word (Very likely / Likely / Possible), a "matched on" explanation, and a "Not sure it's right?" card that sends the photo to a botanist (Premium, 24 h).

## v4: Haptics
Settings → Experience → "Haptic feedback" (on by default). The prototype shows a small chip under the Dynamic Island each time a haptic fires.
| Moment | Haptic |
|---|---|
| Switch tab, timelapse scrub, room chip | `Haptic.selection()` |
| Toggle, play timelapse, send chat | `.impact(.light)` |
| Chat reply arrives | `.impact(.soft)` |
| Scan finished | `.impact(.medium)` |
| Task done, water, purchase, save light reading, expert sent | `Haptic.success()` |
| Offline retry fails | `Haptic.warning()` |

---

## Overview
Tend is a premium plant-care app for everyday houseplant owners with 3–30 plants. It identifies plants with AI, monitors their health using sensor and room data, diagnoses pests and diseases, schedules care reminders, teaches care step by step and hands plants off to a sitter during trips. The target is a **native iOS app in SwiftUI** (iOS 17+, iPhone, dark appearance only).

## About the design files
`Tend App v2.dc.html` is a **design reference built in HTML**. It's a working prototype that shows the intended look and behavior. It is not production code. To view it, open it in a browser (Chrome or Safari) with `support.js` and `ios-frame.jsx` in the same folder. Everything in it is tappable. The left rail jumps straight to each screen.

The task is to **recreate these screens in SwiftUI** using native patterns: `NavigationStack`, `TabView` or a custom tab bar, `@Observable` models, SF Symbols where an icon isn't specified and `AVFoundation` for the camera. Don't embed the HTML.

## Fidelity
**High-fidelity.** Colors, type, spacing, radii, copy and interactions are final. Match them closely. Photos and sensor values are placeholders (see "Not final" below).

The design canvas is **402 × 874 pt** (iPhone 16 Pro / 17). 1 CSS px = 1 pt.

---

## Design tokens

### Colors
| Token | Hex | Use |
|---|---|---|
| `bg` | `#0D110D` | App background |
| `bgDeep` | `#090C09` | Behind toasts, segmented-control wells |
| `surface` | `#151B15` | Cards, inputs, segmented-control tracks |
| `surfaceHover` | `#1A221A` | Pressed rows |
| `brand` | `#228B22` | Forest green: scan button, toggles on, checked states |
| `brandButton` | `#1F7A1F` | Primary button fill (pressed state: `#228B22`) |
| `brandBright` | `#26982A` | Pressed state for the scan button and Premium CTA |
| `accent` | `#7BD88F` | "Good" state, links, active outlines, ring stroke |
| `accentSoft` | `#B6EEC2` | Text on green tints |
| `amber` | `#D8BE73` | "Needs attention" / watch state, "BEST VALUE" badge |
| `clay` | `#E5A47A` | Issue / late / pest / destructive actions |
| `text` | `#EAF0E8` | Primary text; also the fill of the selected segment |
| `text2` | `#D2DAD0` | Body on cards |
| `text3` | `#A1ACA0` | Secondary text |
| `text4` | `#889487` | Tertiary text, eyebrows |
| `text5` | `#7A8579` | Captions, mono labels |
| `muted` | `#5C685B` | Placeholder labels |
| `ring` | `#465046` | Unchecked circle outline |
| `hairline` | `#EAF0E8` @ 7% | Card borders (`rgba(232,240,230,.07)`) |
| `divider` | `#EAF0E8` @ 6–10% | Row dividers |

Common tints:
- Green tint fill: `#228B22` @ 18–20%
- Green border: `#7BD88F` @ 16–18%
- Clay tint: `#E5A47A` @ 10–14%, with border @ 28%

**Glow** is part of the brand. Green elements carry a soft shadow of `rgb(80,200,110)` @ 25–45% with a 20–36 pt radius and no offset. Status dots (6–8 pt) glow in their own color with an 8 pt radius.

**Ambient background:** a radial gradient circle, 460 pt in diameter, placed at top −150 / right −130. It fades from `#228B22` @ 22% to clear at 65%. It appears on all screens.

### Typography
Bundle these fonts and register them in Info.plist:
- **Newsreader** (Google Fonts, variable, opsz 6–72): all headlines, plant names, big numbers. Usually weight 400. Italic for Latin species names.
- **Geist** (Vercel, OFL) at 400, 500, 600 and 700: all UI and body text.
- **JetBrains Mono** at 500: data readouts, timestamps and small technical labels.

| Style | Font | Size / line height | Weight | Notes |
|---|---|---|---|---|
| Display | Newsreader | 48 / 0.98 | 400 | Onboarding 1 only, tracking −0.01em |
| H1 | Newsreader | 40–44 / 1.02 | 400 | Screen titles |
| H2 | Newsreader | 24 | 400 | Section titles ("Today", "Treatment") |
| Card title | Newsreader | 20–22 / 1.1 | 400 | Plant names, suggestions |
| Big number | Newsreader | 26–30 / 1 | 400 | Sensor values, prices, ring % |
| Eyebrow | Geist | 12 | 600 | Uppercase, tracking 0.12em, `text4` |
| Body | Geist | 15–16 / 1.5 | 400 | `text3` |
| Label | Geist | 15 | 500–600 | Row labels, buttons |
| Meta | Geist | 12–13 | 400–600 | |
| Mono | JetBrains Mono | 10–13 | 500 | Uppercase for labels, tracking 0.04–0.06em |

### Radii
- 999: pills, chips and tabs
- 30: camera viewfinder and onboarding hero
- 24–26: hero cards and photos
- 20–22: standard cards
- 18: primary buttons and sensor tiles
- 14–16: thumbnails, inputs and segmented controls
- 11–12: inner segments and small buttons
- 9: small icon tiles

Use `.continuous` corner style throughout.

### Spacing
- Screen side padding is 22 pt. Cards that sit wider use 16 pt.
- Top padding is 62–70 pt, which clears the status bar and Dynamic Island.
- Tab-bar screens have 150 pt bottom padding.
- Vertical gap between sections is 18–22 pt. Gap inside cards is 8–14 pt.
- Card padding is 14–18 pt.
- Hit targets are ≥ 44 pt. Primary buttons are 56 pt tall (the Premium CTA is 58).

### Components
- **Primary button:** 56 pt tall, full width, radius 18, fill `brandButton`, white Geist 16/600. Glow `0 0 30 rgba(80,200,110,.25)`. Scales to 0.98 when pressed.
- **Light button:** fill `text`, label `bg`. Used for "Create plan" and "Start exploring".
- **Back pill:** 40 pt tall, radius 999, fill `#1A221A` @ 90%, 1 pt border at 10%, "‹ Back" in 15/500.
- **Segmented control:** track `surface` with a 1 pt hairline border and 3 pt padding. The selected segment fills `text` with a `bg` label. Unselected labels are `text3`.
- **Chip:** 36–38 pt tall, radius 999. Selected chips fill `text` with a `bg` label. Unselected chips are clear with a 14% border.
- **Card:** `surface` fill, 1 pt hairline border, radius 20.
- **Toggle:** 50 × 30. On is `brand` with a glow; off is `text` @ 16%. White knob with a shadow. Use a custom `ToggleStyle`.
- **Check circle:** an empty 30 pt circle with a 1.5 pt `ring` stroke. When done it becomes a 32 pt `brand` fill with a white ✓ and a glow.
- **Toast:** sits 104 pt from the bottom with 16 pt side insets. Fill `text`, text `bg` at 14 pt, radius 18. Optional "Undo" in `brandButton` 14/700. Auto-dismisses after 4 s.
- **Placeholder photo:** diagonal stripes at 135°, alternating `#1A221A` and `#202920` every 6 pt, with a mono label. Replace with real images.

### Tab bar (floating, custom)
- A floating capsule, centered, 30 pt above the bottom edge.
- Fill `#1A221A` @ 82% with a blur (`.ultraThinMaterial` plus a tint), 1 pt border at 8%, shadow `0 10 30 −10 black@60%`.
- Three tabs (Home, Plants, Guides), each 46 pt tall with 17 pt horizontal padding. The active tab fills `text` with a `bg` label.
- The Home tab shows a clay badge with the count of due tasks when Home isn't the active tab.
- To its right, with a 10 pt gap, is a **58 pt circular scan button**. It's filled `brand`, glows, and shows the scanner icon: four corner brackets plus a horizontal line, white, 2.2 pt stroke, 26 pt (see `Tend App v2.dc.html`, search for `aria-label="Scan a plant"`). Recreate the icon as a SwiftUI `Shape` or SVG asset.
- The tab bar is visible only on Home, Plants and Guides.

---

## Screens

The navigation stack starts at onboarding. After onboarding, the root is the tab bar, and each tab has its own `NavigationStack`. Scan, Premium and Guide steps behave like full-screen covers. Hide the default navigation bars; every screen draws its own header.

### 1. Onboarding (3 steps)
**1a Welcome**
- Hero image: 420 pt tall, radius 30, `assets/onboard-plant.avif`. Fit is `scaledToFill`, anchored at 30% from the top. A bottom fade runs from clear at 55% to `bg` @ 85%.
- H1 Display: "A plant expert in your pocket."
- Body: "Identify any plant, catch problems early, and know exactly what each one needs. No gardening experience required."
- Pinned to the bottom: a primary "Get started" button and a text button "I already have an account". The text button skips straight to Home.

**1b Level**
- A two-segment progress indicator. Each segment is 22 × 4. Active segments are `accent`; inactive are 15%.
- H1: "How at home are you with plants?"
- Sub: "This sets how much Tend explains. You can change it later."
- Two option cards, radius 22, padding 20:
  - "Still learning": "Step-by-step guidance and plain-language tips. Reminders explain why."
  - "I know my way around": "Raw sensor data, schedules I can tune and fewer explanations."
- The selected card has a 1.5 pt `accent` border, a green 20% fill and a glow.
- "Continue" button.

**1c Reminders**
- H1: "When should we nudge you?"
- Three rows, 60 pt tall: Morning 08:00, Midday 12:30, Evening 19:00 (the default). The time is in mono.
- A live notification preview card: "Tend · {time}" and "Ottoline is dry and Goldie is ready for a feed."
- "Allow reminders" requests notification permission. "Not now" skips it.

### 2. Home / Today
- Eyebrow with the date ("Wednesday, 28 October") and H1 "Good evening, Alex." The greeting depends on the time of day.
- An avatar button (44 pt circle, Newsreader "A") opens Settings. Premium users get a green 16 pt dot on the avatar.
- **Health card:** a green gradient card at 160°, from `#228B22` @ 22% to 6%.
  - A 92 pt ring with an 8 pt stroke and round caps, starting at 12 o'clock. The track is 8%; the progress is `accent` with a glow. The center shows "75%" (Newsreader 28) over "HEALTHY".
  - A legend: Thriving (green), Needs attention (amber), Pest or disease (clay), each with a count. Tapping a row goes to Plants, Environment or Diagnosis respectively.
  - Health % = thriving plants ÷ total plants. Animate the ring over 0.8 s.
- **Pest alert card:** clay tint. Eyebrow "Detected in Monday's scan", title "Possible spider mites on Figgy", sub "87% match · caught early · see treatment". Opens Diagnosis. After treatment has started it reads "Treatment in progress".
- **Today list:** header "Today" with "{n} to do" on the right. Each task row has:
  - a 52 pt thumbnail
  - the plant name (Newsreader 21)
  - meta, e.g. "Water · 200 ml · Bedroom"
  - a status line: a dot plus "Due today" (green) or "{n} days late" (clay)
  - an underlined "Later" link
  - a check circle on the right
- Task types: water (when days since watering ≥ the interval), feed (when days since feeding ≥ the feed interval), mist and treatment. Late tasks sort first.
- When the list is empty it shows a dashed card: "All tended. Enjoy the quiet." plus "Tomorrow: …".
- **Environment strip:** horizontal scroll of 150 pt room cards showing temperature, humidity and lux in mono, with a status dot. "All rooms ›" opens Environment.
- **Tend suggests card:** e.g. "Pinstripe would be happier in the bathroom." with a reason. Buttons: "Move to bathroom" (primary small, 38 pt) and "Not now".
- **Going away? row** opens the Plant-sitter flow.

### 3. Plants
- Eyebrow "8 plants · 4 rooms" and H1 "Your collection".
- A Grid / Moisture segmented toggle.
- Room filter chips: All plus each room. The chip row scrolls horizontally.
- **Grid view:** two columns with a 12 pt gap.
  - Each card has a 150 pt photo with a health pill at the top left ("Thriving", "Needs attention", "Pest found" or "Treating").
  - Below it: the name, a status line ("Water in 3 days", "Thirsty now", "Water tomorrow") and a 3 pt moisture bar.
  - Moisture below 25% is clay; otherwise green.
- **Moisture (shelf) view:** horizontally scrolling vertical "stems", each 46 × 260. The fill height equals moisture %, with a gradient and a glow. The % sits on top and the short name below. Animate fill height over 1 s with ease `cubic-bezier(.2,.8,.2,1)`.

### 4. Plant detail
- Back pill and a "Check health" pill. The health pill opens the scanner in Diagnose mode.
- A 260 pt photo.
- Room eyebrow, name (Newsreader 44), species (italic 18) and a health pill.
- Segmented control: **Health / Growth / Care**.

**Health tab:** a 2 × 2 grid of sensor tiles: Soil moisture, Light, Humidity, Temperature. Each tile has:
- the label and a status dot
- the value in Newsreader 30
- a 4 pt range bar with the ideal band shaded (`accent` @ 22%) and a 10 pt marker dot at the current value
- a note, e.g. "Low · ideal 50–80"

Marker color is green when in range, amber when within 15% of the range span outside it, and clay otherwise. Below the tiles:
- A primary button "Water {name} now". After logging it becomes a tinted confirmation: "✓ Watered. Next drink {date}".
- "Tend's read": an insight paragraph in Newsreader 20.

**Growth tab:**
- A chart card with the delta ("+26 cm") over 8 weeks.
- Eight bars for weeks W37–W44, 120 pt tall overall. Bar height = 25% + 75% × normalized value. The current week is solid `accent` with a glow; the others are 28%.
- Size and "{n} new leaves".
- Weekly photos: a horizontal strip. The first item is a dashed "+ This week" tile (110 × 146); the rest are photos of 110 × 120 with week labels.

**Care tab:**
- A watering interval stepper card ("Water every 7 days" with − / + buttons, range 1–45).
- Rows: Fertilize, Repot, Prune, Watering technique. Each shows its next date and a "Guide ›" link that opens that guide with the plant's name as context.
- Health history list.

### 5. AI scanner
- Header: "Close", "AI scanner".
- Segmented control: Identify / Diagnose.
- **Viewfinder:** 440 pt tall, radius 30. Shows the live camera feed.
  - An inset frame (56 pt from top and bottom, 46 pt from the sides, radius 24) with a 1.5 pt border, white @ 35%.
  - While analyzing, the border turns `accent` with an inner and outer glow, and a scan line sweeps from 24% to 76% over 1.3 s with ease-in-out.
- Hint text per mode.
- Free tier: "{n} of 3 free scans left this month" and "Go unlimited ›".
- Capture button: "Identify plant" or "Check health". While working it reads "Analyzing…" (about 1.6 s in the prototype).
- With 0 free scans left, capture opens Premium.

**5a Identify result**
- "‹ Rescan" and an "IDENTIFIED" mono tag.
- H1 "It's a peace lily."
- Three candidate rows with a photo, common name, Latin name in italic and confidence (top 92%). Selecting a row updates the care summary.
- A three-column strip: Water / Light / Humidity.
- A care paragraph and an "Add to my plants" button.

**5b Add details**
- H1 "Make it yours."
- Name input (52 pt, radius 16, focus ring `accent` @ 15%).
- "Where it lives" room chips, with the best match tagged "BEST". Room fit text, e.g. "A great match."
- Watering stepper.
- "Add to collection" adds the plant, goes to Plants and shows a toast.

**5c Diagnosis**
- Mono tag "DIAGNOSIS · FIGGY".
- Two photos (1.4 : 1 split, 200 pt tall). The first has a clay circle marking the affected area.
- H1 "Spider mites" with pills: "87% match", "Moderate · caught early", "Contagious".
- "What Tend saw" card: three bullets plus the likely cause.
- Treatment checklist with 4 numbered steps. Tapping a step toggles it done (green fill, ✓, title dimmed).
- "Add treatment reminders". After tapping it shows a tinted confirmation, and a treatment task appears on Home.

### 6. Environment
- "Live · updated just now" with a green dot. H1 "Your home, room by room."
- Suggestion cards with an accept action. Accepting moves the plant and shows a toast with Undo.
- One card per room: name, plant list and a three-column metric grid (Temp, Humidity, Light) with a value and a 3 pt bar each, plus a note.
- Bar color rules:
  - Temperature below 12 °C → clay
  - Humidity below 50% → amber
  - Light below 2000 lux → amber
  - otherwise green

### 7. Care guides
- Eyebrow "Care guides" and H1 "Learn it once, do it well."
- "For your plants this week": tinted cards, e.g. "Feed Goldie" and "Repot Big Monstera".
- A two-column grid with four guides: Watering, Fertilizing, Repotting, Pruning. Each card has a photo and "{n} steps · {m} min".
- **Guide step screen:**
  - Header: Close, title, counter "1/4".
  - A progress pip bar (3 pt).
  - A 300 pt step photo.
  - "For {plant}" eyebrow (when opened from a plant), step title (Newsreader 36) and body.
  - Buttons: Back (outline, 35% opacity on the first step) and Next step / Done. "Done" closes the guide and logs a toast.
  - The full step copy is in the `GUIDES` constant in the HTML file.

### 8. Plant-sitter (away)
**8a Plan**
- H1 "Leave them in good hands."
- Range options: Weekend (4 days), A week (7), Two weeks (14). Selected options fill `text`.
- Sitter name input.
- A visit schedule card ("{n} visits", "{n} of 8 plants need care") listing each date and the plants due.
- "Fine on their own · …"
- "Create plan for Sam" (light button).
- Visits are computed per plant from its watering interval and days since last watered. The algorithm is `awayPlan()` in the HTML file.

**8b Shared:** "✓ Hand-off ready", a letter card "{Sitter}, thank you.", "Copy link to share" (which then reads "✓ Link copied"), "Preview as Sam" and "Edit plan".

**8c Sitter view:** a clay preview banner, "Hi Sam. Here's everything.", a progress bar and checklist cards per visit date. Each plant row shows a photo, name and amount, and spot. This view is shared as a web link in production; the app shows it only as a preview.

### 9. Settings
- Back to Home and H1 "Settings".
- Profile card: photo, "Alex Moreno", plan line ("Free plan · 2 of 3 scans left"), and a FREE or PREMIUM badge.
- Premium upsell card for free users:
  - Gradient at 150°, `#1E5A1E` → `#123812`, with a glow.
  - Eyebrow "Tend Premium", title "Unlimited scans, live sensors and growth timelapses.", "From $4.99 a month" and a "See plans" chip.
- Grouped lists (inset cards, rows ≥ 56 pt):
  - **Reminders:** Daily care reminder (toggle), Reminder time (cycles through 08:00, 12:30 and 19:00), Weather alerts (toggle), Pause while I'm away (toggle)
  - **Plant care:** Experience (Learning / Confident segmented), Sensor alerts (toggle), Connected sensors "3 active" ›, Rooms "5 rooms" ›
  - **Units:** Temperature °C / °F, Water ml / fl oz
  - **Account:** Subscription ›, Sitter check-ins (toggle), Export plant data "CSV" ›, Help & support ›, Terms of service ›, Privacy policy ›
- "Sign out" in clay, and the version line "TEND 2.0.1 · BUILD 418" in mono.

### 10. Premium (paywall)
- Background: a radial gradient at the top, `#228B22` @ 35%.
- A ✕ close button and "Restore".
- A 76 pt app-mark tile (gradient at 150°, `#2BA52B` → `#145214`, glow), eyebrow "Tend Premium" and H1 "Grow with an expert beside you."
- Five feature rows, each with a ✓ in a 22 pt green circle:
  1. Unlimited AI scans & diagnoses
  2. Live sensor monitoring
  3. Growth timelapse
  4. Room-by-room advice
  5. Unlimited plants & sitter hand-offs
- Plan cards (radius 22, radio on the left, price in Newsreader 26 on the right):
  - **Lifetime $59.99 one-time.** Selected by default, with a "BEST VALUE" amber badge on the top edge.
  - **Monthly $4.99/month** with a 7-day free trial.
- CTA: "Unlock Lifetime · $59.99" or "Start 7-day free trial". It's 58 pt tall, fill `brand`, with a glow.
- Fine print changes with the selected plan. Below it are Terms, Privacy and Restore purchase links.
- Success state: a 96 pt green ✓ circle, "Welcome to Premium." and "Start exploring".
- Implement with **StoreKit 2**:
  - a non-consumable for Lifetime
  - an auto-renewable subscription with an introductory offer for Monthly
  - `AppStore.sync()` for Restore
- Load prices from `Product.displayPrice`. Don't hard-code them.

### 11. Terms & Privacy
- Back pill and a Terms / Privacy segmented control.
- Mono "LAST UPDATED · 1 OCTOBER 2026", H1 and intro.
- Privacy only: a 2 × 2 "at a glance" grid. "We never" uses a clay tint; the others are green.
- A contents card with numbered sections, then the sections themselves (number in mono `accent`, heading in Newsreader 24, body 15 / 1.6 in `#B9C2B8`).
- Privacy actions: "Download my data" (moves through "Preparing export…" to "✓ Sent to …") and "Delete my account", which needs a second tap within 3 s.
- Footer contact line.
- All copy is in the `LEGAL` constant. **It's placeholder text and must be reviewed by counsel.**

---

## Interactions & behavior
- **Completing a task:** the check fills (0.45 s), then the action is logged and a toast appears ("Ottoline is watered. Next drink Sat 31 Oct.") with **Undo**, which restores the previous state. Add a light haptic (`.sensoryFeedback(.success)`).
- **Later:** defers the task to tomorrow and shows a toast with Undo.
- **Watering:** sets days since watered to 0. Moisture = 1 − daysSince ÷ interval, clamped to between 4% and 100%.
- **Plant health** comes from room readings compared with each species' ideal ranges:
  - all in range → Thriving
  - any out of range, or temperature within 3 °C of the minimum → Needs attention
  - a pest flag → Pest found (Treating once treatment has started)
- **Live data:** in the prototype, values drift every 2.5 s. In production, update from sensors (HomeKit / Matter or a vendor SDK) and animate values with `.contentTransition(.numericText())`.
- **Transitions:** use the standard push for detail screens and full-screen covers for Scan, Premium and Guide. Animate selection changes at 0.2 s and bars and rings at 0.6–0.8 s ease-out. Cards lift by 2 pt when pressed.
- **Free tier:** 3 scans a month. At 0 scans, capture opens the paywall.
- Reminders are local notifications at the chosen time, one per day, sent only when something is due.

## State (suggested `@Observable` models)
- `AppState`: onboarding step, experience level (`new` / `mid`), reminder time, premium (`nil` / `lifetime` / `monthly`), scans left, prefs (toggles plus units).
- `Plant`: id, name, species, room, spot, `waterEvery`, `daysSinceWater`, amount, ranges for humidity, light and temperature, `feedEvery`, `daysSinceFeed`, repot note, weekly heights (8), new leaves, photos, pest flag.
- `Room`: name, temperature, humidity, lux (live).
- `TaskList`: derived from plants, plus a snoozed set, a completed list and an undo snapshot.
- `Treatment`: active flag and completed steps.
- `AwayPlan`: range, sitter name, computed visits, sitter checkmarks.
- The sample data (8 plants, 5 rooms, 3 scan candidates, 4 guides, treatment steps, legal copy) is in the `<script>` block of the HTML file as `PLANTS`, `ROOMS`, `SUGG`, `GUIDES`, `TREAT` and `LEGAL`. Port it as Swift preview data.

## Assets
- `assets/onboard-plant.avif` is the onboarding hero (bird of paradise in a terracotta pot), supplied by the user. Convert it to HEIC or PNG for the asset catalog.
- The scanner icon is inline SVG in the HTML. Recreate it as a vector asset.
- All other images are striped placeholders. Real plant photography is needed for plant cards, guides and diagnosis.
- Fonts: Newsreader and JetBrains Mono (Google Fonts, OFL), Geist (github.com/vercel/geist-font, OFL).

## Not final
- Prices are placeholders. Use StoreKit products.
- Terms, Privacy and the company address ("Tend Labs Ltd.") are drafts and need legal review.
- Sensor readings, AI identification and diagnosis results are mocked. They need a real backend or model (for example, a plant-ID API and a Core ML diagnosis model).

## Files
- `Tend App v4.dc.html` / `Tend App v4 Dark.dc.html`: the current interactive prototype (light and dark). It's the source of truth for copy and behavior.
- `Tend App v2.dc.html`: the earlier dark-only version, kept for reference.
- `support.js` and `ios-frame.jsx`: needed only to open the prototype in a browser.
- `assets/onboard-plant.avif`: the onboarding image.
- `Theme.swift`: starter design tokens for SwiftUI.
