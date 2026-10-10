# dw-13-character-chat — the planet characters talk like a friend who knows your chart

## Goal

Each planet character becomes a person with a personality: a cached CHARACTER CARD drawn from the user's placement and written in no astrological vocabulary. The card takes up most of the system prompt. The chat keeps dw-10's checked phenomena, drops the dw-9 bans, and texts in a short, uneven rhythm. English first. Lab-verified with a multi-turn harness. QUEUE.md `dw-13-character-chat` (USER RULINGS 2026-09-29, tier 1); epic `pipeline/epics/divination-web.md`.

## Non-goals

- Tuning Chinese. zh is one English-worded line, "Reply in Simplified Chinese.", and no zh quality bar is set here.
- New routes, stores, tables, migrations or job kinds. The dw-7 voice topic, table, job and route are reused under a new VERSION.
- Any change to dw-10's tag grammar, the checks or the pill wire, the side read (mood + handoff), handoff behaviour, dice rolling, the sky computation or the summary job. (The tag PROMPT text is compressed and made sample-free; the summary's zh line loses its CJK.)
- Web redesign. Only the opening letter changes: it shows the greeting and loses the bias aside. The header's placement line stays.
- `app-native/`, and a lab for zh or for more than one birth chart.

## Decided defaults

1. **The character card.** It reuses `divination/voice.py`: topic `divination_voice`, `VERSION` 2, key unchanged (topic, VERSION, persona, lang, sheet facts), the same `divination_voice` table and the same job kind.
   - The job returns `{card, greeting}`.
   - `card`:
     - English, written in the second person ("You are …"), between 2,800 and 3,800 characters (the only enforced bound; roughly 480–650 words);
     - describes temperament, what the character cares about, how it talks, its quirks, one flaw, and how it treats a friend;
     - is drawn from the persona's base description (its domain) plus the sheet facts and meanings. `voice.py` registers each `personas/<id>.txt` as `base.<id>` on its OWN topic (reading the same file), so the voice FINGERPRINT covers it and voice never imports render; `voice_role.txt` tells the model not to use the planet's name in the card;
     - is server-only.
   - `greeting`:
     - the opening message in the request language, as that character, at most 200 characters;
     - may use the character's own name.
   - Both fields pass the ASTRO-VOCABULARY check (default 2). A hit, or a card outside its length bounds, REGENERATES, up to 3 attempts in all. After that the job fails (`AnalysisUnavailable`, nothing is stored, and the route answers 502 as today).
   - `intro`, `bias` and `style` are gone.
2. **Astro-vocabulary check.** `voice.astro_terms(text, allow=())` returns the hits, with one term list defined in one place:
   - the dictionary's `PLANETS`, `SIGNS` and `ASPECTS` keys;
   - `Ascendant`, `Midheaven`, `retrograde`, `zodiac`, `horoscope`, `natal`, `astrology`/`astrological`, `planet(s)`, `transit(s)`, `birth chart`;
   - the house pattern (an ordinal or number followed by "house").

   Words match case-insensitively on whole words. For a greeting, the character's own name is allowed. The allowance covers the character's name in both languages (e.g. Moon and 月亮). For a zh greeting, the same check also runs over a code-side list of zh planet, sign and aspect names. That list lives in code, not in a prompt.
3. **The system prompt,** in order:
   - (a) the identity line, `identity`: "You are {Name}, one of six planet characters this person talks to.";
   - (b) the CHARACTER: the cached card when the chart and card exist, else the persona's base description (`personas/<id>.txt`, rewritten as a character description without rules lists);
   - (c) `ground.rules`, at most six lines and at most 500 characters (leaving the tag block room, L4), exactly these five rules:
     - never claim to know what another person feels, thinks or intends;
     - never invent chart facts, transits or dates: use only the data below, and with no chart data, say you have not read their chart;
     - medical, legal or financial questions go to a professional;
     - never say you are an AI;
     - the six characters and their domains, in one line: name the one who reads a question better;
   - (d) the rhythm, `rhythm.chat` or `rhythm.deeper`: two friends texting. Each message sits on its own line. Most messages are one or two short sentences, and now and then one longer message carries a lot. Plain text only, no lists or markdown. Comfort is fine, and questions come when they come naturally. The deeper variant (at most 300 characters, like `rhythm.chat`) says: say more about your last message, taking it further;
   - (e) the data sections, as today: the chart with a short `chart.read` intro and no examples, the sky with `sky.read` compressed and no sample, the dice with `dice.brief` rewritten without its sample;
   - (f) dw-10's tag block, rewritten with placeholder syntax only;
   - (g) the language line.

   The following RETIRE: `shape.chat`, `shape.deeper`, `depth.chart`, `depth.none`, `self.read`, `self.marker`, `self.voice`, `roster.rules`, `roster.list`, `roster.timing`, `focus.*` and `chart.none`. The sheet JSON leaves the turn prompt; the card replaces it. The rule that the prompt carries exactly one of the sky section and `roster.timing` (dw-11) goes with `roster.timing`, and ground rule 2 covers the same ground.
4. **Proportion — one rule.** The card is at least as long as the whole shared instruction text in EVERY case, sky and dice included. The shared instruction text is everything except the character block and the JSON data lines. Three tiers, whatever the action (chat, cast or deeper): at most 1,900 characters with a chart and neither sky nor dice; at most 2,300 with exactly one of a sky section and dice (a cast, or `dice_in_view`); at most 2,800 with both. The card's minimum (2,800) is at least the highest tier, so the rule holds for every persona's maximal configuration (a sky-persona cast, or a sky-persona deeper turn with `dice_in_view`). With no cached card yet (the base-description fallback, P6) and in chart-less prompts the rule is exempt: a transient state until the card job lands. The chart/sky/dice JSON is excluded because it is data the character reasons from, not instructions — ruling (3)'s "bulk" is about what the character is told to be and do.
5. **No quotable samples, no CJK.** No divination prompt fragment of any of the three topics (`divination`, `divination_voice`, `divination_summary`) or any persona asset:
   - names a concrete placement, aspect or transit (a planet within one clause of a sign, a house or an aspect word, or a tag with concrete names), except the persona's own name in its identity and base description;
   - contains a CJK character (U+3000–U+9FFF, U+FF00–U+FFEF).

   The tag syntax is described as `⟦placement:<Body>|<Sign>|<House>⟧`. The P2 sample regex matches case-SENSITIVELY on capitalised names, so the common words square, cancer or mercury in lower case do not trip it. The ground-rule-5 roster line names domains only (for example "Mars: action and conflict") and passes it.
6. **Rhythm enforcement.** `bubbles.Budget` becomes a TOTAL sentence ceiling only: CHAT = 12 sentences, DEEPER = 20. A line break still ends a bubble. There is no per-bubble sentence cap, so a long message stays one bubble. At the ceiling the segmenter stops at the next visible character, never mid-sentence, as today.
7. **Web.** The persona wire becomes `schemaVersion: 2`, `voice: {greeting}`. Core `isPersonaWire` and `PersonaVoice` follow. The opening letter renders the greeting as prose, and `VoiceAside`, with its i18n `biasLabel`, is removed. Without a greeting, the static `roster.<id>.greeting` shows, as before.
8. **Lab — FIRST, then iterate.** The harness and its metrics are built BEFORE any prompt or card change and run once on the current (dw-10) prompts as a baseline, saved under `transcripts/baseline/`. The prompt and card work is then iterated in the lab until L1–L6 hold; every run's transcripts are kept (`transcripts/run-NN/`). The feature lands on the loop's own judgement (L7) without waiting for the user, who audits the transcripts later. A new script, `server/tests/prompt_lab/divination_chat_lab.py`. It is not collected by pytest; its pure metrics live in `divination_chat_metrics.py`, and those are unit-tested.
   - For each of the six characters it:
     - ensures the card via the real persona route with `JOBS_SYNC=1`;
     - runs a 10-turn English chat through the real turn route, in-process with TestClient and `ANALYSIS_LLM=claude-cli`, with birth data F (1990-06-15 08:30 Beijing);
     - drives the chat with a simulated user: one `llm.generate_sections` call per turn, given a fixed per-character scenario and the transcript, writing casual texting-register messages.
   - It saves each transcript (with the card and every SSE frame) to `pipeline/logs/dw-13-character-chat/transcripts/<run>/<persona>.json` plus a readable `.md`, and computes the metrics in `metrics.json`.
   - The loop reads the Moon transcript itself and records a judgement.
   - The harness sets `ANALYSIS_LLM=claude-cli` and `JOBS_SYNC=1` in the environment BEFORE importing `app`.
   - The baseline run tolerates the pre-change persona wire (v1 `{intro, bias}`, no card): the card fields are recorded as absent, and L6's card checks apply to the final run only.
   - For each sky persona, the harness logs the episode count of the turn's sky packet (read with the same `sky_context` call at the route's instant), so an L4 transit shortfall on an empty sky is not blamed on the prompt. If a sky persona's packet has no planet-target episode, L4's transit clause is waived for it, and that is recorded.
9. **Precedence.** User rulings (0)–(5) are tier 1. This supersedes:
   - dw-9's shape, depth and closing-question rules (its queue notes and its acceptance fix);
   - dw-7's mirror and owned bias (`self.read`, `intro`/`bias`/`style`, open call C);
   - dw-8's `roster.rules`, `roster.list` and `focus.*` text;
   - dw-11's `roster.timing` exclusivity;
   - dw-9's DEEPER budget (6 bubbles × 4 sentences = 24 possible → a total ceiling of 20);
   - the chart-less golden fixtures, which are re-recorded.

   The key keeps `lang`, so a placement gets one card per language (the card itself is always English; the greeting is per language) — accepted for simplicity.

   CLAUDE.md rules 9 and 10 are reworded: "voice" becomes character card, and the bubble cap becomes a total ceiling.

## Architecture

This section cites `pipeline/epics/divination-web.md` (the dw-7, dw-8, dw-9, dw-10 and dw-11 entries in "Built so far", and the dependency rules) and writes only dw-13's delta. It was confirmed by targeted reads on 2026-09-29 at `c5b1c7e`.

### Reuse (verified file:line)

| Need | Existing | Use |
|---|---|---|
| Cached per-placement job | `divination/voice.py` (`voice_key`, `generate_voice`, `cached_voice`, `cached_for`, `to_wire`); `generation.py:229` `ensure_divination_voice`; `main.py:503` `divination_persona_voice`; `main.py:453–469` the turn route's `cached_for` read | Kept as the card's machinery. `VERSION` 1 → 2 and the fields change; the key recipe does not |
| Store | `store.put_voice`/`get_voice`, table `divination_voice` (`voice_key`, `voice` TEXT JSON; migration 012) | Unchanged. The JSON payload is now the card record |
| Sheet | `persona.sheet_for` :120, `sheet_facts` :137 | The card job's input (facts plus meanings), unchanged |
| Prompt assembly | `render.system_prompt` :488–585, `tags_section` :590, `turn_messages` :611 | Reassembled per default 3 |
| Segmenter | `bubbles.Budget`/`CHAT`/`DEEPER`, `Segmenter._end_sentence` | The budget becomes a total-sentences ceiling |
| Tier B terms | `app.dictionary` `PLANETS`, `SIGNS`, `ASPECTS` | The source of `astro_terms`'s list; `voice.py` may import dictionary (divination may, rule 10) |
| Web opening letter | `ChatPanel.tsx:461–462` (intro Prose + `VoiceAside`); `PersonaHeader.tsx:86` `VoiceAside`; core `persona.ts:48, 111` | Greeting only |

### Module map (created or changed only)

```
server/app/divination/
├── voice.py             CHG  VERSION 2; VOICE_SCHEMA {card, greeting}; ASTRO_TERMS + astro_terms();
│                             generate_voice retries ≤3; to_wire → voice:{greeting}; lang lines CJK-free
├── voice_role.txt       CHG  the card brief (person, not placement; no astro words)
├── render.py            CHG  identity, ground.rules, rhythm.chat/deeper; retired fragments removed;
│                             system_prompt(persona, lang, ctx, cast, action, card, sky, dice_in_view);
│                             chart.read/sky.read/tags.* compressed, sample-free, CJK-free
├── personas/<id>.txt    CHG  six base character descriptions (no rules lists); dice.txt sample-free
├── (main.py unchanged: the route still hands the cached voice dict to turn_events; turn.py reads voice["card"])
├── bubbles.py           CHG  Budget(sentences) total ceiling; CHAT 12, DEEPER 20
├── summary.py           CHG  lang.zh CJK-free (provenance only)
└── turn.py              CHG  passes the card (voice["card"]) instead of voice; budget names
server/tests/
├── prompt_lab/divination_chat_lab.py      NEW  live harness (not collected)
├── prompt_lab/divination_chat_metrics.py  NEW  pure metrics
├── test_divination_chat_metrics.py        NEW  unit tests of the metrics
├── fixtures/divination_chartless_{en,zh}.txt  RE-RECORDED
└── test_divination_{render,turn,persona,roster,bubbles,sky,dice}.py  CHG  superseded assertions
packages/core/src/divination/persona.ts    CHG  PersonaVoice = {greeting}; schemaVersion 2
web-divination/src/chat/{ChatPanel,PersonaHeader}.tsx, i18n/{en,zh}.ts  CHG  greeting; no bias aside
```

### Contracts

(Also changed: `sky.py`'s docstring — its `roster.timing` degradation note becomes ground rule 2. Docs-sync gives the epic a dw-13 "Built so far" entry, rewords its "dw-7 voice store" dependency rule to the character card and restates the bubble budget as a total ceiling.)

- **`voice.generate_voice(sheet, persona, lang)`**
  - It sends one structured call per attempt, with at most 3 attempts. An attempt is accepted when `card` is 2,800–3,800 characters, `greeting` is 1–200 characters, and `astro_terms` finds nothing in either (the persona's own planet name is allowed in the greeting only).
  - It stores `{persona, lang, card, greeting, generatedAtUtc, model, promptVersion}`.
  - Each rejected attempt is logged at INFO with its reason. The log never holds the text. The next attempt's prompt names the rejected TERMS (never the text), and `voice_role.txt` lists the banned vocabulary verbatim.
- **`voice.astro_terms(text, allow=()) -> list[str]`**
  - It is pure. It uses one module-level `ASTRO_TERMS` built from the dictionary keys and fixed extras, plus `_HOUSE_RE`.
  - `ZH_ASTRO_TERMS` is a code constant (not a prompt), used only for zh greetings.
- **`voice.to_wire(sheet, voice)`** returns `{schemaVersion: 2, persona, lang, sheet, voice: {greeting}}`. `card`, `model` and `promptVersion` never leave the server.
- **`render.system_prompt(...)`**
  - Order: identity → character → ground.rules → rhythm → [chart.read + chart JSON] → [sky.read + sky JSON] → [dice.brief + dice JSON] → tags block → lang.
  - `card: str | None` replaces `voice: dict | None`. When there is no chart, `card` is ignored.
  - Without a chart there is no chart section at all; ground rule 2 covers "not read".
- **`bubbles.Budget(sentences: int)`**: `CHAT = Budget(12)`, `DEEPER = Budget(20)`. The segmenter ends a bubble only at a line break, and stops once the total sentence count reaches the ceiling and a new visible character arrives.
- **Lab.**
  - `divination_chat_lab.py --turns 10 --personas all --out <dir>` imports the app in-process, sets `JOBS_SYNC=1` and `ANALYSIS_LLM=claude-cli`, and captures `app.divination.turn` WARNINGs with a logging handler.
  - Metrics functions take a transcript and return plain dicts: `bubble_words`, `long_share`, `pill_counts`, `question_endings`, `self_intro_hits`.

### Dependency rules and forbidden edges

- `voice.py` now imports `app.dictionary`. That is a legal divination edge (rule 10); `persona.py` already does it. ❌ `render.py` and `turn.py` still never import `voice`, `store` or `summary`: the route hands the card string in (`test_divination_keeps_no_state` and the existing fence).
- ❌ The card never enters the side read, the summary or any wire. A test asserts that `card` is absent from the persona 200 body and from every SSE frame.
- ❌ The lab lives only under `server/tests/prompt_lab/` and writes only under `pipeline/logs/`. Nothing in `app/` imports it.
- The web keeps every dw-1 guard. The removed i18n keys go from both `en` and `zh`, which keeps parity.

### CLAUDE.md amendments (same commit)

- **Rule 9:** "persona voice cache" becomes "the persona CHARACTER CARD cache (`divination_voice`, VERSION 2)", with the key unchanged.
- **Rule 10:**
  - the dw-7 sentence names the card job and says the turn reads the cached card;
  - the dw-9 bubble sentence becomes "a total sentence ceiling per action (chat 12, deeper 20); a line break ends a bubble";
  - the dw-8 sentence "A prompt carries exactly one of `roster.timing` and the sky section" is removed.
- **New sentence:** "Divination prompts are English-only text (no CJK) and give no quotable sample placements (dw-13, pinned by tests)."

## Acceptance Criteria

Server checks run under `conda run -n astrology pytest`, client checks under `npm test`, and the lab as in default 8.

**Prompt (unit)**
- P1. A test walks every registered fragment of `divination`, `divination_voice` and `divination_summary` and every file in `divination/personas/`, and finds no CJK character.
- P2. None of those texts contains a concrete sample. The test regex matches a planet name followed within 40 characters, and within the same sentence, by a sign name, an aspect word or `house`, and it matches a tag with a capitalised concrete name (`⟦\w+:[A-Z]`). Each persona's own planet name standing alone in its identity line and base description is allowed. A planted sample turns the test red.
- P3. The retired fragments (default 3) are absent from the topic. No fragment contains "sharp question", "generic comfort", "question mark", "one question" or "Barnum".
- P4. `ground.rules` has at most 6 lines and at most 500 characters, and names the other person's feelings, invented facts or dates, professionals, AI, and the six characters.
- P5. With fixture F and a cached card of exactly 2,800 characters. The shared instruction text is the prompt minus the card and minus the data blocks, each data block being its marker line plus the single-line JSON after it (`json.dumps` without indent). Then:
  - for each of venus, mars and mercury on a chat turn with no sky or dice, the system prompt contains the card, contains neither the base description nor the sheet JSON, and its shared text is at most 1,900 characters;
  - for moon, saturn and jupiter chat with a sky packet, and for a venus cast, the shared text is at most 2,300 characters;
  - for a CAST with a sky packet by each of moon, saturn and jupiter, and for a moon DEEPER turn with a sky packet and a transcript roll (`dice_in_view`), the shared text is at most 2,800 characters;
  - in every case the shared text is no longer than the card.
- P6. With a chart but no cached card, the base description stands in. Without a chart, the prompt equals the re-recorded chart-less golden fixture for each of the six personas in en and zh.
- P7. `deeper` turns carry `rhythm.deeper` and chat and cast turns carry `rhythm.chat`. dw-10's tag block is still present with a chart (the dw-10 T8 test passes, amended only where it named retired fragments).

**Card job (unit, fake llm)**
- K1. `generate_voice` stores `{card, greeting, …}` under `VERSION` 2. A card containing "Taurus" on the first attempt and a clean card on the second stores the clean one, after 2 llm calls. Three dirty attempts raise `AnalysisUnavailable` and store nothing.
- K2. `astro_terms` flags `Taurus`, `trine`, `seventh house`, `10th house` and `retrograde`, and does not flag "a house by the sea" or "fall". For a Moon greeting it allows "Moon" and flags "Moon in Pisces" through `Pisces`. A zh greeting containing `金牛座` is flagged.
- K3. A card shorter than 2,800 or longer than 3,800 characters regenerates just as a vocabulary hit does, and the retry prompt names the rejected terms but not the rejected text.
- K4. `POST /api/divination/persona` returns 200 `{schemaVersion:2, …, voice:{greeting}}`. `card` never appears in any response body. The turn route passes the cached card into the prompt.

**Rhythm (unit)**
- B1. One line of 6 sentences gives one bubble, where dw-9 gave two.
- B2. A chat reply of 15 one-sentence lines is cut after the 12th sentence, and a deeper reply after the 20th. The cut never falls mid-sentence, and the provider is cancelled.
- B3. The existing typography rules still hold: line breaks, `3.5`, CJK terminators, and chunk-boundary independence. The dw-9 tests are rewritten only where they asserted the per-bubble cap.

**Client**
- W1. Core `isPersonaWire` accepts `schemaVersion 2` with `voice.greeting` and rejects the v1 `{intro, bias}` shape.
- W2. The web opening letter shows the greeting text. No `VoiceAside` or bias element renders. `npm test` and `npm run typecheck` pass, and the i18n parity holds.

**Suites and docs**
- G1. The full server suite, `npm test` and `npm run typecheck` pass. `test_handoff_is_never_parsed_from_the_reply` and the dw-10 boundary tests are unchanged.
- G2. By grep, CLAUDE.md rule 9 names the character card, and rule 10 describes the total sentence ceiling and names the card and not the "voice".

**Lab** (real claude-cli; metrics computed by the unit-tested `divination_chat_metrics.py` over `pipeline/logs/dw-13-character-chat/transcripts/<final-run>/`)
- L1. All six conversations have 10 completed turns, with no `error` event.
- L2. Across all bubbles, where a pill counts as its en label's words, the median word count is at most 22 (a placement pill counts as "Body in Sign" plus ", house N" when present, an aspect or transit pill as "A type B", a dice pill as its value — defined once in the metrics module) and at least 70% of bubbles are at most 30 words.
- L3. Bubbles over 40 words make up between 2% and 20% of all bubbles, and appear in at least 2 of the 6 conversations.
- L4. Each conversation has at least 3 checked pills. Each of moon, saturn and jupiter has at least 1 transit pill. Failed or malformed tags (the server WARNINGs captured by the lab) are at most 10% of all tags.
- L5. In no conversation do more than 60% of replies end their last bubble with "?". There are zero matches of self-introduction by placement (`\b(I'?m|I am|as) your (Sun|Moon|Mercury|Venus|Mars|Jupiter|Saturn)\b`).
- L6. All six stored cards have zero `astro_terms` hits and are 2,800–3,800 characters long (final run only). `transcripts/baseline/` (the pre-change run) exists beside the final run.
- L7. The validating log quotes three consecutive Moon turns. It records the loop's judgement that the chat reads like texting a friend who knows the chart, noting short messages, a distinct personality and real phenomena, with no stock bans visible.
