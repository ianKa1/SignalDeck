# 06 · validating — plan step 10, device checks (coordinator, 2026-09-30)

Code under test: worktree `/Users/kaimao/Projects/astrology-wt/rn-onboarding-after-signin`,
branch `feature/rn-onboarding-after-signin` @ `bf355b6`, plus the TEMPORARY harness
stub (spec D14). Simulator iPhone 17 `7DB5C491-1C54-4FC3-9090-CDEC174732D4`.
Scratch (`<s>`): `/private/tmp/claude-501/-Users-kaimao-Projects-astrology/4cb30d3d-9400-410d-b035-a12dd2fddaa3/scratchpad/onb/`.

## Harness (D14)

- Throwaway Postgres: `initdb` `<s>/pgdata`, port 54318, db `onb_main` (not astrace_dev, not Neon).
- Backend :8018 from the worktree `server/`: `env TOKENROUTER_API_KEY= ANTHROPIC_API_KEY= OPENAI_API_KEY= LLM_API_KEY= GEMINI_API_KEY= GOOGLE_API_KEY= DATABASE_URL=postgresql://astrace@127.0.0.1:54318/onb_main WEB_DATABASE_URL= GOOGLE_IOS_CLIENT_ID=123-abc.apps.googleusercontent.com APPLE_BUNDLE_IDS= FAKE_EMAIL_FILE=<s>/fake_email.txt PYTHONPATH=. conda run --no-capture-output -n astrology python <s>/fake_server.py 8018` — the wrapper replaces `app.accounts.google._verify_token` with a function accepting only the token `onb-device-check-token` and returning `{"email": <fake_email.txt>, "email_verified": True}`; no `--env-file`. Email: `onb.new@example.com`.
- Client stub: one line at the top of `googleIdToken()` in `app-native/src/platform/sign-in.ts` returning `'onb-device-check-token'`, uncommitted.
- Metro :8098 from worktree `app-native/`: `APP_VARIANT=dev GOOGLE_IOS_CLIENT_ID=123-abc.apps.googleusercontent.com EXPO_PUBLIC_API_BASE=http://127.0.0.1:8018 CI=1 npx expo start --dev-client --port 8098`. Freshness: Metro log `iOS Bundled 938ms app-native/index.ts (1662 modules)`; dev menu "Connected to: http://localhost:8098".
- No native change in this feature → the installed dev-client binary was reused (sha256 prefix `a9e5b36b3068fe61`). Before: user's data container `13F88B3C-…` backed up to `<s>/data-backup` (entries/files 174/142 = 174/142); app bundle copied to `<s>/AstraceDev.app`; `simctl uninstall` + `install` for a fresh container (`1FFE20E3-…`).

## AC6 — fresh install: words, then buttons below, same page — PASS

Burst `<s>/ac6-b1..b8.png`: splash frames, words fading in, buttons region dark
(max luminance 9) while words present (166–171); settled `<s>/ac6-settled.png`.
idb dump (`<s>/ac6-describe.json`), verbatim:

```
StaticText | read the universe, | None | {'y': 370, 'x': 107.33, 'width': 187.67, 'height': 24}
StaticText | trust yourself. | None | {'y': 398, 'x': 122, 'width': 158.33, 'height': 24}
Button | Sign in with Apple | None | {'y': 592, 'x': 41, 'width': 320, 'height': 50}
Button | Sign in with Google | sign-in-google | {'y': 654, 'x': 41, 'width': 320, 'height': 50}
(+ dev-launcher gear/Tools)
```
Buttons y 592/654 > line-2 bottom 422. No "Astrace" heading. No request left the app at launch (no stored pair).

## AC22 — empty account: Appearance → Light (reload) → 中文 → Birth → chart — PASS

- Tap Google → backend `POST /api/auth/google 200`, `GET /api/profiles 200` (empty). Screen `<s>/ac22-1-appearance.png`: `setup-marks` "Step 1 of 3", heading "How should Astrace look?", `setup-ground-dark` (selected), `setup-ground-light`; no rail.
- Tap Light → reload: backend `GET /api/auth/whoami 200`, `GET /api/profiles 200`. Frames `<s>/ac22-2-r1..r6`: r1–r2 white launch splash, r3 onward already the Language step (no opening words in the words band — r3 shows "Which language?"). Page background pixel (60,1500) = (249,249,247) = `GROUND_TOKENS.light.ground` `#f9f9f7` (tokens.ts:228) in every frame from r3. Dump: "Step 2 of 3", "Which language?", `setup-lang-en` English, `setup-lang-zh` 中文.
- Tap 中文 → `<s>/ac22-3-birth.png`: "第 3 步，共 3 步", heading "你在何时何地出生？", the shared form (`sheet-date`, `sheet-time`, `sheet-time-unknown`, quick cities, `city-country`, `city-city`), submit `sheet-submit` "打开我的星盘", no dismiss control.
- Unfurl+close date (commits 1990-01-01), time (12:00), tap Beijing chip (39.9042, 116.4074 · Asia/Shanghai), submit → `POST /api/chart 200`, `PUT /api/profiles/traveler 204 No Content` (204 is this route's success status; the criterion's "200" means success), rail visible (`tab-chart`… `tab-settings`), Big Three 摩羯座/水瓶座/白羊座, wheel. The card band's "星空暂时无法触及" is the reading job failing with no LLM key (`POST /api/analysis 502`), expected in this harness and unrelated.
- DB: `traveler | 1990-01-01 | 12:00:00 | Beijing | onb.new@example.com` (1 row).
- Settings (bonus, AC19): account email, 退出登录, 删除账号…, birth row "1990-01-01 · Beijing", 语言 EN/中文, 你所在的地方, 外观 深色/浅色.

## AC23 — sign out, sign in again: no setup, chart loads — PASS

- Settings → 退出登录 → `POST /api/auth/logout 204`; reload; `<s>/ac23-1-threshold.png`: light ground, the two lines, Apple (black on light) + "通过 Google 登录" beneath.
- Tap Google → `POST /api/auth/google 200`, `GET /api/profiles 200`, `POST /api/chart 200`. Six polls (0.7 s apart) of the accessibility tree: `['tab-chart']` every time, never a `setup-*` id. `<s>/ac23-2-chart.png`: the same chart (摩羯座/水瓶座/白羊座) in 中文 on light.

## AC24 — Reduce Motion: words and buttons at once — PASS

Signed out, `ReduceMotionEnabled -bool true`, terminate, relaunch; 16 frames ~0.4 s apart (`<s>/ac24-b1..b16`). b1–b8 launch/splash, b9–b10 dev-client loading (uniform 9), b11 the first app frame: words band min luminance 0 and buttons band min 0 on bg 249 — both fully drawn; b12–b16 identical values (no fade). `<s>/ac24-b11.png` read: lines + both buttons.

## Cleanup

- `ReduceMotionEnabled -bool false`.
- Stub reverted (`git checkout -- app-native/src/platform/sign-in.ts`); `git status --short` empty; `grep -c "DEVICE-CHECK STUB"` → 0.
- Simulator data restore + stopping :8018/:8098/:54318 happen after acceptance (logged in the final review).

Transition: validating → docs-sync
