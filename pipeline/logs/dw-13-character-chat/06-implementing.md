# dw-13-character-chat — 06 implementing (2026-09-29)

Worker: implementing → validating → docs-sync. Branch `feature/dw-13-character-chat` (primary checkout), base c5b1c7e.
Note: the plan says baseline numbers go in "05-implementing.md"; 05 is the planning log, so they are recorded here (06).

## Step 1 — lab metrics (pure)
Files: server/tests/prompt_lab/divination_chat_metrics.py, server/tests/test_divination_chat_metrics.py.
- `pill_label` is the one L2 pill-word rule; `turn_bubbles` rebuilds bubbles from SSE frames; `bubble_words`, `long_share`, `pill_counts` (failed tags from captured `tag <kind> failed: <reason>` WARNINGs), `question_endings`, `self_intro_hits`, `completed_turns`, `card_check`, `evaluate`/`summary(run_dir)` → L1–L6 booleans with the sky-transit waiver (planetTargetEpisodes == 0).
- Thresholds are the spec's verbatim constants. The L5 self-intro regex also matches a capitalised "As your …" at a sentence start (stricter than the literal lowercase `as`, never looser).
- First run: 3 failed (fixture had 1.6% long bubbles < 2%; "As your Saturn" not matched by lowercase `as`) → fixed fixture + regex.
`conda run -n astrology pytest tests/test_divination_chat_metrics.py -q` → 11 passed in 0.26s. Step 1 ticked.

## Step 2 — lab harness + baseline
File: server/tests/prompt_lab/divination_chat_lab.py (not collected: not test_*.py).
- Env set before any `app` import: ANALYSIS_LLM=claude-cli, JOBS_SYNC=1; DATABASE_URL and provider keys popped. Divination store = a throwaway SQLite per process (fresh cards every run). `main._utcnow` pinned to 2026-09-29T04:00Z (`--now`) so every run sees the same sky. The six characters run as six parallel child processes (one log capture per process); the parent writes metrics.json.
- Simulated user: `llm.generate_sections` with a per-character scenario (fixed opening text; situation incl. a natural timing ask for moon/saturn/jupiter), texting register pinned (3–20 words, ≤40).
- Transcript re-sent exactly as the web client stores it: bubbles blank-line joined, pills as `pillToken` tokens.
- Smoke (scratchpad, moon × 2 turns): OK in 48 s.
Baseline command (from server/): `conda run --no-capture-output -n astrology python tests/prompt_lab/divination_chat_lab.py --turns 10 --personas all --out ../pipeline/logs/dw-13-character-chat/transcripts/baseline` → all six exit 0 in ~6 min.

### Baseline metrics (unchanged dw-10 prompts, v1 voice wire)
criteria: L1 true, L2 FALSE, L3 FALSE, L4 true, L5 FALSE, L6 FALSE (no card — expected)
totals: 220 bubbles, median 43.0 words, ≤30-word share 0.227, >40-word share 0.605 (6/6 convs), 161 pills, 0 failed tags.
| persona | done | bubbles | median | >40w | placement/aspect/transit | pills | ?-ending share | self-intro |
|---|---|---|---|---|---|---|---|---|
| venus | 10 | 39 | 40 | 18 | 17/13/0 | 30 | 1.0 | "I'm your Venus" ×3+ |
| moon | 10 | 38 | 48.5 | 27 | 13/8/9 | 30 | 0.9 | "I'm your Moon" ×3+ |
| mars | 10 | 32 | 40 | 15 | 7/19/0 | 26 | 1.0 | "I'm your Mars" ×2 |
| jupiter | 10 | 36 | 47.5 | 25 | 14/13/3 | 30 | 0.8 | "I'm your Jupiter" ×3+ |
| saturn | 10 | 36 | 48 | 26 | 14/2/7 | 23 | 0.9 | "I'm your Saturn" ×3+ |
| mercury | 10 | 39 | 42 | 22 | 7/15/0 | 22 | 1.0 | "I'm your Mercury" |
Reading: the dw-9 shape (2–4 messages × 1–3 sentences, closing question mandatory) produces uniform ~45-word slips, a question ending on 80–100% of replies, and placement self-introductions — exactly what rulings (1), (3), (4) retire. Phenomena are plentiful and all check (L4 already holds).

## Step 3 — bubbles total ceiling
bubbles.py: `Budget(sentences)`; CHAT = Budget(12), DEEPER = Budget(20); a line break ends a bubble; no per-bubble cap; the ceiling stops the segmenter at the next visible character. Decided: a line break after unterminated text also ends a sentence (texting-style lines without periods would otherwise escape the ceiling). turn.py: the INFO log names the ceiling.
Tests rewritten (only where they asserted the dw-9 caps): test_divination_bubbles.py::test_budgets, test_b2 (→ test_dw13_b2_the_total_ceiling_never_splits_a_sentence, test_b3_sentence_ends_still_follow_typography), test_b3_cjk… (budgets), test_b4_bubble_cap… (→ dw13 b2), test_b4_not_stopped…, test_b5 (the cap-filling whitespace case; now asserts bubbles); new test_dw13_b1_one_line_of_six_sentences_is_one_bubble, test_dw13_b2_unpunctuated_lines_count_toward_the_ceiling. test_divination_turn.py::test_dw9_t3_cut_at_the_cap… (13 lines → cut after 12, provider closed), test_dw9_t5_deeper… (25 paras → 20); new test_dw13_b1_a_long_message_stays_one_bubble.
`pytest tests/test_divination_bubbles.py -q` → 14 passed; `pytest tests/test_divination_turn.py -q` → 59 passed.

## Step 4 — character card job
voice.py: VERSION 2, SCHEMA_VERSION 2, `VOICE_SCHEMA {card, greeting}`, CARD 2,800–3,800, GREETING ≤200, MAX_ATTEMPTS 3; `base.<id>` registered from personas/<id>.txt (+ `base.marker`); `retry` fragment names problems (terms, lengths) never text; INFO log per rejected attempt (reasons only). `ASTRO_TERMS` (dictionary PLANETS/SIGNS/ASPECTS keys + extras) + `_HOUSE_RE`; `ZH_ASTRO_TERMS` + zh house regex in code; `OWN_NAMES` allowance (en+zh) via `greeting_terms`. `to_wire` → `{schemaVersion 2, …, voice:{greeting}}`. lang lines CJK-free.
store.py: `_VOICE_FIELDS` → ("card", "greeting") (payload only; columns/SQL unchanged).
voice_role.txt: the card brief (portrait: temperament, cares, talk, quirks, flaw, friendship; sheet→behaviour mapping; banned vocabulary verbatim, each list its own sentence so P2 stays clean; no own name in card; greeting ≤200).
Decided: a greeting over 200 chars regenerates (no cut) — a cut mid-word greeting is worse than a retry.
Tests (test_divination_persona.py): rewritten P9 (prompt carries base), p7 bad-output → K1 3-attempt tests, route P5/P6/P7/P8 for `{greeting}` + schemaVersion 2 + card absent from body; new test_base_descriptions_are_the_persona_files, K1 (store v2, dirty→clean after 2 calls, 7 dirty variants → 3 calls + raise + nothing stored), K2 (astro_terms incl. "a house by the sea"/"fall" clean, Moon allowance, 金牛座), role lists every ASTRO_TERM, K3 (retry names Scorpio/trine + lengths, never the text), K4 wire. Retired: test_p7_long_fields_are_cut, test_p7_route_serves_the_cut_bias, test_voice_role_asks_the_bias_to_name_the_sign, test_voice_role_keeps_intro_and_bias_inside_the_cut (intro/bias gone).

## Step 5 — prompt reassembly
render.py: new `identity`, `ground.rules` (5 rules, 496 chars, 6 lines), `rhythm.chat` (252), `rhythm.deeper` (207); retired shape.*, depth.*, self.*, roster.*, focus.*, chart.none; `chart.read`, `sky.read`, `tags.*` compressed, placeholder syntax only; `lang.zh` = "Reply in Simplified Chinese."; `system_prompt(..., card=...)`: identity → card|base → ground.rules → rhythm → chart/sky/dice blocks → tags → lang; `DISPLAY_NAMES`; `NatalContext.sheet` removed (the sheet leaves the turn). personas/*.txt rewritten as character descriptions (no rules lists; ~690–770 chars); dice.txt sample-free (~450). turn.py passes `voice["card"]`; sky.py + turn.py docstrings (roster.timing → ground rule 2); summary.py lang.zh CJK-free.
P5 measurement (shared text, 2,800-char card, fixture F, sky at 2026-09-29 local noon):
| config | venus | moon | mars | jupiter | saturn | mercury |
|---|---|---|---|---|---|---|
| chat (cap 1900; sky personas cap 2300) | 1692 | 2186 | 1691 | 2185 | 2184 | 1694 |
| cast (+sky for sky personas; caps 2300 / 2800) | 2274 | 2768 | 2273 | 2767 | 2766 | 2276 |
| deeper + dice_in_view (+sky) | 1765 | 2259 | 1764 | 2258 | 2257 | 1767 |
First draft was over (ground.rules 542, venus cast 2370, sky cast 2886) → trimmed ground.rules, tags.rules, dice brief, sky.read.
Goldens re-recorded: tests/fixtures/divination_chartless_{en,zh}.txt.

## Step 6 — superseded server tests rewritten
- test_divination_render.py: test_topic_is_registered (new set), test_s11 (not-read now in ground.rules), test_system_prompt_is_persona_plus_lang, test_s1 (identity/base/chart.read order), test_d4/d5 (chart.read, no chart.none), dw-9 block → test_t6_chat_prompt_order_without_a_chart / _with_chart_a / test_t6_cast_keeps_the_rhythm_before_the_dice / test_t5_deeper_prompt_uses_the_deeper_rhythm / test_t6_old_length_rules_are_gone; retired test_t6_depth_rule…, test_acceptance_cycle1_only_one_question…, test_merged_order_shape_and_depth_before_the_mirror; test_dw10_examples_are_in_tag_form → test_dw10_tag_syntax_is_placeholders_only; T8 goldens amended (identity name swapped with the base). New: P1–P7 (test_p1…test_p7).
- test_divination_persona.py: P10 → test_p10_turn_carries_the_base_before_the_card_exists, test_k4_the_next_turn_carries_the_cached_card; retired test_p10_self_read_carries_the_mirror_instructions.
- test_divination_roster.py: S4 (identity+base, ground.rules once), S4 signs → the card job's sheet, S4 order, S4 domain; S5 → chart-less golden + other-person rule in ground.rules; S6 dice section → brief+marker+JSON; S6 mars; S2/S9 with card fakes. Removed the orphaned fixtures dir tests/fixtures/divination_pre_dw8 (only the retired byte-identity pins read it).
- test_divination_sky.py: K2 render/route (sky iff chart+packet; ground.rules once), K9, K1, K7 (degrade → ground.rules, no sky).
- test_divination_dice.py test_d4/test_d5, test_divination_turn.py test_dw3_s1/s2, test_dw9_t5 (rhythm).
- test_divination_chat_metrics.py loads the metrics module by path (full-suite name clash with tests/prompt_lab/prompt_lab.py).
- test_boundaries.py untouched (incl. test_handoff_is_never_parsed_from_the_reply and the dw-10 fences).
`conda run -n astrology pytest -q` → 1361 passed, 50 skipped in 112.82s.

## Step 7 — client (after /frontend-design loaded; the change is a removal, the letter keeps its existing prose styling)
core persona.ts: `PersonaVoice = {greeting}`, `PersonaWire.schemaVersion: 2`, `isPersonaWire` requires schemaVersion 2 + non-blank greeting (rejects v1 {intro, bias}). web ChatPanel: the ready letter renders `<Prose text={voice.greeting}>`; `VoiceAside` removed from PersonaHeader; `.persona__aside` CSS removed; i18n `persona.biasLabel` removed from en and zh (parity holds).
Tests: core-persona.test.ts (READY v2; new "isPersonaWire (dw-13 W1)"; blank-greeting and v1-shape 200s → null), PersonaHeader.test.tsx (W2: prose = greeting, no aside/`aside`; W5: greeting never on the wire), i18n.test.ts (dropped the removed key from the {name}-template list).
`npm test` → jest 90 suites / 1069 tests passed; vitest 26 files / 272 passed. `npm run typecheck` → clean (both workspaces).

## Step 9 (done early, doc-only) — CLAUDE.md rules 9 and 10
Rule 9: "persona CHARACTER CARD cache (`divination_voice`, VERSION 2 …) … share its character card". Rule 10: generation's job named "persona character-card job"; the turn route "reads the cached character card and hands it in; the card is the bulk of the turn's system prompt and never leaves the server"; the bubble sentence → "a line break ends a bubble, and a total sentence ceiling per action — chat 12, deeper 20"; new sentence "Divination prompts are English-only text (no CJK) and give no quotable sample placements (dw-13, pinned by tests)."; removed "A prompt carries exactly one of `roster.timing` and the sky section." (Committed with the step-8 prompt tuning.)

## Step 8 — lab iteration
### run-01 (prompts as committed in ad04921)
Command: `… divination_chat_lab.py --turns 10 --personas all --out ../pipeline/logs/dw-13-character-chat/transcripts/run-01` (~9 min).
criteria: L1 true, L2 true, L3 true, L4 true, L5 true, L6 true
totals: 316 bubbles, median 19.0, ≤30-word share 0.801, >40-word share 0.060 (5/6 convs), 46 pills, 0 failed tags.
| persona | done | bubbles | median | >40w | P/A/T | pills | ?-end | self-intro | card chars / hits |
|---|---|---|---|---|---|---|---|---|---|
| venus | 10 | 55 | 19 | 1 | 3/4/0 | 7 | 0.1 | 0 | 3384 / 0 |
| moon | 10 | 57 | 20 | 4 | 6/2/3 | 11 | 0.1 | 0 | 3564 / 0 |
| mars | 10 | 51 | 17 | 2 | 5/5/0 | 10 | 0.0 | 0 | 3481 / 0 |
| jupiter | 10 | 47 | 23 | 10 | 4/4/1 | 9 | 0.1 | 0 | 3389 / 0 |
| saturn | 10 | 50 | 18 | 2 | 2/0/3 | 5 | 0.1 | 0 | 3473 / 0 |
| mercury | 10 | 56 | 18.5 | 0 | 3/1/0 | 4 | 0.1 | 0 | 3433 / 0 |
Card job: one rejection across six (jupiter attempt 1: card 3,895 chars > 3,800), regenerated clean on attempt 2; no vocabulary hits.
Loop's read (not a metric): the Moon reads like a friend (soup pot, bread aisle, lamp in a hallway), phenomena are real and checked (Moon in Pisces h8, Pluto in Scorpio h4, Moon trine Pluto, Uranus square Moon with packet dates). DEFECT the metrics miss: 57/60 turns hit the 12-sentence ceiling (INFO "sentence ceiling reached"): every turn is 4–7 messages and the server cuts the tail — a friend does not send six texts per turn, and a routine cut is truncation, not rhythm. Also one invented capability ("i'll send [a playlist] tomorrow", moon turn 10) — noted, not tuned (the ground rules are capped at 5).
Change for run-02: `rhythm.chat` → "…each message on its own line, usually two to four per turn, most of them one or two short sentences; now and then one longer message carries a lot…" (278 chars). To keep P5, trimmed `tags.rules` and dice.txt by ~15 chars each (mercury cast was 2,302). P5 now also covers the mars and mercury casts. Goldens re-recorded. Divination suites 291 passed.

### run-02 (rhythm.chat "usually two to four per turn")
criteria: L1 true, L2 FALSE, L3 true, L4 true, L5 FALSE, L6 true
totals: 246 bubbles, median 25.0, ≤30 share 0.614, >40 share 0.159 (6/6), 44 pills, 0 failed.
Per persona median: venus 24, moon 23, mars 29.5, jupiter 36.5, saturn 23.5, mercury 19; ?-ending: venus 0.7 (>0.6), jupiter 0.6. Ceiling cuts 20/60 (was 57/60).
Reading: capping the message COUNT made each message longer (the model keeps its total and packs it into fewer bubbles) — the opposite of ruling (4). Rejected.

### run-03 (rhythm.chat "most of them one or two short sentences, and a turn is a few messages, not a letter"; "no markdown")
criteria: L1 true, L2 true, L3 true, L4 true, L5 true, L6 true
totals: 319 bubbles, median 19, ≤30 share 0.784, >40 share 0.088 (6/6 convs), 44 pills, 1 failed tag (venus aspect:not-in-chart), failed share 0.022.
| persona | done | bubbles | median | >40w | P/A/T | pills | ?-end | self-intro | card chars / hits |
|---|---|---|---|---|---|---|---|---|---|
| venus | 10 | 51 | 21 | 4 | 4/5/0 | 9 | 0.2 | 0 | 3484 / 0 |
| moon | 10 | 65 | 14 | 5 | 3/2/3 | 8 | 0.1 | 0 | 3481 / 0 |
| mars | 10 | 49 | 18 | 1 | 3/5/0 | 8 | 0.0 | 0 | 3638 / 0 |
| jupiter | 10 | 43 | 24 | 12 | 6/3/2 | 11 | 0.1 | 0 | 3726 / 0 |
| saturn | 10 | 50 | 21.5 | 5 | 1/1/2 | 4 | 0.0 | 0 | 3451 / 0 |
| mercury | 10 | 61 | 14 | 1 | 3/1/0 | 4 | 0.2 | 0 | 3665 / 0 |
Sky packets: moon/saturn/jupiter each 6 episodes, 5 planet-target → no transit waiver needed. Ceiling cuts still 57/60.

### run-04 (run-03 + "rarely past ten sentences in all"; chart.read/dice trims)
criteria: all six true, but ceiling cuts only 57→50/60 and failed tags rose to 5 (0.094 share, cap 0.10: moon 3, venus 2 aspect:not-in-chart). Rejected; render.py and dice.txt restored byte-for-byte to the run-03 text (P5 re-measured identical: venus/mars/mercury chat 1725/1724/1727, sky chat 2217–2219, casts 2292–2295 / sky casts 2785–2787, moon deeper+dice 2261), goldens re-recorded to run-03 text.

### Decision: final run = run-03 (4 runs used of the 6-run cap)
The long turns are a model habit that prompt wording barely moves (57/60 → 20/60 only by trading for long bubbles; 50/60 at the cost of tag accuracy). Ruling (4) chose a server-side total ceiling as the enforcement, and it cuts only at sentence ends, so the character still sends a complete stream of short texts; the cost is that the tail of most turns is dropped (see the L7 note in the validating log). Recorded as a known limitation, not tuned further.
Divination suites after the revert: 371 passed.
