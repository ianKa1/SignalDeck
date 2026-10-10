# dw-10-phenomenon-pills — 06 docs-sync (2026-09-29)

## docs/ARCHITECTURE.md (via /update-architecture-doc)
Baseline `e81006d` (the doc's last touch); diff `e81006d..2068e5e`. Surgical edits only:
- Overview (web-divination bullet): the dw-10 sentence (checked inline pills, tap → wheel + meaning, chips legacy-only).
- Repo tree: `chat/` gains Pill.tsx + pill-meaning.ts; server `divination/` comment drops `side.refs`/`side.dice`/`side.sky`, adds the `tags.*` fragments, `pill_ref_ids` and `tags.py`.
- Boundary-test paragraph: `test_tags_is_pure`, `test_only_phenomenon_tags_are_read_from_the_reply`.
- `core/chart-view` glyphs bullet: `ASPECT_TONES`.
- `core/divination`: the `pill` event, the new `pills.ts` bullet, `streamTurn`'s pill mapping.
- Server divination section: fragment list (side.* removed, tag block added), `system_prompt`/`turn_messages` signatures + `tags_section`, the pre-dw8 fixture comparison note, `side_prompt`/`side_schema` new signatures, `pill_ref_ids`, `to_wire_refs` source, a new `tags.py` paragraph, `turn.py` scanner/_Framer/WARNING/refs, the tests paragraph (`test_divination_tags.py`, dw-10 turn tests).
- Web section: pill rendering/press/note, legacy-only chips, `wheel-activation` chip-with-empty-refs, `useChat` pill → token, i18n `pills`/`lore`, tests list.
- Data flow: scanner and `pill` frames on the chat path.
- Feature index: dw-10 entry.
- Verified: `grep "side\.refs\|side\.dice\|side\.sky"` leaves only the dw-10 "deleted" note and dw-5's historical index line. All named files exist.
- Committed `8ce604c`.

## docs/features/dw-10-phenomenon-pills.md
Written directly (as built, deviations, limitations). NOTE: `docs/features/` is gitignored in this repo (`git add` refused: "The following paths are ignored … docs/features"); like the other feature docs it lives on disk only and was NOT force-added.

## pipeline/epics/divination-web.md
- "User rulings (2026-09-28)" Streamed-turns bullet rewritten: structured side fields (mood, handoff, dice) stay out of the prose; the absolute "never parsed" reading was a loop derivation (DECISIONS 2026-09-29, decision precedence); ruling B's one exception — phenomenon tags checked by `tags.py` into `pill` events (review suggestion 4).
- "Built so far": a dw-10 entry; dw-3, dw-5 and dw-11 entries mark `side.refs`/`side_schema(catalogue)`, `side.dice` and `side.sky` as retired by dw-10.
- "Target modules": `tags.py`, turn.py dw-10 line, core `pills.ts`, web `Pill.tsx` + `pill-meaning.ts`, chips legacy-only.
- Event grammar: `pill` row; `delta` gains "never contains ⟦ ⟧"; `bubble` precedes a delta or pill, emptied bubbles collapse; `done.chartRefs` from natal pills; order line `dice? → (delta | pill | bubble)* → done | error`.

Transition: docs-sync done → accepting (coordinator).
