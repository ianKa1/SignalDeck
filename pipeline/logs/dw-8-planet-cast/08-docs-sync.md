# 08 docs-sync — dw-8-planet-cast

Skill: `/update-architecture-doc` (diff-driven from the doc's last touch,
c4342d6). Commit `54b3390`.

## docs/ARCHITECTURE.md — sections edited
- Executive summary (web-divination bullet): the six characters, "The
  six", `/api/divination/sheets`, per-character ink/transcripts, handoff.
- Repo tree: core `divination/` (roster.ts), web `chat/` (persona/seed/
  HandoffSlip), new `roster/`, `log/`; server `divination/` (personas,
  dice.txt, focus/roster/side.handoff/to_wire_handoff).
- Boundary tests paragraph: `test_persona_lists_agree`,
  `test_sheets_route_is_pure`, `test_handoff_is_never_parsed_from_the_reply`.
- `core/divination`: PersonaId, done.handoff, handoff in sanitize/toWire,
  new `roster.ts` bullet, the new test file.
- Server Tier C `divination/`: six persona assets, focus.<id>, roster block
  (with the dw-11 ownership note), self.read `{planet}`, `dice.brief`,
  system_prompt order, pre-dw-8 fixtures, side_prompt/side_schema/
  handoff_ids/to_wire_handoff, done triple, persona literal on the three
  routes, the sheets route + `sheets_for`, planet-neutral role texts,
  `test_divination_roster.py`.
- web-divination section: `--venus` → `--char` throughout; SummaryCard /
  SessionTranscript per-record character; vitest css include; PersonaHeader
  per persona + "The six" button; NEW "The six" bullet (useRoster,
  RosterPicker, persona-scope mapping, keyed ChatPanel, seed, HandoffSlip);
  Theme & i18n (persona/personaGhost tokens, local PersonaKey union,
  `roster` namespace, `{name}` templates); Tests list.
- Runtime flows: a "The six" paragraph (sheets → picker → switch → handoff).
- Test counts: web 24 files / 248 tests. Feature index: dw-8 entry.
- Verified: `PERSONA_PLANETS` 8, `roster.timing` 2, `to_wire_handoff` 4,
  `/api/divination/sheets` 5, `fetchSheets` 4, `RosterPicker` 4 mentions.
- No pre-existing drift found outside the diff.

## docs/features/dw-8-planet-cast.md
Written in the worktree (gitignored, not committed): what it does, what
was built, tests, deviations, known limitations.

## Epic delta — for the coordinator (epic file NOT edited)
See the handback report ("Epic changes").

**Transition:** docs-sync → accepting (coordinator).
