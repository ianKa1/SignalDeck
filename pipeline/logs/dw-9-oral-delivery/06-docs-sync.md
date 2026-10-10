# 06 docs-sync — dw-9-oral-delivery (worker #2)

Skill `/update-architecture-doc` (diff-driven). Baseline: `docs/ARCHITECTURE.md`
last touched at b308a92 (dw-6); diff `b308a92..HEAD` = the six dw-9 commits.
Triage: structural — new module `divination/bubbles.py`, new wire event
`bubble`, request `action` + `deeper`, new web module `chat/pacer.ts`, new
components; local — render fragments/signatures, core types/guard,
transcript sanitize, i18n keys, vite test config, test counts.

Sections edited in `docs/ARCHITECTURE.md` (surgical, present tense):
- Stack overview (web-divination bullet): the spoken slips, the bubble
  event, the go-deeper chip.
- Repo tree: `web-divination/src/chat/` (Slips/GhostSlip/DeeperChip,
  pacer.ts); `server/app/divination/` (shape/depth fragments, bubbles.py).
- `core/divination`: `bubble` TurnEvent, `'deeper'` action,
  `TranscriptEntry.deeper`, the bubble guard in `streamTurn`, sanitize and
  `toWire` keeping `deeper` on the device.
- Server divination: persona/lang.zh no length rule, the four new
  fragments, `system_prompt`/`turn_messages` `action`, a `bubbles.py`
  paragraph, `turn.py` segmentation + cap + joined side-read reply + "no
  delta sent", the `action` wire incl. deeper 422, tests list.
- web-divination Chat: Pending/pacer/in-flight lifetime/Stop-after-done/
  joinBubbles/deeper send+retry+canDeepen; slips, ghost slip, chip styling;
  reduced motion; vite `test.css.include` gains chat.css; i18n keys; tests
  list; the data-flow chain; vitest count 20 files / 194 tests.
- Feature index: dw-9 entry.
Confirmed still accurate: boundary-test paragraph (no existing pin changed;
the new `test_bubbles_is_pure` is described in the server section),
main.py/llm.py descriptions (unchanged by dw-9).
Spot-check: `bubbles.py` 4, `Segmenter` 5, `bubble {index}` 3,
`shape.chat` 3, `depth.chart` 3, `createPacer` 1, `DeeperChip` 2 mentions;
app-native guards `1069 passed` after the edit.

`docs/features/dw-9-oral-delivery.md` written (gitignored; not force-added),
dw-6's shape: what it does, what was built, tests, deviations, limitations.

Epic file NOT edited (coordinator's): the delta is in the handback report.

Transition: docs-sync done → coordinator runs `accepting`.
