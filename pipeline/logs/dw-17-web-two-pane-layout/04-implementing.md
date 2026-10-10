# 04 — implementing (2026-09-29, parallel-wave worker)

Worktree `/Users/kaimao/Projects/astrology-wt/dw-17-web-two-pane-layout`, branch
`feature/dw-17-web-two-pane-layout` (base 2e6cfe8).

## Step 0 — baseline
- `npm test` (root): app-native jest `Test Suites: 90 passed, 90 total` / `Tests: 1078 passed, 1078 total`;
  web-divination vitest `Test Files 42 passed (42)` / `Tests 386 passed (386)`. EXIT 0.
- `npm run typecheck`: EXIT 0 (both workspaces).

## Step 1 — remove Placements
- `git rm` chart/Placements.tsx + Placements.test.tsx; wheel.css `.big-three`…`.placements__note` block removed;
  ChatScreen no longer renders it (and no longer reads useChart there).
- i18n keys deleted in en+zh (only referenced by Placements, N4): chart.retrograde, chart.timeUnknownNote,
  chart.placementsTitle, chart.bigThree, chart.house. Kept chart/format.ts (ChartStage uses degreeText).
- App.test T5 dropped its `[data-placement="Sun"]` degree assertion (the list is gone).
- `npx vitest run`: Test Files 41 passed (41), Tests 383 passed (383) (−3 = the deleted Placements suite).
  `tsc --noEmit` OK. `grep -rn "bigThree\|Placements" web-divination/src` → empty.

## Step 2 — birth chip + popover
- NEW birth-input/BirthChip.tsx (`button.birth-chip[data-birth-chip]`, ☉ + date · place, place ellipsized at 28ch in CSS,
  `title` = `date · time · place (tz)`, `aria-label` = form.birthChipLabel, `aria-haspopup="dialog"`, `aria-expanded`).
- BirthCard.tsx: nothing saved → `<BirthForm/>` inline; saved → `.birth-anchor` with the chip and, while open, a
  `div.birth-popover[role=dialog][aria-modal=false]` labelled form.birthDialog holding `<BirthForm initial onSaved onCancel>`.
  Focus → first enabled field on open; Save/Cancel/Escape close and refocus the chip; document `mousedown` outside
  the anchor closes (listeners only while open). Reads via `useBirthData()` (N7).
- BirthSummary.tsx deleted (`git rm`). i18n en+zh: − form.edit, − form.summaryTitle; + form.birthChipLabel,
  + form.birthDialog (form.summaryTimeUnknown kept: the chip's title uses it for a null time).
- CSS (birth-input.css): `.birth-summary__*` removed; chip (line hairline, panel fill, text-dim body serif, ☉ in voice,
  hover/focus/expanded → voice border) and popover (panel + blur, line hairline, `0 12px 32px var(--aura)` shadow,
  220 ms fade/raise; no animation/transition under reduced motion).
- Tests: NEW birth-input/BirthCard.test.tsx (W2, W3 ×2, W5 unit); App.test T5 + dw-14 W2 moved from summary/Edit to the chip.
- `npx vitest run`: Test Files 42 passed (42), Tests 387 passed (387). `tsc --noEmit` OK.

## Step 3 — two panes
- app/ChatScreen.tsx: `main.layout.layout--chat[data-birth=saved|none]` > `section#chart-pane.pane--chart[data-slot=stage]`
  (saved: `.pane__head` = BirthCard chip + `button[data-jump=chat]`, then ChartStage; none: BirthCard's inline form only)
  + `aside#chat-pane.pane--chat[data-slot=side]` (`.pane__head` = SessionBar + `button[data-jump=chart]` when saved; ChatPanel).
  Jumps are buttons calling `scrollIntoView` (N1; smooth unless reduced motion via theme/motion); none while nothing is saved
  (the form already sits above the chat, so an arrow would point the wrong way).
- App.tsx: shell gains `shell--chat` on chat routes.
- app.css: `.stage`/`.side` rules replaced. `.shell.shell--chat` = 100dvh flex column; `.layout--chat` flex:1/min-height:0.
  ≥960: two `minmax(0, 1fr)` columns, one row, gap 32, divider = `.pane--chat::before` 1px line-soft at −16px; chart stage
  `container-type: size`, disc `width: min(100cqw, 100cqh - 118px)` (N6: room for toggle + status line); pane overflow only
  when data-birth=none. <960: layout = scrolling flex column inside the viewport; chat pane `flex: 0 0 100%`, min 420px,
  `order:-1` only when saved (form first otherwise). Jumps hidden ≥960.
- chat.css: `.chat__log` `flex: 1 1 auto; min-height: 0` (60vh cap gone); header + composer `flex: none`. Autoscroll reads the
  log's own scrollTop/scrollHeight, so it is unaffected.
- i18n en/zh: + layout.toChart / layout.toChat.
- Tests (N5): App.test first test + dw-4 W3 and ChartStage.focus F3 moved from the empty ring to form-in-stage. NEW
  app/ChatScreen.test.tsx: W1, W4, W6 (import.meta.glob raw over src), W7 ×4 (app/chat/birth-input css ?raw).
- `npm test`: jest Test Suites 90 passed / Tests 1078 passed; vitest Test Files 43 passed (43) / Tests 394 passed (394).
  First `npm run typecheck` failed: `ChartStage.focus.test.tsx(8,23): error TS6133: 'screen' is declared but its value is
  never read.` → import removed; typecheck EXIT 0.
