# 08 · accepting — rn-onboarding-after-signin (fresh-context acceptance checker, 2026-09-30)

Code under test: worktree `/Users/kaimao/Projects/astrology-wt/rn-onboarding-after-signin`,
branch `feature/rn-onboarding-after-signin` @ `6eb517a`. No source file modified;
`git status --short` empty at the end.

## Suites (run by this checker)

- `npm test`: app-native jest **97 suites / 1186 tests passed**; web-divination vitest **48 files / 447 tests passed**; exit 0.
- `npm run typecheck`: exit 0.
- `DATABASE_URL= WEB_DATABASE_URL= npm run server:test`: **1504 passed, 124 skipped**, exit 0.

## Per criterion

| AC | Verdict | Evidence |
|---|---|---|
| AC1 | PASS | `App.test.tsx` "AC1 — no stored account…": at TOTAL−1 no `sign-in-buttons`; at TOTAL `opening-line-1/2` + `sign-in-google`, no `en.brand.wordmark`, no `tab-chart`. |
| AC2 | PASS | "AC2 — the opening is the same instance…": `opening-prototype` and `opening-line-2` `toBe` the same instances after the buttons appear. |
| AC3 | PASS | "AC3 — Reduce Motion…": both lines opacity 1, `sign-in-buttons` present, `withTiming` not called, with no timer advance. |
| AC4 | PASS | "AC4 — checking after the words…" (App level: lines, no buttons/note; after a 503 the unavailable note and `sign-in-retry`, lines still there). Offline note + retry: `sign-in-gate.test.tsx` "offline at boot". Busy, failed, no-email, cancelled, Google-not-set-up and Apple absent/disabled gate tests still pass. The two edited gate tests (U1 signed-out, checking) were changed by the spec (no wordmark) and assert more than before. "Beneath": `opening.test.tsx` "children render in the lower region". |
| AC5 | PASS | "AC5 — a stored account whose pull holds birth data…": no `sign-in-buttons` at any 250 ms tick through TOTAL+200, then `tab-chart`. Note: the test does not separately check that the lines show first. That ordering holds because `App.tsx` only computes `signedIn` once `wordsDone` is true, so the shell can only appear after the words finish. |
| AC6 | PASS | 06-validating idb dump (`ac6-describe.json`): line 2 y=398,h=24 (bottom 422); Apple y=592, Google y=654. `ac6-settled.png` shows the lines and both buttons, with no "Astrace" heading. Burst `ac6-b1..b8`. |
| AC7 | PASS | "AC7 — signing in with Google into an empty account…": `setup-appearance`, no `tab-chart`. |
| AC8 | PASS | "AC8 — while /api/profiles is unresolved…": lines only; no `setup-flow`, buttons or `tab-chart`. |
| AC9 | PASS | "AC9 — /api/profiles 500": no `setup-flow`, `tab-chart` present. |
| AC10 | PASS | "AC10 — the pull holds birth data…": `getBirthData()` matches the account's date and location, no setup, `tab-chart`. |
| AC11 | PASS | `setup/setup.test.tsx` AC11: exactly 2 buttons (Dark/Light) with dark selected; tapping dark goes to `setup-language` with reloads 0 and ground still dark. |
| AC12 | PASS | AC12: ground store and KV both `light`, progress `language`, reloads === 1 (even after repeated taps). |
| AC13 | PASS | `App.light-ground.test.tsx`: progress `language`, light ground, stored pair, empty pull → `setup-language`, no `withTiming`, `setup-flow` background === `GROUND_TOKENS.light.ground`. |
| AC14 | PASS | AC14: English/中文 with en selected; tapping zh gives `getLanguage()==='zh'`, KV `zh`, progress `birth`, and the text "你在何时何地出生？". |
| AC15 | PASS | AC15: `sheet-date`, `sheet-time`, `sheet-time-unknown`, `city-cascade` present; no `sheet-cancel` or `birth-sheet-dismiss`; empty submit shows `sheet-error-date-required` and `-location-required` and stays on `setup-birth`. |
| AC16 | PASS | `App.test.tsx` AC16, end to end: one `PUT /api/profiles/traveler` whose body has date 1990-06-15 and time 08:30; key removed; `tab-chart`. Minor: the PUT body's location is not asserted (Beijing is asserted on the device store in `setup.test.tsx` AC16). |
| AC17 | PASS | "AC17 — booting with progress `birth`…": `setup-birth` directly, no Appearance, no `withTiming`. |
| AC18 | PASS | "AC18 — a session end mid-setup…" (real MMKV adapter): after `logout()` the progress key is null and lang `en` / ground `dark` are kept. |
| AC19 | PASS | settings.test "prefills the sheet from the stored moment"; screen-shell.test "saves a complete moment" (sheet closes after save); birth-sheet, city-picker and settings suites green; settings tests cover the Dark/Light row, `settings-lang-zh` and the birth row. Gap: no test presses `birth-sheet-dismiss` (same as on dev). I checked by reading the code: `BirthSheet.tsx:57` still wires the scrim to `onClose`. Device log also saw Settings with 深色/浅色, EN/中文 and the birth row. |
| AC20 | PASS | i18n parity test green (`setup.english`/`setup.chinese` added to the "own script" identical list, with a reason). Grep of `setup/*` finds no hex/rgba, raw `<Text>` or `fetch(`/`apiUrl(`. `setup/` was added to the raw-JSX-literal and paid/card-channel walks in `native-guards.test.ts`. The text-variant-guard residue totals are unchanged and still pass. |
| AC21 | PASS | All three commands green (counts above). The amended pins are equal or stronger: surface-paint E1 and field point at `BirthForm.tsx` (the code moved there); text-variant-rulings now bans the wordmark and `title`; native-guards scope widened. Logged in 04-implementing.md ("Guard pin repointed (equal strength)"). |
| AC22 | PASS | 06-validating: `ac22-1-appearance.png`; after the Light reload `ac22-2-r3.png` shows the Language step on the light ground, with no opening words in r3–r6 and pixel (249,249,247) = `#f9f9f7`; `ac22-3-birth.png` shows the Chinese Birth step; `ac22-5-chart.png` shows the chart and the rail. backend.log: `POST /api/chart 200`, `PUT /api/profiles/traveler 204`. The DB row holds 1990-01-01. Caveats: the PUT returned 204, not the literal "200" (204 is this route's success code), and the date and time entered were the dials' defaults (1990-01-01, 12:00), which the coordinator committed by opening and closing each dial. |
| AC23 | PASS | backend.log: `POST /api/auth/logout 204`, then `auth/google 200`, `GET /api/profiles 200`, `POST /api/chart 200`. `ac23-1-threshold.png` shows the light ground, the lines and the buttons, with the Google label in Chinese. `ac23-2-chart.png` shows the chart, and 6 polls found no `setup-*`. Caveat: the evidence is one settled frame, so "lines then buttons" is shown by the end state only (the sequence itself is covered by jest AC1). The opening lines are English by design, and the Apple label follows the system locale. |
| AC24 | PASS | `ac24-b11.png` (first app frame) shows both lines and both buttons. 06-validating reports b12–b16 with identical luminance, which covers the 4-frame burst with no fade. |

## Overall verdict: **ACCEPT**: 24/24 PASS

Non-blocking notes: (1) the scrim dismiss has no test (an existing gap, wiring checked by reading the code); (2) the AC16 jest tests don't check the location in the PUT body; (3) AC22's PUT status was 204, which is success for this route.
