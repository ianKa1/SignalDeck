# dw-17-web-two-pane-layout — wheel | chat, two equal panes

## Goal

On `/chat/<planet>` the web screen becomes two equal panes: the wheel on the left and the chat, full height, on the right. The Big Three and the Placements list leave the page, and "Your birth" shrinks to one button that opens the birth form. QUEUE.md `dw-17-web-two-pane-layout` (user request 2026-09-29); epic `pipeline/epics/divination-web.md`.

## Non-goals

- Any server, core or app-native change. Web layout and the birth-input surface only.
- New colour tokens, a new router, new routes, or a change to Home's plates, the Sessions screen, the masthead or the sign-in gate beyond the birth button on Home (D6).
- Changing the chat's content, pills, pacer, dice, persona header or session bar behaviour.
- Account-backed birth data (that is dw-16, running in parallel; this feature only changes where the form is shown).

## Decided defaults

1. **Desktop layout (≥ 960 px).** `.layout` on a chat route is `grid-template-columns: minmax(0,1fr) minmax(0,1fr)` (equal widths, gap 32 px). The layout's height is the viewport below the masthead, in pure CSS: on chat routes the shell is a `100dvh` flex column, the masthead keeps its natural height, and `.layout` takes `flex: 1; min-height: 0`, so the page never scrolls. Left pane: the birth button row on top, the wheel centered below it, scaled to the pane (square, `min(pane width, pane height minus the row)`), with dw-15's focus toggle and spotlight unchanged. Right pane: `SessionBar` at the top, then the `ChatPanel` filling the rest; the panel's transcript scrolls inside it (the 60vh cap goes) and the composer stays pinned at its foot.
2. **Removed.** `<Placements>` is no longer rendered anywhere; `chart/Placements.tsx`, its test and the `.big-three`/`.placements` CSS are deleted, and the i18n keys used only by it (`chart.bigThree` and the placement-row labels) are deleted from en and zh (parity kept). The wheel's own `aria-label` stays; a screen reader still gets the wheel label and every pill.
3. **The birth button.** `BirthCard` becomes: with saved data, ONE button `button.birth-chip[data-birth-chip]` whose label is `"<date> · <place>"` (time omitted; the place is the saved location name, ellipsized at 28ch with a `title` carrying the full `date · time · place (timezone)`), prefixed by the ☉ glyph and an `aria-label` "Your birth: <full line> — edit". Pressing it opens the birth form in a popover panel anchored under the chip (not modal: `role="dialog"`, `aria-modal="false"`, labelled "Your birth"), focus moves to the first field; Save closes it and returns focus to the chip; Cancel or Escape closes without saving; a click outside closes it. `aria-expanded` on the chip reflects the state.
4. **No birth data yet.** The left pane shows the full birth form in place of the wheel (the "Your birth" card as today), so a first-time user enters it where the wheel will appear; after Save the wheel renders there and the chip appears above it. The chat pane stays usable (characters without a chart speak from their base role, as today).
5. **Phone and tablet (< 960 px).** The panes stack with the CHAT FIRST: the chat pane (session bar + panel) is the first block and is sized to the viewport below the masthead (the same flex column; min height 420 px) with its own scroll; the chart pane follows. A small "Chart ↓" link at the top-right of the chat pane (`a[href="#chart-pane"]`, visible only < 960 px) jumps to the wheel, and the chart pane carries "↑ Chat" back. With no birth data, the birth form block comes FIRST (above the chat) at this width. No tab switch (both panes stay mounted, so the pills keep lighting the wheel and the spotlight keeps its frame loop only when visible as today).
6. **Home.** Home's colophon `BirthCard` uses the same chip (and the same inline form when nothing is saved). Nothing else on Home changes.
7. **Other surfaces unchanged.** Pills light the wheel (dw-10/15), the focus toggle and "Show full chart" work (dw-15), routes, Back/Forward and headings behave as dw-14, the masthead and gate as dw-12. The not-found and Sessions screens keep their one-column layout.
8. **Design.** Existing tokens only (rule 13); class selectors only. The chip: hairline `line` border, `panel` fill, `text-dim` label in the body serif, ☉ in `voice`; hover/focus lifts the border to `voice`. The popover: `panel` background, `line` hairline, 12 px shadow in an existing translucent token, 220 ms fade/raise, none under reduced motion. The pane divider on desktop: a 1 px `line-soft` vertical rule centred in the gap.

## Architecture

Cites the epic (web tree rules: barrels only, network only in `src/platform/`, colours only in `theme/tokens.ts`, text-free guards). Web-only.

### Reuse (verified on 2e6cfe8)

| Need | Existing | Use |
|---|---|---|
| Chat route layout | `app/ChatScreen.tsx` :31-45 (`main.layout > section.stage + aside.side`) | Restructured into the two panes; `data-slot="stage"`/`"side"` kept (tests and the gate's W2 read them). |
| Birth card | `birth-input/BirthCard.tsx`, `BirthSummary.tsx`, `BirthForm.tsx` (`initial`, `onSaved`, `onCancel`) | `BirthCard` gains the chip + popover; `BirthForm` reused as-is inside it. `BirthSummary` is replaced by the chip (deleted). |
| Layout CSS | `app/app.css` :74-107 (`.layout`, `.stage`, `.side`, the 960 px query) | Rewritten for equal panes and full height. |
| Chat scroll | `chat/chat.css` :87-88 (`max-height: 60vh`) | Replaced by a flex-filled scroll region. |
| Placements | `chart/Placements.tsx`, `Placements.test.tsx`, `chart/wheel.css` `.big-three` :4-20 | Deleted. |

### Module map

```
web-divination/src/
├── app/ChatScreen.tsx           CHG  two panes: chart pane (BirthCard chip/form + ChartStage), chat pane (SessionBar + ChatPanel), jump links
├── app/app.css                  CHG  equal panes, the 100dvh shell column on chat routes, < 960 px stacking order
├── birth-input/BirthCard.tsx    CHG  chip + anchored popover over BirthForm; inline form when nothing is saved
├── birth-input/BirthChip.tsx    NEW  the chip button (label, title, aria)
├── birth-input/BirthSummary.tsx DEL
├── birth-input/birth-input.css  CHG  chip + popover styles
├── chat/chat.css                CHG  transcript fills the panel height
├── chart/Placements.tsx (+test), wheel.css big-three rules  DEL
└── i18n/en.ts, zh.ts            CHG  − Placements-only keys, + chip/popover keys (`form.birthChipLabel`, `form.birthDialog`, `layout.toChart`, `layout.toChat`)
```

### Contracts and rules

- `BirthCard()` props unchanged (none); state `open: boolean`; outside-click and Escape listeners attach only while open and are removed on close/unmount. No new global beyond `document` event listeners (G16 unaffected: no `history`/`location`).
- `ChatScreen` keeps `ChartStage persona`, `SessionBar persona`, `ChatPanel key=persona`. The chart pane has `id="chart-pane"`, the chat pane `id="chat-pane"`.
- No new dependency, no new core import. Guards G1–G17 and the colour/text guards unchanged.

## Acceptance Criteria

Suites: `npm test`, `npm run typecheck` (vitest/jsdom for W-criteria). Real-app checks on Vite + a local backend, headless Chrome at 1440×900 and 390×844.

**Web (vitest)**
- **W1**: `/chat/venus` with saved birth data and a chart renders `[data-slot="stage"]` and `[data-slot="side"]` inside `main.layout`, contains no `[data-big-three]`, no `.placements`, no element with text "Big Three"/"Placements", and exactly one `[data-birth-chip]` inside the stage slot.
- **W2**: the chip's text contains the saved date and place, its `title` contains the time and timezone, `aria-expanded="false"`. Clicking it → a `role="dialog"` labelled "Your birth" containing the birth form's date field, `aria-expanded="true"`, focus on the first field.
- **W3**: in the open popover, changing the date and pressing Save → the core birth-data store holds the new date, the popover closes, and focus returns to the chip. Escape and Cancel close without saving; a mousedown outside closes it.
- **W4**: with no saved birth data, `/chat/venus` shows the birth form (no chip, no wheel) in the stage slot, and the chat panel still renders in the side slot; after Save, the chip appears.
- **W5**: Home with saved data shows the chip in the colophon (no summary line, no Edit button); with none, the inline form.
- **W6**: `chart/Placements.tsx` and `birth-input/BirthSummary.tsx` no longer exist; the en↔zh parity test passes; no remaining source file references `bigThree`.
- **W7**: the stylesheet check (as dw-6/W8): `app.css` gives `.layout` two `minmax(0, 1fr)` columns at ≥ 960 px; `chat.css` no longer contains `60vh`; the popover has no transition under `prefers-reduced-motion: reduce`.
- **W8**: existing suites for pills → wheel, focus toggle, routes and the gate pass unchanged except where they asserted Placements/summary content (those assertions move to the chip).
- **G1**: architecture, colour and text guards green; `npm test` + `npm run typecheck` green; no new colour literal.

**Real app** (headless Chrome, signed in with a minted pair on a local db — never the Neon URLs; backend and Vite on the worker's own ports)
- **R1 (desktop 1440×900)**: `/chat/venus` → the stage and side panes' bounding boxes have equal widths (±2 px) and sit side by side; the page's `scrollHeight` equals its viewport height (no page scroll); the chat composer's bottom is within the viewport; no Big Three / placements text visible. Screenshot logged.
- **R2**: one click on the birth chip opens the form; changing the city and saving updates the chip label and redraws the wheel (the `/api/chart` request fires). 
- **R3**: after a Venus reply with a pill, tapping the pill lights the wheel (`data-lit` present) and "Show full chart" toggles as before.
- **R4 (phone 390×844)**: the chat pane is the first pane below the masthead and its composer is visible without scrolling; "Chart ↓" scrolls the wheel into view; with no birth data the form is first. Screenshot logged.
- **R5**: Back/Forward between `/`, `/chat/venus` and `/sessions` still land correctly, and a reload of `/chat/venus` restores the two-pane layout.
