# 02 spec-review (round 1) — fresh-context reviewer

**Verdict: PASS**

Inputs read: QUEUE `dw-6-session-log` + the DIVINATION WEB EPIC comment, `pipeline/specs/dw-6-session-log.md`, `pipeline/epics/divination-web.md`, CLAUDE.md (from disk), PIPELINE.md (Spec requirements, Auto spec review, pipeline-mode overrides). I checked the code claims with targeted reads on `feature/divination_web`.

## Claims checked against code
- **2026-08-13 ruling (the fingerprint is not part of the key).** Confirmed. `prompts.py:21-26` says "THE FINGERPRINT IS PROVENANCE, NEVER KEY MATERIAL". `interpretation/service.py:88-94` keeps the fingerprint out of the key and records it beside the row. `ask/store.py:6-7` does the same. D8's departure from the epic's "a persona edit changes the cache key" is justified by the code and properly flagged for docs-sync.
- **Migrations.** The highest is `010_analysis_doctrine.sql`, and the runner globs the files in sorted order. `011_divination_summary.sql` is the correct next number, and neither dw-4 nor dw-5 adds a migration.
- **Other shapes.** The `generation.ensure_transit_reading` shape (key known → enqueue → return key), the `main.py` `/api/analysis` 200/202/502 shape, `turn_available`, and `DivinationTranscriptEntry` (role, text ≤8000; list cap 40) all match. The `interpretation/store.py` shape matches too (`db.connect`, `doctrine` column, `generatedAtUtc`↔`created_at`).
- **Boundary tests.** `DIVINATION_FORBIDDEN_RE`, `_divination_fence_offenders` (the per-file strip already used for the restate borrow), `test_divination_keeps_no_state`, `test_no_tier_imports_divination` (main.py only today), `GENERATE_ON_REQUEST_RE` and `test_main_names_the_synchronous_exceptions` are as described. The planned changes keep the fence regex unchanged and exempt exactly one file/line, with a self-check for each. That is not a weakening.
- **dw-5 compatibility.** dw-5 adds `dice: DivinationDice | None = None` on the server and `cast` on user entries only on the device. `toWire` never sends `cast`. So S1's "exactly role and text under exclude_none" still holds after dw-5 lands, and D7's claim that the dice reach the summary with no dw-6 edit is right.
- **Clearing the transcript.** `useChat` reads the transcript through `useSyncExternalStore(subscribeTranscript…)`, so `clearTranscript` notifying listeners empties the chat without touching `chat/`.
- **Chip names.** dw-4 keeps the chips' accessible names unchanged, so W2's "as in the chat chips" is stable.

## Checklist
1. **Serves the notes, right-sized: yes.** Every note item is covered: End → POST summary, content-keyed SQLite+PG store, job, 200/202 poll, device-local KV log, history list, read-only reopen. The emotional card image is a non-goal, as the notes say. Nothing is invented.
2. **Checkable criteria: yes.** Each criterion is checkable by a test or by using the app. The 202→poll→200 path is covered by S3/C4/A1, reload persistence by C7/C8/A3, and resume after a server restart by C6/A4.
3. **Architecture contract: holds.** Rule 6: the journal is untouched. Rule 9: the store is content-keyed and identity-free, with the column list pinned. Rule 11: the importer list is amended. Rule 14: an ordinary job, no new exception. Rule 10 on disk says divination "keeps NO server state… nothing imports it but main.py". The spec amends it in the same commit, the QUEUE notes and the epic target modules direct this, and the fence and state pins get narrower exemptions with self-checks.
4. **Non-goals and defaults: yes.** Non-goals are explicit, D1–D13 settle every open point, and the shared-file footprint is stated (D13 + Shared files).

## Non-blocking refinements
- **Rule 14 wording.** Rule 14 says generation.py "may import interpretation AND cards". Once generation imports divination that sentence is incomplete, and "Rule 14 needs no edit" leaves it stale. Add "and divination (the summary job)" as a half-clause.
- **Stored fields.** The store's `summary` column is described as "the three generated fields". State outright that `generatedAtUtc` round-trips through `created_at` (as in `interpretation/store`), so that S2's equal-body second POST is obviously satisfied.
- **Key collisions.** D6 means two >40-entry sessions that differ only in the dropped middle entries share one key and one summary. Accept this in a sentence.
- **Retry during cooldown.** The jobs queue holds a failed key for a cooldown, so Retry inside that window gets 502 again. W4 only checks that Retry re-POSTs, which is fine, but a one-line note in D9 would stop an implementer from treating it as a bug.
- **Summary wording.** A1's "restates what was asked" is a judgement call. It is acceptable for a real-app check.
