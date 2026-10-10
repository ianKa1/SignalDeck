# dw-11-sky-now — Moon, Saturn and Jupiter read the current sky

## Goal

With birth data, the Moon, Saturn and Jupiter characters are given today's transits to their own natal planet and their own planet's current windows, taken from the memoized `chart.transit.compute_transits`, so a timing question gets a real transit with correct dates. Every other prompt keeps dw-8's `roster.timing` ("pattern, not timing"). QUEUE.md `dw-11-sky-now` (open call A); epic `pipeline/epics/divination-web.md`.

## Non-goals

- Sky reading for Venus, Mars or Mercury. They keep `roster.timing`. Widening is a later one-line change to `SKY_PERSONAS`.
- New sky math. No new walk, orb, window, scan horizon or scoring. dw-11 filters and formats what Tier A already returns.
- Tier S selection doctrine: topic manifests, band quantization, `standing_view`. The divination fence against `selection` stays as it is.
- Deciding from the question's words whether it is a timing question. There is no prose parsing of the question or of the reply.
- Chips, pills or wheel marks for transits. There is no new ref kind and no `done` change. Separate sky pills belong to dw-10.
- Lunations, eclipses, sign ingresses of other bodies, and the fast calendar.
- A sky without birth data, where there is nothing natal to touch.
- Any change to the voice, summary or sheets routes, to stores, migrations or jobs, to web UI or to `app-native/`.

## Decided defaults

1. **Who reads the sky.** `divination/sky.py` holds `SKY_PERSONAS = ("moon", "saturn", "jupiter")`, a subset of dw-8's `PERSONA_PLANETS`, pinned by a test.
2. **When: structurally, every turn.** A sky persona gets the sky section on every turn, whatever its action (chat, cast or deeper), whenever birth data is sent. It does not get it without birth data, or when the sky computation raises. In that failure case the reply still streams, and a warning is logged. No question text is inspected.
3. **Never both.** Every divination system prompt carries exactly ONE of `roster.timing` and the sky section. The sky section takes `roster.timing`'s place: `roster.rules` and `roster.list` stay. The sky section's slot is dw-8's: persona < shape < depth < roster < self < chart < **sky** < dice < lang.
4. **What the character is given.** The sky packet (JSON) holds, for persona planet P:
   - `today`, the local date of the turn;
   - `planet`: transiting P's sign, the natal house it is in (null when the birth time is unknown) and whether it is retrograde;
   - `episodes`: every current contact from the bundle where P is the transiting body, or where the target is natal planet P. Contacts by the transiting Moon are dropped unless P is the Moon, because they last hours. The rows are ordered by Tier A's `score` (descending), with ties broken by transiting body, then target, then type, and capped at 8. Each row carries:
     - transiting body, target name and kind, and aspect type;
     - `exact` and `applying`, as Tier A gives them;
     - `window {from, to}` from the episode's enter/exit;
     - `passes [{date, motion}]`;
     - `stations [{date, kind}]`.
   - `events`: P's own events from the bundle's `events`: stations, sign ingresses, house ingresses, and dated returns (a return with no date, one that is only approaching, is dropped).
5. **Dates.** Every date is a `YYYY-MM-DD` local calendar date. It is the Tier A UTC instant converted into the effective zone. A null boundary stays null ("beyond the computed horizon"). Degrees, orbs and scores never enter the packet.
6. **The clock and the zone.** The server clock decides "now". The client never sends a date.
   - The route resolves the instant with the existing `transit_instant(currentTimezone, birth timezone, now)`, which gives local noon of today in the effective zone. That is the same quantization as the transit page, so a day's turns share one memo entry.
   - The turn request gains an optional `currentTimezone` (an IANA zone, validated as on the transit routes, 422 otherwise). When it is absent, the birth timezone is used.
   - Core's `streamTurn` fills `currentTimezone` from the device zone when the caller leaves it out. The web app is unchanged.
   - The zone is not identity, and nothing is stored.
7. **Prompt text.** There are three new fragments:
   - `sky.read`, the instructions. The character has the current sky as data. For a timing question it names the one or two episodes that bear on it, with its window and pass dates exactly as given. A pass still ahead means building, and all passes behind means easing. A null end is said as "runs past the next year", never as a date. It invents no date, transit or duration, never recites the packet, and leaves out degrees. With `time_unknown` it names no house.
   - `sky.marker`: "THE SKY NOW, AGAINST THEIR CHART (JSON):".
   - `side.sky`: tells the side read that a transiting planet is not the person's placement. Only the natal end of a transit may be a chart ref. It is appended only when the turn carried a sky section, the same way `side.dice` works.

   All three are registered on the `divination` topic, so FINGERPRINT moves. That is provenance only: no key changes and no VERSION bump.
8. **Cost.** There is one `compute_transits` per person per local day. It walks about 0.5 s cold, and a memo hit takes about 1 ms. It runs inside the stream after the 200, like `natal_context`. It is pure computation, neither a job nor generation, so rule 14 is unchanged.
9. **Goldens.** Chart-less prompts are byte-identical to dw-8's for all six personas. "Re-recording" the chart-less goldens at landing therefore yields an empty fixture diff. With-chart prompts for Venus, Mars and Mercury are byte-identical to dw-8's.
10. **UI.** Nothing changes. `frontend-design` was skipped: dw-11 renders nothing new.

## Architecture

This section cites `pipeline/epics/divination-web.md` (the reuse map, event grammar and dependency rules) and dw-8's spec (the persona list, `roster.*` fragments, the prompt order and "Composition with dw-11"). It writes only dw-11's delta. The base is the working branch after dw-8 lands, so the worktree is cut then (dw-8's hand-off contract).

### Reuse (verified 2026-09-28, pre-dw-8 line numbers)

| Need | Existing | Use |
|---|---|---|
| Sky walk + memo | `chart/transit/instant.py:457` `compute_transits(person, at_utc)` (content-keyed LRU of 8, deep copies, `:445–476`); `:450` `_clear_transits_memo` (test seam); `:479` `_compute_transits_uncached` (spy point) | Called as-is, one call per turn |
| What the bundle carries | `instant.py:597` return: `transit.planets[]` (`sign`, `natalHouse`, `retrograde`), `contacts[]` (`transiting`, `target{kind,name}`, `type`, `exact`, `applying`, `score`, `timeline{enterUtc, exitUtc, passes[{atUtc,motion}], stations[{atUtc,kind}]}`), `events{stations, ingresses, returns, houseIngresses}` | Filtered and date-formatted only |
| Instant quantization | `interpretation/service.py:219` `transit_instant(current_tz, birth_tz, now_utc)`, local noon; used the same way by `transit_day.py:81` and `cards/transit/event/service.py:54` | Called by the ROUTE (main.py), never by divination |
| Zone validation | `models.py:217` `check_current_timezone` (the `StandingSkyRequest` pattern, repeated at `:240`, `:270`) | Same validator on the turn request |
| Turn plumbing | `main.py:424` `divination_turn_stream`, `:148` `_person`; `divination/turn.py:200` `turn_events`, `:211` `natal_context` call, `:167` `_side_read`; `render.py:247` `system_prompt`, `:351` `side_prompt` (dw-8/dw-9 signatures) | Add one keyword each |
| Orb policy and engine for tests | `chart/transit/policy.py:33` `TRANSIT_MAX_ORB`; `chart/ephemeris.py:193` `ecliptic_longitude` | K4 only; production code does not use them |
| Device zone in core | `core transit-day/service.ts:87` `deviceTimezone()` (a one-liner, documented as duplicated rather than imported) | Same one-liner, private to `divination/turn.ts` |

### Module map (created or changed only)

```
server/app/divination/
├── sky.py            NEW  SKY_PERSONAS; sky_view(bundle, planet, zone) (pure);
│                          sky_context(person, persona, at_utc, zone) → dict | None
├── render.py         CHG  + sky.read, sky.marker, side.sky (declared before FINGERPRINT);
│                          system_prompt(..., sky=None): sky section in dw-8's slot,
│                          roster.timing iff sky is None; turn_messages passes sky;
│                          side_prompt(..., sky_in_view=False)
└── turn.py           CHG  turn_events(request, person, voice, sky_at=None): builds the
                           sky after natal_context (own try → None + warning);
                           passes it to turn_messages and sky_in_view to _side_read
server/app/models.py  CHG  DivinationTurnRequest.currentTimezone: str | None (IANA-validated)
server/app/main.py    CHG  _utcnow() clock seam; the turn route computes
                           sky_at = transit_instant(currentTimezone, birth tz, _utcnow())
                           when birthData is present, and passes it to turn_events
server/tests/         CHG  + test_divination_sky.py (K3–K7); test_divination_render/turn
                           (K1, K2, K8, K9; mechanical: dw-8's "roster.timing once" pin
                           becomes "exactly one of timing/sky");
                           test_boundaries.py (+ test_divination_reads_no_clock,
                           + test_sky_personas_are_personas)
packages/core/src/divination/
├── types.ts          CHG  TurnRequest.currentTimezone?: string
└── turn.ts           CHG  body fills currentTimezone from the device zone when absent
CLAUDE.md             CHG  rule 10, one sentence (below)
```

Nothing in `web-divination/`, `app-native/`, `selection/`, `chart/` or the stores changes.

### Contracts

**`divination/sky.py`** (Tier C, pure except for the one memoized Tier A call):
- `SKY_PERSONAS: tuple[str, ...] = ("moon", "saturn", "jupiter")`.
- `sky_view(bundle: dict, planet: str, zone: str) -> dict`. It is PURE: no engine call and no clock. It returns `{today, planet, episodes, events}` exactly as Decided default 4 describes:
  - `today` is the local date of `bundle.transit.instantUtc` in `zone`;
  - each episode row is `{transiting, target, targetKind, type, exact, applying, window{from,to}, passes[{date,motion}], stations[{date,kind}]}`;
  - each event row is `{event: "station"|"sign-ingress"|"house-ingress"|"return", date, …}`, carrying its own `kind`/`sign`/`house`/`retrograde`, filtered to `body == planet`, ordered by date.
  - One private helper, `_local_date(iso, zone)`, is the only date formatter (UTC ISO → local `YYYY-MM-DD`, with None passed through).
  - It reads no orb, score value, longitude or degree into the output. Score is used only to order and cap.
- `sky_context(person, persona, at_utc, zone) -> dict | None`: None when `persona not in SKY_PERSONAS`, `person is None` or `at_utc is None`. Otherwise it returns `sky_view(compute_transits(person, at_utc), PERSONA_PLANETS[persona], zone)`. Exceptions propagate, and the caller degrades.
- The zone is `request.currentTimezone or person["timezone"]`. `turn.py` resolves it; `sky.py` receives it.

**`render.py`**:
- `system_prompt(persona, lang, ctx, cast, voice, action, sky=None)`. `sky` is used only when `ctx` is not None. The result is dw-8's ordered list with two changes:
  - `roster.timing` is emitted only when the sky section is absent;
  - the sky section (`sky.read` + blank line + `sky.marker` + newline + `json.dumps(sky, sort_keys=True, ensure_ascii=False)` + blank line) sits between the chart section and the dice section.
- `turn_messages(..., sky=None)` passes it through.
- `side_prompt(..., sky_in_view=False)` appends `side.sky` after the refs clause when the catalogue is non-empty, the way `side.dice` is appended.

**`turn.py`**:
- After `natal_context` succeeds, it runs `sky = sky_context(person, request.persona, sky_at, zone)` inside its own `try`. Any exception logs a warning and sets `sky = None`, and the turn continues.
- It then passes `sky` to `turn_messages` and `sky_in_view = sky is not None` to `_side_read`.
- The `dice`-first frame order, the deadline and the `done` shape are unchanged.
- The walk runs inside the generator, after the 200 and before the provider stream: about 0.5 s cold, which is under the 1 s keepalive interval.

**`main.py`**:
- `def _utcnow() -> datetime` returns `datetime.now(timezone.utc)`. It is the one clock read on the divination path, and tests monkeypatch it.
- The turn route adds only: `sky_at = interpretation_service.transit_instant(request.currentTimezone, request.birthData.timezone, _utcnow()) if request.birthData else None` (main already imports `interpretation_service`, `main.py:33`), then `turn_events(request, person, voice, sky_at=sky_at)`.
- main never names `SKY_PERSONAS`, so which personas read the sky has one home.

**core `divination/turn.ts`**: the POST body becomes `{...req, currentTimezone: req.currentTimezone ?? deviceTimezone()}`. `TranscriptEntry`, `toWire` and the stored transcript are untouched.

### Wire (exact delta)

- `POST /api/divination/turn` request: + `currentTimezone?: string | null`, an IANA zone. An invalid zone is a 422 before any stream opens. It is ignored unless a sky is built.
- Events: unchanged (`dice`, `delta`, dw-9 `bubble`, `done {mood, chartRefs, handoff}`, `error`). The sky packet lives only inside the system prompt, never on the wire.
- `/summary`, `/persona` and `/sheets` are unchanged.

### Dependency rules and forbidden edges

- ✅ `divination/sky.py` → `app.chart.transit` (Tier A). The fence (`test_boundaries.py:321`, `DIVINATION_FORBIDDEN_RE`) already allows chart, so the fence regex is NOT widened.
- ❌ `divination` → `selection`: it stays forbidden. dw-11 needs no band doctrine, and its dates are local-zone, unlike Tier S's UTC-day `cadence.day`.
- ❌ `divination` → `interpretation` beyond the existing `_restate` borrow. `transit_instant` is reached from main.py, the delivery layer that may import every tier, so no second borrow is pinned.
- ❌ No wall clock in `divination/render.py`, `turn.py` or `sky.py` (`datetime.now`, `utcnow`, `date.today`, `time.time(`). `time.monotonic` deadlines are allowed. `summary.py`/`voice.py`'s `created_at` stamps are outside the pin.
- ❌ No new state: `test_divination_keeps_no_state` is unchanged. The memo is Tier A's, content-keyed by (person, instant), with no identity.
- Rule 14: `compute_transits` is pure computation, not generation, so `GENERATE_ON_REQUEST_RE` (`test_boundaries.py:102`) and `test_main_names_the_synchronous_exceptions` stay unchanged.
- Rule 5: the web and core do no sky or date arithmetic. Core only reports the device zone.

### Guard and CLAUDE.md amendments (same commit)

- `test_boundaries.py`:
  - `test_divination_reads_no_clock` scans the three files, with a self-check that bites on a planted `datetime.now(` in `sky.py`.
  - `test_sky_personas_are_personas` pins `set(SKY_PERSONAS) <= set(PERSONA_PLANETS)` and the exact tuple.
- `test_topic_is_registered`: the fragment set gains `sky.read`, `sky.marker` and `side.sky`.
- CLAUDE.md rule 10, the divination paragraph, gains one sentence: "The Moon, Saturn and Jupiter (`divination/sky.SKY_PERSONAS`) read the current sky. With birth data, every turn adds a sky section built by the pure `sky.sky_view` over the memoized `chart.transit.compute_transits` bundle at the instant the ROUTE resolves (`transit_instant`: local noon in `currentTimezone`, else the birth zone). Divination reads no clock, does no sky math and never imports selection. A prompt carries exactly one of `roster.timing` and the sky section."
- Epic file: at docs-sync ("Built so far", the target modules, and a note under the event grammar that the request gained `currentTimezone`).

### Composition and shared files

- **dw-8** (landed before): `render.py` (the return expression, one conditional on `roster.timing`, three declarations), `turn.py` (after `natal_context`, `_side_read`'s call), `main.py` (the turn route only), `models.py` (one field), `test_boundaries.py` (appends), CLAUDE.md rule 10, and dw-8's `test_divination_roster.py` S4 pin (mechanical). The goldens are re-recorded from the merged render, and the fixture diff is empty (K9).
- **dw-9/dw-12**: no further overlap. `deeper` turns get the sky too (K2).
- No migration, job, store or i18n change.

## Acceptance Criteria

Server tests use monkeypatched `llm.stream_turn`/`llm.generate_sections` only, with the REAL chart and ephemeris engines. "Now" is frozen at `NOW = 2026-09-28T03:00:00Z` through the route's clock seam (or by passing the instant to `turn_events`). Chart A = 1990-06-15 08:30, 39.9042/116.4074, Asia/Shanghai, placidus. Run `npm run server:test`, `npm test`, `npm run typecheck`.

**Server**
- **K1 (who)**: `sky.SKY_PERSONAS == ("moon","saturn","jupiter")`, each a key of `persona.PERSONA_PLANETS` (pinned). A chart-A turn for `venus`, `mars` and `mercury` calls `compute_transits` zero times (spy), and its system text contains `roster.timing` and no `sky.marker`.
- **K2 (never both)**: for every persona in the six, for each of {no birth data, chart A, chart A + cast, chart A + deeper}, and with sky computation succeeding and forced to raise, the system text contains exactly one of `roster.timing` and `sky.read`. `sky.read` appears iff the persona is in `SKY_PERSONAS`, birth data is present and the computation succeeded. When present, `sky.marker` appears after `chart.marker` and before `dice.brief` (a cast) and the `lang.*` line.
- **K3 (Saturn packet, chart A, no `currentTimezone`)**: the sky JSON in Saturn's prompt parses to `today:"2026-09-28"` and `planet:{body:"Saturn", sign:"Aries", natalHouse:9, retrograde:true}`.
  - Its episodes, in order, are Saturn conjunction MC, Saturn conjunction Mars, Saturn opposition IC, Saturn square Neptune, Saturn quincunx house-3-cusp, and Mercury square Saturn. There is no Moon-transiting row.
  - The Saturn conjunction Mars row equals `window {from:"2026-04-18", to:"2027-03-06"}`, passes `2026-05-15 direct`, `2026-10-12 retrograde`, `2027-02-05 direct`, and stations `2026-07-27 retrograde`, `2026-12-11 direct`.
  - Events include a house ingress into 9 on `2026-09-13` (retrograde) and `saturn-quarter` on `2027-06-01`. No undated return appears.
  - The packet contains no key named `orb`, `score` or `longitude`.
- **K4 (dates against the ephemeris)**: the test is independent of the timeline walk. For every Saturn-packet and Jupiter-packet episode whose transiter is Saturn or Jupiter and whose target is a planet or angle, it uses `chart.ephemeris.ecliptic_longitude` at local noon (Asia/Shanghai):
  - on each pass date, |separation − the aspect angle| ≤ 0.25°;
  - on `window.from` − 1 day the orb exceeds `policy.TRANSIT_MAX_ORB`, and on `window.from` + 1 day it is within it;
  - `window.to` is checked the same way, mirrored;
  - a null boundary is skipped.
- **K5 (Jupiter, Moon)**: Jupiter's first episode is Jupiter square Venus, `2026-09-08`–`2026-10-10`, pass `2026-09-23`. Moon's packet contains Uranus square Moon with `window.to: null`, and contains transiting-Moon rows.
- **K6 (zone)**: `currentTimezone:"America/New_York"` gives Saturn's packet `today:"2026-09-27"` and a Saturn conjunction Mars window `to:"2027-03-05"`, first pass `2026-05-14`. `currentTimezone:"Mars/Olympus"` answers 422 and calls no fake. An absent `currentTimezone` equals sending `"Asia/Shanghai"` for chart A.
- **K7 (memo, degrade)**: two chart-A Saturn turns at the same frozen `NOW` run the uncached walk once (spy on `instant._compute_transits_uncached`, memo cleared first). With `compute_transits` forced to raise, a Saturn turn streams `delta…done`, its prompt carries `roster.timing` and no `sky.read`, and a warning is logged.
- **K8 (side read)**: a chart-A Saturn chat turn's side-read system text contains `side.sky`, and a Venus turn's does not. `done` keeps exactly dw-8's keys.
- **K9 (goldens and stability)**: the chart-less golden fixtures pass with an empty diff. The with-chart system text for venus/mars/mercury equals `render.system_prompt(…)` without a sky section, and contains `roster.timing` once. `test_topic_is_registered` lists `sky.read`, `sky.marker` and `side.sky`.
- **K10 (boundaries)**: `test_boundaries.py` passes. `test_divination_reads_no_clock` passes, and bites on a `datetime.now(` planted in `sky.py`. `sky.py` imports nothing from `selection`, `interpretation`, `cards` or `db`, because the unchanged divination fence passes. `test_main_names_the_synchronous_exceptions` and `test_delivery_never_generates_on_the_request_path` pass unchanged.

**Core**
- **C1**: `streamTurn` sends `currentTimezone` equal to the device zone (Intl stubbed to `"Asia/Shanghai"`) when the request omits it, and passes a caller's value through unchanged. `toWire` and stored transcripts carry no zone.

**Real app** (dw-12's gate is on the base. Use a throwaway local Postgres cluster on a free port with `DATABASE_URL` pointing at it, never the `.env` remote. Start the backend without `--env-file`, with `ANALYSIS_LLM=claude-cli`, `CORS_ALLOW_ORIGINS` for the Vite origin and a placeholder `GOOGLE_CLIENT_ID`. Mint a bearer pair per `logs/dw-12-google-sign-in/05-validating.md`. Point Vite at that backend with `VITE_API_BASE`. Any free ports. Delete the cluster afterwards.) The validator records the day's Saturn, Jupiter and Moon packets for chart A by calling `sky.sky_context` in the conda env at the real current time and zone. It runs K4's ephemeris check on those packets and logs both.
- **R1 (Saturn, the loop-closer)**: with chart A saved, Saturn asked "When will this hard stretch end?" names at least one episode from that day's Saturn packet by its transiting body and natal point (e.g. "Saturn on your Mars"). It gives at least one of that episode's dates: a pass, a station or a window end. Every calendar date or month the reply names equals a date in the packet, or is that date's month. A date absent from the packet is a FAIL. One rephrase or retry is allowed, and the log quotes every attempt beside the packet.
- **R2 (Moon, Jupiter)**: Moon asked "Will this pass?" and Jupiter asked "Will the next step open things up?" each name an episode from their own packet with at least one of its dates, under R1's date rule. The log quotes both replies.
- **R3 (the others)**: Venus asked "When will this end?" with chart A, and Saturn asked it with NO birth data saved, each say they can read the pattern but not the timing, and name no date and no current transit.
