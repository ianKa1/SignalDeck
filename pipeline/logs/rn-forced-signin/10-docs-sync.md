# rn-forced-signin — 10 docs-sync (partial: the parts that need no device)

Done ahead of the device steps, per the coordinator's instruction; re-check
after steps 16/17 in case the simulator run changes anything described.

## Skills
- `update-architecture-doc` (Skill tool). Baseline: `docs/ARCHITECTURE.md`
  last touched at `d35517f` (rn-appearance-dark-light, merged into this
  branch); the diff since is this feature's commits.

## docs/ARCHITECTURE.md (commit c828f73) — sections updated
- Stack summary (data core): accounts REQUIRED; native Google/Apple; every
  route but the allowlist needs a bearer.
- Repo tree comments: `settings/` (AccountSection), `accounts/` (google.py
  importer pair, apple.py, gate.py).
- Boundary-test paragraph: `test_no_email_gateway`, the PyJWT/Apple pin,
  `test_every_route_requires_a_bearer` (8 / 12 / 14).
- Core `platform/api.ts` postJson paragraph (always apiFetch + report; no
  `{auth:true}`), `auth.ts` (every surface installs a provider; each
  listener acts on its own session), planet_chat `{auth: true}` mentions,
  `cards/image-uri.ts` (bearer + private cache).
- `app/accounts/` server section rewritten (routes, service, apple.py,
  gate.py, deletion/revocation); google.py `verified_email(credential,
  audiences=None)` and its two importers; sync (account wins, generation
  counter, 401 report) and the native session end + device wipe; migrations
  014/015.
- web-divination threshold paragraph: `/api/chart` now needs the web bearer.
- app-native: navigator/accounts intro, `platform/boot.ts` (no fire-and-forget
  Keychain load; bootAccount), paint residue, shown-store card URI,
  Settings ACCOUNT section, `src/account/` rewritten (gate, section, hook,
  and the platform half: token-store, account-boot, device-wipe, sign-in,
  remote-image).
- Server test-suite paragraph (new suites, conftest native-gate stub,
  A4′); feature index + rn-forced-signin entry; dw-18 entry's `{auth:true}`.
- Confirmed still accurate: web-divination's own sections, planet_chat,
  interpretation/cards/selection tiers, db doors.
- Verification: every new path named exists (loop over 10 files, none
  missing); `grep -n "UNAUTHENTICATED\|unauthenticated" docs/ARCHITECTURE.md server/app/main.py`
  → no hit (exit 1).

## docs/features/rn-forced-signin.md
- Written to the PRIMARY checkout
  (`/Users/kaimao/Projects/astrology/docs/features/rn-forced-signin.md`):
  `docs/features/` is gitignored (local-only), so it cannot ride the branch
  and would be lost with the worktree.

## CLAUDE.md
- Re-checked against the final code: backend paragraph, NATIVE SIGN-IN ENV
  paragraph, rules 3, 6, 11, 12, 14 match what was built (committed in
  step 6, db72bc8). `grep -n "tokenStore\|AccountSheet\|deepLink\|magic" CLAUDE.md`
  → no stale hit; "OTP" appears only in "no email link or OTP" statements.
- Census note: `docs/text-variant-census.md` §T (step 14).

`git diff --stat dev -- docs CLAUDE.md` → CLAUDE.md, docs/ARCHITECTURE.md,
docs/text-variant-census.md (the feature doc is local-only, see above).

## Hand-back draft (for the coordinator's single user hand-back)

Set these (never commit values):
- Root `.env` (local server + local dev builds): `GOOGLE_IOS_CLIENT_ID` (the
  dev iOS OAuth client id for `com.astrace.app.dev`; comma-separate later
  ids), `APPLE_BUNDLE_IDS=com.astrace.app.dev`, `APPLE_TEAM_ID`,
  `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY` (the Sign in with Apple `.p8`, one line
  with `\n` escapes). Remove `RESEND_API_KEY` / `APP_BASE_URL` if present.
- EAS `preview` environment (and `development` if cloud dev builds are
  used): `GOOGLE_IOS_CLIENT_ID`.
- Dev Render dashboard: the same five server names.
- Apple Developer: enable Sign in with Apple on `com.astrace.app.dev`; the
  key used for `APPLE_KEY_ID` must have Sign in with Apple enabled.

Live checks:
- L1: dev app on the local backend (LAN) → Sign in with Google completes;
  the app opens with the account's birth data or the first-run entry; one
  `users` row for that email.
- L2: Sign in with Apple completes (share or hide email); `apple_identities`
  holds one hashed row; no raw `sub` anywhere.
- L3: kill + relaunch → still signed in (wordmark only, no gate flash);
  Settings › Sign out → the gate; relaunch → the gate; sign in again → birth
  data restored from the account.
- L4: Delete account on an Apple-linked account → Apple's sheet → 204 → the
  gate; the row is gone; Settings › Apple ID › Sign in with Apple no longer
  lists Astrace Dev.
- L5: `eas build --profile testflight` → TestFlight install → both sign-ins
  complete against `https://astrology-dev.onrender.com` and a chart loads.

Deliberate behaviour to flag: a signed-in user launching OFFLINE sees
"Can't reach Astrace." + Try again, not the app (every screen needs the
network, D13). The prod variant's gate shows both buttons disabled ("isn't
set up in this build") until prod credentials exist.

Status: docs-sync (non-device half) done; overall `validating — needs device`.
