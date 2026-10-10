# Plan — dw-10-phenomenon-pills

Spec: `pipeline/specs/dw-10-phenomenon-pills.md` (what + structure). This file is ORDER only. Branch `feature/dw-10-phenomenon-pills` in the primary checkout (serial feature). Python via `conda run -n astrology`; server tests from `server/`.

## Steps

- [x] **1. `tags.py`: the pure checker and scanner.** Files: `server/app/divination/tags.py`, `server/tests/test_divination_tags.py`.
  - Build `KINDS`, `Ground`, `check` and `Scanner` (`feed`/`boundary`/`close`/`failures`) as spec Architecture › Contracts describes.
  - The fallback texts follow spec default 2.
  - Tests cover S1–S7 on fixture F, including the time-unknown variant, a hand-built sky packet and a roll {Pluto, Leo, 7}. S7 is a corpus × every-split property test.
  - **Done when:** `pytest tests/test_divination_tags.py -q` is green.

- [x] **2. Boundary tests.** File: `server/tests/test_boundaries.py`.
  - Add `test_tags_is_pure`. It allows imports of the stdlib, `app.chart.points` and `.persona` only, and bans logging, clock, `re`, llm, prompts and store. Include a planted-violation self-check.
  - Add `test_only_phenomenon_tags_are_read_from_the_reply`. It pins `tags.KINDS`, and checks that the `done` frame's mood and handoff come from `_side_read`'s return values (a source match on the `done` frame line). Write it now; it passes after step 3.
  - `test_handoff_is_never_parsed_from_the_reply` is untouched.
  - **Done when:** both new tests exist; `test_tags_is_pure` is green.

- [x] **3. Turn wiring and the side-read shrink.** Files: `server/app/divination/turn.py`, `render.py`.
  - Build the Ground per turn: `ctx.chart`, the sky packet, and the rolls (this turn's cast, then the transcript's).
  - Route segmenter ops through the scanner, and hold each `bubble` frame until the first non-empty item of its bubble. Renumber the bubble frames actually sent so they stay consecutive.
  - Frame `pill` events. A pill counts toward `sent`.
  - Log each failure as a WARNING carrying only kind and reason.
  - Compute `done.chartRefs` as `to_wire_refs(pill_ref_ids(pills), catalogue)`.
  - Reduce the side read to mood plus handoff. `side_prompt` and `side_schema` get the new signatures, and the `side.refs`, `side.dice` and `side.sky` declarations are deleted.
  - Update the docstrings in both modules: the event grammar now includes `pill`, and the "never parsed" line names the tag exception.
  - **Done when:** `pytest tests/test_divination_turn.py tests/test_boundaries.py -q` runs. The failures that remain are only the dw-3/dw-5/dw-11 side-read tests that step 5 rewrites.

- [x] **4. Prompt fragments.** File: `render.py`.
  - Declare `tags.rules`, `tags.natal`, `tags.sky` and `tags.dice`, and add `tags_section()`. It sits after the dice section and before `lang.*`.
  - `system_prompt` and `turn_messages` take `dice_in_view`, and `turn.py` passes it.
  - Rewrite the plain-words examples in `chart.read`, `self.read` and `sky.read` in tag form.
  - The chart-less, dice-free prompt must stay byte-identical: the golden fixtures `server/tests/fixtures/divination_chartless_{en,zh}.txt` must not change.
  - The "with-chart byte-identical" assertions that pin dw-8/dw-11 sections (`fixtures/divination_pre_dw8/venus_chart_section_en.txt` and so on) are expected to change where `chart.read` changes. Update those tests deliberately and name each one in the step log.
  - **Done when:** `pytest tests/test_divination_render.py -q` passes the golden chart-less test, and a new test for T8 exists and is green.

- [x] **5. Rewrite the superseded server tests (T6, T7, T9).** Files:
  - `server/tests/test_divination_turn.py`: `S3_IDS`, `test_dw3_s3_refs_are_validated`, `test_dw3_s4_cap_end_to_end`, `test_dw3_s5_side_read_gets_the_catalogue`, `test_dw3_s9_every_ref_is_in_the_chart`, and anything else that asserts refs from the side read.
  - `test_divination_render.py`: `test_side_prompt_with_a_catalogue_asks_for_refs`, `test_d11_side_dice_only_when_dice_are_in_view`, and the fragment set in `test_topic_is_registered`.
  - `test_divination_dice.py`: `test_d11_*`.
  - `test_divination_sky.py`: `test_side_sky_*` and `test_k8_*`.
  - `test_divination_roster.py`: the side-read tests, if they assert the catalogue.

  Rewrite them so refs come from pills (T6) and the side read has no refs (T7). Add T1–T5 as new turn tests. T2 uses a provider that blocks on an Event; T3 uses caplog and checks the record contains no birth date or lat/lon.
  - **Done when:** `conda run -n astrology pytest -q` is fully green. Commit: `(feat): dw-10-phenomenon-pills — server checks phenomenon tags into pill events`.

- [x] **6. Core pills and the stream event.** Files:
  - `packages/core/src/divination/pills.ts` (new), plus `types.ts`, `turn.ts` and `index.ts`;
  - `packages/core/src/chart-view/glyphs.ts` and `index.ts` for `ASPECT_TONES`;
  - `app-native/src/architecture.test.ts`, which enumerates `ASPECT_TONES`.

  Tests go in the existing web-divination core test files: `web-divination/src/chat/core-divination.test.ts` for C1 and C2, and a chart-view test for C3.
  - **Done when:** `npm test` (both workspaces) and `npm run typecheck` are green.

- [x] **7. i18n.** Files: `web-divination/src/i18n/en.ts`, `zh.ts`, `web-divination/src/i18n.test.ts`.
  - Add a `pills` namespace: label templates for each kind, the note's aria label, and the "now" mark.
  - Add a `lore` namespace: the ten bodies plus the Ascendant, 12 signs, 12 houses and 5 aspects. The en text is copied from `server/app/dictionary/symbols.py` (PLANETS, SIGNS, HOUSES, ASPECTS, and ANGLES for the Ascendant), trimmed to one clause where a row is long. The zh text is a faithful translation.
  - Bind the lore keys to the core unions in `i18n.test.ts`.
  - **Done when:** the web vitest i18n suite and typecheck are green.

- [x] **8. Web pill rendering and press.** Load `/frontend-design` first. Files:
  - `web-divination/src/chat/Pill.tsx` and `chat/pill-meaning.ts` (both new), plus `useChat.ts`, `ChatPanel.tsx` and `chat.css`;
  - `chart/wheel-activation.ts`, where a chip with empty refs is kept;
  - `log/SessionTranscript.tsx` and `log/SummaryCard.tsx`;
  - `theme/tokens.ts`, only if a new named rgba token is needed.

  What changes:
  - `useChat` pushes each pill into the pacer as `pillToken`.
  - `Slips`, the failure partial and the stored entries render through `PillText`.
  - The note line sits under the letter whose pill is pressed.
  - The chip row renders only for legacy entries.

  Tests (vitest + Testing Library): W1–W6 go in `chat/ChatPanel.test.tsx`, a new `chat/Pill.test.tsx` and `log/*.test.tsx`. Update the dw-4 activation test only where it asserts `showRefs([], chip)`.
  - **Done when:** `npm test` and `npm run typecheck` are green, and app-native's colour, architecture and text-variant guards pass (they run inside the app-native jest suite). Commit: `(feat): dw-10-phenomenon-pills — web renders checked pills inline`.

- [x] **9. CLAUDE.md and docstring amendments (R5).**
  - CLAUDE.md rule 10: add the dw-10 sentence as the spec states it.
  - CLAUDE.md rule 8: record the `lore` namespace.
  - CLAUDE.md rule 1: add `ASPECT_TONES` to the enumeration.
  - Update the core `types.ts` header and the `ChartRef` doc: refs now come from the checked natal pills.
  - **Done when:** each of the three greps finds its amendment, and the suites are still green. Commit in the same commit as step 8, or as its own `(docs)` commit before validating.

- [x] **10. Validating.** Run the full suites: `npm run server:test`, `npm test` and `npm run typecheck`.
  - Real app (R1–R4): start the backend on :8000 with `ANALYSIS_LLM=claude-cli` and `CORS_ALLOW_ORIGINS=http://localhost:5173` (`npm run web:server` with the env var), and run `npm run web`.
  - Drive it with Chrome tools, using birth data F: Venus in en, Venus in zh, then Saturn.
  - Record the rendered reply text, the pills and the WARNING lines in `logs/dw-10-phenomenon-pills/NN-validating.md`.
  - If R4 fails because the model does not comply with tags, tune the `tags.*` fragments (prompt text only) and re-run. Each trip back to implementing counts toward the cycle budget.
  - **Done when:** everything is green and R1–R4 hold, with evidence in the log.

## Acceptance map

| Criterion | Step |
|---|---|
| S1–S7 | 1 |
| S8 | 2 |
| T1–T5 | 3 (code), 5 (tests) |
| T6, T7 | 3, 5 |
| T8 | 4 |
| T9 | 2 (kept), 5 (full suite) |
| C1, C2 | 6 |
| C3 | 6 |
| W1–W6 | 8 (W1's zh label needs 7) |
| W7 | 7, 8 |
| R1–R4 | 10 (needs 1–8) |
| R5 | 9 |

## Risks for the implementer

- **Segmenter output.** It already strips a newline inside a would-be tag and turns it into a bubble op. So a tag broken by a newline arrives as a `boundary()` call, not as a newline char. Test it through `turn_events`, not just the scanner.
- **The bubble cap.** `seg.stopped` can fire while the scanner holds an open tag. `close()` must run BEFORE `done`/the side read, and the held text becomes plain.
- **The pacer and pause length.** The pacer counts the token's characters for pause length. That is harmless (the pause is clamped to 450–1100 ms); do not "fix" it by splitting tokens.
- **Golden fixtures.** The `divination_pre_dw8/` fixtures pin with-chart sections. Changing `chart.read` will break them on purpose. Re-record them ONLY for the sections dw-10 changes, and say so in the log.
- **`splitPills` and zh.** Chinese text can sit directly against a token with no spaces. Rendering must not insert spaces: the pill is inline and the adjacent text runs are kept verbatim.
- **Wheel activation in `ChatPanel`.** The note's owner is found by matching `activation.chip` against `"<entry>:p<n>"`. Entries re-index when a session ends, which dw-4 already clears on shrink.
- **Tier B copy.** Tier B rows mix English and Chinese for POINTS (the nodes). Only PLANETS, SIGNS, HOUSES, ASPECTS and the ANGLES Ascendant row are copied.
