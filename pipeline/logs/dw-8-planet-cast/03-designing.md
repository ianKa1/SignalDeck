# 03 designing — dw-8-planet-cast (revision round 1)

Input: `02-spec-review.md` (FAIL on B1, plus non-blocking notes), with the coordinator's decisions for B1.

## Changes to `specs/dw-8-planet-cast.md`

- **B1.** The composition heading is now "Composition with dw-9, dw-12 and dw-11". A new "Composition with dw-11" hand-off contract states:
  - (a) Serial landing in queue order (PIPELINE.md, Parallel waves 6), so dw-8 lands first and dw-11 merges it in.
  - (b) dw-8 emits `roster.timing` unconditionally. dw-11 owns replacing or suppressing it wherever a sky section is present, and adds the "never both" test.
  - (c) The sky section's slot is after the chart and before the dice: persona < shape < depth < roster < self < chart < sky < dice < lang. The shared files are `render.py` (the `system_prompt` order and return expression), `turn.py`, `main.py`, `test_boundaries.py`, CLAUDE.md rule 10 and the goldens.
  - (d) dw-8 re-records the chart-less goldens at its landing, and dw-11 re-records at its own.
- **Jupiter examples.** They are "Is it worth grabbing?" / 这个机会值得抓住吗？ and "Will the next step open things up?" / 下一步会打开局面吗？
- **S7.** Adds a chart-less chat case. The contract now says `side_schema` adds `handoff` on the empty-catalogue branch too, returning `{mood, handoff}` in place of `MOOD_SCHEMA`.
- **Sheets route.** Computes one `natal_report`, then `persona_sheet` per planet.
- **`system_prompt` signature.** Now includes dw-9's `action`.
- **Picker mid-stream.** Decided: the picker OVERLAYS the chat, and ChatPanel stays mounted, so opening it does not stop a turn. Only switching character stops it, through the stopped path, which after dw-9 is the pacer's `flush()`.
  - Panel key and seed: the panel is keyed by persona ONLY. `seed` is `{text, nonce}`, and it is reapplied whenever the nonce changes. So a same-character example or handoff refills the composer without a remount, and without killing the turn in flight. This deviates from the reviewer's "key by persona + nonce", because that remount would abort a live turn.
  - W3 gains the overlay and same-character checks.
- **Handoff validity on the device.** Defined as `isPersonaId` in `sanitize`.
- **A3.** Allows one rephrase or retry, with both attempts and their `done.handoff` logged.

## Word counts (wc -w)
- WHAT (Goal, Non-goals, Decided defaults): 1442
- Architecture: 1490
- Acceptance Criteria (exempt from the budget): 1479

## Transition
designing (revision 1) → spec-review round 2.
