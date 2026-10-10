# 10 — docs-sync

- `/update-architecture-doc` on `docs/ARCHITECTURE.md` (baseline b308a92, diff
  b308a92..f4fede3). Sections edited in place: Overview (web-divination paragraph:
  the persona header + voice job); the core tree comment (divination/ gains the
  persona client); the web tree `chat/` entry (usePersona, PersonaHeader, persona.css);
  the server tree `divination/` entry (persona.py, voice.py, second table + migration
  012) and the `data/` comment (divination.db holds both caches; migration 012);
  the boundaries paragraph (two-table pin, persona purity, turn-state regex +
  voice, turn route reads/never ensures, `generate_voice` in the generator regex);
  `core/divination` (persona.ts bullet + its test file); the server divination section
  (render's self.* fragments, natal_context sheet, system_prompt order + chart-less
  goldens, and a dw-7 paragraph: persona.py, voice.py, store table, ensure job, route,
  the turn's read, tests); the web-divination section (a "persona header" bullet,
  i18n `persona` namespace + `PersonaDignity` binding, persona.css under vitest,
  tests); the data-flow paragraph (the persona flow); the web test count
  (21 files / 181 tests); the feature index line.
  Spot-checked: every named path exists (`persona.py`, `voice.py`,
  `012_divination_voice.sql`, `PersonaHeader.tsx`, the golden fixtures) and the doc
  names `persona_sheet` (3), `divination_voice` (11), `012_divination_voice.sql`,
  `ensure_divination_voice` (2), `fetchPersona` (4), `PersonaHeader` (3).
  Pre-existing drift noticed: none beyond the web test count, which now reads 21/181.
- `docs/features/dw-7-persona-mirror.md` written (gitignored, not force-added):
  what it does, what was built, tests, deviations (the two validation-driven role
  fixes, ChartStage stub by URL, vite css include, unexported enum tuples, N1, GeoNames
  coordinates), known limitations.
- Epic file NOT edited (worker rule); its delta is in the handback report.
- Commit: `docs/ARCHITECTURE.md` only.
