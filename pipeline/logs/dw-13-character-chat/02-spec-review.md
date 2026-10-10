# dw-13-character-chat — 02 spec-review round 1 (2026-09-29)

Fresh-context general-purpose subagent. Inputs: the QUEUE entry, the spec, the epic, CLAUDE.md, and PIPELINE.md's Spec requirements and Decision precedence.

## Verdict (verbatim)

VERDICT: FAIL. There are two blocking problems, and both have small, local fixes. The rest of the spec is sound: it serves the user's intent, it is right-sized, and its code citations are accurate.

Checked against the code at c5b1c7e:
- The voice.py machinery exists as the spec describes.
- main.py:453–469 is the turn route's `cached_for` read, and main.py:503 is the persona route.
- render.py: `system_prompt` is at :488–585, `tags_section` at :590 and `turn_messages` at :611.
- bubbles.py has `Budget(4,3)` and `(6,4)`.
- `ChatPanel.tsx:461–462`, `PersonaHeader.tsx:86` and core `persona.ts:111` are all as cited.
- The dictionary's `ASPECTS` has exactly the five Ptolemaic keys. ELEMENTS and MODALITIES are separate dicts, so `astro_terms` will not flag "air", "fixed" and similar words.
- The chart-less goldens are one file per language with the persona base swapped in (T8), so P6's "each of six personas" form is feasible.

Checklist:
1. **Serves the user's notes.** Mostly yes.
   - Ruling (0): English-first and CJK-free prompts are covered by P1, with zh as one English line.
   - Ruling (1): the cached card has no astro vocabulary and uses a regeneration check. The self-intro and the owned bias are dropped, and `self.read` is retired. Covered by K1–K3 and L5–L6.
   - Ruling (2): astrology stays, via dw-10 pills. Comfort is allowed and questions are optional. Covered by L4 and L5.
   - Ruling (3): the ground rules drop to five, and the depth/shape bans are retired. Covered by P3 and P4.
   - Ruling (4): a total ceiling only. Covered by B1 and B2.
   - Ruling (5): no samples. Covered by P2.
   - "Loop closed" is covered by L7 plus the lab metrics.
   - LAB FIRST is not honoured as a sequence (blocking item B).
   - Retiring `focus.*` and `roster.*` is justified. `focus.*` would fail P2 anyway, because it contains "Venus, the Moon, Mars, the 5th and 7th houses", and the proportion ruling needs the cut. No invented scope.
2. **Checkable.** Yes, except that P5 contradicts itself (blocking item A).
3. **Architecture Contract.** No violation.
   - `voice.py` importing `app.dictionary` is a legal divination edge.
   - `render`/`turn` still never import voice, store or summary; the route hands the card string in.
   - The card never goes on the wire.
   - The CLAUDE.md rule 9 and 10 amendments are listed, and the Supersedes list follows the precedence rules.
4. **Non-goals and defaults.** Non-goals are stated, and every open point carries a decided default.

BLOCKING
A. The proportion defaults contradict P5, and the sky case breaks ruling (3).
- Default 4 says that with sky the shared text is ≤2,300 characters and the card is "still the largest block", which compares the card with single blocks.
- P5 says the shared text is ≤2,300 "and shorter than the card", which compares it with the whole shared text. P5's setup is a 1,600-character card, so the 2,300 bound is moot there.
- Read as default 4 intends, a sky persona could carry 2,300 characters of shared text against a 1,600-character card, so the card would not be "the bulk of the system prompt" (user ruling 3).
- Fix: state one rule identically in both places. The card is ≥ the whole shared instruction text in every case, sky included. Either cap the sky-case shared text at the card minimum, or raise the card's lower bound (default 1, K3, L6) to at least the sky-case cap, e.g. a 2,300–3,200 character card with P5's fixture card at that minimum.
- Also state why the chart, sky and dice JSON are excluded from "bulk": they are data, not instructions.

B. LAB FIRST is not honoured as an ordering. Default 8 and the L criteria define the harness only as an acceptance check.
- Fix: build the harness and its metrics first; run them once on the current prompts as a baseline (`transcripts/<baseline-run>/`); iterate the prompt and card work in the lab until L1–L6 hold, keeping every run's transcripts; then land on the loop's judgement (L7) without waiting for the user.

NON-BLOCKING
1. The non-goals bullet about dw-10's tags conflicts with defaults 3(f) and 5. Reword it to: no change to the grammar, checks or pill wire; the tag prompt text is compressed and made sample-free.
2. 1,600 characters is tight, because `tags.rules` is about 900 characters today. Over-compressing it risks L4. Consider a cap of ≤500 for `ground.rules`.
3. A case-insensitive whole-word `astro_terms` will flag ordinary words (sun, moon, square, opposition, conjunction, Mercury). Risk: the job fails three times and answers 502. Mitigate by listing the banned words in `voice_role.txt` and feeding the hit TERMS (not the text) back into the retry.
4. Because the key keeps `lang`, each placement gets two English cards. Acceptable, but say so.
5. L2's pill word count needs a definition in the metrics module.
6. Add `sky.py`'s docstring to the module map. Docs-sync should add a dw-13 epic entry, reword "dw-7 voice store" and restate the bubble budget as a total.
7. Record the DEEPER change from 24 to 20 as a deliberate supersession.

## Coordinator revision (round 1 → round 2)
- A:
  - One rule in default 4 and P5: the card is ≥ the whole shared text in every case.
  - The card is 2,300–3,400 characters (default 1, K1/K3 contract, L6).
  - Shared text is ≤1,900 characters without sky or dice, and ≤2,300 with sky and/or dice.
  - P5's fixture card is exactly 2,300 characters, and the JSON exclusion is justified.
- B: default 8 is now LAB FIRST. The baseline run goes to `transcripts/baseline/`, iteration runs go to `run-NN/`, and L6 checks that the baseline exists.
- Non-blocking:
  - 1: the non-goal is reworded.
  - 2: `ground.rules` is capped at ≤500 characters (default 3c, P4).
  - 3: the retry names the rejected terms, and `voice_role.txt` lists the banned words (contract, K3).
  - 4: the per-language card is noted in default 9.
  - 5: pill word counts are defined in L2.
  - 6: `sky.py` is in the module map, with an epic note.
  - 7: DEEPER 24→20 is added to Supersedes.
- The revised spec goes to a round-2 review.
