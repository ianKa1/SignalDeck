# rn-forced-signin — 11 validating (2026-09-30, device steps, coordinator-serialized)

Code under test: worktree `/Users/kaimao/Projects/astrology-wt/rn-forced-signin`,
branch `feature/rn-forced-signin` at `c828f73`. Simulator iPhone 17
`7DB5C491-1C54-4FC3-9090-CDEC174732D4` (iOS 26.5), app `com.astrace.app.dev`.
Backend: the throwaway cluster `127.0.0.1:54317/rfs_main` (not astrace_dev).
Scratch (screenshots, logs, dumps, data backup):
`/private/tmp/claude-501/-Users-kaimao-Projects-astrology/4cb30d3d-9400-410d-b035-a12dd2fddaa3/scratchpad/rfs-device/` (below: `<scratch>`).

## Before: protect the user's app data

- Previously installed `com.astrace.app.dev`: version 0.1.0 (1), binary built
  Aug 31 2026 11:43, URL schemes `astrace-dev`, `com.astrace.app.dev` (no
  Google scheme), sha256(AstraceDev) prefix `b748d167d1a5fe7d`.
- `xcrun simctl terminate` → 0. Data container
  `.../Data/Application/1E680857-9491-4059-A9F0-083E0657E221` copied with
  `shutil.copytree(src, dst, symlinks=True)` to `<scratch>/data-backup/`.
  Counts: entries 167 = 167, files 134 = 134 (Documents/mmkv, Documents/SQLite,
  Library/…, SystemData, tmp).

## Step 16 — dev-client rebuild: PASS

Backend (worktree root, background, no `--env-file`):

    env TOKENROUTER_API_KEY= ANTHROPIC_API_KEY= OPENAI_API_KEY= LLM_API_KEY= GEMINI_API_KEY= GOOGLE_API_KEY= \
      DATABASE_URL=postgresql://astrace@127.0.0.1:54317/rfs_main WEB_DATABASE_URL= \
      conda run --no-capture-output -n astrology uvicorn app.main:app --app-dir server --port 8017 --host 0.0.0.0

Build (worktree `app-native/`, background, log `<scratch>/build.log`):

    APP_VARIANT=dev GOOGLE_IOS_CLIENT_ID=123-abc.apps.googleusercontent.com \
      EXPO_PUBLIC_API_BASE=http://127.0.0.1:8017 \
      npx expo run:ios --port 8097 --device 7DB5C491-1C54-4FC3-9090-CDEC174732D4

Verbatim milestones from the build log:

```
✔ Created native directory
✔ Finished prebuild
✔ Installed CocoaPods
› Build Succeeded
› 0 error(s), and 2 warning(s)
Waiting on http://localhost:8097
› Installing /Users/kaimao/Library/Developer/Xcode/DerivedData/AstraceDev-fsxulgrnukfjakcmmuladjkwvqkh/Build/Products/Debug-iphonesimulator/AstraceDev.app
› Installing on iPhone 17
› Opening on iPhone 17 (com.astrace.app.dev)
› Opening exp+astrace://expo-development-client/?url=http%3A%2F%2F192.168.1.13%3A8097 on iPhone 17
iOS Bundled 842ms app-native/index.ts (1525 modules)
```

The build installed, launched and bundled from the :8097 Metro (first launch
screenshot `<scratch>/s16-first-launch.png`: the gate). The dev menu later
showed `Connected to: http://localhost:8097`.

- **Fingerprint / runtime version: `fa8f265489b5ad6ff09b1349c1803a815e2c2176`**
  (`npx expo-updates fingerprint:generate --platform ios` with the build env,
  and the same string shown as "Runtime version" in the dev-launcher menu on
  device).
- Built `Info.plist` `CFBundleURLTypes`: `[astrace-dev, com.astrace.app.dev]`,
  **`[com.googleusercontent.apps.123-abc]`**, `[exp+astrace]`.
- `usesAppleSignIn`: `ios/AstraceDev/AstraceDev.entitlements` and the binary's
  `__TEXT,__entitlements` section both carry
  `com.apple.developer.applesignin = [Default]` (with
  `application-identifier 3Y5G5Z7J8M.com.astrace.app.dev`).
- `EXConstants.bundle/app.config`: `"appleSignIn":true`,
  `"googleIosClientId":"123-abc.apps.googleusercontent.com"`.
- New binary sha256 prefix `620df50c9634d849`.
- `git status --short` in the worktree after prebuild/build: empty (ios/ is
  gitignored by `app-native/.gitignore:5`); no tracked files written.

Note: `expo run:ios` replaced the install with a NEW data container
(`E96F5B76-…`); the old container `1E680857-…` no longer existed afterwards.
The backup above is the only copy of the user's prior data container.

## Step 17 A1 — fresh install shows only the gate: PASS

```
xcrun simctl terminate … → 0
xcrun simctl uninstall 7DB5C491-… com.astrace.app.dev → 0
xcrun simctl get_app_container … data → "No such file or directory" (exit 2: app gone)
xcrun simctl install 7DB5C491-… <DerivedData>/AstraceDev.app → 0
  new data container …/B423EB0C-9BC8-481F-BEB9-642B7276663E
xcrun simctl openurl 7DB5C491-… 'astrace-dev://expo-development-client/?url=http%3A%2F%2Flocalhost%3A8097' → 0
```

Observed (screenshot burst `<scratch>/a1-t1..t6.png`, `a1-settled.png`):
dev-client "Downloading 100%" over the splash star (`a1-t2.png`), then the
opening on the dark ground ("READ THE UNIVERSE" behind the first-run dev-menu
sheet, `a1-t3.png`), resolving to the wordmark (`a1-settled.png`). The
first-run dev-launcher onboarding sheet (expected on any fresh dev-client
install) was dismissed (Continue, then Close).

Settled screen `<scratch>/a1-gate.png`: dark ground, "Astrace" wordmark at
~38 % height, WHITE system "Sign in with Apple" button, then WHITE "Sign in with
Google" (G logo) — U3's white-on-dark holds. Nothing else but the dev-client's
own floating Tools button.

idb dump (`conda run -n astrology idb ui describe-all --udid …`,
`<scratch>/a1-describe-all.json`), verbatim:

```
Application | Astrace Dev | None | {'y': 0, 'x': 0, 'width': 402, 'height': 874}
Heading | Astrace | None | {'y': 332, 'x': 166, 'width': 71, 'height': 24}
Button | Sign in with Apple | None | {'y': 674, 'x': 41, 'width': 320, 'height': 50}
Button | Sign in with Google | sign-in-google | {'y': 736, 'x': 41, 'width': 320, 'height': 50}
Image | gearshape.fill | gearshape.fill | {'y': 82, 'x': 348, 'width': 26, 'height': 26}
StaticText | Tools | None | {'y': 128, 'x': 347, 'width': 29, 'height': 13}
```

Substring check over the whole dump: `tab-` False, `chart` False, `settings`
False, `rail` False, `reading` False, `transit` False, `gallery` False. (The
gear/Tools element is expo-dev-launcher's floating button, not the app.)

Backend log (`<scratch>/backend.log`), complete request lines:

```
INFO:     127.0.0.1:58691 - "GET /api/auth/whoami HTTP/1.1" 401 Unauthorized
INFO:     127.0.0.1:58691 - "POST /api/auth/token/refresh HTTP/1.1" 401 Unauthorized
INFO:     127.0.0.1:58786 - "GET /api/health HTTP/1.1" 200 OK              (my probe)
INFO:     127.0.0.1:58788 - "GET /api/chart HTTP/1.1" 405 Method Not Allowed (my probe)
INFO:     127.0.0.1:58789 - "POST /api/chart HTTP/1.1" 401 Unauthorized    (my probe)
```

The whoami/refresh pair came from the step-16 launch (the line count was 6
before the A1 launch, i.e. the pair was already there): the simulator
Keychain survived the old app (Keychain items outlive a data container), so
`restoreAccount` found a refresh token from the user's earlier session, the
:8017 server rejected it (401 → refresh 401), and the session ended
(`endSession` cleared the token store). The fresh-install (A1) launch made
**zero** requests — the D13 "no refresh token → signed-out, nothing sent"
path. No gated request succeeded at any point.

Unauthenticated probes against :8017:

```
GET  /api/health → 200 {"status":"ok","db":"ok","webDb":"unconfigured","ephemeris":"ok"}
GET  /api/chart  → 405 {"detail":"Method Not Allowed"}   (route is POST-only)
POST /api/chart (valid body, no bearer) → 401 {"detail":"not signed in"}
```

Optional Google tap (once): the system sheet "“AstraceDev” Wants to Use
“accounts.google.com” to Sign In" appeared; tapped Cancel → back on the gate
(Heading Astrace, both buttons), app process still running, no crash
(`<scratch>/a1-google-cancel.png`). No live sign-in attempted.

## Cleanup and restore

- `xcrun simctl terminate` → 0.
- Restore: new data container
  `.../Data/Application/B423EB0C-9BC8-481F-BEB9-642B7276663E` emptied and the
  backup copied in (shutil copytree/copy2, symlinks preserved). Entries
  167 = 167, files 134 = 134, `diff -rq <container> <scratch>/data-backup` →
  no differences ("IDENTICAL").
- Per the coordinator's environment update, reopened on the user's Metro
  **:8082** (`packager-status:running`):
  `xcrun simctl openurl … 'astrace-dev://expo-development-client/?url=http%3A%2F%2Flocalhost%3A8082'` → 0.
  The new binary runs the dev-branch JS: dark (Ink) appearance, the full rail
  (`tab-chart`, `tab-ask`, `tab-transit`, `tab-gallery`, `tab-settings`), the
  chart screen with the user's birth data present ("Your birth data is safe")
  — screenshot `<scratch>/restore-8082.png`.
- The chart shows "The sky is out of reach" because the :8082 bundle inlines
  `EXPO_PUBLIC_API_BASE = http://192.168.1.13:8000` while the user's :8000
  uvicorn (pid 39950) binds loopback only (`192.168.1.13:8000` → connection
  refused; `localhost:8000/api/health` → 200). That is the user's server/Metro
  configuration, not this check; untouched.
- Not restorable: the Keychain session (refresh/access tokens) the user had
  before was ended by the step-16 launch against :8017 (see above). The
  dev-branch JS treats that as anonymous mode; local data is intact. A
  re-sign-in is needed if the user was signed in on the dev client.
- Stopped only my own processes: the `expo run:ios` Metro on :8097 and the
  :8017 backend (both now connection-refused). User's :8082 Metro and :8000
  backend untouched. Throwaway Postgres :54317 left running (pg_isready:
  accepting connections).

## Verdicts

- Step 16: **PASS** — built, installed, launched, connected to :8097;
  fingerprint `fa8f265489b5ad6ff09b1349c1803a815e2c2176`; Google scheme
  `com.googleusercontent.apps.123-abc`; Apple Sign In entitlement present.
- A1: **PASS** — fresh install → opening → only the gate (wordmark + Apple +
  Google); no rail, chart or settings in the accessibility tree; no gated
  request succeeded; `POST /api/chart` without a bearer → 401.

Transition: validating → docs-sync
