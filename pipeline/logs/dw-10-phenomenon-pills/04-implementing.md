# dw-10-phenomenon-pills — 04 implementing (2026-09-29)

Worker run, primary checkout, branch `feature/dw-10-phenomenon-pills` (from `bfcd0f7`).

## Steps 1–5 (server)

### Step 1 — `server/app/divination/tags.py` + `tests/test_divination_tags.py`
- Pure module: `OPEN`/`CLOSE`, `MAX_BODY = 64`, `KINDS`, `DICE_FACES`, `Ground(chart, sky, rolls)`, `check(body, ground) -> (pill|None, fallback, reason)`, `tag_kind(body)`, `Scanner(ground).feed/boundary/close/failures`.
- Checks are equality against the ground's own values (case-insensitive); the pill carries the ground's canonical spelling (chart order for aspects). No sign table is needed in tags.py — the chart/roll IS the vocabulary for signs and aspect types; body names canonicalise through `PLANET_NAMES` / `persona.SHEET_POINTS`.
- Reasons used: `ok`, `malformed`, `no-chart`, `not-in-chart`, `time-unknown`, `no-sky`, `not-in-sky`, `no-roll`, `not-rolled`.
- A log line may carry only `tag_kind(body)` (one of KINDS or `unknown`), never the model's text.
- `conda run -n astrology pytest tests/test_divination_tags.py -q` → `30 passed in 0.31s`.

### Step 2 — boundary tests (`tests/test_boundaries.py`)
- `test_tags_is_pure`: non-stdlib imports limited to `app.chart.points` and `.persona`; stdlib `logging`, `re`, `time`, `datetime`, `random`, `sqlite3` banned; names `getLogger`, `datetime.now`, `utcnow`, `time.time`, `monotonic`, `generate_sections`, `stream_turn`, `register_topic` banned. Seven planted-violation self-checks.
- `test_only_phenomenon_tags_are_read_from_the_reply`: pins `tags.KINDS`; `turn.py` has exactly one `frame("done", …)`, it is `{"mood": mood, "chartRefs": refs, "handoff": handoff}`, and `mood, handoff = yield from _side_read(` precedes it; tags.py names neither `mood` nor `handoff`. Self-checks plant a pill-derived mood and a second done frame.
- First run (before step 3), as the plan expected: `test_tags_is_pure` PASSED, `test_only_phenomenon_tags_are_read_from_the_reply` FAILED (`assert _done_sources_ok(turn_src)` — turn.py still unpacked three values). Green after step 3.
- `test_handoff_is_never_parsed_from_the_reply` untouched.

### Step 3 — turn wiring
- `turn.py`: `Ground(ctx.chart, sky_packet, rolls)` with rolls = this turn's cast (`dice.to_wire`) then transcript `dice`; segmenter ops → `scanner.feed`/`boundary()`; `scanner.close()` at `_END` or at the cap (before the side read). New `_Framer` holds a bubble frame until the bubble's first item and renumbers consecutively (bubble never first). Pills count as sent. One WARNING per failure: `"divination turn: tag %s failed: %s"`. `done.chartRefs = render.to_wire_refs(render.pill_ref_ids(framer.pills), catalogue)`. `_side_read` returns `(mood, handoff)`. Docstring grammar gains `pill`; the "never parsed" paragraph names the tag exception.
- `render.py`: `side.refs`, `side.dice`, `side.sky` declarations deleted; `side_prompt(message, reply, lang, persona, handoff)`; `side_schema(handoff=None)`; `pill_ref_ids(pills)`.
- Run after step 3 (divination suites): 28 failures, all in the dw-3/dw-5/dw-8/dw-11 side-read/golden-slice tests step 5 rewrites; boundary tests all green.

### Step 4 — prompt fragments
- `tags.rules`, `tags.natal`, `tags.sky`, `tags.dice` declared; `TAG_FRAGMENTS`; `tags_section(has_chart, has_sky, has_dice)` between the dice section and `lang.*`. `system_prompt`/`turn_messages` gain `dice_in_view`; turn.py passes it.
- Examples rewritten in tag form: `chart.read` (`your ⟦placement:Venus|Taurus|10⟧`, `your ⟦aspect:Venus|opposition|Pluto⟧`), `self.read` (`⟦placement:{planet}|Capricorn|4⟧, and ⟦aspect:{planet}|square|Pluto⟧ is behind it`; `⟦placement:{planet}|Scorpio⟧`), `sky.read` (`⟦transit:Saturn|square|Mars⟧`).
- Golden fixtures `fixtures/divination_chartless_{en,zh}.txt`: NOT changed, still equal.
- `fixtures/divination_pre_dw8/*`: NOT re-recorded. `test_divination_roster.py::test_s5_venus_chart_section_is_byte_identical` now slices up to the tag block and compares after swapping the one rewritten `chart.read` example line back (`DW10_CHART_EXAMPLE` → `PRE_DW10_CHART_EXAMPLE`); `test_s6_venus_cast_dice_section_is_byte_identical` slices up to the tag block and is byte-identical as before.

### Step 5 — superseded tests rewritten (named)
- `test_divination_turn.py`: `test_s1_deltas_then_done_in_order` (schema call), `_chart_json` (raw_decode: the tag block now follows the chart JSON), `test_dw3_s2_no_chart` (schema call), `test_dw3_s3_refs_are_validated` → `test_dw10_t6_side_read_refs_are_ignored`, `test_dw3_s4_cap_end_to_end` → `test_dw10_t6_refs_are_the_natal_pills_capped`, new `test_dw10_t6_refs_dedupe_in_order_and_skip_non_natal`, `test_dw3_s5_side_read_gets_the_catalogue` → `test_dw10_t7_side_read_has_no_refs_and_no_catalogue`, `test_dw3_s8_time_unknown` (asserts tags.natal instead of the enum), `test_dw3_s9_every_ref_is_in_the_chart` → `test_dw10_every_ref_is_in_the_chart` (refs from pills). New: `test_dw10_t1_a_pill_between_two_deltas` (tag split across chunks), `test_dw10_t2_text_before_an_open_tag_is_sent_at_once` (provider blocked on an Event), `test_dw10_t3_a_planted_tag_is_plain_text_and_a_warning` (caplog; no 1990/06-15/39.9/116.4/Beijing/Shanghai in the record), `test_dw10_t5_bubble_frame_right_before_a_pill`, `test_dw10_t5_only_a_pill_is_a_reply`, `test_dw10_t5_an_emptied_bubble_collapses`, `test_dw10_t5_a_tag_cut_by_a_line_break_is_plain` (segmenter → boundary path), `test_dw10_t4_dice_and_transcript_rolls`. T4 (no bracket in any delta) is asserted in T1, T3, T5, dice.
- `test_divination_render.py`: `test_topic_is_registered` fragment set (−side.refs/side.dice/side.sky, +tags.*), `_chart_json`/`_dice_json` raw_decode, `test_s5_catalogue…` schema half, `test_side_prompt_carries_the_exchange` (call), `test_side_prompt_with_a_catalogue_asks_for_refs` → `test_dw10_t7_side_prompt_never_asks_for_refs`, `test_d10…` (dropped the side.dice line), `test_d11_side_dice_only_when_dice_are_in_view` → `test_dw10_tags_dice_whenever_dice_are_in_view`. New: `test_dw10_t8_tag_block_by_ground`, `test_dw10_tags_section_is_empty_without_a_ground`, `test_dw10_examples_are_in_tag_form`, `test_dw10_pill_ref_ids`, `test_dw10_t8_chartless_chat_prompts_match_the_goldens` (all six personas × en/zh: the golden with only the persona base swapped).
- `test_divination_dice.py`: `_dice_json` raw_decode; `test_d11_side_dice_whenever_dice_are_in_view` → `test_dw10_tags_dice_whenever_dice_are_in_view`; `test_d11_dice_free_chat_side_read_is_unchanged` (no side.refs).
- `test_divination_sky.py`: `test_side_sky_is_appended_only_with_a_sky_and_a_catalogue` → `test_dw10_side_sky_is_retired`; `test_k8_side_read_is_told_about_the_sky` → `test_k8_the_sky_prompt_carries_tags_sky`.
- `test_divination_roster.py`: S5/S6 slices (above), `test_s7_side_role_names_the_persona_neutrally` (call).
- Two of my own test bugs fixed on the way: the builder puts a sky section in any persona's prompt when handed a packet (the persona gate is the route's `sky_context`), and the scripted RNG serves one cast only.

`conda run -n astrology pytest -q` → `1339 passed, 50 skipped, 1 warning in 112.24s`.

Commit `b29ad9c` — `(feat): dw-10-phenomenon-pills — server checks phenomenon tags into pill events`.

## Deviation found at step 6 — transit tags limited to the five Ptolemaic types
- `chart/transit/policy.py:23` adds `quincunx` to transit aspect types, so a sky packet episode can be a quincunx. Core's `AspectType` (and `ASPECT_TONES`, `ASPECT_GLYPHS`) have five types; a quincunx pill would fail `isPill` in core and be DROPPED — the model's words would vanish.
- Decision: `tags.PILL_ASPECT_TYPES` = the five; a transit tag with any other type fails (`not-in-sky`, plain text + WARNING). `tags.sky` tells the model a quincunx episode has no tag. Test added in `test_divination_tags.py::test_s4_…`.
- `pytest tests/test_divination_tags.py tests/test_divination_render.py tests/test_divination_roster.py tests/test_boundaries.py -q` → `162 passed`.

## Step 6 — core
- `packages/core/src/divination/pills.ts` (new): `Pill`, `PILL_KINDS`, `PILL_OPEN/CLOSE`, `isPill`, `pillOf`, `pillToken`, `splitPills`, `hasPills`, `pillRef`, `pillSource`. `types.ts`: `TurnEvent` + `{type:'pill', pill}`; `isBody`/`isAspectPoint` exported, `isAspectType`/`isSign` added; header + `ChartRef` doc say refs come from the checked natal pills. `turn.ts`: `pill` frames (`isPill` → `pillOf`), a pill counts as a prior item for `bubble` and closes the dice window. Barrel exports `hasPills, isPill, pillRef, pillSource, pillToken, splitPills` + types `Pill`, `PillSource`.
- First `npm test` run: app-native `architecture.test.ts` › "every core barrel export is consumed somewhere or carries a declared intent" FAILED with `divination/PILL_CLOSE, PILL_KINDS, PILL_OPEN, hasPills` unconsumed. Fixed by keeping the three constants module-internal (not in the barrel); `hasPills` is consumed by the web at step 8.
- `chart-view/glyphs.ts`: `AspectTone`, `ASPECT_TONES` (+ index export); `app-native/src/architecture.test.ts` one-definition enumeration + expectation gained `ASPECT_TONES: glyphs`.
- Tests: `web-divination/src/chat/core-pills.test.ts` (C1, C2) — a new file beside `core-divination.test.ts` rather than inside it (plan said the existing file; kept separate for size); `chart/chart-view-additions.test.ts` + C3.

## Step 7 — i18n
- `pills` namespace (label templates `placement`, `placementHouse`, `rising`, `aspect`, `transit`, `dicePlanet/Sign/House`; `aspects` words — en conjunct/sextile/square/trine/opposite, zh 合相/六分/四分/三分/对分; `now`; `meaning`; `noteLabel`; three source words) and `lore` namespace (bodies ×10 + Ascendant, signs ×12, houses '1'–'12', aspects ×5) in en + zh. en rows copied verbatim from `server/app/dictionary/symbols.py` (PLANETS, SIGNS, HOUSES, ASPECTS, ANGLES.AC). `i18n.test.ts` binds them to `Body|'Ascendant'`, `ZodiacSign`, house keys and `AspectType`.
- `npx vitest run src/i18n.test.ts` → 11 passed; web typecheck green.

## Step 8 — web (after loading /frontend-design)
- `chat/pill-meaning.ts` (pure: `pillGlyphs`, `pillTone`, `pillLabel`, `pillMeaning`), `chat/Pill.tsx` (`PillText`, static span / `button.chat__pill--press[aria-pressed]`, `countPills`, `nthPill`; imports `./chat.css` so the log screens get the rules).
- `useChat`: `pill` → `pacer.push({type:'delta', text: pillToken(pill)})`. `ChatPanel`: `Slips` renders `PillText` with entry-wide pill offsets; stored entries pressable, streaming/failure static; `PillNote` (`role="note"`) under the letter whose pill is pressed; chip row only when `!hasPills(entry.text)`. `wheel-activation.showRefs(refs, chip)` keeps `{refs: [], chip}` when a chip id is given. `SessionTranscript`: static pills, seals only for legacy. `SummaryCard`: `question` and `toneNote` via `PillText`.
- `chat.css`: pill base, `.chat__pill--press` (class, not `button.` — CSS is class selectors only), one rule per `data-source` (natal engraved seal: inset hairline on a wash; sky: dashed round orbit + small-caps "now"; dice: die-cut clipped corner) and per `data-tone` (underline hairline + aspect glyph in `--aspect-trine` / `--aspect-square` / `--aspect-conjunction`), note line, reduced-motion block. No new token needed.
- Tests: `chat/Pill.test.tsx` (W1, W1 zh, W2, W3, W4, W4 zh, W5, W6 ×3); `chart/wheel-activation.test.ts` + the chip-with-empty-refs case.
- `npm test` → app-native `Test Suites: 90 passed, Tests: 1069 passed`; web-divination `Test Files 26 passed, Tests 270 passed`. `npm run typecheck` → both workspaces clean.

## Step 9 — CLAUDE.md
- Rule 1: the chart-view enumeration names `ASPECT_TONES`. Rule 8: the web `lore` namespace replaces "no lore as of dw-1". Rule 10: the dw-10 paragraph (tags.py pure, pill event, the ONE phenomenon-tag exception, chartRefs from natal pills).
- `grep -n "divination/tags.py\|lore. namespace\|ASPECT_TONES" CLAUDE.md` → lines 187, 269, 370.
