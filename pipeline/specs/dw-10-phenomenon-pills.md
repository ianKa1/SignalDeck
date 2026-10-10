# dw-10-phenomenon-pills — every astrological claim in a reply is a checked pill

## Goal

A character writes each phenomenon it names (a natal placement or aspect, a current transit, a die face) as a closed-vocabulary inline tag. The server checks each tag against the turn's real chart, sky packet or roll and streams it as a `pill` event, or as plain text plus a log line when the check fails. The web renders pills inline in the slips, with glyphs, tone colour and a translated label; tapping one lights the wheel and shows a one-line meaning. QUEUE.md `dw-10-phenomenon-pills`; user ruling B (DECISIONS.md, 2026-09-29 · dw-10-phenomenon-pills · user ruling); epic `pipeline/epics/divination-web.md`.

## Non-goals

- Parsing any OTHER field out of the prose. Mood and handoff stay side-read fields, and the dice roll stays the server's `dice` event. `test_handoff_is_never_parsed_from_the_reply` stays as it is.
- Tags in USER messages. A user line renders verbatim, whatever it contains.
- Tags for anything outside the four kinds below: no houses alone, no signs alone, no dignities, no nodes, no Chiron, no angles other than the Ascendant, no transits to angles or cusps, no progressions.
- Re-checking tags in the transcript the client sends back. That text is model input only.
- Any change to the dw-6 summary route, its store or its key. (The web renders the summary card's generated text through `splitPills` too, so an echoed canonical tag shows as a static pill, not brackets.)
- `app-native/`. Storage and the history journal are untouched. There are no new routes, stores, jobs or migrations.
- Translating the degraded plain text of a failed tag. It stays English words inside the reply.

## Decided defaults

1. **Tag grammar.** A tag is `⟦kind:field|field…⟧`, opened by U+27E6 and closed by U+27E7. It has at most 64 characters between the brackets and never contains a line break or a second opener. Names are canonical English whatever the reply language. Kind and names match case-insensitively and surrounding whitespace is ignored. There are four kinds:

   | Tag | Example (fixture chart, 1990-06-15 08:30 Beijing) | Checked against |
   |---|---|---|
   | `placement:Body|Sign` or `placement:Body|Sign|House` | `⟦placement:Venus|Taurus|10⟧` | The turn's natal chart. Body is one of the ten planets or `Ascendant`. The sign must be the chart's sign, and a given house must be the chart's house. The Ascendant takes no house. With `timeUnknown`, any house and any Ascendant tag fail. |
   | `aspect:A|type|B` | `⟦aspect:Venus|trine|Saturn⟧` | The chart's aspects, in either order. Both ends are in `persona.SHEET_POINTS`. The pill carries the chart's own a/b order. |
   | `transit:Moving|type|Target` | `⟦transit:Saturn|square|Mars⟧` | The turn's dw-11 sky packet. An episode must have that `transiting`, that `type`, and a `target` that is a natal planet (`targetKind` `planet`), with both names among the ten planets. With no sky packet, every transit tag fails. |
   | `dice:face|value` | `⟦dice:planet|Pluto⟧`, `⟦dice:house|7⟧` | The rolls in view: this turn's cast, plus every `dice` on the request's persona transcript entries. The face (`planet`, `sign` or `house`) must equal that face of one roll in view. |

2. **The stream filter.** A pure scanner sits after dw-9's bubble segmenter, on its `delta` text. The segmenter is unchanged.
   - Text outside a tag passes through at once: text before an opener is framed before the scanner waits for the closer.
   - A complete tag is checked. It becomes a `pill` frame if it passes. If it fails, it becomes a `delta` of fallback text: `Venus in Taurus, house 10`, `Venus trine Mars`, `Saturn square Mars`, `Pluto` / `Leo` / `house 7`.
   - A malformed tag is emitted as its inner characters as plain text, brackets dropped. That covers an unknown kind, a wrong field count, an over-length or unclosed tag, a line break, a nested opener, a bubble boundary or the stream's end while open. A stray `⟧` is dropped.
   - As a result, `⟦` and `⟧` never appear in any `delta`.
   - Every failed or malformed tag logs one WARNING from `app.divination.turn` with the kind and the reason (`not-in-chart`, `no-sky`, `no-roll`, `malformed`, …). The log never includes birth data.
3. **`pill` event.** Its data is exactly one of these:
   - `{kind:"placement", body, sign, house:int|null}`
   - `{kind:"aspect", bodyA, type, bodyB}`
   - `{kind:"transit", transiting, type, target}`
   - `{kind:"dice", face, value}`, where `value` is a string for planet/sign and an int for house.

   Order is `dice`? → (`delta` | `pill` | `bubble`)* → `done` | `error`. A `bubble` is sent just before the first `delta` OR `pill` of its bubble: `turn.py` holds a pending `bubble` frame until that bubble's first non-empty item, so a bubble left empty by the filter is collapsed (the next bubble frame reuses its index; indices stay consecutive). A reply that is only pills counts as a reply (it is not "ended without a word").
4. **chartRefs: pills are the single source.** Supersedes dw-3's side-read refs. `done.chartRefs` is built from this turn's checked NATAL pills, in order:
   - a planet `placement` gives a planet ref;
   - an `aspect` gives an aspect ref;
   - `Ascendant` placements, transit pills and dice pills give none.

   The refs are de-duplicated and capped at `REFS_MAX` = 6, through the existing `to_wire_refs`. The side read now asks for `mood`, plus `handoff` on chat turns, only. The `side.refs`, `side.dice` and `side.sky` fragments and the catalogue in its payload are deleted. The `done` shape and the wheel behaviour of dw-4 are unchanged.
5. **Prompt.** There is one new block of fragments on the `divination` topic, placed after the dice section and before the language line:
   - `tags.rules`: write every placement, aspect, transit or die face you name ONLY as a tag, English names inside; the tag stands in the sentence as a noun phrase; never invent one;
   - `tags.natal`, when there is a chart;
   - `tags.sky`, when there is a sky section;
   - `tags.dice`, on a cast or with a transcript roll.

   The block is present only when at least one of those grounds exists. The chart-less, dice-free chat prompts stay byte-identical to the golden fixtures. The plain-words examples in `chart.read`, `self.read` and `sky.read` are rewritten in tag form. FINGERPRINT moves; that is provenance only.
6. **Client storage.** The web client writes each pill into the reply text as its canonical token. The token uses the same grammar and canonical casing, with no house field when `house` is null. The transcript store, the wire `toWire` and the session log are unchanged and simply carry these tokens. A later turn therefore shows the model its own earlier pills as tags.
   - Core owns the token helpers: `pillToken`, `splitPills` and `isPill`. `splitPills` only yields pills that pass `isPill`; anything else stays text.
   - Persona text is split into pills. User text never is.
7. **Rendering.** A pill is an inline element in the slip, at its place in the sentence, and never breaks inside.
   - It shows a glyph cluster: `♀△♂`; `♀♉︎` plus the house number; `♄□♂` for a transit; the die face's glyph or number for dice.
   - It shows a label from the web dictionary: en `Venus trine Mars`, zh `金星三分火星`, rendered at display time.
   - It carries `data-source` (`natal`, `sky` or `dice`), with a distinct style per source: natal is an engraved seal, sky a dashed orbit with a small "now" mark, dice a die-cut corner.
   - For an aspect or transit it carries `data-tone`: `harmonious` (trine, sextile), `tense` (square, opposition) or `fused` (conjunction). The tone comes from a new one-definition table `ASPECT_TONES` in `core/chart-view` and is coloured from the existing `--aspect-*` tokens.
   - Pills in a streaming slip are static. Pills in stored entries are `button[aria-pressed]`.
8. **Tapping a stored pill.** The pill takes dw-4's pressed-chip slot, with id `"<entry>:p<n>"`. The activation store now keeps a pressed id with empty refs, and the wheel stays neutral in that case.
   - What the wheel lights: a natal pill lights its ref. A transit pill lights its natal target planet. A dice `planet` face lights that natal planet. A dice sign or house face lights nothing.
   - A one-line meaning appears under the letter that holds the pill (`role="note"`). It is composed from the web dictionary's new `lore` namespace: short en/zh meanings for the ten planets, the Ascendant, the 12 signs, the 12 houses and the 5 aspect types. The en rows are copied from Tier B (`dictionary/symbols.py`). There is no parity test against Tier B; like tokens, the rows may diverge.
   - Pressing the pill again clears it. Pressing another pill switches to it. A new turn clears it.
9. **Chips.** The dw-3 chip row renders only for a LEGACY entry, one whose text holds no pill token. Old transcripts keep their chips, and new replies show pills instead. `SessionTranscript` renders pills statically and keeps its seals row for legacy entries only.
10. **Placement of the exception.** CLAUDE.md rule 10 states the phenomenon-tag exception where the divination grammar is described. Rule 8 records the web `lore` namespace. Rule 1's chart-view enumeration gains `ASPECT_TONES`. The epic's event grammar gains `pill`.

## Architecture

This section cites `pipeline/epics/divination-web.md` for the reuse map, the event grammar, the dependency rules and "Built so far" through dw-11, and writes only dw-10's delta. It was confirmed by targeted reads on 2026-09-29 against `bfcd0f7`.

### Reuse (verified file:line)

| Need | Existing | Use |
|---|---|---|
| The stream loop | `divination/turn.py:273–311`: the Segmenter ops become frames, then `_side_read`, then `done` | Insert the scanner between the ops and the frames. `sent` also becomes true on a pill. |
| Bubble cutting | `divination/bubbles.py` (pure, typography only) | Unchanged. The scanner runs on its `delta` text, and its `bubble` op is a tag boundary. |
| Allowed natal refs | `render.ref_catalogue` `:387` (ids `planet:<Body>` and `aspect:A|t|B`, chart order); `to_wire_refs` `:677` (catalogue-only, dedup, cap 6) | `to_wire_refs` stays the ONE ref shaper and now takes ids derived from the natal pills. The catalogue stays the check set for refs. |
| Ref ends | `persona.SHEET_POINTS` `:49` (ten planets plus the Ascendant) | The aspect ends and placement bodies a tag may name |
| Sky packet | `sky.sky_view` `:103` (episodes `{transiting, target, targetKind, type, …}`) | Transit tags are checked against `episodes` by equality |
| Roll | `dice.Roll`, and `turn._wire_entry` `:227` re-sending `dice` | The dice tags' ground |
| Side read | `render.side_prompt` `:593`, `side_schema` `:631`, `turn._side_read` `:193` | Loses refs, the catalogue, and the `side.dice` / `side.sky` fragments; keeps mood and handoff |
| Client stream | core `divination/turn.ts:77–111` (per-event guards) | Add a `pill` branch; the bubble guard accepts a preceding pill |
| Pacing | web `chat/pacer.ts` (text-only queue) | A pill enters as a `delta` whose text is its token; the pacer is unchanged |
| Slip render | `ChatPanel.tsx` `Slips` `:105`, `Entry` `:287`, `ChartRefChips` `:186` | Slips render through `PillText`; the chip row is gated on legacy |
| Press slot | `chart/wheel-activation.ts` `showRefs` `:34` (empty refs clear) | Allow `{refs: [], chip}` when a chip id is given; `activationFor([])` stays null |
| Glyphs | `core/chart-view/glyphs.ts` (`PLANET_GLYPHS`, `SIGN_GLYPHS`, `ASPECT_GLYPHS`, `ASCENDANT_GLYPH`) | Pill glyph clusters; `ASPECT_TONES` joins this file |
| One-definition guard | `app-native/src/architecture.test.ts:254`, `:303` | Enumerates `ASPECT_TONES` |

### Module map (created or changed only)

```
server/app/divination/
├── tags.py        NEW  pure: KINDS, Ground, Pill (dict), check(body, ground),
│                       Scanner(ground).feed(text)/boundary()/close() → items
├── turn.py        CHG  Ground built per turn; ops → scanner → delta/pill frames;
│                       failures logged; refs from natal pills; side read = mood+handoff
└── render.py      CHG  tags.* fragments + tags_section(); side.refs/dice/sky deleted;
                        side_prompt/side_schema lose the catalogue; chart.read,
                        self.read, sky.read examples in tag form; pill_ref_ids()
packages/core/src/
├── divination/pills.ts   NEW  Pill, isPill, pillToken, splitPills, pillRef,
│                              pillSource, PILL_KINDS
├── divination/types.ts   CHG  TurnEvent + {type:'pill', pill}
├── divination/turn.ts    CHG  pill frames; bubble after a pill
├── divination/index.ts   CHG  barrel exports
└── chart-view/glyphs.ts  CHG  ASPECT_TONES (+ index export)
web-divination/src/
├── chat/Pill.tsx          NEW  Pill (static | pressable), PillText (splitPills → runs)
├── chat/pill-meaning.ts   NEW  pure: pill → label and meaning line from Dict
├── chat/useChat.ts        CHG  pill event → pacer delta(pillToken)
├── chat/ChatPanel.tsx     CHG  Slips via PillText; pressed-pill note; legacy-only chips
├── chat/chat.css          CHG  .chat__pill rules per data-source / data-tone
├── chart/wheel-activation.ts CHG  pressed id with empty refs
├── log/SessionTranscript.tsx CHG  PillText static; legacy-only seals
└── i18n/en.ts, zh.ts      CHG  `pills` (label templates, note label), `lore`
```

### Contracts

**`tags.py`**
- It is pure: it imports only the stdlib, `app.chart.points.PLANET_NAMES` and `.persona.SHEET_POINTS`. It has no logging, clock, `re`, llm, prompts or store.
- `KINDS = ("placement", "aspect", "transit", "dice")` is pinned.
- `Ground(chart: dict | None, sky: dict | None, rolls: tuple[dict, ...])`, where each roll is `{planet, sign, house}`.
- `check(body: str, ground) -> tuple[dict | None, str, str]` returns `(pill, fallback_text, reason)`. `pill` is not None exactly when `reason == "ok"`. For a malformed body, `fallback_text` is the body itself.
- `Scanner(ground)`:
  - `feed(text) -> list[Item]`;
  - `boundary() -> list[Item]` is called before a `bubble` op and flushes an open tag as malformed;
  - `close() -> list[Item]`;
  - `failures -> list[(kind, reason)]` accumulates.
- An `Item` is `("text", str)`, never empty and never containing a bracket, or `("pill", dict)`.
- Output is independent of chunk boundaries.

**`turn.py`**
- It builds `Ground(ctx.chart if ctx else None, sky_packet, rolls)`, where `rolls` is this turn's cast (`dice.to_wire`) followed by each transcript `dice`.
- For each segmenter op: a `bubble` op sends `scanner.boundary()` items, then the `bubble` frame. A `delta` op sends `scanner.feed(text)` items. At `_END` or at the cap it sends `scanner.close()` items.
- Text items become `delta` frames and pill items become `pill` frames.
- After the loop, each failure logs one `log.warning("divination turn: tag %s failed: %s", kind, reason)`.
- `done.chartRefs = render.to_wire_refs(render.pill_ref_ids(pills), catalogue)`.
- It still imports no `re`, and `_side_read` returns `(mood, handoff)` only.

**`render.py`**
- `pill_ref_ids(pills) -> list[str]`:
  - a placement of a planet gives `planet:<Body>`;
  - an aspect gives `aspect:A|t|B`;
  - anything else gives nothing.
- `tags_section(has_chart, has_sky, has_dice) -> str` returns `""` when none of the three holds. It sits in `system_prompt` between `dice_section` and the `lang.*` line.
- `turn_messages` and `system_prompt` gain `dice_in_view: bool`. It is passed from `turn.py`'s existing `dice_in_view`, so a follow-up turn gets `tags.dice`.
- `side_prompt(message, reply, lang, persona, handoff)`: the catalogue, dice and sky parameters are removed.
- `side_schema(handoff)` returns `MOOD_SCHEMA` without `handoff`, else `{mood, handoff}`.

**core `pills.ts`** (pure; no DOM)
- The `Pill` union mirrors the four `pill` data shapes.
- `isPill(v)` checks shape and vocabulary: `Body`, `ZodiacSign`, `AspectType`, and house 1–12. Placement bodies are `Body | 'Ascendant'`, aspect ends reuse `isAspectPoint` (the set `isChartRef` accepts), a transit's two ends are `Body`, and a dice face is one of three.
- `pillToken(p)` is canonical: its house segment is omitted when null.
- `splitPills(text): (string | Pill)[]` scans for `⟦…⟧`. A body that parses to an `isPill` pill becomes a pill; anything else stays text, verbatim with its brackets.
- `pillRef(p): ChartRef | null`:
  - a planet placement gives a planet ref;
  - an aspect gives an aspect ref;
  - a transit gives a planet ref to its target;
  - a dice planet face gives a planet ref;
  - everything else gives `null`.
- `pillSource(p)` returns `natal`, `sky` or `dice`.

**web `Pill.tsx`**
- `PillText({text, entry?, interactive})` renders `splitPills(text)` runs.
- A pill's index `n` counts pills in that entry's text, in order. The pressed id is `"<entry>:p<n>"`.
- On press it calls `showRefs(ref ? [ref] : [], id)`, or `clearActivation()` if that pill is already pressed.
- The pill's element carries `data-pill={kind}`, `data-source` and `data-tone`, and a visible label built by `pill-meaning.ts`.
- `ChatPanel` renders the note for the pressed pill under its letter by matching `activation.chip` against its own entries.

### Wire (exact delta to the epic grammar table)

| Event | Carries | Added in |
|---|---|---|
| `pill` | `{kind:"placement", body, sign, house}` \| `{kind:"aspect", bodyA, type, bodyB}` \| `{kind:"transit", transiting, type, target}` \| `{kind:"dice", face, value}` | dw-10. It is only ever the result of a passed check. It comes after `dice` and before `done`, anywhere a `delta` may go, and a `bubble` may immediately precede it. |
| `done.chartRefs` | Unchanged shape. The source is now the natal pills (default 4) | dw-10 |

The request is unchanged. `delta` gains one invariant: it never contains `⟦` or `⟧`.

### Dependency rules and forbidden edges

- `tags.py` is pure. ❌ It must not import `llm`, `prompts`, `render`, `turn`, `store`, `sky` or `dice`; it receives the sky packet and the rolls as data. This is pinned by a new `test_tags_is_pure`, which has a planted-violation self-check.
- ❌ `turn.py` and `render.py` still never import `re` (`test_handoff_is_never_parsed_from_the_reply`, unchanged). Tag scanning lives only in `tags.py`.
- ❌ Mood and handoff are never derived from tags. A new `test_only_phenomenon_tags_are_read_from_the_reply` pins two things: `tags.KINDS`, and that `done`'s `mood` and `handoff` come only from `_side_read`'s return. It checks the latter by matching the `done` frame construction in the source.
- `divination` gains no new importer and no new tier edge. Rule 10's fences are unchanged.
- Web: `chat/Pill.tsx` and `chat/pill-meaning.ts` import only TYPES from `@astrace/core/chart` (rule 5: `useChart.ts` is the one value-importer); glyphs come from `@astrace/core/chart-view`, validation from the `divination` barrel. `log/SummaryCard.tsx` renders its generated text via `PillText` (static).
- Web: `chat/Pill.tsx` → `chart/wheel-activation` is the existing dw-4 edge. `log/SessionTranscript.tsx` → `chat/Pill.tsx` is a new intra-app edge, and the static pill never imports the activation store (`interactive=false` renders a `span`). Core is used through barrels only. Colours are `var(--aspect-*)`, `var(--char)` and `var(--line)`, plus new named rgba tokens in `theme/tokens.ts` if needed.

### Guard and CLAUDE.md amendments (same commit as the code)

- **Rule 10.** Its divination paragraph gains a dw-10 sentence. `divination/tags.py` (pure) scans the reply for closed-vocabulary PHENOMENON tags and checks each one against the turn's chart, sky packet or rolls. A passing tag becomes a `pill` event and a failing one becomes plain text plus a WARNING, so no unchecked tag reaches the client. This is the ONE exception to "side fields are never parsed from the prose" (user ruling B, 2026-09-29). Mood, handoff and dice stay structured, and `done.chartRefs` is now built from the checked natal pills.
- **Rule 8.** The web dictionary gains a `lore` namespace: short en/zh meanings for the tag vocabulary. This replaces "no lore as of dw-1".
- **Rule 1.** The chart-view enumeration lists `ASPECT_TONES`.
- **Tests.** `server/tests/test_boundaries.py` gains the two tests above. `app-native/src/architecture.test.ts` enumerates `ASPECT_TONES`.
- **Supersedes** (journal): the dw-3 decision that chartRefs come from the side read (the "2026-09-28 · dw-3-chart-grounded-reply · spec-review" approval's refs clause), and the dw-5 and dw-11 side-read fragment choices `side.dice` and `side.sky`.

## Acceptance Criteria

Fixture chart F = 1990-06-15 08:30 Asia/Shanghai, Placidus: Venus Taurus 10, Moon Pisces 8, Mars Aries 9; aspects include `Venus|trine|Saturn`, `Moon|sextile|Venus`, `Venus|opposition|Pluto`; there is NO Venus–Mars aspect. Server checks run under `conda run -n astrology pytest`, client checks under `npm test`.

**Server — tags (pure scanner/checker)**

- S1. For F, `⟦aspect:Venus|trine|Saturn⟧` yields one aspect pill `{bodyA:"Venus", type:"trine", bodyB:"Saturn"}`. `⟦aspect:venus|sextile|moon⟧` yields `{bodyA:"Moon", type:"sextile", bodyB:"Venus"}`, in chart order with canonical case.
- S2. For F, `⟦aspect:Venus|trine|Mars⟧` (planted, not in the chart) yields no pill. It yields the plain text `Venus trine Mars` and one failure record with the reason `not-in-chart`.
- S3. Placement checks on F:
  - `⟦placement:Venus|Taurus|10⟧` gives a pill with house 10.
  - `⟦placement:Venus|Taurus⟧` gives a pill with house null.
  - `⟦placement:Venus|Gemini⟧` fails.
  - `⟦placement:Venus|Taurus|7⟧` fails.
  - `⟦placement:Ascendant|Cancer⟧` gives a pill.
  - On F with the time unknown, `⟦placement:Venus|Taurus|10⟧` and `⟦placement:Ascendant|Cancer⟧` fail and `⟦placement:Venus|Taurus⟧` passes.
- S4. A transit tag that matches an episode of a given sky packet (transiting, type, planet target) gives a transit pill. The same tag with no sky packet fails with `no-sky`, and a tag whose target is not a natal planet fails.
- S5. With a roll {Pluto, Leo, 7} in view:
  - `⟦dice:planet|Pluto⟧`, `⟦dice:sign|leo⟧` and `⟦dice:house|7⟧` give pills (canonical `Leo`, house int 7);
  - `⟦dice:planet|Mars⟧` fails;
  - with no roll in view, every dice tag fails with `no-roll`.
- S6. Each of these outputs its inner characters with no bracket: an unclosed tag at the close, a tag with a line break, a tag over 64 characters, an unknown kind (`⟦mood:tender⟧` → `mood:tender`), a wrong field count, and a nested opener. A stray `⟧` is dropped.
- S7. Over a fixed corpus of replies mixing valid, failed and malformed tags, every split of each reply into chunks gives the same concatenated output. No emitted text contains `⟦` or `⟧`.
- S8. `tags.py` imports only the stdlib, `app.chart.points` and `.persona`, and names no clock, logger, store or llm (a boundary test with a planted-violation self-check). `tags.KINDS == ("placement", "aspect", "transit", "dice")` is pinned.

**Server — turn**

- T1. With birth data F and a fake provider streaming `Your ⟦aspect:Venus|trine|Saturn⟧ steadies you.`, the SSE body is `delta "Your "`, then `pill {aspect Venus trine Saturn}`, then `delta " steadies you."`, then `done`, and `done.chartRefs == [{kind:"aspect", bodyA:"Venus", type:"trine", bodyB:"Saturn"}]`.
- T2. With a provider that sends `Your ⟦asp` and then blocks until the test releases it, the `delta "Your "` frame is received BEFORE the release.
- T3. A planted wrong tag (`⟦aspect:Venus|trine|Mars⟧`) produces no `pill` frame and a delta containing `Venus trine Mars`. `caplog` shows one WARNING from `app.divination.turn` naming `aspect` and `not-in-chart`, and the record contains no birth date or coordinates.
- T4. No frame of any T-test body contains `⟦` or `⟧` in a `delta`.
- T5. Pills after a bubble break: in a reply whose second bubble opens with a tag, the `bubble {index:1}` frame comes immediately before that `pill` frame. A reply made only of one valid tag gives `pill` then `done`, not `error`.
- T6. `done.chartRefs`:
  - they are the natal pills in order, de-duplicated and capped at 6;
  - a placement of Venus gives `{kind:"planet", body:"Venus"}`;
  - `Ascendant`, transit and dice pills add nothing;
  - with no pills they are `[]`, even if the fake side read returns a `chartRefs` list.
- T7. The side read's schema has no `chartRefs` property, and its user payload has no `catalogue`. The fragments `side.refs`, `side.dice` and `side.sky` are gone from the topic. Mood and handoff behave as before (the existing dw-2/dw-8 turn tests pass).
- T8. Prompts:
  - with birth data, the system prompt contains `tags.rules` and `tags.natal`;
  - a Saturn turn with a sky packet also contains `tags.sky`, and a Venus turn does not;
  - a cast contains `tags.dice`;
  - the chart-less chat prompts for all six personas equal the golden fixtures byte for byte.
- T9. `test_handoff_is_never_parsed_from_the_reply` is unchanged and passes, and the full server suite passes.

**Core**

- C1. `streamTurn` yields `{type:"pill", pill}` for a well-formed `pill` frame at its stream position. It drops a malformed one (unknown kind, bad name, house outside 1–12). It accepts a `bubble` whose previous item was a pill.
- C2. `pillToken` and `splitPills` round-trip every kind: placement with and without a house, aspect, transit, and dice for each face. `splitPills("a ⟦aspect:Venus|trine|Mars⟧ b")` gives `["a ", pill, " b"]`. `⟦mood:tender⟧` and `⟦aspect:Venus|trine⟧` stay text.
- C3. `ASPECT_TONES` maps trine and sextile to `harmonious`, square and opposition to `tense`, and conjunction to `fused`. It has exactly one definition, and the architecture guard's enumeration includes it.

**Web**

- W1. A streamed reply `Your `, pill(aspect Venus trine Saturn), ` steadies you.` renders ONE slip. Inside it, an element `[data-pill]` sits between the two text runs and shows `♀`, `△` and `♄` and the label `Venus trine Saturn`. With the language set to zh, the label is `金星三分土星`.
- W2. Pills carry `data-source` (`natal` for placement and aspect, `sky` for transit, `dice` for dice) and `data-tone` (`harmonious`, `tense` or `fused`) for aspect and transit. `chat.css` has a distinct rule per `data-source` and per `data-tone` value, and the colour guard passes.
- W3. Once stored, an aspect pill is a `button` with `aria-pressed="false"`. Pressing it:
  - sets `aria-pressed="true"`;
  - makes the activation `{refs:[the aspect ref], chip:"<entry>:p0"}`, so the wheel shows `data-lit` on Venus and Saturn;
  - shows a `role="note"` line containing the web lore text for `trine`.

  Pressing it again clears both. Pressing a second pill switches to it.
- W4. Pressing a dice `sign` pill shows the meaning line with the sign's lore, sets `aria-pressed="true"`, and leaves the wheel neutral (no `data-active`). A transit pill `Saturn|square|Mars` lights natal Mars.
- W5. After a reload, the stored reply renders the same pills. The KV transcript text contains the token `⟦aspect:Venus|trine|Saturn⟧`, and no `⟦` is visible in the rendered text of that reply.
- W6. A legacy persona entry (with `chartRefs` and no token) still renders the dw-3 chip row. An entry with a pill token renders no chip row. `SessionTranscript` renders the pills of a stored entry as non-button `[data-pill]` elements, and `SummaryCard` renders a canonical token in its question text as a static pill.
- W7. `en` and `zh` have identical leaf paths, including the new `pills` and `lore` namespaces (`i18n.test.ts`). `npm test` and `npm run typecheck` pass, including app-native's architecture, colour and text-variant guards.

**Real app** (backend with `ANALYSIS_LLM=claude-cli`, `npm run web`, birth data F, evidence in the validating log)

- R1. Ask Venus "Why do I keep choosing people who pull away?". The reply shows at least one natal pill, and each pill's fact is present in `POST /api/chart` for F.
- R2. In zh, the same question shows the pills' labels in Chinese. Tapping one lights the wheel and shows its Chinese meaning line.
- R3. Ask Saturn "When will this heavy stretch end?". Every sky pill shown names an episode present in that turn's sky packet (checked against a `compute_transits` read at the same instant).
- R4. Across R1–R3, no clause outside a pill names a body (en planet name or zh 太阳/月亮/水星/金星/火星/木星/土星/天王星/海王星/冥王星/上升) together with a sign name, a house number or ordinal, or an aspect word (conjunct/sextile/square/trine/opposite and their en/zh forms; the persona's self-reference such as "I sit in Taurus" counts), except a failed tag's fallback text, which must have a matching WARNING in the server log. The log records all three replies' rendered text.
- R5. CLAUDE.md rule 10 names `divination/tags.py`, the `pill` event and the phenomenon-tag exception. Rule 8 names the web `lore` namespace. Rule 1's chart-view enumeration names `ASPECT_TONES`. Each is checked by grep.
