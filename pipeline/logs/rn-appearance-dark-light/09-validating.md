# 09 — validating (rn-appearance-dark-light) — device checks AC-13, AC-14

Run by the coordinator's device agent on the shared simulator, 2026-09-30, per
plan steps 8–9 and the checklist at the end of 07-validating.md. AC-1..AC-12
were graded in 07.

Scratch / evidence dir (every screenshot and number below):
`/private/tmp/claude-501/-Users-kaimao-Projects-astrology/4cb30d3d-9400-410d-b035-a12dd2fddaa3/scratchpad/appearance-device/`
(shots named `NN-*.png` below live there).

## Setup

- Simulator: iPhone 17, udid `7DB5C491-1C54-4FC3-9090-CDEC174732D4` (booted,
  `xcrun simctl list devices booted`), app `com.astrace.app.dev`. Screenshots
  1206×2622 px, taps in logical pt = px/3.
- PRE-FEATURE bundle: the user's Metro :8081 (primary checkout, branch `dev`),
  used as-is, never restarted.
- FEATURE bundle: own Metro :8093 from the worktree
  `/Users/kaimao/Projects/astrology-wt/rn-appearance-dark-light/app-native`
  (HEAD `fd4a88c`), `EXPO_PUBLIC_API_BASE=http://localhost:8003 APP_VARIANT=dev npx expo start --dev-client --port 8093`;
  own backend :8003 from the worktree root with
  `DATABASE_URL=postgresql://astrace@127.0.0.1:54320/astrace_dev WEB_DATABASE_URL=`
  and every LLM/image key blanked (so card art shows "resting" on :8003 — expected,
  unrelated to ground).
- Switching bundles: `xcrun simctl terminate <udid> com.astrace.app.dev` then
  `xcrun simctl openurl <udid> 'astrace-dev://expo-development-client/?url=http%3A%2F%2Flocalhost%3A<PORT>'`
  (a cold launch every time). The app was never reinstalled or erased.
- Freshness proof: `fresh.py <port>` fetches the manifest (`expo-platform: ios`), downloads
  the launch bundle and counts word-bounded markers. It ran before EVERY swap (6×).
  Verbatim, identical on every run:

      :8081  bundle url: http://127.0.0.1:8081/app-native/index.ts.bundle?platform=ios&dev=true&...
             groundLight (word-bounded): 0   (raw substring: 3)
             groundPlaster (word-bounded): 3   (raw substring: 3)
             groundExhibition (word-bounded): 3
             groundInk (word-bounded): 3
             groundDark (word-bounded): 0   (raw substring: 5)
      :8093  bundle url: http://127.0.0.1:8093/app-native/index.ts.bundle?platform=ios&dev=true&...
             groundLight (word-bounded): 3   (raw substring: 6)
                ctx: groundDark: 'Dark',       groundLight: 'Light'
                ctx: groundDark: '深色',       groundLight: '浅色'
             groundPlaster / groundExhibition / groundInk (word-bounded): 0
             groundDark (word-bounded): 3

  (The raw-substring hits of `groundLight` on :8081 are inside longer identifiers
  such as `backgroundLight…`; the i18n key itself, word-bounded, is absent.)
  Metro :8093 also logged `iOS Bundled 587ms app-native/index.ts (1606 modules)`.
- Measurement: `sample.py` crops the fixed empty Settings margin px box
  (60,1800)-(1146,2300) and prints the mean RGB, luminance min/max and distinct
  colours, plus `--diff` against a before shot (|mean diff| per channel and
  per-pixel mean abs channel diff). `chrome.py` finds the most extreme pixel vs the
  corner in the status-bar clock box (160,70)-(290,125) and the active rail label
  box (960,2490)-(1200,2540).

User's starting state (pre-feature :8081, shot `01-pre-settings-original.png`):
**Ink** selected, language **EN**.

## AC-13 — Settings shows Dark and Light; each renders as before — PASS

Before shots (pre-feature :8081, Settings, same spot):

| shot | ground | margin mean | lum min/max | distinct | status clock | active rail label |
|---|---|---|---|---|---|---|
| `01-pre-settings-original.png` | Ink | (8.0, 9.0, 14.0) | 9/9 | 1 | (255,255,255) on (8,9,14) → LIGHT | (211,169,79) gold on (10,13,26) |
| `03-pre-exhibition-settings.png` | Exhibition | (246.9, 246.9, 244.9) | 225/250 | 27 | (0,0,0) on (249,249,247) → DARK | (38,35,31) near-black on (255,255,255) |

After, on the feature bundle :8093:

- Row, en: `11-paper-feature-settings.png` / `55-feature-dark-settings.png` show
  APPEARANCE with exactly two segments, **Dark | Light**.
- Row, 中文: tapped 中文 (85,258) → `52-feature-light-zh.png` shows 外观 with exactly
  two segments **深色 | 浅色** (浅色 selected). Tapped EN (41,269) back
  (`53-feature-light-en-back.png`).
- Tap **Light** (96,525) from Dark → app reloaded onto the Chart on the light ground
  (`50-feature-tap-light-reload.png`), then Settings `51-feature-light-settings.png`:

      mean=(246.9, 246.9, 244.9) lum[min,max]=[225,250] distinct_colours=27
      vs 03-pre-exhibition-settings.png |mean diff|=(0.0, 0.0, 0.0) max=0.0 per-pixel mean abs channel diff=0.00
      status-bar clock extreme-ink=(0, 0, 0) on (249,249,247) => DARK glyphs
      active rail label extreme-ink=(38, 35, 31) on (255,255,255) => black chrome

  Mean vs #f9f9f7 (249,249,247): |Δ| = 2.1, 2.1, 2.1 ≤ 3. Grain: 27 distinct colours,
  luminance 225–250 (> 1 shade). Black chrome, dark status glyphs. Diff vs Exhibition
  before: 0.00.
- Tap **Dark** (45,525) → reloaded onto the Chart on the dark ground
  (`54-feature-tap-dark-reload.png`, gold rail/chrome, white status glyphs), then
  Settings `55-feature-dark-settings.png`:

      mean=(8.0, 9.0, 14.0) lum[min,max]=[9,9] distinct_colours=1
      vs 01-pre-settings-original.png |mean diff|=(0.0, 0.0, 0.0) max=0.0 per-pixel mean abs channel diff=0.00
      status-bar clock extreme-ink=(255, 255, 255) on (8,9,14) => LIGHT glyphs
      active rail label extreme-ink=(211, 169, 79) on (10,13,26) => gold chrome

  = #08090e exactly, gold chrome, light status glyphs, diff vs Ink before 0.00.

Verdict AC-13: PASS.

## AC-14 — a legacy device opens right — PASS (4/4)

For each value, in order: select on pre-feature :8081 (the app reloads; confirmed
selected in a screenshot), then terminate → freshness proof on :8093 → openurl :8093
(cold launch) → Chart screenshot → Settings screenshot + margin sample.

| legacy | pre-feature selected (shot, margin mean) | feature cold launch (shots) | feature margin mean / distinct | status / rail | Settings selection | result |
|---|---|---|---|---|---|---|
| Paper | `10-paper-pre-selected.png`, (231,225,209) | `11-paper-feature-launch.png`, `-settings.png` | (246.9,246.9,244.9) / 27, lum 225–250 | DARK / (38,35,31) | **Light** | PASS |
| Plaster | `21-plaster-pre-selected.png`, (239.96,237.02,231.15) | `22-plaster-feature-launch.png`, `-settings.png` | (246.9,246.9,244.9) / 27 | DARK / (38,35,31) | **Light** | PASS |
| Exhibition | `31-exh-pre-selected.png`, (246.9,246.9,244.9) | `32-exh-feature-launch.png`, `-settings.png` | (246.9,246.9,244.9) / 27; vs 31: diff 0.00 | DARK / (38,35,31) | **Light** | PASS |
| Ink | `41-ink-pre-selected.png`, (8,9,14) | `42-ink-feature-launch.png`, `-settings.png` | (8.0,9.0,14.0) / 1; vs 01: diff 0.00 | LIGHT / (211,169,79) | **Dark** | PASS |

Each Light result is within 3 of #f9f9f7 (Δ 2.1 per channel) and shows grain.
Ink → Dark is #08090e exactly.

Procedural note (Ink round): on the pre-feature bundle a stored `'light'`/`'dark'`
is an unknown value, so the pre-feature app falls back to Ink and already shows Ink
selected (`40-ink-prebundle-settings.png`, and likewise `20-`/`30-` show the Ink
fallback). Tapping an already-selected segment may not write. To make sure `'ink'`
was really stored, the Ink round tapped Paper first (`41a-ink-pre-via-paper.png`,
margin (231,225,209)) and then Ink (`41-ink-pre-selected.png`). The same method was
used for cleanup.

Verdict AC-14: PASS.

## Verify-skill tap coordinates (plan step 10 input)

Measured on the feature bundle's Settings (`55-feature-dark-settings.png`): the
segment container spans px ≈60–363 and the divider sits at ≈210, with the row
centre at y ≈1574 px. That gives Dark (45,525) and Light (96,525) in pt. Both
taps drove the reloads above. The old y 446 was stale (the row sits at 525 on
this build). In the worktree `.claude/skills/verify/SKILL.md`, only the line
`appearance row Dark(TODO,446) / Light(TODO,446)` changed, to
`appearance row Dark(45,525) / Light(96,525)`. Committed as `70b0f10`
`(docs): rn-appearance-dark-light — verify skill appearance taps re-derived`.

## Cleanup

- On pre-feature :8081 (freshness re-proven, `60-cleanup.txt`), tapped Paper then
  Ink to restore the user's stored **Ink** (`61-cleanup-ink-restored.png`: Ink
  selected, EN selected, margin (8,9,14), diff vs `01` 0.00). Language restored
  to EN earlier (`53-`).
- terminate + openurl :8081. The first attempt stopped on the dev-client launcher
  (`62-`), the second on the splash (`63-`/`64-`). A clean terminate + openurl with
  a 25 s wait loaded the Chart on Ink with the user's card art from :8000
  (`65-cleanup-final-8081.png`). The app is left open on :8081.
- Stopped only own processes (SIGTERM via python os.kill): uvicorn :8003 (83779,
  83701, 83672, 83668) and Metro :8093 (83700, 83675, 83673). After: no process
  matches `port 8093|port 8003`, :8093/status is empty, :8081/status
  `packager-status:running`. The user's :8081, :8000 and :5173 were not touched.

## Result

| AC | Result |
|---|---|
| 13 device: Settings shows Dark/Light, both render as before | PASS |
| 14 device: Paper/Plaster/Exhibition → Light, Ink → Dark | PASS |

Transition: validating → docs-sync
