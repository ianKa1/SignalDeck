# dw-2-venus-chat · 03 planning

Date: 2026-09-28. Branch: feature/dw-2-venus-chat. Output: `pipeline/plans/dw-2-venus-chat.md`.

## Read
- CLAUDE.md; PIPELINE.md "Skills per stage" and "Pipeline-mode overrides"; the spec `pipeline/specs/dw-2-venus-chat.md`; the review `logs/dw-2-venus-chat/02-spec-review.md`; the epic file `pipeline/epics/divination-web.md`; and the dw-1 plan (for format and precedents).
- Targeted code reads:
  - `web-divination/{package.json, vite.config.ts, src/app/App.tsx (dw-2 slot l.47), src/platform/boot.ts, src/i18n/en.ts namespaces, src/theme/tokens.ts}`;
  - `packages/core/{package.json exports, src/platform/index.ts}`;
  - `app-native/jest.config.js` (roots);
  - `app-native/src/architecture.test.ts` (WEB_GLOBAL_RE l.102, G3 l.551–570, public-API guard l.890–950);
  - `server/tests/test_boundaries.py` (test list, ask fence l.229–272);
  - `server/tests/test_ask_fitness.py:561` (pin);
  - `server/app/main.py` (lifespan l.65–73, ask_fitness l.385);
  - `server/app/ask/fitness.py` judge_available;
  - `server/app/llm.py` LocalClaudeProvider l.604–660;
  - `server/tests/test_llm_backup_mode.py` (subprocess.run monkeypatch idiom);
  - `claude --help` (stream-json / include-partial-messages exist);
  - uvicorn `load_dotenv` (override=False);
  - `docs/ARCHITECTURE.md` ~l.4257 (core tests run under no runner).

## Skill invoked
- `imple-plan`, under the pipeline-mode override: Steps, Acceptance map and Risks. Code Structure, Calling Sequence, Data Flow and Test Plan are dropped. `architecture-designer` was not re-run.

## Result
- **Steps:** 9. Steps 1–7 are implementing, 8 is validating (real app on :8001 with claude-cli, web on :5173), and 9 is docs-sync.
- **Plan word count:** 1,509 words (`wc -w`), within the ~2,000 budget.
- **Acceptance map:** covers all 28 criteria (S1–S11, C1–C5, W1–W5, A1–A7).
- **Review notes settled:**
  - unanswered user entry: send stays enabled, and the server merges adjacent same-role entries;
  - S11: a named regex, made a pytest test;
  - disconnect: a close-propagation unit test, plus a threadpool risk note.

## Deviations to journal
- **D1:** core seam tests (C1–C3) live in `web-divination/src` vitest, because `packages/core/src/**/*.test.ts` has no runner.
- **D2:** `render.turn_messages` merges adjacent same-role entries and drops leading persona entries.
- **D3:** a temporary `@public-intent domain` marker on the core divination barrel between steps 5 and 7.
- **D4:** the S11 grep is implemented as the pytest `test_divination_keeps_no_state`.

## Transition
spec-approved → implementing.
