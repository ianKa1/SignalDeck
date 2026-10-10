# 02 — spec-review (round 1)

**Verdict: FAIL** (one blocking precision defect; otherwise sound and right-sized)

Verified against the worktree at 4a74364 and FastAPI 0.139.2 in the `astrology` env.

## Checklist

1. **Serves the notes, right-sized: yes.** It covers all four routes, 401 before chart/LLM work, 503 when the web db is dormant (`service.user_for` → `_require_web` runs before the token check, service.py:105), identity-free caches, native routes unchanged, and the client sending the bearer and treating 401 as signed out. It adds no scope. Route set: the only non-`/api/web` paths named in `web-divination/src` are `/api/chart` (shared with native, no LLM) and `/api/auth/google`, which appears only in a comment in `platform/google.ts`. Core's divination module calls only the four `/api/divination/*` paths. The claim in D3 holds. The dw-12 decision is correctly listed under "Earlier decisions this revises" (tier 2 over tier 3).
2. **Criteria checkable: mostly.** See B1.
3. **Architecture Contract: no violation.** The check stays in `main.py` and `accounts/web`. `divination/` still imports no accounts (B3), and no identity reaches a key (rule 9). The core signal goes through `platform`, so core `divination` never imports `account`. Rules 10 and 12 are amended in D7, along with the epic's dependency rules.
4. **Non-goals stated; defaults decided: yes.**

## BLOCKING

**B1 — D2 misstates FastAPI's order, and S2 is ambiguous because of it.** In `fastapi/routing.py` (0.139.2, lines ~418-470) the handler READS and JSON-parses the body BEFORE `solve_dependencies`. Malformed JSON raises `RequestValidationError` (`json_invalid`, 422) and a non-JSON parse failure raises a 400. Both happen before any dependency runs. Inside `solve_dependencies` (dependencies/utils.py ~628-712), sub-dependencies (including decorator `dependencies=[...]`) run first and raise immediately. Body *schema* validation errors are collected afterwards. So:
- well-formed JSON that fails the schema (e.g. `{}` or a bad `persona`), sent with no bearer → **401** ✔ (the intent holds);
- malformed JSON (`not json`), sent with no bearer → **422**, not 401.

No chart or LLM work happens in either case, so the user's intent is met. But D2's sentence "resolves decorator dependencies before it reads the body" is false. S2's "an invalid body without a bearer → 401 (not 422)" would fail an acceptance tester who sends unparseable bytes. Fix: reword D2 as "before body validation (the body is parsed as JSON first; a malformed-JSON body is 422 with no dependency run and no work done)". Pin S2 to "a well-formed JSON body failing the request schema (e.g. `{}`) → 401". Optionally add "malformed JSON → 422, zero-call spies" so the behaviour is recorded.

## Non-blocking notes (fold in on the redesign)

- **N1 — duplicate bearer logic (D4).** Core already has the exact mechanism: `platform/api.ts` `apiFetch` :41 injects `Authorization: Bearer` from the provider and refreshes ONCE on a 401. The spec's reuse table omits it, and D4 describes re-implementing it inside `postJson`. Say that `postJson(opts.auth)` shares or delegates to `apiFetch`'s send/refresh path, adding only the timeout signal and the final `reportUnauthorized()`, so refresh-once has one home. `apiFetch`'s header comment ("identity-free seams go through postJson … bearer auth stays a platform concern of the account edge") becomes stale and belongs in the module map.
- **N2 — prompt lab breaks silently.** `server/tests/prompt_lab/divination_chat_lab.py:278-317` drives `/api/divination/persona` and `/turn` through an in-process `TestClient`. After this change it gets 503/401. It is not pytest-collected, so no suite catches it. Add it to the module map with a `dependency_overrides` stub (D6's approach).
- **N3 — native side effect of D5.** `google-session.ts` is exported through the `@astrace/core/account` barrel (index.ts:30-39). A module-load `onUnauthorized` subscription therefore also runs on native. That is harmless, because only `auth:true` callers report and native has none, but state it. Also confirm C2's "tokens cleared" doesn't double-clear when the provider's own refresh failure already cleared.
- **N4 — native `postJson` callers** (`analysis/service.ts`:94, `deck/service.ts`:150, `transit-day/service.ts`:182, `transit-day/archive.ts`:231, `ask/fitness.ts`:90) pass no 5th argument. The added optional `opts` leaves them source- and byte-identical ✔ (C1 covers the no-header path). The divination callers must pass `undefined` for `timeoutMs`. That is fine, but an options-object-only form would be cleaner.
- **N5 — stream retry.** On a 401 retry in `streamTurn`, the first response's `chunks` are never read. Say that the plan must release them (the web adapter's `reader.cancel()` only runs if iteration starts).
- **N6 — labels.** The "Core + web (vitest)" heading is right: core divination tests live under `web-divination/src/**/core-*.test.ts`. C5's "dw-16's wipe keys absent" should name the keys (`astrology.web.owner.v1`, `astrology.web.dirty.v1`, session/profile keys) so the check is literal.
- **N7 — S1 spies.** The turn route reads `persona_voice.cached_for` (main.py:467), not `cached_voice`. Add it to S1's spy list.
