# rn-forced-signin — 14 designing (rework amendment)

Date: 2026-09-30. Trigger: QUEUE `rework`. The user's `feedback:` (tier 1) makes the app to launch the PRODUCTION variant. It asks for Apple on both variants, a per-variant Google id under the one name `GOOGLE_IOS_CLIENT_ID`, a `testflight` build of `APP_VARIANT=prod` against `https://astrace.onrender.com`, `APPLE_BUNDLE_IDS` listing both bundles, and a dev variant that keeps working. The coordinator added: prod rollout (dev→main, prod Render env, prod migrations 013–015) is a non-goal.

The spec was amended in place. No code was edited, and no `.env` values were read. A pre-amendment copy is in the session scratchpad (`spec-pre-rework.md`).

## What was built (read in the worktree, feature/rn-forced-signin @ c828f73)
- `app-native/app.config.ts`: `VARIANTS[v].signIn` (prod false, dev true); `googleIosClient(env, readRootEnv)` takes the FIRST list entry; `buildConfig` gates the plugin, `extra.googleIosClientId`, `usesAppleSignIn` and `extra.appleSignIn` on the flag. `readRootEnvKey` keeps everything after the key's first `=`, so a value containing `=` (tagged entries) parses intact.
- `app-native/eas.json`: `testflight` extends `preview` (dev variant, dev Render, environment `preview`); `production` has no `environment`.
- `app-native/src/platform/sign-in.ts`: `googleConfigured()`, `appleConfigured()` (reads `extra.appleSignIn`), `appleAvailable()`.
- `app-native/src/app-config.test.ts`: the B1/B2 cases pin the dev-only flag and the dev `testflight`; they need rewriting.
- `server/app/accounts/google.py` `ios_client_ids()`: comma split and trim, with no tag handling.

## Decided mechanism
**A tagged list in one variable.** `GOOGLE_IOS_CLIENT_ID=com.astrace.app=<PROD_ID>,com.astrace.app.dev=<DEV_ID>`.
- The server strips each entry's `<bundle>=` tag and accepts every id, tagged or untagged.
- `app.config.ts` takes ONLY the entry tagged with its own bundle id, independent of order. Untagged entries are never used by a build, because an iOS client id is bound to one bundle and a wrong guess ships a broken Google sheet.
- No entry for the bundle, or a malformed id → Google is cleanly unconfigured for that build (disabled button with its note). This guard replaces the removed flag.
- A duplicate tag throws at config time, naming the bundle and not the value.
- The SAME string goes everywhere: the root `.env`, the EAS `production` / `preview` / `development` environments, and dev Render (prod Render at the user's rollout). There is therefore no per-environment divergence to get wrong.

I rejected EAS per-environment values with no tags: the local build path would still need a selection rule, and two mechanisms would drift.

The `signIn` flag is REMOVED. Both variants set `usesAppleSignIn` and `extra.appleSignIn: true`, and `appleConfigured()` stays as a data-only opt-out. `testflight` now extends `production` with environment `production`, `APP_VARIANT=prod` and base `https://astrace.onrender.com`; `production` also names environment `production`. `APPLE_BUNDLE_IDS=com.astrace.app,com.astrace.app.dev`.

Apple prerequisite stated: Sign in with Apple must be enabled on both App IDs, with `com.astrace.app` grouped under the key's primary App ID (`com.astrace.app.dev`), so one `.p8` key signs both bundles' revocation client secrets. Google prerequisite: a second iOS OAuth client for `com.astrace.app`.

## Spec changes (marked "Rework" in the text; listed in the note under Goal)
- **Non-goals:** prod setup becomes prod ROLLOUT (dev→main, prod Render env, prod migrations 013–015). The prod variant itself is in scope.
- **D3:** tag stripping on the server.
- **D16:** variant-neutral no-email copy ("stop using Astrace").
- **D19:** rewritten (the tagged list, per-bundle selection, the guard, Apple on both, the exact per-place values).
- **D20:** rewritten (`testflight` = prod).
- **Contracts:** `google.ios_client_ids`; `app.config` `googleIosClient(bundleId, …)`.
- **Reuse and module-map rows:** app.config, eas.json, google.py.
- **CLAUDE.md:** the Commands bullet.
- **Criteria:**
  - S2 (tagged and untagged audiences);
  - B1 (dev picks its tagged id, prod picks its tagged id, order-independence, untagged-only or other-bundle-only → no Google but Apple on, malformed → same, duplicate tag throws, no `signIn` key);
  - B2 (`testflight` is prod with environment production; production's environment; dev profiles unchanged);
  - U1 (the opt-out path is now a mocked-Constants case);
  - LIVE: the preamble lists the new user steps. L1 and L2 are marked dev variant. L4 is variant-neutral. L5 is rewritten as the prod TestFlight build against astrace.onrender.com, marked POST-ROLLOUT and not gating. The new L6 is the prod variant on a device against the local backend, with both providers, plus a dev re-run.
- **Supersedes added** (verbatim headings):
  - `### 2026-09-30 · rn-forced-signin · spec-review — spec auto-approved (round 3); forced Google + Apple native sign-in on the main db, OTP/magic-link/cookie/email removed, every route bearer-gated`: the dev-only-flag, first-entry and dev-testflight points.
  - `### 2026-09-30 · rn-forced-signin · accepting — every non-LIVE criterion PASS; parked `blocked` on the user's credentials and live sign-in (L1–L5)`: its B1/B2 verdicts and L list are re-graded.

## Transition
rework → spec-review (rework amendment)

---

## Re-amendment (same day). The user decision overrides the tagged list, and review 15 is folded in.

Inputs:
- The coordinator relayed a user decision (tier 1): `GOOGLE_IOS_CLIENT_ID=<prod id>,<dev id>`, production first, chosen by position, with one entry serving both variants and no tags. The `.env` Apple key is being revoked, and a new key and key id are coming.
- `logs/rn-forced-signin/15-spec-review.md` (FAIL, F1 and F2, written against the tagged version). Its tag-specific remarks (check-4 parsing, note 2's `=` trimming, note 4's "tagged entry") are moot.

The spec was edited in place; no code. The rework note under Goal gained a "Re-amendment" paragraph listing the re-changed IDs.

### The final rule (D19, Contracts, B1)
- The server's `ios_client_ids()` splits on commas, trims, drops empties, and treats every entry as an audience. There are no tags and no count limit.
- The build (`googleIosClient(variant, …)`) splits on commas and trims each entry, keeping empty slots so positions never shift:
  - unset or all-empty → Google disabled on both variants;
  - exactly 1 entry → both variants use it (the single per-environment EAS value);
  - exactly 2 → prod takes entry 1 and dev entry 2; an empty or malformed slot disables Google for that variant only;
  - more than 2 → the build THROWS, naming the count and never a value. Rejected alternative: "use the first two and ignore the rest", which could silently ship a wrong id after a careless append.
- All tag syntax is removed from D3, D19, the Contracts, S2, B1 and the user steps. B1's jest cases pin: one entry for both, whitespace, `,dev`, `prod,`, a malformed slot, unset or `","`, and 3 entries throw (count 3, no ids in the message).

### What the user sets (D19)
- Root `.env`: `GOOGLE_IOS_CLIENT_ID=<PROD_ID>,<DEV_ID>`, `APPLE_BUNDLE_IDS=com.astrace.app,com.astrace.app.dev`, `APPLE_TEAM_ID`, and the NEW `APPLE_KEY_ID` and `APPLE_PRIVATE_KEY`.
- EAS: `production` = `<PROD_ID>`; `preview` and `development` = `<DEV_ID>`. The full pair also works. Visibility must be plain text or sensitive, not secret.
- Dev Render: the pair plus the four Apple variables. Prod Render: the same, at rollout only.
- Apple: the user is creating the new key now. Recommendation: `com.astrace.app` as the PRIMARY App ID, with `.dev` grouped under it.
- Google: a second iOS client for `com.astrace.app`.

No criterion or step relies on the revoked key: the LIVE preamble requires the NEW key and key id.

### Review 15 fixes
- **F1 (prod Apple revocation not gated).**
  - L6(c): the PROD build deletes an Apple-linked account (reauthorization sheet → 204 → gate, the row gone, the app no longer listed in Apple ID settings). The 204 itself proves the revoke with `client_id=com.astrace.app` (D6 deletes only after a successful revoke).
  - D6 now says `client_id` = the token's `aud` = the signing app's own bundle.
  - Criterion D2 gains a fake-`aud` `com.astrace.app` case: the exchange and revoke carry `client_id=com.astrace.app`, and the client secret's `sub` is `com.astrace.app`.
- **F2 (L6 transport undecided).**
  - Decided in the LIVE preamble: the prod Info.plist is never edited.
  - First choice: the iOS simulator against `http://127.0.0.1:8000`, with step 1 a reachability probe (a Sign in with Google tap whose `POST /api/auth/google` shows in the uvicorn log).
  - Fallback, when no request arrives or simulator Apple sign-in fails: an HTTPS tunnel (`cloudflared tunnel --url http://127.0.0.1:8000`, `EXPO_PUBLIC_API_BASE=https://<tunnel-host>`), on the simulator or a device.
  - `npx expo prebuild --clean` is required when switching `ios/` between variants (D20, L6).
- **Notes:**
  - 1: applied as the primary-App-ID recommendation above.
  - 2: moot (no tags); entry trimming is pinned in B1 and S2.
  - 3: EAS visibility is stated.
  - 4: not taken (a later entry, per the reviewer).
  - 5: the stale Non-goals are reworded, and L5 names `eas submit --profile production` (the existing `ascAppId`).
  - 6: no action.

### Transition
rework → spec-review (rework amendment)
