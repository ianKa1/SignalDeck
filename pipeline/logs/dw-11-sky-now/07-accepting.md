# 07 accepting — fresh-context acceptance check

Checker: fresh context, never saw the implementation. Code under test: worktree
`astrology-wt/dw-11-sky-now` (branch `feature/dw-11-sky-now`, HEAD `81d0430`).
Run on 2026-09-29 (~04:50–05:00 UTC; device zone America/New_York).

**Suites:** `server/` `DATABASE_URL= conda run -n astrology pytest -q` → 1282 passed, 50 skipped, exit 0.
Root `npm test` → exit 0 (web-divination 251/251 plus app-native). Root `npm run typecheck` → exit 0.

**dw-12 caveat:** the web sign-in gate (dw-12) is NOT on this branch. The real-app
section's Postgres cluster, bearer minting and `GOOGLE_CLIENT_ID` do not apply here.
I ran the real app ungated on SQLite as instructed: backend on :8002 from a scratch
`.env` copy with the `DATABASE_URL` line removed, plus `DATABASE_URL=` in the environment.
`/api/health` returned `{"status":"ok","db":"unconfigured","ephemeris":"ok"}` before any
other request. The remote Postgres was never contacted, and the server log has no
db/psycopg lines. Vite ran on :5175 with `VITE_API_BASE=http://localhost:8002`. I drove
headless Chrome over CDP with a fresh profile and captured every request body and the full
SSE frames through `Network.streamResourceContent`.

**Independent packet check:** my script `verify_packets.py` (in the scratchpad) calls
`sky.sky_context` / `transit_instant` and checks dates against
`chart.ephemeris.ecliptic_longitude` at local noon, with its own K4 logic.
- **Frozen NOW (2026-09-28T03:00Z), Asia/Shanghai:** reproduced every K3/K5 value, and all K4 checks were true.
- **New York:** `today` 2026-09-27, Mars window `to` 2027-03-05, first pass 2026-05-14.
- **Real app:** for each captured turn, `verify_request.py` rebuilt the packet from the exact
  request body (`models.BirthData` → `main._person` → `transit_instant(currentTimezone, …)`
  → `sky.sky_context`) and ran K4 on it. All K4 checks were true: Saturn MC/Mars/IC/Neptune
  and Jupiter square Venus. The form picked GeoNames Beijing (39.9075/116.3972, placidus),
  and the zone was America/New_York, so `today` was 2026-09-29.

| ID | Verdict | Evidence | Basis |
|---|---|---|---|
| K1 | PASS | `SKY_PERSONAS == ("moon","saturn","jupiter")`, pinned as a subset of `PERSONA_PLANETS` by `test_sky_personas_are_personas`. `test_k1_the_others_never_walk_the_sky` passes: a spy on `sky.compute_transits` sees 0 calls for venus/mars/mercury, and each prompt has `roster.timing` and no `sky.marker`. `sky_context` returns None early for non-sky personas (sky.py:134). | TESTS/CODE |
| K2 | PASS | `test_k2_route_carries_exactly_one_of_timing_and_sky[False/True]` covers all six personas × {none, chart, cast, deeper}, with the sky call succeeding and raising, through the real route. It asserts exactly one of `roster.timing` and `sky.read`, the iff condition, and marker order: `chart.marker` < `sky.marker` < `lang.en`, and < `dice.brief` on a cast. The render-level twin also passes. | TESTS/CODE |
| K3 | PASS | `test_k3_saturn_packet_chart_a` and the route twin pass. I reproduced the values independently: today 2026-09-28; planet Saturn/Aries/9/℞. Episode order: MC conj, Mars conj, IC opp, Neptune sq, house-3 quincunx, Mercury sq Saturn, with no Moon row. Mars row: window 04-18→2027-03-06; passes 05-15 d, 10-12 r, 2027-02-05 d; stations 07-27 r, 12-11 d. Events include a house-ingress 9 on 09-13 (℞) and saturn-quarter on 2027-06-01, with no undated return. No `orb`/`score`/`longitude` keys. | TESTS/CODE (plus an independent recompute) |
| K4 | PASS | `test_k4_dates_match_the_ephemeris` uses `ecliptic_longitude` at Shanghai noon, independent of the walk. My own recompute agrees: pass orbs ≤0.04°. At every boundary ±1 day, the orb is >3° outside the window and ≤3° inside it (e.g. Mars from 3.135/2.896, to 2.884/3.117; Jupiter–Venus from 3.184/2.774, to 2.839/3.169). | TESTS/CODE (plus an independent recompute) |
| K5 | PASS | Jupiter's first episode is Jupiter sq Venus, 2026-09-08→10-10, pass 09-23. Moon has Uranus sq Moon with `to: null`, plus transiting-Moon rows (Moon sq Saturn, sextile Sun, …). Test and my recompute agree. | TESTS/CODE (plus an independent recompute) |
| K6 | PASS | `test_k6_new_york_dates` and `test_k6_zone_at_the_route` pass: NY gives today 09-27, Mars `to` 2027-03-05, first pass 05-14 (reproduced independently). An absent zone gives a prompt identical to sending `"Asia/Shanghai"`. `Mars/Olympus` → 422 with no fake called. The real app also returned 422 for `Mars/Olympus` (curl to :8002). | TESTS/CODE (plus a real-app 422) |
| K7 | PASS | `test_k7_one_walk_per_day`: a spy on `_compute_transits_uncached` with the memo cleared counts 1 call for two Saturn turns. `test_k7_a_failed_sky_degrades`: the stream is delta…done, the prompt has `roster.timing` and no `sky.read`, and the "sky context failed" warning is logged. turn.py wraps the call in try/except → `log.warning`. | TESTS/CODE |
| K8 | PASS | `test_k8_side_read_is_told_about_the_sky`: Saturn's side-read system contains `side.sky`, Venus's does not, and `done` keys == {mood, chartRefs, handoff}. In the real app, every captured `done` frame had exactly those three keys. | TESTS/CODE (plus real-app frames) |
| K9 | PASS | No fixture file changed vs `feature/divination_web` (`git diff --stat server/tests/fixtures` is empty), and the chartless golden tests pass. The chartless prompt ignores a sky (`test_k9_chartless_prompts_ignore_a_sky`). For venus/mars/mercury with a chart, `roster.timing` appears once and there is no `sky.marker`. On equality: the K1 route test shows no sky section, and the render signature defaults `sky=None`. `test_topic_is_registered` lists `sky.read`, `sky.marker` and `side.sky`. | TESTS/CODE |
| K10 | PASS | `test_boundaries.py` passes; its diff is additions only, so `test_main_names_the_synchronous_exceptions` and `test_delivery_never_generates_on_the_request_path` are unchanged and pass. Planted `datetime.now()` in sky.py → `test_divination_reads_no_clock` FAILED (bites). Planted imports in sky.py → the fence test FAILED for each of `app.selection`, `app.interpretation`, `app.cards` and `app.db` (the db plant turned 3 tests red). All plants were reverted with `git checkout`, and `git status` is clean. | TESTS/CODE (planted edits) |
| C1 | PASS | core `streamTurn` sends `{...req, currentTimezone: req.currentTimezone ?? deviceTimezone()}`. The vitest `streamTurn currentTimezone (dw-11 C1)` stubs Intl to Asia/Shanghai, checks that a caller's `America/New_York` passes through, and checks that neither `toWire` nor the stored transcript has a zone. In the real app, every captured turn body carried `"currentTimezone":"America/New_York"`, and the localStorage transcripts had no zone. | TESTS/CODE (plus real-app bodies) |
| R1 | PASS (1st attempt) | See the R1 section below. | REAL APP |
| R2 | PASS | See the R2 section below. | REAL APP |
| R3 | PASS | See the R3 section below. | REAL APP |

## R1: Saturn, chart A, "When will this hard stretch end?"

The session was sealed first, so the transcript was empty. Response 200; frames: 56 delta, 3 bubble, 1 done.

The rebuilt Saturn packet (NY, today 2026-09-29):

| Episode | Window | Passes |
|---|---|---|
| MC conj | 05-07 → 2027-03-24 | 06-09, 09-12, 2027-02-27 |
| Mars conj | 04-18 → 2027-03-05 | 05-14, 10-12, 2027-02-05 |
| IC opp | 05-07 → 2027-03-24 | (same as MC) |
| Neptune sq | 05-15 → 2027-03-31 | 06-21, 08-30, 2027-03-06 |
| house-3 quincunx | 05-12 → 2027-03-12 | 06-03, 09-19, 2027-02-23 |

- Stations: 07-26 r, 12-10 d.
- Events: house-ingress 9 on 09-12; saturn-quarter on 2027-06-01.

The reply, verbatim:
> "It won't end this autumn. I'm crossing your Mars in Aries, which sits on your Midheaven, and that crossing runs from April 18, 2026 to March 5, 2027. One exact pass is still ahead on October 12, so the pressure is still building. / The last exact passes come on February 5, 2027 over your Mars and February 27, 2027 over your Midheaven. My weight on your career and public standing lifts when that window closes on March 24, 2027. I turn direct on December 10, and after that I stop doubling back over the same ground. / It feels this hard because your Mars in Aries is the apex of both your t-squares … / Since May, what have you been trying to force through at work that I'm making you build more slowly?"

Dates the reply names, checked against the packet:

| In the reply | Packet source |
|---|---|
| Apr 18 2026 | Mars `from` |
| Mar 5 2027 | Mars `to` |
| Oct 12 | Mars pass |
| Feb 5 2027 | Mars pass |
| Feb 27 2027 | MC pass |
| Mar 24 2027 | MC `to` |
| Dec 10 | station direct |
| "May" | month of 05-07 / 05-14 |

"This autumn" is a season, not a date. No date outside the packet. The reply names the episode by body and point ("crossing your Mars").

## R2: Moon and Jupiter

**Moon, "Will this pass?"** The rebuilt packet includes:
- Uranus sq Moon: 07-16 → null, pass 2027-07-15
- Moon opp Pluto on 09-29
- Venus trine Moon: passes 10-01, 10-04
- …

The reply:
> "…Part of it will pass tonight. Today I'm moving opposite your Pluto in Scorpio in the fourth house … lasts only hours. / … Uranus has been square me in your chart since July 16, 2026, and it's still building toward exact on July 15, 2027 … / Is it today that feels so heavy, or has this restlessness been with you since the middle of July?"

Dates: Jul 16 2026 = Uranus `from`, Jul 15 2027 = Uranus pass, "July" = month of 07-16, "today" = 09-29, the Moon opp Pluto pass. All in the packet.

**Jupiter, "Will the next step open things up?"** The rebuilt packet:
- house-11 sq and house-5 sq: 09-14 → 10-18, pass 09-30
- Venus sq: 09-07 → 10-09, pass 09-23
- house-2 conj: 09-08 → 10-10, pass 09-23
- house-ingress 2 on 09-23

The reply:
> "…I moved into your second house on September 23, and tomorrow, September 30, I square the cusp of your eleventh house, in a window that runs from September 14 to October 18. … My square to your Venus in Taurus in the tenth house was exact on September 23 and runs until October 9…"

Dates: Sep 23, Sep 30, Sep 14, Oct 18 and Oct 9 all match packet dates, and the reply names Jupiter sq Venus.

## R3: Venus with a chart, and Saturn without birth data

**Venus, chart A, "When will this end?"** Its prompt has no sky section by design.
> "You asked me when, and the timing is the one thing I can't see. I'm your evening star, not your clock … What I can read is the pattern, and it starts with me: your Venus in Taurus, opposite Pluto…"

It says pattern-not-timing, names natal aspects only, and gives no date and no current transit. The handoff went to Saturn.

**Saturn, no birth data** (`birthData: null`, `currentTimezone: America/New_York`):
> "You asked me when this will end, and that is the one thing I cannot tell you. I can read the shape of what someone is carrying, but not its timing. …"

It gives no date and no transit.

## Cleanup

Uvicorn :8002, Vite :5175, headless Chrome :9333 and the CDP recorder were all stopped, and `lsof` shows 8002 and 5175 free. The scratch `.env` copy was deleted. All planted edits were reverted, and the worktree's `git status --short` is clean.

ACCEPTANCE: PASS
