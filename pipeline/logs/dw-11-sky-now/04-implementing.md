# 04 · implementing — dw-11-sky-now

Worker in worktree `/Users/kaimao/Projects/astrology-wt/dw-11-sky-now`,
branch `feature/dw-11-sky-now`, cut from `feature/divination_web` at
fc38893.

## Step 0 — worktree prep and base (2026-09-29)

- Branch `feature/dw-11-sky-now`; `node_modules/@astrace/core` resolves;
  `.env` and the three `server/data/*.se1` are symlinks into the primary
  checkout; no `*.db` symlinked (server/data holds only the three .se1).
- `git log --oneline | grep -E "dw-8|dw-9|dw-12"` → fc38893 (dw-8), c4342d6
  (dw-9). **dw-12 is NOT in the base** (blocked upstream, per coordinator).
  Recorded as a deviation from the plan's step 0: every dw-12-specific part
  (Postgres gate, bearer mint in validating) is skipped; the real-app run
  uses SQLite/no-db instead (coordinator instruction).
- `grep -n roster.timing server/app/divination/render.py` hits (lines 48,
  253, 280, 319, 423); `server/app/divination/sky.py` does not exist.
- dw-8 signatures as found (note: `system_prompt`'s keyword order is
  `action` then `voice`, not the spec's `voice, action`; sky is added as a
  trailing keyword, no positional caller breaks):
  - `system_prompt(persona, lang, ctx=None, cast=None, action="chat", voice=None)`
  - `turn_messages(persona, transcript, message, lang, ctx=None, cast=None, action="chat", voice=None)`
  - `side_prompt(message, reply, lang, catalogue, dice_in_view=False, persona="venus", handoff=False)`
  - `turn_events(request, person, voice=None)`
- Baseline, before any edit:
  - server `DATABASE_URL= conda run -n astrology pytest -q`: `1254 passed, 50 skipped, 1 warning in 106.30s`
  - root `npm test`: jest `Test Suites: 90 passed, 90 total / Tests: 1069 passed`; vitest `Test Files 24 passed (24) / Tests 248 passed (248)`
  - root `npm run typecheck`: clean (no output past the script header).
- Bundle shape confirmed for chart A at NOW (transit_instant → 2026-09-28T04:00:00Z):
  Saturn Aries, natalHouse 9, retrograde; Saturn conj MC 8.36, conj Mars
  6.72, opp IC 5.02 …; returns carry `approaching` without `atUtc` for the
  undated Saturn return.

## Step 1 — the pure sky module

- New `server/app/divination/sky.py` (`SKY_PERSONAS`, `EPISODES_MAX = 8`,
  `_local_date`, `sky_view`, `sky_context`); new
  `server/tests/test_divination_sky.py` (K3, K3u, K4, K5, K6 packet half,
  sky_context gates); `test_boundaries.py` + `test_divination_reads_no_clock`
  (with planted `datetime.now(` self-check) + `test_sky_personas_are_personas`.
  Divination fence regex untouched.
- Station event rows carry `{event, date, kind, sign}`; sign-ingress
  `{sign, retrograde}`; house-ingress `{house, retrograde}`; return `{kind}`.
- `pytest tests/test_divination_sky.py tests/test_boundaries.py`: `37 passed in 3.02s`
- full server: `1262 passed, 50 skipped, 1 warning in 108.41s`

## Step 2 — prompt fragments and the one-of rule

- `render.py`: `sky.read` (incl. same-day window = today, null end = "runs
  past the next year", time_unknown → no house), `sky.marker`, `side.sky`
  declared before FINGERPRINT; `system_prompt(..., sky=None)` (sky only
  with a chart; `roster.timing` dropped iff the sky section is present;
  slot chart < sky < dice < lang); `turn_messages(..., sky=None)`;
  `side_prompt(..., sky_in_view=False)` appends `side.sky` after
  `side.dice` when the catalogue is non-empty.
- Tests: `test_topic_is_registered` gains the three; dw-8 S4 gains the
  "exactly one of timing/sky" sky variant (mechanical addition, no
  assertion loosened); render-level K2 matrix (6 personas × {none, chart,
  cast, deeper} × {sky, None}), K9 render halves and a side.sky test in
  `test_divination_sky.py`.
- Goldens re-recorded from `render.system_prompt("venus", lang)`:
  `git diff --exit-code tests/fixtures/` → empty (FIXTURES-UNCHANGED).
- full server: `1274 passed, 50 skipped, 1 warning in 108.56s`

## Step 3 — wire the turn

- `models.DivinationTurnRequest.currentTimezone` (IANA-validated like the
  transit requests; 422 otherwise). `main._utcnow()` clock seam; the turn
  route resolves `sky_at = transit_instant(currentTimezone, birth tz,
  _utcnow())` when birthData is present and passes it to `turn_events`.
  `turn.turn_events(..., sky_at=None)` builds the packet after
  `natal_context` in its own try (warning `divination turn: sky context
  failed` → sky None), zone = `currentTimezone or person["timezone"]`,
  passes `sky` to `turn_messages` and `sky_in_view` to `_side_read`.
- CLAUDE.md rule 10: the spec's sentence, verbatim (wrapped).
- Pre-existing route tests: none sends birthData for moon/saturn/jupiter
  (dw-8's `_turn` helper defaults to venus; S2's saturn turn has no
  birthData), so no existing test needed a frozen clock. All new route
  tests freeze `main._utcnow` at NOW.
- Route tests in `test_divination_sky.py`: K1 (spy on
  `sky.compute_transits`, zero calls for venus/mars/mercury), K2 route
  matrix (6 personas × {none, chart, cast, deeper} × {ok, forced raise}),
  K3 route packet == sky_view, K6 (NY today 2026-09-27 / to 2027-03-05 /
  first pass 2026-05-14; absent == "Asia/Shanghai"; Mars/Olympus 422 with
  no fake called), K7 (uncached walk spy = 1 for two turns; forced raise →
  delta…done, roster.timing, warning logged), K8 (side.sky in Saturn's side
  read only; done keys == dw-8's).
- `pytest tests/test_divination_sky.py`: `26 passed`
- full server: `1282 passed, 50 skipped, 1 warning in 112.22s`;
  `test_main_names_the_synchronous_exceptions` and
  `test_delivery_never_generates_on_the_request_path` pass unchanged.

## Step 4 — core sends the device zone

- `packages/core/src/divination/types.ts`: `TurnRequest.currentTimezone?`.
  `turn.ts`: private `deviceTimezone()` one-liner (duplicated, not
  imported, as in transit-day/service.ts); body =
  `{...req, currentTimezone: req.currentTimezone ?? deviceTimezone()}`.
- C1 in `web-divination/src/chat/core-divination.test.ts` (Intl
  `resolvedOptions` stubbed to Asia/Shanghai; caller value passes through;
  toWire and a stored transcript carry no zone).
- Mechanical updates of three exact-body pins that now see the added wire
  field (no assertion loosened — each now names the exact zone/key):
  core-divination.test.ts "POSTs the request…" (body == REQ + device zone),
  `ChatPanel.test.tsx` W1 (body + `currentTimezone`),
  `PersonaHeader.test.tsx` W5 (key list + `currentTimezone`).
  The first run showed exactly these two web failures (verbatim diff: `+ "currentTimezone": "America/New_York"`).
- `grep -n currentTimezone packages/core/src/divination/transcript.ts` → nothing.
- root `npm test`: jest `90 passed / 1069 passed`; vitest `Test Files 24 passed (24) / Tests 251 passed (251)`.
- root `npm run typecheck`: clean. Server: `1282 passed, 50 skipped, 1 warning in 111.84s`.
