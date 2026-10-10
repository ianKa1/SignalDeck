# 02 — spec-review (round 1)

**Verdict: PASS**

Inputs: QUEUE entry `dw-16-web-account-db` (tier-1 user rulings 2026-09-29), `pipeline/specs/dw-16-web-account-db.md`, `pipeline/epics/divination-web.md`, `CLAUDE.md`, PIPELINE.md (Spec requirements, Auto spec review, Decision precedence, pipeline-mode overrides). Code claims spot-checked on the worktree (2e6cfe8).

## 1. Serves the notes, right-sized — PASS

Every tier-1 ruling is honored:
- (1) Option A, separate `WEB_DATABASE_URL` with its own users/sessions/refresh tokens, own migrations folder, `app/db` as sole psycopg owner, 503 when unset, native unchanged, local `astrace_web` on 127.0.0.1:54320, Neon never used before landing: D1, D2, D3, D14, D16, Non-goals. Independent identity spaces: Non-goals bullet 3, A3.
- (2) `web_sessions` row shape, client-generated id with idempotent upsert, FK cascade, stateless turn route, PUT after each reply, summary into the same row, GET on boot, per-session delete, account delete cascades, owner-only access, transcripts never logged, no server cap: D3, D5, D6, D7, D10, D13, S2–S7.
- (3) One web birth profile per account; the browser copy is a cache; sign-out clears it; another account sees only its own data: D5, D8, D11, C3, C9, R3.
- (4) Ask once on first sign-in with legacy local data, yes imports and no discards: D8, D9, C4–C6, R4.
- (5) app-native untouched: Non-goals.
- (6) Rule 12 rewritten, the dw-12 "device-local" sentence replaced, rule 6 kept by "no journal events", rule 9 caches stay identity-free in the main db, new code in an accounts-side package and not in `divination/`: D6, D17, Architecture "CLAUDE.md and guard amendments", B3.
- The loop-closing scenario maps to R2/R3/R5 (minted) and U1 (live Google).

Derived scope that goes beyond the notes is small and justified. It is not invented product scope:
- D1: the identical-URL dormancy guard.
- D7: also saving on the user's own line, which adds to "after each finished reply".
- D12: removing dw-6's 50-record client cap. This follows from "kept forever".
- D13: the delete-account UI. This follows from "deleting the account deletes everything".
- D14: stale dw-12 tokens.

## 2. Criteria checkable — PASS

Every D/A/S/B/C/W/G/R criterion names a route, status, table, KV key or rendered string, so each can be checked. Live suites say "a skip is not a pass". U1 is correctly marked [USER-INPUT], and R2 gives a minted-pair stand-in so the loop can still be checked without a person.

## 3. Architecture Contract / epic consistency — PASS

- Rule 11: `app/db` keeps being the only psycopg importer, with a web door and a separate ledger and folder. The amendment is in D17. Rule 12 is rewritten as the notes require. Rule 6 is kept, since `accounts/web/` has no journal import (B3). Rule 9 is untouched. Rule 3: google-auth's single importer is unchanged (B4, existing `test_only_google_module_imports_google_auth`). Rule 10: the dw-10 statelessness of `divination/` is preserved (B3, `test_divination_keeps_no_state`). Rule 14: the new routes are not generative. Rules 1/2/5: the new core module `web-account` is React-free, uses platform ports, is consumed through a barrel, and keeps web fetches in core/platform.
- Epic: the one conflict is the epic dependency rule "no session table and nothing keyed by user". The spec states it and narrows it to `divination/`, citing the tier-1 ruling ("Earlier decisions this revises", "Dependency rules"). "Local only / no Render change" still holds: hosting is a non-goal.

## 4. Non-goals and defaults — PASS

Non-goals are explicit. There is no open-question section, and each point that might have been open has a decided default (D1–D17).

## Non-blocking notes for the plan

1. **Epic file amendment.** The module map should list `pipeline/epics/divination-web.md`: narrow "no session table and nothing keyed by user" to `divination/`, and add dw-12/dw-16 accounts notes at docs-sync. Otherwise the epic contradicts the code.
2. **D3/A3 gating.** These need BOTH databases live. Name the env guard (for example `TEST_DATABASE_URL` alongside `TEST_WEB_DATABASE_URL`) and apply the same localhost-only refusal to the main URL, so a validation run can never touch Neon.
3. **Line refs.** `db/__init__.py` line refs are off by one (`_url` :28, `connect` :37, `health` :48, `apply_migrations` :60). `routes.post_google` is at :245 and `_parse_bearer` at :72. This is cosmetic.
4. **Logout wire row.** The row lists "bearer" but no 401. Say explicitly that logout with a dead or missing bearer is still 204, and write a test for it.
5. **Payload bound.** D5 allows 2000 entries × 20,000 chars, which is about 40 MB per PUT. Consider a total body cap (a 413/422 on the aggregate), or explicitly accept it for a local-first app.
6. **CORS.** `main.py` already uses `allow_methods=["*"]`, so PUT/DELETE preflights from :5173 work. Keep that in mind for R-series runs with `npm run web:server`.
7. **D1 warning.** The single startup warning for identical URLs has no criterion. Either add a caplog assertion to D1 or drop the claim.
8. **Save cadence.** D7 saves on the user line as well as the reply. The ruling only requires after-reply saves, and C8 pins the superset. That is fine, but the plan should make sure coalescing keeps request volume sane when a reply streams bubbles.
9. **Tombstones.** Offline session delete via tombstone (D7) has no vitest criterion. Consider extending C8 or W3 with "DELETE failing → tombstone persisted → retried at next boot before pull".
