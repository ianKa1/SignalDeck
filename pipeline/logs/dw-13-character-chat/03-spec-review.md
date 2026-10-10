# dw-13-character-chat — 03 spec-review round 2 (2026-09-29)

This was a fresh-context general-purpose subagent. It used the same inputs as round 1 and also read the round-1 log.

## Verdict (verbatim)

VERDICT: FAIL. There is one blocking issue: the unfinished half of round-1 item A. The fix is small and local. Round-1 item B (LAB FIRST) is genuinely resolved, and the rest of the spec is sound.

Verified at HEAD (c5b1c7e, clean tree):
- `render.system_prompt` is at :488, `tags_section` at :590 and `turn_messages` at :611.
- `bubbles.CHAT = Budget(4,3)` and `DEEPER = Budget(6,4)`, so B1's "dw-9 gave two" is right, and 24→20 is right.
- The dictionary has PLANETS = the ten bodies and ASPECTS = the five Ptolemaic types.
- Every persona can cast (turn.py:280–300; the Cast button is not gated by persona), and `dice_in_view` adds `tags.dice` on every later turn after a cast.

Checklist:
1. **Serves the notes, right-sized.** Yes.
   - Ruling (0): covered by P1, and zh becomes one English line.
   - Ruling (1): the card replaces intro/bias/style, the astro-term check regenerates (K1–K3, L6), `self.read` is retired, and L5 has the self-intro regex.
   - Ruling (2): phenomena stay via dw-10 tags (L4). Comfort is allowed and questions are optional (the rhythm text, and L5's ≤60%).
   - Ruling (3): five ground rules (P4), and the dw-9 bans are retired (P3). The Supersedes list correctly treats dw-9, dw-7, dw-8 and dw-11 as tier 3.
   - Ruling (4): a total ceiling only (B1, B2). L2 and L3 are distribution metrics, not caps, which fits "illustrative, not a cap".
   - Ruling (5): covered by P2.
   - LAB FIRST is now an explicit order in default 8: harness and metrics first, a baseline in `transcripts/baseline/`, iterations in `run-NN/`, and L6 checks that the baseline exists.
   - "Loop closed" is L7, with the loop landing on its own judgement.
   - One acknowledged deviation: the key keeps `lang`, so there is one card per language (default 9). That is acceptable.
2. **Checkable.** Yes, apart from the proportion gap below.
3. **Architecture Contract.** No violations.
   - `voice.py` → `app.dictionary` is a legal rule-10 edge.
   - `render` and `turn` still never import voice, store or summary; the route hands the card string in.
   - The card never goes on the wire (K4 and the forbidden-edge test).
   - The rule 9 and rule 10 amendments and the new no-CJK / no-sample sentence are listed.
   - The epic divergences (the dw-7 voice store, the dw-9 bubble budget, dw-11 exclusivity) are stated and handed to docs-sync.
4. **Non-goals and defaults.** Non-goals are stated, and the round-1 non-blocking item 1 is fixed. Every open point has a decided default.

BLOCKING
A′. Default 4 is untested and likely unmet in the heaviest configurations.
- Where: default 4 and P5.
- The gap: default 4 says the card is at least the shared text "in EVERY case, sky and dice included", with shared text capped at 2,300 "with a sky section and/or dice". But P5 tests only three setups: venus/mars/mercury chat without sky, moon/saturn/jupiter chat with sky, and a venus cast (dice, no sky). The acceptance stage checks only the listed criteria. Three cases go unchecked:
  - a sky-persona CAST, which carries the sky section, dice.brief, the dice JSON, tags.sky and tags.dice;
  - a sky-persona chat or deeper turn after a cast (`dice_in_view` adds tags.dice);
  - a deeper turn with sky.

  These are exactly where the rule is most at risk.
- Measurements: the fragments today are tags.rules 850, tags.natal 476, tags.sky 378, tags.dice 226, chart.read 783, sky.read 1,122, dice.brief 1,485 and shape.chat 474 characters.
- Aggressively compressed estimate:
  - chart base ≈ 1,550–1,900: identity 70, ground.rules 380–450, rhythm 250, chart.read 200–350, tags.rules 350–450, tags.natal 200–250, markers/lang/separators ~80;
  - sky add-on ≈ 550: sky.read ~350 (it still needs its window, pass, building/easing and open-end date rules), marker 40, tags.sky ~150;
  - dice add-on ≈ 500: dice.brief ~350, marker 16, tags.dice ~130.
- So a sky-persona cast comes to about 2,600–2,950 characters. That is above both the 2,300 cap and the card's 2,300 minimum, which violates default 4 and with it tier-1 ruling (3). Squeezing it under 2,300 means cutting sky.read's date rules or the tag rules, which risks dw-11's date truth and L4 (tag failures ≤10%).
- Fix: pick one option and apply it identically in default 4 and P5.
  - (i) Keep 2,300, and add two P5 cases: a moon cast with a sky packet, and a moon deeper turn with sky and `dice_in_view`. Each must have shared text ≤2,300 and ≤ the card. Accept that sky.read, dice.brief and the tag block must be compressed to fit.
  - (ii) Preferred: add a third tier.
    - Sky plus dice ≤2,800 characters.
    - Raise the card bounds to about 2,800–3,800 characters (about 480–650 words) in default 1, the `generate_voice` contract, K3 and L6.
    - Make P5's fixture card 2,800 characters.
    - Add the sky+dice and dice-in-view cases to P5.
  - (iii) State one formula and test it per persona: P5 asserts that each persona's MAXIMAL configuration (sky if it is a sky persona, plus a cast, plus deeper) has shared text ≤ the card minimum. Size the minimum to match.

NON-BLOCKING
1. The baseline run on dw-10 code: the persona route returns the v1 `{intro, bias}`. Say that the harness and metrics tolerate a missing card for the baseline, and that L6's card checks apply to the final run only.
2. The P2 regex: say it matches case-SENSITIVELY, or "square", "cancer" and similar words will trip it. Confirm that the ground-rule-5 roster line ("Mars — action and conflict; …") and the six base descriptions pass it as written.
3. L4 needs ≥1 transit pill for each of moon, saturn and jupiter. That assumes chart F's sky packet on the lab date has an episode touching each planet. The harness should log the packet's episode count, so a failure caused by an empty sky is not blamed on the prompt.
4. Only the deeper rhythm variant's wording is given. Give its length, because it counts toward the shared-text cap on deeper turns.
5. "The prompt minus the card and every JSON line" relies on the data being single-line JSON (true today: `json.dumps` without indent). Say so in P5, or have the test strip by marker lines rather than by a leading brace.
6. "About 400–600 words" and "2,300–3,400 characters" agree only roughly. Make the character bounds the only enforced ones (K3 implies this) and drop or soften the word range.
7. The module map omits main.py. That is fine if the route keeps handing the voice dict to `turn_events` and turn.py extracts `card`; list it if main.py changes.

## Coordinator revision (round 2 → round 3)
- A′: took option (ii) combined with (iii).
  - Default 4 now has three tiers, whatever the action: ≤1,900 characters with neither sky nor dice, ≤2,300 with one of them, ≤2,800 with both.
  - The card is 2,800–3,800 characters, and characters are the only enforced bound. This is updated in default 1, the contract, K3 and L6.
  - P5 uses a fixture card of exactly 2,800 characters and adds a moon cast with sky and a moon deeper turn with sky and `dice_in_view`.
  - P5 now defines the shared text by stripping each data block's marker line plus its single-line JSON.
- Non-blocking items:
  - 1: the baseline tolerates a missing card; L6 is final-run only.
  - 2: P2 is case-sensitive, and the roster line names domains only.
  - 3: the harness logs the sky episode count, and the transit clause is waived on an empty sky.
  - 4: rhythm.deeper is ≤300 characters.
  - 5: JSON stripping is by marker.
  - 6: the character bound is the only one enforced.
  - 7: the module map notes that main.py is unchanged.
- Sent to review round 3. Per PIPELINE: a third failure makes 2 failed revision rounds, and the feature is then `blocked`.
