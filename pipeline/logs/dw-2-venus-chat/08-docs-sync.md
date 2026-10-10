# 08 — docs-sync (dw-2-venus-chat)

Date: 2026-09-28. Skill: `update-architecture-doc` (baseline f02e88b, the last commit touching docs/ARCHITECTURE.md; the diff since then is exactly dw-2's commits).

## docs/ARCHITECTURE.md (surgical)
- Overview, web-divination bullet: the Venus chat + SSE turn + device-only transcript.
- Repo tree: core `platform/` (stream.ts, sse.ts) and `divination/`; web `platform/stream.ts`, `chat/`; server `divination/` (Tier C fourth package).
- Guards paragraph: architecture.test.ts is now 38 tests; the core stream guard; `deck/ask/divination` named in the barrel coverage.
- Server layering paragraph: the divination fence, the no-state pin, and TWO synchronous exceptions pinned by `test_boundaries.py::test_main_names_the_synchronous_exceptions` (the old test name is gone everywhere).
- `core/platform`: Seam 4 `stream.ts` and `sse.ts` bullets.
- New section `core/divination`.
- server `llm.py`: the Provider ABC's `stream` + `stream_turn` per provider.
- ask section: now "the FIRST of rule 14's two synchronous exceptions"; a new "Tier C fourth package — divination/" block.
- web-divination section: boot's `configureStreamPost`, the side slot, a new Chat bullet, tokens, the i18n `chat` namespace binding, tests.
- Data flow: the chat chain. Feature docs: a dw-2 entry. The ask-fitness-judge feature entry wording fixed.
- Also `server/app/ARCHITECTURE.md`: delivery now has TWO synchronous exceptions under the new pin name; `llm.py` consumers include divination.
- Confirmed still accurate without edit: deployment, native sections, data-core chart sections.

## docs/features/dw-2-venus-chat.md
Written as a frozen as-built snapshot: what it does, what was built (server/core/web), validation, deviations D1–D9, known limitations.

## pipeline/epics/divination-web.md (not committed; pipeline/)
- "Built so far": a dw-2 block plus "Hooks dw-2 leaves for later entries" (the dw-3 natal-context hook in `turn_messages`, the `chartRefs`/`dice` additive events, FINGERPRINT for dw-6, `chat/` for chips and the dice card).
- Reuse map: the core platform line now names the stream port.
- Target modules: dw-2 items ticked ✔ with what actually landed (the claude-cli `--system-prompt`).
- Event grammar: exact dw-2 payloads, the keepalive comments, the non-stream answers and the client-only codes.

## Transition
docs-sync → accepting (coordinator).

## Commit
- `5e72f50 (docs): dw-2-venus-chat — sync the architecture docs …` (docs/ARCHITECTURE.md + server/app/ARCHITECTURE.md).
- `docs/features/dw-2-venus-chat.md` is written on disk but NOT committed: `.gitignore:17` ignores `docs/features/` (0 tracked files there, dw-1's too). Not force-added, following the no-force-add rule.
