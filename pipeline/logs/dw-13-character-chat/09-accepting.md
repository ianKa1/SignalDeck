# dw-13-character-chat — 09 accepting (2026-09-29)

Fresh-context acceptance check. Branch feature/dw-13-character-chat @ 137c3fe, clean tree, no source touched.
Criteria: the spec's Acceptance Criteria list (P1–P7, K1–K4, B1–B3, W1–W2, G1–G2, L1–L7).

OVERALL: PASS

## Suites (re-run here)
- `cd server && conda run -n astrology pytest -q` → **1361 passed, 50 skipped, 1 warning in 127.27s**.
- Targeted: `pytest -q tests/test_divination_{render,persona,bubbles,turn,chat_metrics}.py tests/test_boundaries.py` → **216 passed**.
- `npm test` (root) → jest **Test Suites 90 passed, Tests 1069 passed**, then vitest **26 files, 272 passed**; exit 0.
- `npm run typecheck` → app-native and web-divination `tsc --noEmit` clean, exit 0.

## Prompt (unit)
- **P1 PASS.** `test_p1_no_cjk_in_any_divination_prompt` walks every fragment of the three topics plus `personas/*.txt`. Independently I scanned 48 texts (all three topics' fragments, every persona file, `voice_role.txt`, `summary_role.txt`) with `[　-鿿＀-￯]`: 0 hits.
- **P2 PASS.** `test_p2_no_quotable_sample_placement` uses the spec regex (planet, then within 40 chars of the same sentence a sign, aspect word or `house`; plus `⟦\w+:[A-Z]`), expects zero hits with no exemptions, and plants 5 samples that must turn it red. My own looser case-insensitive, cross-sentence regex found only `voice_role.txt`'s banned-vocabulary list ("…Saturn, Uranus, Neptune, Pluto. Sign names: Aries"). That match crosses a sentence end, so it is not a sample under the spec regex.
- **P3 PASS.** No `shape.*`/`depth.*`/`self.*`/`roster.*`/`focus.*`/`chart.none` in `render.PROMPTS.fragments()` (25 fragments listed). The five stock phrases appear in 0 texts.
- **P4 PASS.** `ground.rules` has 6 lines and 496 chars. It names someone else's feelings, inventing chart facts/transits/dates, professionals, AI, and the six characters with their domains.
- **P5 PASS.** Recomputed with the test's `_shared` on fixture F (1990-06-15 08:30 Beijing) with a 2,800-char card:

  | Configuration | Shared text (chars) | Cap |
  |---|---|---|
  | venus / mars / mercury chat | 1725 / 1724 / 1727 | ≤1900 |
  | moon / saturn / jupiter chat+sky | 2219 / 2217 / 2218 | ≤2300 |
  | venus cast (also mars 2292, mercury 2295) | 2293 | ≤2300 |
  | moon / saturn / jupiter cast+sky | 2787 / 2785 / 2786 | ≤2800 |
  | moon deeper+sky+dice_in_view | 2261 | ≤2800 |

  Every case is ≤ the card. For venus/mars/mercury the test asserts the card is present and that the base description and sheet JSON are absent. Margins are thin (2295 against 2300; 2787 against 2800), but every case passes.
- **P6 PASS.** `test_p6_…` covers the chart-without-card case (the base description stands in, and a card is ignored without a chart). `test_p10_chartless_prompt_is_the_dw6_golden` (en, zh) checks renderer and route against the re-recorded fixtures; `git diff c5b1c7e` shows both fixtures re-recorded. `test_dw10_t8_chartless_chat_prompts_match_the_goldens` covers all 6 personas × 2 languages. There is one golden per language, not one per persona: each persona's expected prompt is the Venus golden with the identity name and base description swapped in.
- **P7 PASS.** `test_p7_rhythm_by_action_and_the_tag_block_stays` checks the rhythm by action and that tags.rules and tags.natal are present. `test_dw10_t8_tag_block_by_ground` is unchanged in the diff. The only dw-10 render test rewritten is the examples test, which named retired sample tags; it became `test_dw10_tag_syntax_is_placeholders_only`.

## Card job
- **K1 PASS.** Independent run with a fake `llm.generate_sections`: the first card contains "Taurus", the second is clean. Result: 2 calls, the clean card stored, promptVersion 2, `cached_voice` returns it. With three bad attempts it raises `AnalysisUnavailable` after 3 calls, and the store read is None. `VERSION = 2` in voice.py.
- **K2 PASS.** `astro_terms`: Taurus→[Taurus], "a trine"→[trine], "the seventh house"→[seventh house], "the 10th house"→[10th house], retrograde→[retrograde]; "a house by the sea"→[], "fall"→[]. Moon greeting: "…the Moon" → [], "the Moon in Pisces" → [Pisces]. The zh greeting "…金牛座" → [金牛座].
- **K3 PASS.** A 5-char card regenerates. The retry segment reads "the card was 5 characters long, and it must be 2,800 to 3,800". For a dirty card it reads "the card used the banned words Taurus", and the rejected text does not appear in the retry prompt. This is also pinned by `test_k3_…`.
- **K4 PASS.** `test_p5_miss_then_hit` checks that the route body keys are exactly {schemaVersion, persona, lang, sheet, voice}, that schemaVersion is 2, that voice is {greeting}, and that the card text is absent. `test_k4_the_next_turn_carries_the_cached_card` checks the card is in the system prompt and never in a frame. In the lab (run-03) every `voiceWire` has the key `greeting` only, and no card snippet appears in any SSE frame.

## Rhythm
- **B1 PASS.** `test_dw13_b1_one_line_of_six_sentences_is_one_bubble` (under dw-9 this gave two bubbles), plus the route-level `test_dw13_b1_a_long_message_stays_one_bubble`.
- **B2 PASS.** 15 lines under CHAT are cut after 12, 25 paragraphs under DEEPER after 20, and a single line is never cut mid-sentence (`_every_split` covers every chunk split). `test_dw9_t3_cut_at_the_cap_does_not_wait_for_the_provider` shows `done` arriving in under 2 s and the provider generator's `finally` running, so the provider is cancelled.
- **B3 PASS.** The typography tests (line breaks, `3.5`, terminator runs, closers, CJK 。！？ and 「」) still run over every two-way chunk split. The diff removes only assertions phrased with the per-bubble cap (`Budget(4,3)`, bubble-cap tests) and restates them with the total ceiling.

## Client
- **W1 PASS.** Core `isPersonaWire` requires `schemaVersion === 2` and a non-blank `voice.greeting`. `core-persona.test.ts` rejects schemaVersion 1 and `{intro, bias}`.
- **W2 PASS.** ChatPanel.tsx:461 renders `<Prose text={persona.voice.greeting}>`. `PersonaHeader.test.tsx` checks there is no `.persona__aside` and no `aside` in the letter. `VoiceAside` and `biasLabel` have no source references left. The i18n parity test passes, and npm test and typecheck are green.

## Suites and docs
- **G1 PASS.** Full server suite, npm test and typecheck are green, as above. `git diff c5b1c7e --stat -- server/tests/test_boundaries.py server/tests/test_divination_tags.py` is empty, so `test_handoff_is_never_parsed_from_the_reply` (test_boundaries.py:851) and the dw-10 boundary tests are unchanged.
- **G2 PASS.** Greps on CLAUDE.md:
  - Rule 9 (l.287–292) has "the persona CHARACTER CARD cache (`divination_voice`, VERSION 2 …) … share its character card".
  - Rule 10 has "the persona character-card job", "the turn route reads the cached character card and hands it in", and at l.356 "a total sentence ceiling per action — chat 12, deeper 20 … the provider stream cancelled at the ceiling".
  - "voice" in rule 10 appears only as the module name `voice` in the import fence, never as the concept.
  - The `roster.timing` sentence is gone, and the new English-only/no-sample sentence is present.

## Lab (final run = transcripts/run-03)
Recomputed with the unit-tested module:
`conda run -n astrology python -c "…m.summary(base/run, voice.astro_terms)…"` →

```
baseline {'L1': True, 'L2': False, 'L3': False, 'L4': True, 'L5': False, 'L6': False} median 43, short 0.227, long 0.605, pills 161
run-01   all True  median 19, short 0.801, long 0.060
run-02   L2 False, L5 False  median 25, short 0.614
run-03   all True  bubbles 319, median 19, short 0.784, long 0.088, longConvs 6, pills 44, failed 1, failedShare 0.022
run-04   all True  median 20, short 0.789, long 0.072, failed 5, failedShare 0.094
```

run-03 per conversation (turns/completed/errors, bubbles, median, >40-word bubbles, pills [transit], failed, ?-share, self-intro, card chars/hits):

| Persona | Turns / completed / errors | Bubbles | Median | >40 | Pills [transit] | Failed | ?-share | Self-intro | Card chars / hits |
|---|---|---|---|---|---|---|---|---|---|
| jupiter | 10/10/0 | 43 | 24 | 12 | 11 [2] | 0 | 0.1 | 0 | 3726 / 0 |
| mars | 10/10/0 | 49 | 18 | 1 | 8 | 0 | 0.0 | 0 | 3638 / 0 |
| mercury | 10/10/0 | 61 | 14 | 1 | 4 | 0 | 0.2 | 0 | 3665 / 0 |
| moon | 10/10/0 | 65 | 14 | 5 | 8 [3] | 0 | 0.1 | 0 | 3481 / 0 |
| saturn | 10/10/0 | 50 | 21.5 | 5 | 4 [2] | 0 | 0.0 | 0 | 3451 / 0 |
| venus | 10/10/0 | 51 | 21 | 4 | 9 | 1 (aspect:not-in-chart) | 0.2 | 0 | 3484 / 0 |

- **L1 PASS.** 6×10 turns completed, 0 error frames, 0 turn errors.
- **L2 PASS.** Median 19 (≤22); 78.4% of bubbles ≤30 words (≥70%).
- **L3 PASS.** 8.8% of bubbles >40 words (2–20%), in 6/6 conversations.
- **L4 PASS.** Every conversation has ≥4 checked pills (≥3). Transit pills: moon 3, saturn 2, jupiter 2. No waiver was used: each packet has 5 planet-target episodes. Failed tags 1/45 = 2.2%, from the one captured WARNING "tag aspect failed: not-in-chart" in venus.
- **L5 PASS.** Max ?-ending share is 0.2 (≤0.6). Self-intro hits are 0. They are also 0 with my own case-insensitive regex (`i'?m|i am|as your <planet>`).
- **L6 PASS.** Six cards, 3,451–3,726 chars, and `voice.astro_terms` gives 0 hits on each; greetings also give 0 hits with own-name allowance. `transcripts/baseline/` exists beside run-03 and was written 12:02, before the prompt commit ad04921 at 12:13. Baseline transcripts carry the v1 wire (`voiceWire {intro, bias}`, `v1Voice`), so they are a true pre-change run.
- **Genuineness.** The transcripts look like real model output:
  - Every turn stores its full SSE frames (moon: 577 delta, 55 bubble, 8 pill, 10 done).
  - Per-turn latencies run 8.3–17.9 s (median 11.3 s), consistent with claude-cli.
  - Text and cards differ across all five runs, and no raw `⟦` survives in any delta.
  - I checked all 44 run-03 pill frames against the real chart for F. All 20 placement and 17 aspect pills match: Moon Pisces house 8, Jupiter Cancer house 12, Ascendant Cancer, and the aspects.
  - The Moon's transit claims match `sky.sky_context` at the lab instant: Uranus square Moon, window from 2026-07-17 with no end, pass 2027-07-16, stations 2026-09-11 R and 2027-02-08 D; Venus trine Moon exact 10-02 and 10-05.
- **Final-run prompt identity.** The committed `rhythm.chat` is the run-03 text ("…a turn is a few messages, not a letter… no markdown") and lacks run-04's "rarely past ten sentences". This agrees with 06-implementing's statement that the run-03 prompt was restored byte-for-byte.
- **L7 PASS.** 07-validating.md quotes Moon run-03 turns 5, 6 and 7 verbatim; I diffed them against run-03/moon.md and they are identical and consecutive. It records "Judgement: PASS. This reads like texting a friend who knows your chart", naming short messages, a distinct personality, real checked phenomena, and no stock bans.

  My own reading of the full Moon transcript agrees:
  - Replies are short lowercase lines ("oh" / "there it is" / "mm"), with one longer message carrying the chart.
  - The character is distinct: tender, playful with the named fridge "gary" and radiator "reggie".
  - Phenomena are real and dated correctly.
  - There is no forced closing question (1/10 replies end on "?"), no "I'm your Moon", and no Barnum-style filler.
  - It keeps ground rule 1 in its own words ("i can't know what she was feeling").

## Evidence noted, not judged: the sentence-ceiling cuts
The turn logs "sentence ceiling reached (12 sentences); rest of the reply dropped" on **57/60 turns in run-03**. By run: baseline 0/60 (the old per-bubble caps), run-01 57/60, run-02 20/60, run-04 50/60. The model routinely writes past 12 sentences, and the server trims the tail at a sentence end.

This shows in the Moon transcript: several turns end on a cut-off lead-in, such as "it isn't a short storm.", "give the flat's noises names." and "okay, gary and the radiator are the easy part". Messages arrive whole, but the reply loses its ending in about 95% of turns. The validating log and the feature doc both record this as a known limitation. No criterion bounds it.
