# 02 spec-review (round 1) — fresh-context reviewer

**Verdict: PASS**

Inputs: the QUEUE entry `dw-7-persona-mirror` and the ROUND 2 comment (A/C/D taken as decided defaults), `pipeline/specs/dw-7-persona-mirror.md`, `pipeline/epics/divination-web.md`, CLAUDE.md read from disk (it is newer than the in-context copy: rules 9, 10, 11 and 14 already name `divination`), and PIPELINE.md's Spec requirements, Auto spec review and pipeline-mode override sections. I checked the claims against the code at b308a92.

## Verified against code

- The P1/P2 fixtures, recomputed with real Swiss Ephemeris:
  - Chart A's Venus is Taurus, house 10, direct, domicile. Its aspects are Chiron 2.16, Jupiter sextile 2.39, Pluto opposition 2.75, Neptune trine 4.44, Saturn trine 5.90 and Moon sextile 9.72. With Chiron filtered out, that is exactly P1's order.
  - Chart B's Venus is Scorpio, house 2, retrograde, detriment. Its aspects are Mercury conjunction 1.04, Midheaven trine 3.05, Jupiter trine 6.37 and Moon opposition 6.53. With the Midheaven filtered out, that is exactly P2.
  - With `time:null`, `house` is None.
- These cited lines match the code: `render.py` :135 `_REF_POINTS`, :170 `natal_context`, :185 `system_prompt`, :241 `turn_messages`; `turn.py:200`; `main.py:271-275` (facts riding with a 202); `main.py:446` (the summary route); `generation.py:207`; `planet_state.py:37` `_dignities`; the dictionary symbols and natal line numbers.
- The next migration number is 012 (the last one is 011).
- These exist as described: `test_boundaries.py`'s `GENERATE_ON_REQUEST_RE`, `test_divination_store_is_one_identity_free_table`, `DIVINATION_TURN_STATE_IMPORT_RE` and `test_main_names_the_synchronous_exceptions`.
- These exist too: core `MAX_POLLS`/`POLL_INTERVAL_MS`/`postJson`/`pollDelay`/`isGenerating`, `SIGN_GLYPHS`, zh `chat.houses['10']` = 第十宫 and `signs.Taurus` = 金牛座.

## Checklist

1. **Serves the notes, right-sized.** Yes.
   - All five factors are covered: sign, house, aspects, dignity and retrograde.
   - The sheet is deterministic, built from Tier A + B.
   - The voice is written once as a job, keyed by content + planet.
   - With no birth data, Venus uses her base role only.
   - The bias is self-aware (C).
   - Two Venuses can be told apart.
   - The sheet is generic over planets for dw-8.
   - Out of scope, correctly: dw-8, dw-9, dw-10 and dw-11.
2. **Criteria are checkable.** Yes. P1–P12, C1 and W1–W6 are all tests. A1–A5 are real-app checks with verbatim transcripts. A3 turns "audibly different" into named-factor conditions (a)–(d).
3. **Architecture Contract.** No violation found.
   - Rule 14: the persona route is store-hit 200 / ensure 202 / 502 / 503. The turn only reads the voice through `cached_for` and never enqueues (P10). main.py names no generator, because `generate_voice` is added to the regex.
   - Rule 9: the voice cache is keyed by topic, VERSION, persona, lang and sheet facts, with no identity column.
   - Rule 10: `persona.py` is pure and imports chart + dictionary only. The join lives in Tier C, as rule 10 requires.
   - Rule 11: store.py is still the single db edge.
   - The fingerprint is provenance only (`doctrine`). P4 proves FINGERPRINT is not key material.
   - Every guard is widened, none weakened, and each gets a self-check (P12).
   - The CLAUDE.md amendments are listed. The epic update is deferred to docs-sync, as PIPELINE allows.
   - The shared-file footprint with dw-9 and dw-12 is stated, including the migration-renumber rule.
4. **Non-goals and decided defaults.** Non-goals are stated, and every open point is decided. There is no Open Questions section.

## Non-blocking

- **N1.** The turn route will compute `natal_report` twice per turn: once in `voice.cached_for`, once in `render.natal_context`. This is acceptable, but the plan could let main.py pass the sheet's facts, or accept the cost knowingly.
- **N2.** `_create_table_columns` reads only the FIRST CREATE TABLE. The two-table pin needs that helper extended (for example, table by name). The plan should say so.
- **N3.** Existing dw-3/5 tests that assert the with-chart system prompt's exact content may need more than "mechanical call-site updates", because the sheet now sits before `chart.read`. The plan should allow golden or order updates for with-chart prompts, and keep the chart-less golden strict.
- **N4.** D (never claim another person's feelings) applies only when a sheet is present. The spec justifies this with the chart-less byte-identity rule and hands it to dw-8. That is fine; the decision journal should record it.
- **N5.** The zh strings for "Your Venus" and "finding her voice…" are not specified. The implementer chooses them under the parity test.
- **N6.** A3(c), "differ in advice or emphasis", depends on judgment. The quoting requirement makes it auditable.
