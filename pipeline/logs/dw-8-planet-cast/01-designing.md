# 01 designing — dw-8-planet-cast

Stage worker for the coordinator, base d2aaf12 (feature/divination_web). QUEUE.md and DECISIONS.md were not edited, and nothing was committed.

## Reads
- CLAUDE.md (from disk, including rules 10 and 14 as amended by dw-7).
- PIPELINE.md: Skills per stage, pipeline-mode overrides, epic files, spec requirements, auto spec review, and parallel waves.
- QUEUE.md: the round-2 comment and the dw-8, dw-9, dw-11 and dw-12 entries.
- The epic file `epics/divination-web.md`.
- The dw-7 spec and its final review.
- DECISIONS.md from line 3405 ("divination-web round 2") to the end.
- For overlap only:
  - the dw-9 spec, grepped for its shared files;
  - the dw-9 worktree's `venus.txt` and `venus-dice.txt`, which have no length lines and a character-neutral dice brief;
  - the dw-12 spec's shared-files section, which shows it does not touch App.tsx, main.py or models.py;
  - dw-12's `05-validating.md`, for the throwaway Postgres cluster and the recipe for minting a token pair.
- Targeted server reads:
  - `divination/persona.py`, `render.py`, `turn.py`, `voice.py` and `voice_role.txt`;
  - `personas/*`, and a grep of `summary_role.txt`;
  - `models.py:320-454`, main.py's divination routes, `generation.py`;
  - the persona-specific asserts in `test_divination_*` and the test names in `test_boundaries.py`.
- Targeted core reads: `divination/types.ts`, `turn.ts`, `transcript.ts` (sanitize), `session-log.ts` (parseRecord), `persona.ts` (exports) and `index.ts`.
- Targeted web reads:
  - `App.tsx`, `Header.tsx`, `useChat.ts`, `usePersona.ts`, `PersonaHeader.tsx`;
  - `ChatPanel.tsx` (head and render), `SessionBar.tsx`;
  - `i18n/en.ts` (the log, chat and persona namespaces);
  - `theme/tokens.ts`, `apply.ts`, and a grep for `var(--venus` (chat.css, persona.css, log.css, wheel.css).
- Ran the real chart A sheets for the six planets (conda env), which are the S3 values.

## Skills (in order)
1. `frontend-design`: the picker is a 2×3 grid of almanac plates with wax-seal glyphs in each character's ink, quoted example marginalia and an engraved placement line. It has a staggered reveal. Each character gets its chrome through a scoped `--char` variable, set by `data-persona` on the shell, so the wheel glow follows the active character. The handoff is a forwarding slip in the target character's ink.
2. `feature-spec` (pipeline mode): Goal, Non-goals, Decided defaults (11) and Acceptance Criteria.
3. `architecture-designer` (pipeline mode): reuse at file:line, the module map, contracts, the exact wire delta, forbidden edges, guard and CLAUDE.md amendments, and composition with dw-9 and dw-12. Migration Steps were skipped.

## Choices
- **One list.** `persona.PERSONA_PLANETS` has six entries in queue order. The models `DivinationPersona` literal and core `PERSONA_IDS` mirror it under pinning tests.
- **Five new base texts.** Jupiter must name the risk, and Mercury asks for the pasted words. Both are enforced in the prompt and verified on the real app.
- **Per-persona `focus.<id>`.** `chart.read` gets a `{focus}` slot, so Venus's chart section stays byte-identical. `self.read` is templated on the planet.
- **D for all characters** in a shared `roster.rules` fragment. The D line moves out of `self.read`. It comes with `roster.list` (the domains, and pointing the person to another character) and `roster.timing` (the pattern, not the timing; dw-11 owns any change to it). The chart-less goldens change by exactly those three fragments.
- **Dice for all six.** `venus-dice.txt` is renamed to `dice.txt` and registered as `dice.brief`; the brief was already character-neutral.
- **Handoff** is a side-read enum field (the other five ids or "none"). It is validated by the one shaper `to_wire_handoff`, and `done` gains `handoff: id|null`. It is judged on chat turns only; cast and deeper give null. The client keeps it device-only on the entry. A tap switches character and prefills the question, and nothing is auto-sent.
- **The personalised line** comes from a new PURE `POST /api/divination/sheets`: six sheets' facts, no LLM, no enqueue, no store, no provider gate. It is rendered through `placementText`. Voice jobs are still ensured only for the active character.
- **The active character** is stored on KV at `astrology.divination.active.v1`. Transcripts reuse dw-2's per-persona keys. Switching clears the activation and stops an in-flight turn.
- **Colour.** Tokens `persona`/`personaGhost` are `Record<PersonaId,…>`, and `venus`/`venusGhost` fold into them. Every `var(--venus…)` becomes `var(--char…)`.
- **Summary and voice role texts** are made planet-neutral. Neither VERSION is bumped, the keys are unchanged, and the FINGERPRINT records the text as provenance.
- **Real app past the dw-12 gate**: a throwaway local Postgres, a backend started with explicit env and no `--env-file`, and a pair minted per dw-12's recipe into the auth KV keys. It never uses the remote `.env` database.

## Word counts (wc -w)
- WHAT (Goal, Non-goals, Decided defaults): 1418
- Architecture: 1271
- Acceptance Criteria (exempt from the budget): 1390

## Shared files (landing surface)
- `render.py` and `turn.py` (dw-9)
- `ChatPanel.tsx` and `chat.css` (dw-9)
- `models.py` (dw-9 `action`)
- `personas/venus-dice.txt` → `dice.txt` (dw-9 edited line 11)
- `i18n/en.ts` and `zh.ts` (dw-9, dw-12)
- `test_boundaries.py` (dw-12)
- `main.py`: one appended route, not touched by dw-9 or dw-12
- CLAUDE.md rule 10
- The chart-less golden fixtures, re-recorded after dw-9's re-record
- dw-11 (parallel) will likely touch `render.py`/`turn.py`'s context path and `roster.timing`.

No migration.

## Transition
designing → spec-review (spec at `pipeline/specs/dw-8-planet-cast.md`).
