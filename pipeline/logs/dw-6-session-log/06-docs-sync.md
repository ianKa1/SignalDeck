# 06 docs-sync — dw-6-session-log (worker #3)

Skill: `/update-architecture-doc` (baseline: `docs/ARCHITECTURE.md` last touched in `2f45dfb`; diff `2f45dfb..HEAD` = the 7 dw-6 commits; no escalation needed).

`docs/ARCHITECTURE.md` sections updated (surgical, present tense):
- Overview → Web-divination bullet: End session, the summary job, the device session log and Sessions screen.
- Layering tree: core `divination/` comment (summary client + KV session log); web-divination `log/` folder; server `divination/` comment (summary.py + store.py, importers main + generation); `data/` (divination.db, migration 011).
- Boundary paragraph: the store.py db-line strip, importers exactly main.py + generation.py, the evolved no-state pin, the new identity-free table pin and the turn/render-never-import-summary pin; generator regex gains `generate_summary`.
- `core/divination`: `clearTranscript`, `summary.ts`, `session-log.ts`, test file list.
- Server Tier C `divination/`: FINGERPRINT line (keys nothing; the summary is its own topic) + a dw-6 paragraph (topic, key doctrine, generator, store, job, route, tests).
- web-divination as built: Layout (session bar, view swap), new **Session log** bullet (the sealed plate, reader, reduced motion, vite css include), i18n `log` namespace + `Tone` binding, tests list.
- Data flow: the End-session chain.
- Testing: web-divination count now 17 files / 114 tests.
- Feature docs list: dw-6 line.
Confirmed still accurate: deployment, native sections, other server tiers.
Pre-existing drift noticed (not fixed — outside this feature's diff): the "Feature docs" list has no `dw-3-chart-grounded-reply` line although `docs/features/dw-3-chart-grounded-reply.md` exists in the primary checkout.

`docs/features/dw-6-session-log.md` written in the worktree (gitignored, not committed).

Done-when: `divination_summary`, `011_divination_summary.sql`, `ensure_divination_summary`, `astrology.divination.sessions.v1`, `SummaryCard` all named in the docs; `git diff --stat feature/divination_web...HEAD -- docs` shows ARCHITECTURE.md. The epic-file edit (incl. the "changes the cache key" line) is NOT made by this worker — reported to the coordinator as text.

Transition: docs-sync → (coordinator) accepting.
