# Implementation Plan: dw-11-sky-now

Spec: `pipeline/specs/dw-11-sky-now.md` (WHAT + Architecture; PASS in
`logs/dw-11-sky-now/02-spec-review.md`). Epic:
`pipeline/epics/divination-web.md`. Hand-off contract: dw-8 spec
"Composition with dw-11"; names dw-11 inherits are in
`plans/dw-8-planet-cast.md` (`PERSONA_PLANETS`, `roster.timing`,
`test_divination_roster.py`, `fixtures/divination_pre_dw8/`).

Worktree `/Users/kaimao/Projects/astrology-wt/dw-11-sky-now`, branch
`feature/dw-11-sky-now`, cut from `feature/divination_web` AFTER dw-8
landed (base = dw-9 + dw-12 + dw-8). Worker ports: backend :8002, Vite
:5175. Commands run from the WORKTREE root; pipeline files by absolute path
under `/Users/kaimao/Projects/astrology/pipeline/`. Steps 0–4 are
`implementing` (log `04-implementing.md`), 5 is `validating`
(`05-validating.md`), 6 is `docs-sync` (`06-docs-sync.md`). Tick a box only
after its done-when passed and its `/git-commit` landed (`(<type>):
dw-11-sky-now — <summary>`). No UI changes, so `/frontend-design` is not
loaded. Automated tests use fakes only (monkeypatched `llm.stream_turn` /
`llm.generate_sections`), the REAL chart and ephemeris engines, and a
frozen `NOW = 2026-09-28T03:00:00Z` (through `main._utcnow`, or by passing
the instant to `turn_events`/`sky_context`); never the wall clock. Server:
`conda run -n astrology pytest -q` from `server/`. Root: `npm test`,
`npm run typecheck`.

## Settled review notes

- **R-a `body`.** The packet's `planet` object is `{body, sign,
  natalHouse, retrograde}` (K3 asserts `body`). The spec's Default 4 omits
  it; the plan adds it.
- **R-b path.** The transit page's use of `transit_instant` is
  `server/app/transit_day.py:81` (not under `interpretation/`). dw-11 does
  not touch that file.
- **R-c unknown birth time.** Added as server check **K3u** in
  `test_divination_sky.py`: chart A with `time: null`, Saturn turn at NOW
  → packet `planet.natalHouse` null, every episode's `targetKind` is
  `planet` (no cusp or angle rows), no `house-ingress` event, no
  exception. Verified at planning in the conda env against the real
  `compute_transits` (natalHouse None, contact target kinds `{planet}`,
  `houseIngresses` empty).
- **R-d cold walk.** Risk note below.
- **R-e same-day windows.** `sky.read` says a window whose `from` and `to`
  are the same date is "today" (hours, not a span of dates); the Moon's
  transiting-Moon rows are the case.

## Steps

- [x] **0. Verify worktree prep and the base.** (dw-12 NOT in base — see 04-implementing.md)
  Branch `feature/dw-11-sky-now`; `npm install` done at the root and
  `node_modules/@astrace/core` resolves; `.env` and the three
  `server/data/*.se1` are symlinks into the primary checkout; no
  `server/data/*.db` is a symlink. dw-8 is in the base: `git log --oneline
  | grep -E "dw-8|dw-9|dw-12"` shows all three, `grep -n "roster.timing"
  server/app/divination/render.py` hits, `server/app/divination/sky.py`
  does not exist. Record the dw-8 function signatures of `system_prompt`,
  `turn_messages`, `side_prompt`, `turn_events` in the log.
  Done when: those checks agree; root `npm test`, `npm run typecheck` and
  server pytest are green before any edit.

- [x] **1. The pure sky module.**
  Files: `server/app/divination/sky.py` (new: `SKY_PERSONAS`, `sky_view`,
  `sky_context`, private `_local_date`), `server/tests/test_divination_sky.py`
  (new), `server/tests/test_boundaries.py` (append
  `test_sky_personas_are_personas`, and `test_divination_reads_no_clock`
  over render/turn/sky with its planted `datetime.now(` self-check).
  Tests build the bundle with `compute_transits(person,
  transit_instant(zone, "Asia/Shanghai", NOW))` and call `sky_view`
  directly; clear the memo in a fixture.
  Done when: K3, K3u, K4, K5, K6's packet half (NY `today`, window end,
  first pass) and the two new boundary tests pass; the divination fence
  (`DIVINATION_FORBIDDEN_RE`) passes unwidened; full server suite green.

- [x] **2. Prompt fragments and the one-of rule in render.**
  Files: `server/app/divination/render.py` (`sky.read` with R-e and the
  null-end and time_unknown clauses, `sky.marker`, `side.sky`, declared
  before `FINGERPRINT`; `system_prompt(..., sky=None)` in dw-8's slot,
  `roster.timing` only without sky; `turn_messages(..., sky=None)`;
  `side_prompt(..., sky_in_view=False)`), `test_divination_render.py`
  (`test_topic_is_registered` gains the three), dw-8's
  `test_divination_roster.py` (S4's "roster.timing once" becomes "exactly
  one of timing/sky" — mechanical), re-recorded
  `fixtures/divination_chartless_{en,zh}.txt`.
  Done when: render-level K2 (six personas × {no chart, chart A, cast,
  deeper} × {sky dict, None}; order chart.marker < sky.marker < dice.brief
  < lang line) and K9 pass; `git diff --exit-code
  server/tests/fixtures/` is empty after re-recording; full suite green.

- [x] **3. Wire the turn: request zone, route clock, turn degrade.**
  Files: `server/app/models.py` (`DivinationTurnRequest.currentTimezone`
  with the existing `check_current_timezone` pattern),
  `server/app/main.py` (`_utcnow` seam; turn route computes `sky_at` and
  passes it), `server/app/divination/turn.py` (`turn_events(...,
  sky_at=None)`, sky in its own try after `natal_context`, zone
  resolution, `sky_in_view` to `_side_read`),
  `test_divination_sky.py` (route-level cases), existing route tests that
  send birthData for moon/saturn/jupiter (freeze `main._utcnow`;
  mechanical), `CLAUDE.md` rule 10 divination paragraph (the spec's one
  sentence, verbatim).
  Done when: K1, route-level K2 (incl. forced raise), K6 (NY, 422 with no
  fake called, absent == `"Asia/Shanghai"`), K7, K8 and K10 pass;
  `test_main_names_the_synchronous_exceptions` and
  `test_delivery_never_generates_on_the_request_path` pass unchanged; full
  suite green.

- [x] **4. Core sends the device zone.**
  Files: `packages/core/src/divination/types.ts` (`TurnRequest.currentTimezone?`),
  `packages/core/src/divination/turn.ts` (body fills it from a private
  `deviceTimezone` one-liner, with the same "duplicated, not imported"
  comment as `transit-day/service.ts:86`),
  `web-divination/src/chat/core-divination.test.ts` (C1: Intl stubbed to
  `"Asia/Shanghai"`; caller value passes through; `toWire` and a stored
  transcript carry no zone).
  Done when: C1 passes; `grep -n currentTimezone
  packages/core/src/divination/transcript.ts` prints nothing; root `npm
  test`, `npm run typecheck` and server pytest all green.

- [x] **5. Validating: the real app (R1–R3).** (SQLite/no-db, not Postgres: dw-12 not in base — 05-validating.md)
  Never use the repo `.env`'s `DATABASE_URL` (shared remote Postgres);
  never `--env-file .env`. :8000/:5173 belong to another checkout. All
  scratch files under `<session scratchpad>/dw11/` only (shared with other
  workers: touch nothing else).
  - **Gate:** `initdb -U astrace --auth=trust` into `scratchpad/dw11/pg`;
    `pg_ctl` on a free port (check `lsof`) with
    `listen_addresses=127.0.0.1` and `unix_socket_directories=''`;
    `createdb astrace_dw11`. Backend with explicit env only:
    `DATABASE_URL=postgresql://astrace@127.0.0.1:<port>/astrace_dw11
    ANALYSIS_LLM=claude-cli CORS_ALLOW_ORIGINS=http://localhost:5175
    GOOGLE_CLIENT_ID=dw11-placeholder.apps.googleusercontent.com conda run
    --no-capture-output -n astrology uvicorn app.main:app --app-dir server
    --port 8002`. Mint a pair with dw-12's `mint.py` recipe
    (`logs/dw-12-google-sign-in/05-validating.md`; assert the throwaway
    URL prefix) and write `astrace.auth.access/refresh/expiresAt`.
  - `curl localhost:8002/api/health` shows the local db BEFORE any POST.
    Web: `cd web-divination && VITE_API_BASE=http://localhost:8002 npx
    vite --port 5175`. Drive with claude-in-chrome; save chart A.
  - **Packets:** read `currentTimezone` from the first turn's request
    body (network panel). `scratchpad/dw11/packets.py` calls
    `sky.sky_context` for saturn, jupiter and moon at
    `transit_instant(<that zone>, "Asia/Shanghai", now)`; run K4's
    ephemeris check on them; log both.
  - Ask R1, R2, R3 as the spec words them. `scratchpad/dw11/datecheck.py`
    extracts every date and month name from each reply and checks it
    against the logged packet; log reply, extraction and verdict per
    attempt.
  Done when: `logs/dw-11-sky-now/05-validating.md` records the packets,
  the K4 check, every reply verbatim with its mechanical date verdict, and
  screenshots; processes stopped, cluster deleted, `lsof` on 8002, 5175
  and the pg port empty.

- [x] **6. Docs-sync.**
  Files: `docs/ARCHITECTURE.md` (via `/update-architecture-doc`: sky
  personas, `sky.py`, the one-of rule, `currentTimezone`, the `_utcnow`
  seam), `docs/features/dw-11-sky-now.md` (new, dw-8's shape, what was
  actually built). Do NOT edit the epic: report its delta to the
  coordinator ("Built so far" dw-11; `divination/sky.py` in the target
  modules; under the event grammar, the turn request gained
  `currentTimezone`).
  Done when: the docs name `SKY_PERSONAS`, `sky_view`, `sky_context`,
  `sky.marker`, `currentTimezone` and `_utcnow`; the epic delta is in the
  handback report.

## Acceptance map

| Criterion | Step |
|---|---|
| K1 who | 1 (pin), 3 (spy, prompt text) |
| K2 never both | 2 (render matrix), 3 (route, forced raise) |
| K3 Saturn packet | 1 |
| K3u unknown time (review note) | 1 |
| K4 dates vs ephemeris | 1 |
| K5 Jupiter, Moon | 1 |
| K6 zone | 1 (packet), 3 (route, 422, default) |
| K7 memo, degrade | 3 |
| K8 side read | 3 |
| K9 goldens, stability | 2 |
| K10 boundaries | 1 (clock, personas), 3 (full, unchanged pins) |
| C1 core zone | 4 |
| R1 Saturn loop-closer | 5 |
| R2 Moon, Jupiter | 5 |
| R3 the others | 5 |

## Deviations (for journaling)

- `planet` in the packet carries `body` (R-a), matching K3.
- K3u (unknown birth time) is added as a server test, beyond the spec's
  criteria (R-c).
- `sky.read` also rules same-day windows as "today" (R-e).
- dw-8's `fixtures/divination_pre_dw8/` are kept, not deleted: dw-8's S5
  test still reads them.

## Risks for the implementer

- **Existing route tests now read the sky.** After step 3, any
  pre-existing `/api/divination/turn` test that sends birthData for moon,
  saturn or jupiter builds a sky at the REAL clock, so its prompt differs
  and an assertion of `roster.timing` breaks. Freeze `main._utcnow` there;
  do not weaken the assertion. Direct `render.system_prompt` callers get
  `sky=None` and are unaffected.
- **Patch where it is looked up.** Forcing a raise or spying means
  patching `app.divination.sky.compute_transits` (the imported name), and
  K7's spy goes on `instant._compute_transits_uncached` with
  `_clear_transits_memo()` first. The Tier A memo is a process-wide LRU of
  8; clear it in a fixture or tests leak cached bundles into each other.
- **Cold walk delays the first frame.** The ~0.5 s walk runs inside the
  generator after the 200, before the provider stream, and emits no
  keepalive; a slow machine delays the first `dice`/`delta` frame, it does
  not fail it. Keep it before the provider call and inside the existing
  deadline; do not add a keepalive or a thread.
- **Clock pin scope.** `test_divination_reads_no_clock` scans render,
  turn and sky only. `summary.py`/`voice.py` `created_at` stamps and
  `time.monotonic` deadlines are legal; the `_utcnow` seam lives in
  `main.py`.
- **Dates are local.** `_local_date` is the only formatter; `today` comes
  from the bundle's `instantUtc`, not a clock. Stations near midnight UTC
  shift a day in Asia/Shanghai (Saturn's 2026-07-26T19:56Z → 07-27).
- **Goldens must not move.** Chart-less prompts never get a sky, so the
  re-recorded fixture diff is empty. A non-empty diff means `roster.timing`
  ordering changed: fix render, never the fixture.
- **Registry freeze.** New fragments are declared before `FINGERPRINT`;
  the summary topic's fingerprint must not move, and no `VERSION` bumps.
- **Real-app zone.** The browser sends its OWN zone. Record packets at the
  zone the request actually carried, and re-record if the session crosses
  local midnight.
- **R3 without birth data.** If the gated web app cannot send a chart-less
  Saturn turn, clear the saved birth-data KV key in the browser and use the
  UI; if that is impossible, POST the turn with curl and say so in the log.
- **R1–R2 depend on the LLM.** One rephrase or retry is allowed; log every
  attempt beside the packet. Any date not in the packet is a FAIL, not a
  retry excuse.
- **Scratchpad is shared.** Touch only `scratchpad/dw11/`; dw-12's
  validator once deleted another worker's Chrome profile.
