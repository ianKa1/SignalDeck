# 15 · spec-review (rework amendment)

Reviewer: fresh-context subagent. It did not see the design conversation and modified nothing except this log. Inputs: QUEUE `rn-forced-signin` (its `feedback:` line, the newest user ruling), the user's restatement, CLAUDE.md, PIPELINE.md (Spec requirements, Decision precedence), the amended spec, the 14-designing note, and the worktree implementation @ c828f73 (`app-native/app.config.ts`, `app-native/eas.json`, `server/app/accounts/google.py`, `app-native/src/platform/sign-in.ts`).

## Verdict: FAIL (2 defects)

### Checklist
1. **Serves the feedback, no invented scope: PASS.** Each feedback item maps to a decision:
   - Apple on both variants → D19;
   - one name `GOOGLE_IOS_CLIENT_ID` holding a comma list, each build taking its own bundle's id, URL scheme derived from that id → D3, D19, the Contracts;
   - `testflight` = `APP_VARIANT=prod` against `https://astrace.onrender.com` → D20, B2;
   - `APPLE_BUNDLE_IDS` lists both → D19;
   - the dev variant keeps working → B1 dev case, B2, the L6 dev re-run;
   - prod rollout stays a non-goal.

   The D16 copy tweak is a small consequence of shipping the prod app, not new scope. The tagged-list mechanism is a legitimate "spec decides how" choice. Rejecting per-environment EAS values is reasoned, and the decision leaves no environment divergence.
2. **Criteria checkable; LIVE checks marked; gating clear: FAIL** (defects F1 and F2). S2, B1 and B2 are concrete and run with fake ids. B1's dev-first ordering also catches a naive `startsWith('com.astrace.app')` prefix bug in the prod build. L5 is marked POST-ROLLOUT and non-gating, which is acceptable only because L6 gates a prod-variant sign-in. But L6 as written does not cover everything the prod variant newly depends on (F1), and its transport is undecided against the prod Info.plist (F2).
3. **Architecture Contract / guards: PASS.**
   - Removing `VARIANTS[v].signIn` is offset by a guard that is equal or stronger for its purpose. The flag existed to stop a wrong or absent Google id shipping in prod. Now a build uses only the entry tagged with its own bundle id, never an untagged one, and fails clean, with a disabled button, on missing or malformed input. A duplicate tag throws, and B1 pins all of it, including "no `signIn` key".
   - The D20 sign-in-path guard (no dev-client imports, no `__DEV__`, no LAN address) is unchanged.
   - Rule 7 holds: the client id is public and is not an API key.
   - Rules 3 and 12 and the route pins are untouched by the amendment.
4. **Open points decided: FAIL on one point (F2).** Tag parsing is otherwise decided:
   - the server strips up to the last `=` and accepts every id;
   - the client matches the exact `bundleId=` prefix, ignores order, never uses an untagged entry, treats malformed or absent as unconfigured, and throws on a duplicate without naming the value;
   - the per-place values the user sets are listed in D19.

   The implementation is amendable as specified. `readRootEnvKey` already keeps everything after the key's first `=`, `googleIosClient` gains a `bundleId` parameter, and `ios_client_ids()` gains the strip.

### Defects

**F1: No gating check proves the prod bundle's Apple revocation, which is the one path that exercises the new single-key prerequisite.**

D19 makes Apple deletion for `com.astrace.app` depend on a new Apple-console setup: `com.astrace.app` grouped under the key's primary App ID (`com.astrace.app.dev`), so that one `.p8`/`APPLE_KEY_ID` signs a `client_secret` whose `sub` is `com.astrace.app`. If that grouping or key scope is wrong, prod sign-in still works, because verifying the identity token needs only the JWKS and `aud`. Only `DELETE /api/auth/account` fails, with 502 `apple revoke failed`, so a prod user could not delete their account. That is also an App Store requirement for apps offering account creation.

Nothing gates this:
- L4 is "variant-neutral", and given L1/L2 it is in practice run on the dev app;
- L6 covers only prod sign-in;
- L5 is post-rollout and non-gating;
- D2 uses only `client_id=com.astrace.app.dev` against fakes.

**Fix:** add to L6 that the PROD build (`com.astrace.app`), on an Apple-linked account, runs Settings → Delete account… → Apple's reauthorization sheet → 204 → the gate. The account row is then gone, and Settings › Apple ID › Sign in with Apple no longer lists the app. Alternatively, state that L4 is run on the prod build in the L6 setup, plus once on dev. Either way, the token exchange/revoke with `client_id=com.astrace.app` must be exercised before acceptance.

**F2: L6's transport is undecided against the prod variant's Info.plist.**

L6 runs the prod bundle against `http://<mac-ip>:8000` (plain http to a LAN IP). The repo's own documented position conflicts with that:
- the `app.config.ts` `localNetwork` comment says cleartext to a LAN address needs the ATS exception, and that the local-network prompt needs `NSLocalNetworkUsageDescription`;
- CLAUDE.md's dev-build paragraph says plain http to a LAN IP works *because* the Info.plist carries `NSAllowsLocalNetworking`;
- the prod variant deliberately declares neither (`NSAppTransportSecurity: {NSAllowsArbitraryLoads: false}` only).

So the one gating prod-variant check may fail for reasons unrelated to sign-in, or tempt someone to add LAN keys to the prod Info.plist ad hoc, which would silently change the store variant's config. The spec neither addresses this nor decides a path.

**Fix:** decide how the prod build reaches the local backend and write it into L6 and the LIVE preamble. For example: an HTTPS tunnel to the local uvicorn (`EXPO_PUBLIC_API_BASE=https://<tunnel-host>`), with the prod Info.plist left untouched and no temporary LAN keys added. Alternatively, cite the iOS rule that permits IP-literal cleartext without these keys, make an on-device `/api/health` reachability probe the first L6 step, and name the tunnel as the decided fallback. Also say that switching `ios/` from dev to prod needs `npx expo prebuild --clean` first (as `scripts/phone.sh` does).

### Non-blocking notes
1. **Primary App ID choice.** D19 makes the DEV App ID the key's primary, with prod grouped under it. Apple shows grouped apps as one entry in the user's Apple ID settings, and the displayed identity plausibly follows the primary. Production users might then see "Astrace Dev" there and in the consent sheet. If the key is not yet created (the queue still lists the Team ID, Key ID and `.p8` as needed), consider making `com.astrace.app` the primary and grouping `.app.dev` under it. Nothing in the server changes, because `client_id` is still the token's `aud`. F1's prod deletion check will prove whichever choice is made.
2. **Whitespace around `=`.** The server trims entries before stripping the tag, so `com.astrace.app = X` would yield the audience `" X"`. State that the tag and the id are each trimmed after the split, on both server and client, or add that case to S2/B1.
3. **EAS variable visibility.** Say that `GOOGLE_IOS_CLIENT_ID` in the EAS environments uses plain-text or sensitive visibility, not secret, so the CLI-side config resolution and the build server resolve the same id. The value is public anyway.
4. **Silent unconfigured store build.** A `testflight`/`production` build missing its tagged entry silently ships with Google disabled. That is acceptable per D19, but consider a loud warning (or a failure) for store profiles in a later entry.
5. **Stale non-goal text.** "The dev variant's NSLocalNetworking string (a noted TestFlight-review risk)" and "EAS `submit` config for the dev app" no longer match, since `testflight` is now the prod variant, which has no LAN strings. Reword them. For L5, also note how the testflight build is submitted: `submit.production` holds the prod `ascAppId`, so either `eas submit --profile production` with that build, or add `submit.testflight`. This is post-rollout and does not gate.
6. **Shared update channel.** `testflight` now shares the `production` update channel with `production`. That is fine under the fingerprint runtime policy and consistent with it being the prod variant.

Transition: spec-review → spec-review (revise)
