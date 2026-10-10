# dw-10-phenomenon-pills — 08 final review (auto-finalization, 2026-09-29)

## What was built
- Server: a pure `divination/tags.py`, with `KINDS`, `Ground`, `check` and `Scanner`. It runs after the unchanged bubble segmenter and checks four tag kinds against the turn's chart, sky packet or rolls in view:
  - `placement`, `aspect`, `transit` and `dice`;
  - a checked tag becomes a `pill` SSE event;
  - a failed tag becomes English fallback text plus a WARNING carrying the kind and the reason;
  - a malformed tag becomes its inner text with the brackets dropped;
  - `⟦`/`⟧` never reach a delta.
- `turn.py` holds a `bubble` frame until the first non-empty item. `done.chartRefs` is now derived from the checked natal pills. The side read asks only for mood and handoff; `side.refs`, `side.dice` and `side.sky` are deleted.
- `render.py` gains the `tags.rules`, `tags.natal`, `tags.sky` and `tags.dice` block before the language line. The examples in `chart.read`, `self.read` and `sky.read` are now in tag form.
- New boundary tests: `test_tags_is_pure` and `test_only_phenomenon_tags_are_read_from_the_reply`. The handoff test is unchanged.
- Core:
  - `divination/pills.ts` holds `isPill`, `pillToken`, `splitPills`, `pillRef`, `pillSource` and `hasPills`;
  - `streamTurn` yields `pill` events;
  - `ASPECT_TONES` is added in `chart-view` and to the architecture guard's enumeration.
- Web:
  - `chat/Pill.tsx` and `pill-meaning.ts` render inline pills, carrying `data-source` (natal/sky/dice) and `data-tone`, with translated labels;
  - a stored pill is a press button that lights the wheel and shows a one-line meaning note from the new i18n `lore`;
  - the new i18n `pills` namespace holds the pill label templates;
  - the chip row shows only for legacy entries;
  - `SessionTranscript` and `SummaryCard` render static pills.
- CLAUDE.md rules 1, 8 and 10 are amended. `docs/ARCHITECTURE.md` and the epic file are synced.

## Deviations from spec
- Transit pills are restricted to the five Ptolemaic aspect types. Quincunx episodes are named in plain words, and a quincunx tag fails as `not-in-sky`.
- Extra failure reasons: `no-chart`, `time-unknown`, `not-in-sky`, `not-rolled`.
- The zh pill aspect words differ from the chip words.
- The `divination_pre_dw8` fixtures were not re-recorded; a slice comparison is used instead.

## Known limitations
- The failed-tag path was not triggered in the real-app runs, because every live tag passed. It is covered by the T3 test only.
- A failed tag's fallback text is English, even inside a zh reply.
- The en `lore` rows are copies of Tier B with no parity test.
- A summary that echoes a tag in non-canonical case shows its brackets.
- `docs/features/dw-10-phenomenon-pills.md` is gitignored and exists on disk only.

## Acceptance
OVERALL: PASS, 32/32 criteria (logs/dw-10-phenomenon-pills/07-accepting.md). Suites: server 1339 passed and 50 skipped; app-native jest 1069 passed; web vitest 270 passed; typecheck clean.
