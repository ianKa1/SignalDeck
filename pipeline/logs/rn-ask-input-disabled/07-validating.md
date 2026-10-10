# rn-ask-input-disabled — 07 validating: AC-10 simulator device check (2026-09-30, coordinator's device agent)

Code under test: worktree `/Users/kaimao/Projects/astrology-wt/rn-ask-input-disabled`
(branch `feature/rn-ask-input-disabled`, HEAD `f8f8fb4`; the feature code is `b88cebf`/`ffc40d2`).
No code was edited. Scratch dir (all screenshots and logs):
`/private/tmp/claude-501/-Users-kaimao-Projects-astrology/4cb30d3d-9400-410d-b035-a12dd2fddaa3/scratchpad/ask-device/` (written `$S` below).

The user's Metro (:8081), backend (:8000) and Vite (:5173) were not touched.

## Setup

- Device: `xcrun simctl list devices booted` → `iPhone 17 (7DB5C491-1C54-4FC3-9090-CDEC174732D4) (Booted)`, iOS 26.5; app `com.astrace.app.dev`.
- My own backend on :8001 from the worktree, local Postgres (not Neon):
  `DATABASE_URL=postgresql://astrace@127.0.0.1:54320/astrace_dev WEB_DATABASE_URL= conda run --no-capture-output -n astrology uvicorn app.main:app --app-dir server --env-file .env --port 8001 > $S/backend-8001.log 2>&1`
  → `Uvicorn running on http://127.0.0.1:8001`; `/api/health` → `{"status":"ok","db":"ok","webDb":"unconfigured","ephemeris":"ok"}`.
- My own Metro on :8091 from the worktree:
  `EXPO_PUBLIC_API_BASE=http://localhost:8001 APP_VARIANT=dev npx expo start --dev-client --port 8091 > $S/metro-8091.log 2>&1` → `packager-status:running`.
- Dev client pointed at it: `xcrun simctl terminate … com.astrace.app.dev` then
  `xcrun simctl openurl <udid> 'astrace-dev://expo-development-client/?url=http%3A%2F%2Flocalhost%3A8091'`
  → metro-8091.log: `iOS Bundled 801ms app-native/index.ts (1547 modules)`.

### Freshness proof
The bundle fetched from `http://localhost:8091/app-native/index.bundle?platform=ios&dev=true`
(14,588,097 bytes) contains `Asking is coming soon.` → `True`, `ask-coming-soon` ×1, and `localhost:8001` → `True`.
On-device, the app's requests land in the :8001 log (below), so the running client uses the worktree
bundle and my backend. The note's on-screen appearance (below) exists only in the feature code.

## Checklist (05-validating.md items 1–7)

| # | Item | Result | Evidence |
|---|------|--------|----------|
| 1 | Tap the field → no keyboard, no caret | **PASS** | `02-ask-tab.png` (before) vs `03-field-tapped-a.png` / `-b.png` (1.5 s and 2.1 s after tapping at pt 175,690): PIL diff of the field box (px 90,1975–1116,2170) = `None` both times, and diff of the lower screen (y ≥ 1800) = `None`. So there is no caret and no keyboard. **Control:** the Settings → Sign in email field (`08-control-email-tapped.png`) shows a blue caret after one tap, so this simulator draws a caret for an enabled field. This simulator has a hardware keyboard connected: the control field raised NO software keyboard. "No keyboard" by itself therefore does not prove the gate, but no caret and no accepted input do. **Typing test:** `idb ui text "hello"` after tapping the Ask field → field AXValue stays `null`, no pixel change (`12-zh-after-typing.png`, `15-en-typing-attempt.png`). |
| 2 | Field and ASK dimmed | **PASS** | Pixel samples from `02-ask-tab.png`: placeholder text brightest `(73,71,67)`. That is textFaint `#8a8577` at 0.5 opacity over ground `#08090e` = (73,71,66.5), so the field wrapper renders at 0.5. ASK label `(138,133,119)` = textFaint, not the gold `(211,169,79)` of the chips and title. ASK outline `(41,35,25)` = lineSoft (gold at 0.16 over ground ≈ (40,35,24)); the enabled `line` at 0.28 would be ≈ (65,53,32). The label still reads "ASK". AX: `ask-submit` `enabled:false`. |
| 3 | `Asking is coming soon.` under the field/ASK row | **PASS** | `02-ask-tab.png`: the note is centred below the ASK row. It renders in the `note` variant's uppercase tracking as "ASKING IS COMING SOON."; the bundle string is `Asking is coming soon.` |
| 4 | Tap ASK → nothing | **PASS** | Tapped pt 343,745 (`ask-submit`, AX `enabled:false`). `04-ask-tapped-1s.png` and `04-ask-tapped-5s.png` vs `02`: diff below the header = `None`, so no "Reading your question…" and no plate. Repeated in zh (`13-zh-ask-tapped.png` vs `10-ask-zh.png`: `None`). |
| 5 | Title, four chips, ring visible; chip swaps placeholder; ring rolls | **PASS** | `02-ask-tab.png`: title "ASK WHAT MATTERS MOST. / LET THE UNIVERSE LEAD YOU", chips LOVE/CAREER/BONDS/SELF, and the card ring are all visible. Tapping CAREER (`05-chip-career.png`) changed the placeholder to "what am I really chasing in this job" (AX label confirms). A swipe across the ring (`06-ring-swipe-mid.png`) shows the cards rotating (diff bbox (0,55,1206,1330)), and they settle afterwards (`06-ring-swipe-after.png`). |
| 6 | 中文 → `提问即将开放。` | **PASS** | Settings → 中文 (`09-settings-zh.png`), then Ask (`10-ask-zh.png`) shows `提问即将开放。` under the 提问 button, with the zh placeholder 心里在想什么？ and the zh chips. The field tap and typing were repeated in zh with no caret and no input (`11-`, `12-`), and 提问 does nothing (`13-`). The language was restored to EN (`14-settings-back-en.png`, `15-en-typing-attempt.png`). EN was the starting value. |
| 7 | Backend log: no `/api/ask` line | **PASS** | See below. |

## Backend log (:8001, whole session, grep after shutdown)

```
total lines:      149
request lines: 57          (58 at shutdown)
/api/ask lines: 0
--- distinct request paths:
   1 "GET /api/auth/whoami
   1 "GET /api/health          (my own probe)
   1 "POST /api/analysis
  52 "POST /api/analysis/deck
   1 "POST /api/auth/token/refresh
   1 "POST /api/chart
--- first/last request lines:
INFO:     127.0.0.1:62258 - "GET /api/health HTTP/1.1" 200 OK
INFO:     127.0.0.1:62294 - "GET /api/auth/whoami HTTP/1.1" 401 Unauthorized
INFO:     127.0.0.1:63669 - "POST /api/analysis/deck HTTP/1.1" 200 OK
INFO:     127.0.0.1:63698 - "POST /api/analysis/deck HTTP/1.1" 200 OK
```
Final `grep -c '/api/ask' backend-8001.log` after shutdown → `0`. The log was live all session:
the app's chart, analysis and deck polls reached :8001 the whole time.

Side note, not a finding: my fresh local DB had no cached natal cards, so the app's normal deck
poll enqueued card jobs on :8001. These hit LLM 429 rate limits (visible in the log) and were
abandoned at shutdown. This is unrelated to Ask.

## Cleanup

- Dev client restored: terminated it, then `xcrun simctl openurl <udid> 'astrace-dev://expo-development-client/?url=http%3A%2F%2Flocalhost%3A8081'`.
  `16-restored-8081.png` shows the chart screen with the user's generated card art (served by :8000).
  The :8001 request count stayed 58 before and after the restore, so the client no longer talks to my backend.
- Stopped only my own processes (PIDs from `pgrep -fl 'port 8001|port 8091'`: uvicorn 74359, conda 74241,
  expo 74271, npm 74244) with `os.kill(SIGTERM)`. Then `pgrep` → none left. :8001 and :8091 are DOWN;
  :8081 → `packager-status:running`; :8000 `/api/health` → ok.
- Language left at EN (the starting value). No simulator settings were changed. The app was not reinstalled.

## Verdict
AC-10 PASS. AC-1…AC-9 had already passed (05-validating.md).

Transition: validating → docs-sync
