# 04 — spec-review (round 2)

**Verdict: PASS** (B1 is fixed and no blocking issues remain)

Checked against the worktree at 4a74364: `platform/api.ts` `apiFetch`, `platform/poll.ts` `postJson`, CLAUDE.md:41, and the epic's "Dependency rules for this epic" (:534).

## B1: fixed
D2 now gives the order correctly. FastAPI parses the JSON body first, then runs the decorator dependency before schema validation and before the handler. Malformed JSON gets 422 `json_invalid` from the framework, and no work is done. S2 pins the two cases:
- a well-formed `{}` sent without a bearer gets 401 (not 422);
- malformed JSON sent without a bearer gets 422, and the zero-call spies stay at zero.

Both are literal and testable.

## Round-1 notes
- **N1 (addressed):** D4 and the reuse table now name `apiFetch`. With `auth:true`, `postJson` sends through `apiFetch`, so refresh-once lives in one place. `postJson` adds only the timeout/abort composition and the final `reportUnauthorized()`. The stale `apiFetch` header comment is flagged for update. Verified: `apiFetch` spreads `init`, so the `signal` and `Content-Type` survive the bearer `Headers` merge.
- **N2 (addressed):** the prompt lab is in D6 and in the module map, with an override stub.
- **N3 (half addressed):** D5 states that the subscription is inert on native. The double-clear question is still not stated. When the provider's own failed refresh already clears the tokens, the handler calls `clear()` again. That is harmless if `clear` is idempotent. The plan should confirm this. It does not block.
- **N4 (addressed):** `opts` is an options object, and the plan may collapse the trailing parameters. Native callers stay byte-identical, and C1 covers that.
- **N5 (addressed):** D4 says the first response's chunks are released before the retry.
- **N6 (addressed):** C5 lists the wipe keys literally.
- **N7 (addressed):** S1 now spies on `persona_voice.cached_for`.

## Checklist
1. **Serves the notes and is right-sized: yes.** The spec covers the four routes (the complete web-only set, as D3 argues), 401 before chart or LLM work, 503 while the web door is dormant, identity-free caches, unchanged native routes, the client bearer, and 401 treated as signed out. The loop-closing check matches R1 and R2. Nothing is invented.
2. **Criteria checkable: yes.** S1–S6 use named spies, status codes and a planted-route red test. C1–C5 are vitest assertions on headers, retries and storage keys. R1–R3 are curl, network-log and database-row steps on a local backend.
3. **No contract violation, consistent with the epic: yes.** The check lives only in the HTTP layer (`main.py` plus `accounts/web`), as a decorator dependency whose value no handler receives. `divination/` stays free of accounts, satisfying rules 9 and 10. The core signal travels through `platform`, so core `divination` never imports `account`. Rules 10 and 12, the CLAUDE.md:41 "UI gate" sentence and the epic's dependency rules are all amended in D7. The dw-12 "stay unauthenticated" choice is a tier-3 loop decision. The spec correctly lists it as superseded by this tier-2 queue entry.
4. **Non-goals and decided defaults: yes.** The spec leaves out native and shared routes, quotas, billing, deploy work and wire changes. Every open point has a decided default.

## Non-blocking
- **N3 residue:** the plan should confirm that the provider's `clear()` is idempotent (web `platform/auth.ts:104`), so the second clear does no harm.
- On the web, `apiFetch` defaults `credentials:'same-origin'` for the cross-origin absolute base. That sends no cookies, which is harmless because the check is bearer-only. Mention it in the plan so nobody "fixes" it to `include`.
- S4's "byte-identical to the overridden-dependency response" for `/turn` requires the fake `stream_turn` to be deterministic. The plan should say this.
