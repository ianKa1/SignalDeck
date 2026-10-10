# 16 · spec-review (rework amendment, round 2)

Reviewer: a fresh-context subagent. It did not see the design conversation and modified nothing except this log. It read no `.env` values.

Inputs:
- QUEUE `rn-forced-signin` (its `feedback:` line);
- the later user decisions relayed by the coordinator: (a) the prod variant is the launch target, Apple on both variants, `testflight` = prod against astrace.onrender.com, `APPLE_BUNDLE_IDS` lists both, prod rollout out of scope; (b) the positional `GOOGLE_IOS_CLIENT_ID=<prod>,<dev>` rule, where one entry serves both; (c) the current Apple key is being revoked; (d) the user's :8000, :5173 and :8082 servers are off limits;
- CLAUDE.md; PIPELINE.md (Spec requirements, Auto spec review, Decision precedence);
- the re-amended spec; `14-designing.md` (its Re-amendment section); `15-spec-review.md`;
- the worktree @ c828f73: `app-native/app.config.ts`, `app-native/eas.json`, `app-native/scripts/phone.sh`, `app-native/src/platform/sign-in.ts`, `app-native/src/app-config.test.ts` (test names only), `server/app/accounts/google.py`.

## Verdict: PASS

### Checklist

**1. Serves the rulings exactly, no invented scope: PASS.**

Each ruling maps to the spec as follows:

| Ruling | Where the spec covers it |
|---|---|
| (b) Positional rule: prod entry 1, dev entry 2 | D19 "The build picks by position", the Contracts `googleIosClient(variant, …)` |
| (b) One entry → both variants | D19 and B1 (`333-one` for both) |
| (b) Server accepts every entry | D3, the Contracts `ios_client_ids()` and S2, which allows three entries on the server |
| (b) Pinned in a test | B1's jest cases |
| (b) One name only | D19, plus B1's scan for `EXPO_PUBLIC_GOOGLE` / `GOOGLE_IOS_CLIENT_IDS` |
| (b) Per-environment EAS values used as is | D19 "What the user sets" |
| (a) Apple on both variants | D19; B1 checks `usesAppleSignIn`/`appleSignIn` true on both variants |
| (a) `testflight` = prod against astrace.onrender.com | D20, B2 |
| (a) `APPLE_BUNDLE_IDS` lists both | D19 |
| (a) Dev variant keeps working | B1 dev case, B2 dev profiles, L1/L2, L6(d) |
| (a) Rollout is out of scope | Non-goals; L5 is post-rollout and non-gating |
| (c) Revoked key | The LIVE preamble and D19 require the NEW key and key id; no check relies on the current values |

All tag syntax is gone from D3, D19, the Contracts, S2, B1 and the user steps.

"More than two entries throws" is a reasonable decided default:
- the ruling gives a third entry no meaning for a build;
- throwing is loud, names only the count, and cannot ship a wrong id;
- the user's own `.env` shape (exactly `<prod>,<dev>`) never triggers it;
- the server side keeps "accept every entry", so the ruling holds where it was stated.

Two decided edges sit within the spec's right to decide:
- empty slots are kept, so `,<dev>` and `<prod>,` are positional;
- a malformed slot disables Google for that variant only.

**2. Criteria checkable; LIVE marked; gating coverage: PASS.**
- S2, B1, B2 and D2 run with fake ids, jest, `expo config` and fakes.
- B1 pins every positional edge (single, spaces, `,dev`, `prod,`, malformed slot, unset/`","`, three entries throwing without ids) plus the absence of `signIn`.
- D2 gains the fake-`aud` `com.astrace.app` case: the exchange/revoke `client_id` and the client secret's `sub`.
- The LIVE items are marked. L1–L4 and L6 gate; L5 is post-rollout and non-gating.
- L6 is the prod-variant gate: (a) Google, (b) Apple with `aud` `com.astrace.app`, (c) an Apple-linked deletion on the PROD build. The 204 can only follow a successful exchange+revoke with `client_id=com.astrace.app` (D6). (d) is a dev re-run.

**3. Architecture Contract / guards: PASS.**
- Removing `VARIANTS[v].signIn` is offset by the positional rule plus clean disablement on empty or malformed input, the three-entry throw, and B1's "no `signIn` key". The D20 sign-in-path guard (no dev-client imports, no `__DEV__`, no LAN address) is unchanged.
- Rule 7 holds: an OAuth client id is public and is not an API key.
- Rules 3, 11 and 12, the route pins, B4 and the text-variant/paint guards are untouched by the amendment. No guard is weakened.
- The amendment is consistent with the unchanged rest:
  - S3/D4 still use `com.astrace.app.dev` fakes, which is fine;
  - U1's opt-out path matches `appleConfigured()` reading `extra.appleSignIn`;
  - the D16 copy is variant-neutral;
  - the CLAUDE.md Commands bullet states the rule;
  - Supersedes lists the earlier approval's "first entry", dev-only-flag and dev-`testflight` points. The unapproved tagged design needed no journal supersession.

**4. Open points decided; user steps complete: PASS.**

User steps, per place:
- **Root `.env`:** the pair (prod first), both bundle ids, `APPLE_TEAM_ID`, and the NEW `APPLE_KEY_ID` and `APPLE_PRIVATE_KEY`.
- **EAS:** `production` = `<PROD_ID>` (this also covers `testflight`, environment production); `preview`/`development` = `<DEV_ID>`. The pair is also valid. Visibility is plain text or sensitive, not secret, which is correct: secret variables are not available to the local config resolution.
- **Dev Render:** the pair plus the four Apple variables. Prod Render is at rollout only.
- **Apple:** Sign in with Apple on both App IDs, with the new key's primary App ID `com.astrace.app` and `.dev` grouped under it.
- **Google:** a second iOS client for `com.astrace.app`.

Implementability against the worktree:
- `googleIosClient` gains a `variant` parameter and replaces `.find(first non-empty)` with the slot rule; `buildConfig` drops the `v.signIn` gates.
- `eas.json` `testflight` switches from `extends: preview`/dev to `extends: production`/prod, and `production` gains `environment`.
- `google.ios_client_ids()` already matches the spec unchanged.
- `sign-in.ts` already matches (`appleConfigured()` reads `extra.appleSignIn`).
- `app-config.test.ts` B1/B2 need the rewrite the spec describes.
- `readRootEnvKey` already trims.

### Review 15 defects
- **F1: RESOLVED.** L6(c) gates a prod-build Apple-linked deletion. D6 states `client_id` = the token's `aud` = the signing app's own bundle. D2 pins the `com.astrace.app` exchange/revoke/secret `sub` with fakes.
- **F2: RESOLVED.** The transport is decided in the LIVE preamble:
  - the prod Info.plist is never edited;
  - first choice: the simulator over loopback, with a reachability probe as step 1;
  - decided fallback: an HTTPS `cloudflared` tunnel with a rebuild, on the simulator or a device;
  - `npx expo prebuild --clean` is required when switching variants (D20, L6, L6(d)).

  `phone.sh` already runs Debug prod-variant builds on a device against Metro over the LAN, which is weak evidence that IP-literal cleartext works without the LAN keys.

### Non-blocking notes
1. **Port (environment constraint d).** The LIVE preamble and L6 name `http://127.0.0.1:8000` and `cloudflared tunnel --url http://127.0.0.1:8000`. :8000 is the user's server and must not be used or touched. The coordinator should run the pipeline's own backend on another port (e.g. 8100) and substitute it in `EXPO_PUBLIC_API_BASE` and the tunnel URL. The same applies to L1's "local backend (LAN)": use the pipeline's port with `--host 0.0.0.0`, never the user's :8000. Metro for `npx expo run:ios` must also avoid :8082 (pass `--port` explicitly if needed).
2. **Metro under the prod Info.plist.** If the loopback probe fails because the Debug JS bundle itself cannot load from Metro (not because the API call is refused), the tunnel fallback will not help. `npx expo run:ios --configuration Release` embeds the JS and avoids Metro entirely (and the dev client), so it is a sensible first try for L6 on either transport.
3. **Evidence for L6(a) "aud is entry 1".** The server accepts both ids and does not log `aud`, so a successful sign-in alone does not show which entry was used. Record the evidence from the built prod project instead: `extra.googleIosClientId` or the Info.plist `CFBundleURLSchemes` equals entry 1's reversed scheme. Combined with B1, that shows the PROD client id was used.
4. **Trailing-comma edge.** `<id>,` is treated as two slots (prod = id, dev = none), not as "one entry". This is a defensible reading of "if only one entry is present", and B1 pins it. If the user later reads it differently, it is a one-line change.
5. **Third audience in the root `.env`.** Because the server and local builds share the root `.env`, adding a third server-only audience there (e.g. during a client-id rotation) would break local builds. Should that ever be needed, set the extra audience only in Render, or revisit the throw.
6. **Apple grouping step.** If `com.astrace.app.dev` was already enabled as a PRIMARY App ID for the old key, the user must edit its Sign in with Apple configuration to "Group with an existing primary App ID → com.astrace.app". Spelling this out in the hand-back would help. Apple's `sub` is team-scoped, so existing dev links survive the regrouping.

Transition: spec-review → implementing (rework)
