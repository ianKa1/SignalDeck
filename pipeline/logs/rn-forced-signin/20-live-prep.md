# rn-forced-signin — 20 live-prep (2026-09-30)

PREPARES L1–L4 and L6; performs none of them. No `.env` line was read or
printed: env checks printed booleans or counts only, and the Google ids were
compared inside python one-liners that printed True/False. No real Google or
Apple sign-in was completed. The one Google tap was cancelled at the system
"wants to use accounts.google.com" prompt.

Worktree `/Users/kaimao/Projects/astrology-wt/rn-forced-signin` at `f17ba8b`, tree clean
(`app-native/ios` is gitignored and was regenerated for prod).
Scratch: `/private/tmp/claude-501/-Users-kaimao-Projects-astrology/4cb30d3d-9400-410d-b035-a12dd2fddaa3/scratchpad/live-prep/` (`<S>` below).

## 1. Live backend (:8017, detached)

- `createdb -h 127.0.0.1 -p 54317 -U astrace rfs_live`: a fresh database. Migrations ran at startup: 15 rows, max `015_apple_identities`.
- Started from the worktree root with python `subprocess.Popen(..., start_new_session=True)` so it is detached from any session:
  `env DATABASE_URL=postgresql://astrace@127.0.0.1:54317/rfs_live WEB_DATABASE_URL= TOKENROUTER_API_KEY= ANTHROPIC_API_KEY= OPENAI_API_KEY= LLM_API_KEY= GEMINI_API_KEY= GOOGLE_API_KEY= ~/miniconda3/envs/astrology/bin/python -m uvicorn app.main:app --app-dir server --env-file .env --port 8017 --host 0.0.0.0`
  The log is `<S>/backend-8017.log`.
- **PID 40738** (also in `<S>/backend-8017.pid`). To stop it: `python3 -c "import os,signal;os.kill(40738,signal.SIGTERM)"`. To drop the database afterwards: `~/miniconda3/envs/astrology/bin/dropdb -h 127.0.0.1 -p 54317 -U astrace rfs_live`.
- Root `.env` (booleans only): GOOGLE_IOS_CLIENT_ID set, with 2 entries. APPLE_TEAM_ID, APPLE_KEY_ID, APPLE_PRIVATE_KEY and APPLE_BUNDLE_IDS are set. APPLE_BUNDLE_IDS contains both `com.astrace.app` and `com.astrace.app.dev`. **I cannot tell whether the Apple key is the NEW one.** The spec says the old key is being revoked, so the user must confirm it before L4/L6(c); otherwise expect 502.
- Probes:
  - `GET /api/health` → 200, `db: ok`, `webDb: unconfigured`.
  - `POST /api/chart` with no bearer → 401.
  - `POST /api/auth/google {idToken:"junk"}` → **401**, so it is configured. The unconfigured check runs before verification, and that check would give 503.
  - `POST /api/auth/apple {identityToken:"junk", nonce:<32 chars>}` → **401**, so it is configured. A body without a nonce gives 422, which is just the schema.

## 2. PROD variant simulator build (Release, no Metro)

- I backed up the previous `com.astrace.app` data container (33 files) to `<S>/prod-app-data-backup/`. The install replaced the container (`4EFA3BEF…` → `647919AD…`). The dev client's container `B423EB0C…` was not touched.
- `APP_VARIANT=prod npx expo prebuild --clean --platform ios` → exit 0 (`<S>/prebuild-prod.log`).
- `APP_VARIANT=prod EXPO_PUBLIC_API_BASE=http://127.0.0.1:8017 npx expo run:ios --configuration Release --device 7DB5C491-1C54-4FC3-9090-CDEC174732D4 --no-bundler` → Build Succeeded, 0 errors, installed and opened, exit 0 (`<S>/build-prod.log`). The CLI printed "Waiting on http://localhost:8081" but started nothing there.
- Evidence from the installed `Astrace.app` (booleans):
  - `CFBundleIdentifier == com.astrace.app`: True. Display name is "Astrace".
  - Exactly 1 `com.googleusercontent.apps.` scheme: True. It equals the reversed slot 1: **True**. It equals the reversed slot 2: False.
  - `EXConstants.bundle/app.config` extra: `googleIosClientId` equals slot 1: True, slot 2: False. `appleSignIn: true`, `variant: prod`.
  - Sign in with Apple entitlement: `Astrace.app-Simulated.xcent` has `com.apple.developer.applesignin = ["Default"]`. The binary carries the string 4×. Prebuild `*.entitlements` gives the same.
  - `main.jsbundle` contains `http://127.0.0.1:8017`: True. It contains `onrender.com`: False.
  - ATS is `{NSAllowsArbitraryLoads: false}` only. `NSAllowsLocalNetworking` is absent. `NSLocalNetworkUsageDescription` is absent in the built app: expo-dev-launcher's "Strip Local Network Keys for Release" phase removed the string the dev-client plugin adds at prebuild. Info.plist was not edited, as the spec requires.
- Launch: after the wordmark, the gate shows only "Sign in with Apple" and "Sign in with Google" (`<S>/prod-gate-1.png`). Boot sent no request. That is expected: there is no stored pair, so `restoreAccount` makes no request.
- Probe: one tap on "Sign in with Google" showed the native `"Astrace" Wants to Use "accounts.google.com" to Sign In` prompt and "SIGNING IN…" (`<S>/prod-google-tap.png`). So the Google SDK starts with the slot-1 client id. I tapped **Cancel** and the app returned to the gate cleanly (`<S>/prod-after-cancel.png`). No request reached :8017, which is correct: the app POSTs only after the provider returns a token.

### Transport decision

- **Loopback `http://127.0.0.1:8017` is built in, but it is NOT yet proven.** No request can leave the gate without a completed provider sign-in, so the user's first L6 Google sign-in is itself the probe the spec calls for.
- If the backend log shows `POST /api/auth/google`, the loopback works on the simulator (cleartext to an IP literal was not blocked by ATS).
- If the app shows "Can't reach Astrace." and the log has no line, ATS refused the connection. The decided fallback is then an HTTPS tunnel. **`cloudflared` is NOT installed** (`which cloudflared` → not found), and I did not install it. The user would need to `brew install cloudflared`. Then:
  `cloudflared tunnel --url http://127.0.0.1:8017` (note the `https://<host>.trycloudflare.com` it prints) and from app-native/:
  `APP_VARIANT=prod EXPO_PUBLIC_API_BASE=https://<host> npx expo run:ios --configuration Release --device 7DB5C491-1C54-4FC3-9090-CDEC174732D4 --no-bundler`.
  No new prebuild is needed: the base is JS-only.
- Apple on the simulator needs the simulator to be signed into an Apple ID (Settings › Apple Account). If Apple cannot complete there, the spec's fallback is a device. A device needs the tunnel, or the LAN base `http://192.168.1.13:8017` for the dev variant only. Re-derive the IP with `ipconfig getifaddr en0`.

## 3. DEV variant (commands only — NOT run)

The current dev client's Google scheme matches **neither** slot of the current `.env` value (False/False; built 2026-09-30 19:56 from an older id value). **L1 cannot pass on it, so the dev client must be rebuilt.** A Release or Debug dev build replaces `com.astrace.app.dev` and its data container, so back up the container first.

```bash
U=7DB5C491-1C54-4FC3-9090-CDEC174732D4; S=<scratch>
xcrun simctl terminate $U com.astrace.app.dev
D=$(xcrun simctl get_app_container $U com.astrace.app.dev data)
python3 -c "import shutil; shutil.copytree('$D','$S/dev-data-backup',symlinks=True)"
cd /Users/kaimao/Projects/astrology-wt/rn-forced-signin/app-native
APP_VARIANT=dev npx expo prebuild --clean --platform ios
# Debug dev client with its own Metro on 8098 (never 8081/8082):
APP_VARIANT=dev EXPO_PUBLIC_API_BASE=http://127.0.0.1:8017 npx expo run:ios --device $U --port 8098
#   (device instead of simulator: EXPO_PUBLIC_API_BASE=http://<mac-ip>:8017)
# Afterwards, restoring the user's state (as in 11-validating): copy $S/dev-data-backup into the NEW
# data container (diff -rq to confirm), rebuild the dev client from the PRIMARY checkout if the
# branch's native code must not stay, and reopen on :8082:
xcrun simctl openurl $U 'astrace-dev://expo-development-client/?url=http%3A%2F%2Flocalhost%3A8082'
```

## 4. State left

- `com.astrace.app` (prod, Release, base `http://127.0.0.1:8017`) is installed and showing the gate.
- The backend on :8017 (PID 40738) and Postgres on :54317 are running.
- The dev client, :8000, :5173 and :8082 were not touched.

## USER steps (L6 first: the prod app is already installed)

Run each step on the simulator's **Astrace** app (not Astrace Dev).

1. **L6(a) Google, prod.** Tap *Sign in with Google* → Continue → choose the Google account. Expect a brief "Signing in…", then the first-run entry (a fresh account has no birth data). Enter birth data so L3 can check restore.
   If instead you see "Can't reach Astrace.", stop: loopback is refused, and the cloudflared fallback above applies.
2. **L3 (prod).** Swipe the app away and relaunch: you go straight into the app, with only the wordmark before it. Then Settings → *Sign out* → the gate. Relaunch → still the gate. Sign in with Google again → your birth data is back.
3. **L6(b) Apple, prod.** Settings → Sign out. Tap *Sign in with Apple* → complete it (sharing or hiding the email). Expect the first-run entry, because this is a new account.
4. **L6(c) / L4 Delete, Apple-linked.** On that Apple account: Settings → *Delete account…* → *Delete account* → Apple's re-authorization sheet → confirm. Expect the gate.
   Then in the simulator's (or device's) Settings › Apple Account › Sign in with Apple, Astrace is no longer listed. The next Apple sign-in shows the first-time share-email sheet.
5. **L1/L2/L6(d) dev variant.** This needs the dev rebuild above (the coordinator runs it). On *Astrace Dev*: sign in with Google, then sign out and sign in with Apple. L2 says "on a device"; a device uses the LAN base.

## Coordinator verification (counts and hashes only)

`P="~/miniconda3/envs/astrology/bin/psql -h 127.0.0.1 -p 54317 -U astrace -d rfs_live -Atc"`, log `L=<S>/backend-8017.log`.

- Transport and route outcomes: `grep -E '"(POST|GET|DELETE) /api/(auth|chart|profiles)' $L | grep -oE '"[A-Z]+ [^ ]+ HTTP/1.1" [0-9]{3}'`. The access log holds paths and statuses only.
- **Step 1 (L6a):** `POST /api/auth/google … 200`, then `GET /api/auth/whoami 200`.
  `$P "select count(*) from users"` → 1, and `$P "select count(*) from sessions; select count(*) from refresh_tokens"` → ≥1 each.
  To prove `aud` = slot 1: `google.ios_client_ids()` accepts both entries, so the token's audience comes from the app's configured id. The built-app evidence (slot 1 only, True) is the proof.
- **Step 2 (L3):** relaunch → `GET /api/auth/whoami 200` with no new `POST /api/auth/google`. Sign out → `POST /api/auth/logout 204`, and the sessions count drops. Second sign-in → the users count is unchanged (1). `$P "select count(*) from profiles"` → ≥1 before and after.
- **Step 3 (L6b):** `POST /api/auth/apple … 200`.
  - `$P "select count(*) from apple_identities"` → 1.
  - `$P "select count(*) from apple_identities where subject_hash ~ '^[0-9a-f]{64}$'"` → 1.
  - `$P "select count(*) from users"` → 2.
  - Check that no raw `sub` was stored: `~/miniconda3/envs/astrology/bin/pg_dump -h 127.0.0.1 -p 54317 -U astrace rfs_live | grep -cE '[0-9]{6}\.[0-9a-f]{32}\.[0-9]{4}'` → 0.
- **Step 4 (L6c/L4):** `DELETE /api/auth/account 204`. A 502 means the Apple key or grouping is wrong.
  `$P "select count(*) from apple_identities"` → 0, and `$P "select count(*) from users"` → 1 (the Google account remains). The sessions and refresh_tokens rows for that user are gone (cascade).
- **Step 5 (L1/L2):** the same checks for the dev app. For a separate audit, compare the user count before and after.

## Dev variant prepared

The same rules applied as above: no `.env` line was read or printed (the Google id comparisons ran inside python and printed True/False only), no source was edited, and no sign-in was completed. `com.astrace.app` (prod), backend :8017 (PID 40738), :8000, :5173 and :8082 were not touched. Working tree is still `f17ba8b` and clean. `<S>` is the same scratch directory as above.

### 1. Backup of the user's dev-client data
- `xcrun simctl terminate … com.astrace.app.dev` → 0. Container `B423EB0C-9BC8-481F-BEB9-642B7276663E` was copied in full with `shutil.copytree(..., symlinks=True)` to `<S>/dev-data-backup/`. Entries 171 = 171, files 139 = 139, and `diff -rq` shows no differences.

### 2. Rebuild (Debug dev client)
- From `app-native/`: `APP_VARIANT=dev npx expo prebuild --clean --platform ios` → exit 0, CocoaPods installed (`<S>/prebuild-dev.log`).
- `APP_VARIANT=dev npx expo run:ios --device 7DB5C491-1C54-4FC3-9090-CDEC174732D4 --no-bundler` → Build Succeeded, installed, exit 0 (`<S>/build-dev.log`). The `--port 8098` flag was dropped because the expo CLI refuses it: "--port and --no-bundler are mutually exclusive". A Debug dev client takes its Metro from the deep link, so the port is not baked in. The CLI opened `…?url=http://192.168.1.13:8081`, but nothing serves 8081 and nothing was started there.
- Installed `AstraceDev.app` (bundle container `2DCF9062-…`, new data container `13F88B3C-246E-4535-AFB7-A2830FC28C44`). Booleans:
  - `CFBundleIdentifier == com.astrace.app.dev`: True. Display name is "Astrace Dev".
  - The root `.env` has 2 GOOGLE_IOS_CLIENT_ID entries, and the worktree `.env` value equals the primary `.env` value: True.
  - Exactly 1 `com.googleusercontent.apps.` scheme: True. It equals the reversed slot 2: **True**. It equals the reversed slot 1: False. The other schemes are `astrace-dev`, `com.astrace.app.dev` and `exp+astrace`.
  - `EXConstants.bundle/app.config` extra: `googleIosClientId` equals slot 2: True, slot 1: False. `appleSignIn: true`, `variant: dev`.
  - Sign in with Apple entitlement: `AstraceDev.app-Simulated.xcent` has `com.apple.developer.applesignin = ["Default"]` (application-identifier `3Y5G5Z7J8M.com.astrace.app.dev`). `ios/AstraceDev/AstraceDev.entitlements` gives the same.
  - ATS is `{NSAllowsArbitraryLoads: false, NSAllowsLocalNetworking: true}` (Debug keeps the local-network key).
- Fingerprint (`APP_VARIANT=dev node_modules/.bin/fingerprint fingerprint:generate --platform ios`): **`c1b71a88f0d0f49215ae5c14d6def2c9c2016477`** (81 sources). `<S>/fingerprint-dev.json` keeps only the hash and the source count.

### 3. Restore
- After terminating the app, the new container `13F88B3C-…` was emptied and the backup copied in (copytree/copy2, symlinks preserved). Entries 171 = 171, files 139 = 139, and `diff -rq` shows no differences.

### 4. Detached Metro :8098
- Started from `app-native/` with python `subprocess.Popen(start_new_session=True)`, equivalent to `nohup env APP_VARIANT=dev EXPO_PUBLIC_API_BASE=http://127.0.0.1:8017 CI=1 npx expo start --dev-client --port 8098`. Log: `<S>/metro-8098.log`. **`CI=1`** keeps it from needing a TTY, but it also turns off watch mode, so edits to the worktree are NOT hot-reloaded. Restart Metro to pick them up.
- **PIDs: 53726** (`npm exec`, the process-group leader; also in `<S>/metro-8098.pid`) and **53758** (`node … expo start`), both in process group 53726.
- To stop it: `python3 -c "import os,signal;os.killpg(53726,signal.SIGTERM)"`.
- `/status` → `packager-status:running`. The manifest's launchAsset is `app-native/index.ts.bundle`. Fetching that bundle (13.8 MB): contains `127.0.0.1:8017` **True** (inlined as `EXPO_PUBLIC_API_BASE`), contains `sign-in-google` **True**. `onrender.com` appears only in a doc comment in `apiUrl`'s setter.

### 5. Probe on :8098
- `openurl …url=http%3A%2F%2Flocalhost%3A8098`. Metro logged `iOS Bundled … app-native/index.ts (1655 modules)`. After the wordmark the app showed the gate with only "Sign in with Apple" and "Sign in with Google" (`<S>/dev-gate-1.png`). The restored local data did not bypass the gate. Boot sent 0 requests to :8017.
- One tap on Google opened the system prompt `"AstraceDev" Wants to Use "accounts.google.com" to Sign In` with "SIGNING IN…" (`<S>/dev-google-tap.png`). So the SDK starts with the slot-2 id. I tapped **Cancel**. The app returned to the gate cleanly, the process was still running, and nothing reached :8017 (`<S>/dev-after-cancel.png`).

### 6. Returned to the user's Metro
- `/status` on :8082 → running. I terminated the app and ran `openurl …url=http%3A%2F%2Flocalhost%3A8082`. It loaded the user's dev-branch JS: the CHART tab rail with the user's state and no gate (`<S>/dev-restore-8082.png`). The chart shows "The sky is out of reach", which is the pre-existing condition noted in 11-validating: the :8082 bundle targets `192.168.1.13:8000`, while the user's :8000 binds loopback only. This build did not cause it.
- NOTE: the installed dev-client BINARY is now the feature branch's native build (Google/Apple modules, fingerprint above). The user's dev-branch JS runs on it. If the dev branch's own native code must be restored, rebuild the dev client from the primary checkout after the live check, and back up the data first.

### USER: open the dev client on :8098 for L1/L2/L6(d)
```bash
xcrun simctl openurl booted 'astrace-dev://expo-development-client/?url=http%3A%2F%2Flocalhost%3A8098'
```
Return to the normal workflow afterwards:
```bash
xcrun simctl terminate booted com.astrace.app.dev
xcrun simctl openurl booted 'astrace-dev://expo-development-client/?url=http%3A%2F%2Flocalhost%3A8082'
```
Note: a completed sign-in on :8098 leaves a refresh token in the Keychain. The :8082 dev-branch JS will see it at its next boot.

### State left
- Metro :8098 (PGID 53726) and backend :8017 (PID 40738) are running.
- The dev client is open on :8082 with the user's data restored. `<S>/dev-data-backup/` is kept.
