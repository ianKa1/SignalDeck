# rn-forced-signin — 17 implementing (rework, 2026-09-30)

Worktree `../astrology-wt/rn-forced-signin`, branch `feature/rn-forced-signin`, from `c828f73`.
Inputs: amended spec ("Rework" + "Re-amendment"), `14-designing.md`, `16-spec-review.md` (PASS).
Plan: `## Rework (2026-09-30)` appended to `pipeline/plans/rn-forced-signin.md`, R1–R7, all ticked.
No `.env` value was read or printed.

## Steps

- **R1 `app-native/app.config.ts`.** `VARIANTS[v].signIn` deleted (type and both entries). `VARIANTS` and `Variant` are now exported (read-only) for the B1 pin. `googleIosClient(variant, env, readRootEnv)` implements D19's positional rule: split on `,`, trim, keep empty slots; all empty → null; 1 entry → both; 2 → prod `[0]`, dev `[1]`, empty/malformed slot → null for that variant; >2 → `throw new Error("GOOGLE_IOS_CLIENT_ID has N entries; a build expects at most two, written \"<prod id>,<dev id>\" (production first), or one id for both variants.")` (no value). `buildConfig` passes its variant; `ios.usesAppleSignIn: true` and `extra.appleSignIn: true` unconditionally.
- **R2 `app-native/eas.json`.** `testflight`: `extends: production`, `distribution: store`, `environment: production`, `autoIncrement: true`, env `APP_VARIANT=prod`, `EXPO_PUBLIC_API_BASE=https://astrace.onrender.com`, channel `production`. `production` gains `environment: production`. development/preview untouched.
- **R3 `app-native/src/app-config.test.ts`.** Rewritten B1 (11 cases: prod pair, dev pair, single entry both, spaces, `,dev`/`prod,`, malformed slot either side with Apple on, unset in shell+root `.env` and `","` on both variants with Apple on, root-`.env` fallback by position, 3 entries throw with `3` and no id, no `signIn` key in `VARIANTS`, an app-native-wide scan for `EXPO_PUBLIC_GOOGLE`/`GOOGLE_IOS_CLIENT_IDS` excluding node_modules/ios/android) and B2 (4 cases: testflight prod, production/development/preview environments, dev profiles unchanged, no Google id in any profile env).
- **R4 server tests (no server code change; `google.ios_client_ids()` and `service.delete_account` already matched D3/D6).**
  - `tests/test_native_signin.py::test_s2_server_accepts_every_trimmed_entry_with_no_count_limit` — `"a, b,,c"` → `[a,b,c]`, fake receives that list.
  - `tests/test_native_signin_live.py::test_d2_prod_bundle_token_revokes_with_its_own_client_id` — `APPLE_BUNDLE_IDS=com.astrace.app,com.astrace.app.dev`, fake token `aud: com.astrace.app` → exchange and revoke forms carry `client_id=com.astrace.app`, both `client_secret` JWTs decode (unverified) to `sub=com.astrace.app`; 204, rows gone. `_apple_claims`/`_apple` gained an `aud` parameter (default dev bundle, existing cases unchanged).
- **R5 touch-ups.** `.env.example` GOOGLE_IOS_CLIENT_ID/APPLE_BUNDLE_IDS comments state the positional rule and both bundles; `native-guards.test.ts` D20 comment now says the TestFlight build is the PROD variant; D16 copy in `i18n/en.ts`/`zh.ts`: "stop using Astrace" / "停止使用 Astrace" (was "Astrace Dev").
- **R6 docs.** CLAUDE.md Commands "NATIVE SIGN-IN ENV" paragraph rewritten (positional rule, Apple on both, EAS per-environment values and visibility, testflight = prod). `docs/ARCHITECTURE.md`: service.py audience passage (server accepts every entry), `delete_account` (`client_id` = token `aud`), `platform/sign-in.ts` passage (+ what app.config writes into `extra`), eas.json profile list (+ testflight), feature index line. `docs/features/rn-forced-signin.md` (primary checkout) gained "## Rework (2026-09-30)".

## Commits

- `159ca81` (feat): rn-forced-signin — prod variant signs in: Google id picked by position (<prod>,<dev>, one entry serves both, more than two fails the build), Apple on both variants, testflight builds prod against astrace.onrender.com
- `f17ba8b` (docs): rn-forced-signin — CLAUDE.md and ARCHITECTURE.md state the positional Google id rule, Apple on both variants and the prod testflight profile

## Decision entries to journal (coordinator)

- `### 2026-09-30 · rn-forced-signin · implementing (rework) — Google iOS client id picked by position from GOOGLE_IOS_CLIENT_ID=<prod>,<dev>; Apple on both variants; testflight = prod` — What: the dev-only `signIn` flag removed; `googleIosClient(variant,…)` keeps empty slots, one entry serves both, >2 throws with the count only; `testflight` extends `production` (environment production); `production` names environment production. Supersedes (verbatim, as the spec lists): `### 2026-09-30 · rn-forced-signin · spec-review — spec auto-approved (round 3); forced Google + Apple native sign-in on the main db, OTP/magic-link/cookie/email removed, every route bearer-gated` (its dev-only flag, first-entry rule and dev-testflight points only) and `### 2026-09-30 · rn-forced-signin · accepting — every non-LIVE criterion PASS; parked `blocked` on the user's credentials and live sign-in (L1–L5)` (B1/B2 verdicts and the L list re-graded).
- Small implementer default: `VARIANTS` and `Variant` exported from app.config.ts (read-only) so B1 can pin "no `signIn` key" structurally rather than by source grep.

Transition: implementing → validating (rework).
