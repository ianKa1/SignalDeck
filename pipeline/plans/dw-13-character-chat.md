# Plan — dw-13-character-chat

The spec is `pipeline/specs/dw-13-character-chat.md`. This file sets the ORDER only. The work runs in the primary checkout on branch `feature/dw-13-character-chat`. Python runs via `conda run -n astrology`, and server tests run from `server/`. The lab comes FIRST (spec default 8).

## Steps

- [x] **1. Lab metrics (pure) and their tests.**
  - Files: `server/tests/prompt_lab/divination_chat_metrics.py` and `server/tests/test_divination_chat_metrics.py`.
  - Build `bubble_words` (pill word rule as in L2), `long_share`, `pill_counts` (by kind, and failures from captured WARNINGs), `question_endings`, `self_intro_hits` and `summary(run_dir)`. `summary` evaluates L1–L6 as booleans, with the transit waiver.
  - **Done when:** `pytest tests/test_divination_chat_metrics.py -q` is green.

- [x] **2. Lab harness and baseline run.**
  - File: `server/tests/prompt_lab/divination_chat_lab.py`.
  - The environment is set before any `app` import. It uses an in-process TestClient.
  - It runs the persona route with `JOBS_SYNC=1`, and tolerates the v1 voice wire.
  - The simulated user is `llm.generate_sections` with a per-character scenario.
  - It runs 10 turns per persona and captures the SSE frames and WARNINGs, plus the sky episode count for sky personas.
  - It writes `<persona>.json`, `.md`, and `metrics.json`.
  - Run it once on the unchanged code into `pipeline/logs/dw-13-character-chat/transcripts/baseline/`.
  - **Done when:** the baseline directory holds 6 transcripts and a `metrics.json`, and the baseline numbers are recorded in `05-implementing.md`. Commit the lab files.

- [x] **3. Bubbles total ceiling.**
  - Files: `divination/bubbles.py`, `turn.py` (names only) and `test_divination_bubbles.py`.
  - Set `Budget(sentences)` to a total of CHAT 12 and DEEPER 20. There is no per-bubble cap.
  - B1–B3 are covered by rewritten dw-9 tests. Cap-cancel is tested in `test_divination_turn.py`.
  - **Done when:** the bubble and turn tests are green.

- [x] **4. Card job.**
  - Files: `divination/voice.py`, `voice_role.txt` and `test_divination_persona.py`.
  - VERSION goes to 2, and the schema becomes `{card, greeting}`.
  - Build `ASTRO_TERMS`/`astro_terms` (English, plus zh for greetings only; the own-name allowance covers both languages).
  - `base.<id>` is registered on the voice topic.
  - Retries go up to 3, with the rejected terms fed back.
  - `to_wire` returns v2 `{greeting}`.
  - K1–K4 are covered, including that `card` never appears on any wire.
  - **Done when:** the persona tests are green.

- [x] **5. Prompt reassembly.**
  - Files: `divination/render.py`, `personas/*.txt`, `turn.py` (pass `voice["card"]`), `sky.py` (docstring) and `summary.py` (`lang.zh`).
  - Add `identity`, `ground.rules`, `rhythm.chat` and `rhythm.deeper`.
  - Retire the fragments listed in default 3.
  - Compress `chart.read`, `sky.read`, `dice.txt` and `tags.*`, making them sample-free and CJK-free.
  - Rewrite the persona base descriptions as character descriptions.
  - `system_prompt` takes `card`.
  - Re-record `fixtures/divination_chartless_{en,zh}.txt`.
  - **Done when:** the new tests P1–P7 in `test_divination_render.py` are green, including the P5 size tiers over the listed configurations.

- [x] **6. Rewrite superseded server tests.**
  - Files: `test_divination_{render,turn,roster,sky,dice,persona}.py`, plus `test_boundaries.py` only if a fence names a retired fragment.
  - Each rewritten test is named in the log.
  - `test_handoff_is_never_parsed_from_the_reply` and the dw-10 boundary tests stay untouched.
  - **Done when:** `conda run -n astrology pytest -q` is fully green. Commit.

- [x] **7. Client.**
  - Files: core `divination/persona.ts` (v2 `{greeting}`), web `chat/ChatPanel.tsx` and `PersonaHeader.tsx` (remove `VoiceAside`), `i18n/en.ts` and `zh.ts` (drop `biasLabel`), and the tests `PersonaHeader.test.tsx` and `core-persona.test.ts`.
  - W1 and W2 are covered.
  - **Done when:** `npm test` and `npm run typecheck` are green. Commit.

- [x] **8. Lab iteration.**
  - Run the harness into `transcripts/run-01/`, `run-02/` and so on. Tune only prompt text and the card brief until `metrics.json` shows L1–L6 all true.
  - Re-run the unit suites after each prompt change, because P1–P5 must stay green.
  - Every run's metrics go in the log.
  - **Done when:** the final run passes L1–L6. The loop's L7 judgement, quoting three Moon turns, is written in `NN-validating.md`.

- [x] **9. CLAUDE.md, rules 9 and 10 (G2).**
  - Rule 9 names the character card.
  - Rule 10 gets the total ceiling and the card.
  - The dw-8/dw-11 exclusivity sentence is removed.
  - The no-CJK / no-samples sentence is added.
  - **Done when:** the greps hit, and the suites are green. Commit.

- [x] **10. Validating.**
  - Run the full suites.
  - In the real app (claude-cli), open the Moon for birth data F in the web: the greeting shows, there is no bias aside, and a two-turn chat renders short slips with pills.
  - Record the evidence.
  - **Done when:** the evidence is logged.

## Acceptance map

| Criterion | Step |
|---|---|
| P1–P7 | 5 (6 for the rewritten fences) |
| K1–K4 | 4 |
| B1–B3 | 3 |
| W1, W2 | 7 |
| G1 | 6, 7, 10 |
| G2 | 9 |
| L1–L6 | 1, 2 (harness), 8 |
| L7 | 8 |

## Risks for the implementer

- **Shared-text tiers are tight.** Measure with the P5 test while writing the fragments; do not write prose first and trim after. The tag block matters most for L4, so keep its placeholders explicit.
- **Astro-term false positives.** Common words (sun, moon, square, opposition) will trigger retries. List the banned words in the card brief and ask for metaphor instead.
- **Lab runtime.** 6 personas × 10 turns × about 30–90 s on claude-cli is long. Run personas in parallel threads only if the claude-cli provider tolerates it; otherwise run sequentially in the background.
- **The simulated user must write casually.** If it writes essays, the character mirrors it. Pin the simulated user's style in its prompt: short texts, sometimes one word.
- **L3 requires some long bubbles.** The rhythm text must invite an occasional longer message, not forbid it.
