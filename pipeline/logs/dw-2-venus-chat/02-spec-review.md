# 02 spec-review (round 1) — fresh-context reviewer

**Verdict: PASS**

Inputs read: the QUEUE entry `dw-2-venus-chat` and the DIVINATION WEB EPIC comment, `pipeline/specs/dw-2-venus-chat.md`, `pipeline/epics/divination-web.md`, CLAUDE.md, and the PIPELINE.md sections (Spec requirements, Auto spec review, Pipeline-mode overrides). I also checked DECISIONS.md 2026-09-28 "divination-web epic · user rulings" and made targeted code reads to verify the reuse claims.

## Checklist

**1. Serves the notes, right-sized: yes.** Every note item maps to the spec:
- streamed SSE turn with `delta`/`done`/`error`;
- `llm.stream_turn` for all providers, including claude-cli `stream-json`;
- `app/divination/` with `personas/venus.txt` (register_topic, fingerprinted), `render.py` and `turn.py`;
- the rule-14 exception, pinned and bounded;
- the core `streamTurn` async iterator and the transcript on KV;
- the stream reader as a core/platform port with a web adapter;
- the panel beside the wheel, with typing state, stop and retry;
- both loop-closure checks: live typing and survival across a reload.

`mood` comes from the notes (`done {mood, …}`). Producing it through a separate post-reply `generate_sections` "side read" honours "never parsed out of prose". Nothing out of scope was added, and the dw-3 to dw-6 items are explicitly excluded.

**2. Criteria are checkable: yes.**
- S1–S11 run against fake providers.
- C1–C5 are jest/guard tests with planted-violation checks.
- W1–W5 run in vitest with a fake StreamPost.
- A1–A7 are real-app checks with concrete observables: computed colour, at least 3 DOM samples 200 ms or more apart, the network panel, reload, and backend stop/restart.

A2's "first-person Venus voice" needs judgement, but it is anchored by objective sub-checks: paragraph count and no markdown symbols.

**3. Architecture contract and epic consistency: yes.**
- **Rule 1:** extended by a new core guard (`ReadableStream`/`TextDecoder`/`getReader(`). `AbortSignal` is already used in core (`platform/poll.ts`).
- **Rule 3:** SDK use stays in `llm.py`.
- **Rule 5:** the network stays in core and in `web-divination/src/platform`. G3 in `architecture.test.ts:565` already allows this.
- **Rules 6 and 9:** no server state and no journal write.
- **Rule 10:** new Tier C fence, amendment stated.
- **Rule 13:** new `venus` token in `theme/tokens.ts`.
- **Rule 14:** "ONE" becomes "TWO". The pin moves to test_boundaries, and `GENERATE_ON_REQUEST_RE` is widened.

Everything matches the epic's target modules, event grammar and dependency rules. The spec is stricter than the epic, because it forbids interpretation outright; the epic's restate-helper exception is left to dw-3. All CLAUDE.md edits are listed as same-commit amendments. Verified reuse refs:
- `llm.py`: :374, :393, :398, :449, :559, :668
- `prompts.py`: :93, :118, :129
- `ask/fitness.py`: :191, :228, :251, :254, :266
- `fitness_prompt.py`: :21-33
- `test_ask_fitness.py:561`
- `test_boundaries.py`: :102, :162, :179, :233-272
- `architecture.test.ts:102` family
- the dw-2 slot comment in `App.tsx` and `VITE_API_BASE` in `boot.ts`
- the web CSS variables `--text-dim`, `--font-body` and `--line-soft`, which exist

**4. Non-goals and defaults: yes.** The Non-goals section is explicit. There is no Open Questions section. Limits, timeouts, failure codes, storage key, client states and local-run ports all have decided defaults.

## Non-blocking notes (implementer or plan may settle)

- **Consecutive user entries.** A Stop before any text, an error, or a reload leaves a trailing unanswered user entry. The spec does not say whether the user may then send a *new* message instead of pressing Retry. If they can, the wire carries two consecutive `user` entries. Anthropic now merges these and OpenAI accepts them, so this is not a defect. The plan should still pick one behaviour: either disable send while Retry is pending, or allow it and let `render.turn_messages` merge adjacent same-role entries.
- **S11 is loosely worded.** Its "grep: no … table, write or insert statement" does not say what to grep for. The plan should name the pattern, for example `CREATE TABLE|INSERT|sqlite3|app\.db|app\.journal`. The S9 fence already forbids `db` and `journal`.
- **Client disconnect is untested.** Nothing checks that a client disconnect sets the cancel flag and closes the provider generator. That is acceptable, since A6 exercises Stop end to end, but it is worth listing as an implementer risk: Starlette runs sync-iterator streaming in a threadpool.

## Pipeline-mode shape and budgets (non-blocking)

- **Sections:** Goal, Non-goals, Decided defaults, Architecture and Acceptance Criteria. The shape is correct.
- **Goal:** 4 lines (lines 9–12), one over the 3-line limit. Cosmetic.
- **Word counts** (designing log): 1,158 words excluding the criteria, 1,420 for Architecture, 964 for the criteria. All within the ~1,500 budgets.
- **Restating:** minimal. The non-goal on server state and the wire table restate epic facts. The wire table is justified, because the epic defers the exact shapes to dw-2.
