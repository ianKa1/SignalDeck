# Feature Queue

Rules: see PIPELINE.md. Order = priority; `depends:` = which entries must be
`done` first (ready entries with no mutual dependency run as a parallel wave). The loop runs fully autonomously —
you only add features (rough notes suffice), reorder, or drop them; optional
override: `rework` + `feedback:` on any entry. Audit trail: DECISIONS.md +
logs/<feature>/.

History cleanups (user-directed): 2026-07-21 (first — finished entries
collapsed into ARCHIVE.md) and 2026-07-25 (second — ALL prior queue
entries, decision entries, specs, plans, and stage logs cleared from the
working tree at the start of the natal_integrated work). NOTHING is lost —
retrieval from git history:

    git log --oneline --all -- pipeline/QUEUE.md
    git show <commit>:pipeline/QUEUE.md
    git show <commit>:pipeline/specs/<slug>.md
    git log --oneline --all -- 'pipeline/logs/<slug>/'

<!-- add features below this line -->

<!-- DIVINATION WEB EPIC (user-directed 2026-09-28): a browser app where the
user chats with planet characters grounded in their natal chart. Each
entry is one closed loop, demoable in the browser. Order = dependency:
dw-1 → dw-2 → dw-3 → {dw-4, dw-5, dw-6}. Shared ground for all entries:
new workspace `web-divination/` (Vite + React) consuming @astrace/core
through barrels only; new server Tier C package `app/divination/`; the
server keeps NO conversation state (the client owns the transcript and
sends it each turn); everything anonymous-first, identity-free.
EPIC ARCHITECTURE: pipeline/epics/divination-web.md (specs cite it).
LOCAL ONLY (user ruling 2026-09-28): Vite dev server against the local
backend; no hosting, no Render CORS change, no deploy work in this epic.
Chat replies STREAM word by word (user ruling 2026-09-28, DECISIONS.md). -->


## rn-appearance-dark-light
status: done
depends: none
cycles: 0
notes: USER-REQUESTED 2026-09-30 (app-native). The app keeps TWO appearance modes. Remove the `paper` and `plaster` grounds (theme/tokens.ts `Ground`, their token tables, the Settings appearance options, and their tests, rulings and census notes). Rename `ink` → `dark` and `exhibition` → `light`, both in code and in what users see (Settings labels in en and zh). The colour values are unchanged: dark is today's ink and light is today's exhibition. A stored preference of paper/plaster/exhibition migrates to light, and ink migrates to dark, on first read, so no user lands on a missing ground. Keep rule 13 (one token home) and rule 15 (PAINT/TEXT_VARIANTS) intact, and amend any guard or ruling that names the removed grounds rather than weakening it. Loop closed: Settings offers exactly Dark and Light, each renders as ink and exhibition did before, and a device that had paper or plaster opens in Light.
last: 2026-09-30 accepting → done — PASS 14/14, landed d35517f; logs/rn-appearance-dark-light/12-final-review.md

## rn-ask-input-disabled
status: done
depends: none
cycles: 0
notes: USER-REQUESTED 2026-09-30 (app-native). The ASK feature is not finished: disable the question input box on the Ask screen (not editable, visibly disabled, and no submit path fires a request). Keep the rest of the Ask screen visible. A short "coming soon" note is fine (en + zh via i18n). Do not delete the Ask code or its tests; only gate the input, with one flag in one place so re-enabling is a one-line change. Loop closed: on the Ask tab the input cannot be focused or submitted, and no /api/ask request leaves the app.
last: 2026-09-30 accepting → done — PASS 10/10, landed d47d24a; logs/rn-ask-input-disabled/09-final-review.md

## rn-forced-signin
status: done
depends: none
cycles: 0
notes: USER RULINGS 2026-09-30. app-native sign-in is forced and simple: at launch a gate shows "Sign in with Google" and "Sign in with Apple", and nothing else (no anonymous mode, no email code). Native accounts stay in the main db, separate from web accounts. The server verifies the Google/Apple token, upserts the user by email and mints the existing native bearer pair; email stays the only PII. Remove OTP, magic link, the cookie session and the email gateway (with a new migration dropping their tables). Every route except /api/health and the sign-in routes requires a bearer. Settings → Account: email, Sign out (wipes the device, back to the gate), Delete account (also revokes Apple). Birth data follows the account via /api/profiles, with no conflict UI. Also fix the native refresh re-entry hang and the cold-start restore race. Rewrite CLAUDE.md rule 12 and the pinning tests (Supersedes, never weaken a guard). Needs from the user: the iOS OAuth client ids, the Apple Team ID, Key ID and .p8 key, and a live sign-in check (hand back once). Loop closed: a fresh install shows only the gate; Google and Apple both sign in; restart keeps the session; sign out returns to the gate; non-health routes return 401 without a bearer.
last: 2026-09-30 accepting → done — live L1–L4 PASS (dev), L5/L6 open for rollout, landed 5d72459; logs/rn-forced-signin/22-final-review.md
feedback: (user 2026-09-30) The app to launch is the PRODUCTION variant (com.astrace.app, "Astrace", backend https://astrace.onrender.com, main branch), not only dev. (1) Enable Sign in with Apple for the prod variant too (usesAppleSignIn on both variants). (2) Pick the Google iOS client id PER VARIANT: GOOGLE_IOS_CLIENT_ID stays the one name and holds a comma-separated list for the server; the build must take the id belonging to its own bundle (spec decides how, e.g. EAS per-environment value, or match by variant); the URL scheme is derived from the chosen id. (3) The TestFlight profile builds APP_VARIANT=prod against https://astrace.onrender.com. APPLE_BUNDLE_IDS lists both com.astrace.app and com.astrace.app.dev. Keep the dev variant working. Then hand back for the live checks with updated user steps.

## rn-onboarding-after-signin
status: done
depends: rn-forced-signin, rn-appearance-dark-light
cycles: 0
notes: USER-REQUESTED 2026-09-30 (app-native). Right after a FIRST sign-in (an account with no birth profile yet), run a short setup before the app opens, in this order: (1) Appearance: Dark or Light; (2) Language: EN or 中文; (3) birth data and location (reuse the existing birth-input form and city picker). Each choice applies immediately, so the next setup screen already renders in the chosen appearance and language. Appearance and language stay device preferences, and birth data saves to the account via /api/profiles. A returning account that already has a birth profile skips setup. Settings can still change all three later. Loop closed: a new account goes gate → Dark/Light → EN/中文 → birth data → app, and signing in again on a wiped device skips setup and loads the saved chart. ADDED 2026-09-30 (user): the sign-in gate is no longer a plain "Astrace" page. It plays the existing opening animation, "read the universe," then "trust yourself." (app-native/src/opening/OpeningPrototype.tsx, tunables in theme/motion.ts OPENING_*), and the Google/Apple sign-in buttons then appear on that SAME page beneath the words, with no hand-off to a separate screen. Reuse the prototype rather than re-implementing it, and keep its Reduce-Motion behaviour (static words, buttons shown at once).
last: 2026-09-30 accepting → done — PASS 24/24, landed ecb505f; logs/rn-onboarding-after-signin/09-final-review.md
