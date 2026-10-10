# 06 · docs-sync — dw-11-sky-now

- `/update-architecture-doc` on `docs/ARCHITECTURE.md` (baseline fc38893,
  the dw-8 landing; diff = this branch's 4 commits). Surgical edits:
  Overview (the three sky readers), the server tree comment (sky.py, three
  fragments), the boundary-test paragraph (`test_divination_reads_no_clock`,
  `test_sky_personas_are_personas`), core/divination types + turn
  (`currentTimezone`, device-zone fill), server divination (the one-of rule
  on `roster.timing`, `sky.read`/`sky.marker`/`side.sky`, the new
  signatures, a `sky.py` entry, `turn_events`' sky step and degrade, the
  wire's `currentTimezone`, `main._utcnow` + `transit_instant`), and the
  tests list (`test_divination_sky.py`). Symbols spot-checked by grep in
  code and doc: SKY_PERSONAS, sky_view, sky_context, sky.marker,
  currentTimezone, _utcnow, EPISODES_MAX, _local_date. No pre-existing drift found
  in the sections touched.
- `docs/features/dw-11-sky-now.md` written in the worktree (gitignored,
  not committed).
- Epic file NOT edited; its delta is in the worker's handback report.

Status: docs-sync → accepting (coordinator).
