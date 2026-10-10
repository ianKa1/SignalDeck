# dw-13-character-chat — 04 spec-review round 3 (2026-09-29)

This review was run by a fresh-context general-purpose subagent. It had the same inputs as the earlier rounds, plus the logs of rounds 1 and 2.

## Verdict (verbatim)

VERDICT: PASS. This is round 3. All three earlier blocking items (A, B, A′) are resolved, and the revisions introduce no new contradiction. The remaining points are non-blocking.

Checked against the code at c5b1c7e:
- **Data-block shape.** `render.system_prompt` builds each data block as `<read text>\n\n<marker>\n<single-line json.dumps>`. That makes P5's "marker line plus single-line JSON" strip well-defined. chart.read, sky.read and dice.brief stay counted as shared text, as default 4 intends.
- **Voice key.** `voice.py` is at VERSION 1, and its key is (topic, VERSION, persona, lang, sheet_facts). Bumping to VERSION 2 cleanly orphans the v1 `{intro, bias, style}` rows, so the turn route never reads an old-shaped card.
- **P1 coverage.** `voice.lang.zh` and the `summary`/`render` `lang.zh` lines are registered PROMPTS fragments, so P1's fragment walk covers them.
- **Turn actions.** In turn.py:279–314, `action` is exactly one of chat, cast or deeper.
  - `dice_in_view` is true on a cast, or when any transcript entry carries dice. It adds `tags.dice` only, not `dice.brief`.
  - `Budget(4,3)` and `Budget(6,4)` are as the spec says, so B1's "dw-9 gave two" and the DEEPER 24→20 supersession are correct.
- **Epic divergences.** The epic's dw-7, dw-8, dw-9 and dw-11 entries, and its dependency rule "dw-7 voice store", differ from this spec. The spec names every divergence and hands it to docs-sync.

Earlier blocking items:
- **A (the proportion rule contradicted itself): resolved.** Default 4 and P5 now state the same rule: the card is at least the whole shared text. The JSON is excluded as data, which is justified against ruling (3)'s "bulk".
- **B (LAB FIRST ordering): resolved.** Default 8 orders the work: harness and metrics first, then a baseline in `transcripts/baseline/`, then `run-NN/` iterations. L6 checks that the baseline exists, and the baseline tolerates the v1 persona wire.
- **A′ (the heavy configurations were untested): resolved.**
  - Default 4 now has three tiers (1,900 / 2,300 / 2,800), and the card is 2,800–3,800 characters. The card minimum is at least the top tier, so the rule holds by construction.
  - P5 tests the two heaviest real configurations: a moon cast with sky (sky.read, dice.brief, tags.sky and tags.dice), and a moon deeper turn with sky and `dice_in_view`.
  - Default 1, the `generate_voice` contract, K3, L6 and the P5 fixture all use the same 2,800–3,800 bound.
  - Feasibility: today's fragments are tags.rules 850, natal 476, sky.read 1,122 and dice.brief 1,485 characters, so they need heavy compression. Round 2's estimate was a chart base of about 1,550–1,900, a sky add-on of about 550 and a dice add-on of about 500, so a full sky cast lands at about 2,600–2,950. With care that fits under 2,800. The rule is achievable in principle and tested at the maximal configurations.

Checklist:
1. **Serves the notes, right-sized: yes.**
   - Ruling (0): no CJK (P1), and zh is one English line.
   - Ruling (1): the card replaces intro/bias/style, and the astro-term check regenerates (K1–K3, L6). `self.read` is retired, and L5 carries the self-intro regex.
   - Ruling (2): phenomena stay, through dw-10's checked pills (L4). Comfort is allowed. L5's ≤60% question ending is a distribution check, not a rule.
   - Ruling (3): five ground rules within 6 lines and 500 characters (P4). The depth/shape bans are retired (P3), and the card is the bulk (default 4, P5).
   - Ruling (4): a total ceiling only (B1, B2). L2 and L3 are distributions, which fits "illustrative, not a cap".
   - Ruling (5): no quotable samples (P2, case-sensitive).
   - LAB FIRST is default 8, and "Loop closed" is L7, landing on the loop's own judgement.
   - The Supersedes list correctly treats dw-7, dw-8, dw-9 and dw-11 as tier 3.
   - One deliberate simplification, one card per language, is accepted in default 9 and breaks no ruling.
2. **Checkable: yes.** Every P, K, B, W, G and L criterion is a test, a grep or a metric over saved transcripts. No criterion or default contradicts another.
3. **Architecture Contract: no violations.**
   - `voice.py` → `app.dictionary` is a legal rule-10 edge.
   - render and turn still never import voice, store or summary; the route hands the card string in.
   - `card` never reaches any wire (K4, plus the forbidden-edge test).
   - The lab lives only under `server/tests/prompt_lab`.
   - The CLAUDE.md rule 9 and rule 10 amendments, and the new sentence on no CJK and no samples, are listed.
4. **Non-goals and defaults: yes.** Non-goals are stated, and every open point carries a decided default.

NON-BLOCKING (for the implementer or the plan):
1. **Default 4 wording.** "A sky persona casting on a deeper turn" cannot happen: cast and deeper are separate actions (turn.py:279). Reword it to "a sky-persona cast, or a sky-persona deeper turn with `dice_in_view`", which are the two cases P5 actually tests.
2. **P5 tests only the moon at the top tier.** The fragments are shared, but `{Name}` shifts the identity line's length by a few characters ("Jupiter" or "Mercury" against "Moon"). Cheap hardening: iterate the cast-with-sky case over all three sky personas.
3. **Where the card's base description comes from.**
   - Default 1 says the card draws on `personas/<id>.txt`, which is registered in render's `divination` topic.
   - The spec does not say how `voice.py` gets that text. Options: read render's PROMPTS (a new voice → render edge, legal but unstated), or carry the domain in `voice_role.txt` or the sheet.
   - The plan should pick one mechanism and note that voice's FINGERPRINT will not cover render's persona asset.
   - The base description names the planet, so the model may copy "Moon" into the card and burn retries. `voice_role.txt` should say to avoid the name.
4. **Proportion when no card is in play.** With a chart but no cached card yet (the base-description fallback, P6), and in chart-less prompts, the bulk rule is not stated. Either declare it a transient exemption, or require base descriptions to be at least as long as the chart-less shared text (about 900 characters).
5. **zh greeting allowance.** Default 2 allows the character's own name in the greeting, but K2 tests only English. The allowance should cover the zh name too (e.g. 月亮), or a zh greeting that uses the name is flagged. There is no zh lab, so this only risks 502s on zh persona fetches.
6. **Retry cost.** Case-insensitive whole-word matching on Sun, Moon, Mars, Mercury, square and opposition over a card of 2,800+ characters will sometimes cost retries. Feeding back the rejected terms and listing them in `voice_role.txt` is the right mitigation. Watch the lab for 502s.
7. **Lab env order.** `ANALYSIS_LLM=claude-cli` and `JOBS_SYNC=1` must be set before `app` is imported, if `llm` or the jobs module reads them at import time. Make that explicit in the harness.

## Coordinator follow-up

Folded into the spec:
- 1: default 4 is reworded.
- 2: P5 iterates the top-tier case over moon, saturn and jupiter.
- 3: `voice.py` registers each `personas/<id>.txt` as `base.<id>` on its own topic, so its FINGERPRINT covers the base description and voice never imports render. `voice_role.txt` says not to use the planet's name.
- 4: the rule is exempt while no card exists yet (the fallback) and for chart-less prompts. This is a transient state.
- 5: the name allowance covers the zh name.
- 7: the harness sets its environment before importing `app`.

Item 6 is left to the lab.

Status: spec-review → spec-approved.
