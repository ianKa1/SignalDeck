# Feature Specification: dw-4-wheel-activation

DIVINATION WEB EPIC, entry 4 of 6. Epic architecture:
`pipeline/epics/divination-web.md` (cited, not restated). The `ChartRef`
wire shape and its wheel mapping are fixed by
`pipeline/specs/dw-3-chart-grounded-reply.md` (Wire delta).

## Goal

Implement QUEUE.md `dw-4-wheel-activation`: when a Venus reply lands, its `chartRefs` light the matching planets and
aspects on the SVG wheel and dim the rest; the light fades when the user sends the next turn; pressing a chip
re-lights just that placement. Web only, through core `chart-view`'s `aspectKey`/`planetFamily`.

## Non-goals

- No server, core (`packages/core`), guard-test or CLAUDE.md change. No new
  token in `theme/tokens.ts`, no new i18n key, no `App.tsx` change.
- No SkSL, canvas or WebGL. Glow is CSS `filter: drop-shadow()` on SVG
  elements; dimming is CSS opacity.
- No highlight from hovering a chip, from clicking the wheel, or from
  scanning the reply prose. Only `done.chartRefs` and chip presses drive it.
- No persistence of the highlight: it is page-session state. After a reload
  the wheel starts neutral (the stored chips still work).
- No houses, signs or angles as highlight targets beyond what a ref names
  (an aspect to the Ascendant lights the Ascendant hub node, nothing more).
- No scroll-into-view of the wheel on narrow layouts, no screen-reader
  announcement of highlight changes.
- No dice (dw-5), no session log or history (dw-6), no native change.

## Decided defaults

**What lights, in three tiers** (all set arithmetic over the SHOWN chart; no
angular maths):
- **Lit**: every planet a planet ref names; every aspect an aspect ref names
  (matched to a `chart.aspects` entry with equal `bodyA`/`type`/`bodyB`,
  keyed by `aspectKey`); both ends of each lit aspect (a planet, or the
  Ascendant hub node).
- **Echo**: for each planet ref, its `planetFamily(chart.aspects, body)` — the
  aspects touching it and their partner bodies — unless already lit.
- **Dim**: every other planet, chord, conjunction dot and hub node. The zodiac
  ring and the houses layer recede a little.
- A ref that does not match the shown chart (birth data edited since, or a
  body/aspect the chart lacks) is ignored. If NO ref matches, there is no
  activation: the wheel stays neutral, never all-dim.

**When it changes**
- A reply's `done` with non-empty `chartRefs` → the wheel shows that set.
  `[]`, a stopped reply or a failed turn → no new activation.
- Sending a message (and Retry) clears the activation at once, at send time,
  so the old light fades while Venus is "listening".
- Pressing a chip shows that ONE ref (same tier rules; a planet chip also
  echoes its family). Pressing the pressed chip clears. Pressing another chip
  switches. Chips on older replies and on replies restored from KV work the
  same. With no chart shown, a press changes only the chip's pressed state.
- Changing birth data keeps the activation; it is re-matched against the new
  chart (misses ignored).

**Look** (candlelit observatory; Venus "points at the sky" in her
rose-copper while the room dims):
- Dim tier: opacity 0.18. Zodiac ring and houses group: 0.55. Echo tier:
  opacity 0.6, no glow.
- Lit planet: glyph and tick in `--venus`, glow
  `drop-shadow(0 0 3px var(--venus)) drop-shadow(0 0 9px var(--venus-ghost))`,
  opacity 1; its hub node fills `--venus`. Lit Ascendant node: same fill and
  glow.
- Lit chord: stroke width 2.2, opacity 1, its own aspect colour, glow
  `drop-shadow(0 0 2.5px var(--aspect-<type>))`. Lit conjunction dot: same
  glow in `--aspect-conjunction`.
- Motion: entering an activation transitions opacity, filter, fill and
  stroke width over 600ms ease-out; returning to neutral transitions over
  900ms ease-in-out (the "fade"). Switching between activations uses the
  600ms entry. Under `prefers-reduced-motion: reduce` every activation
  transition is `none` (states apply at once).
- Chips become press buttons: no border change at rest (the dw-3 seal look
  holds), `cursor: pointer`; hover/focus background `--theme-ghost`;
  `:focus-visible` outline 1px `--voice`, offset 2px; pressed
  (`aria-pressed="true"`) border `--venus` and the glyph glows with
  `drop-shadow(0 0 3px var(--venus-ghost))`. The dw-3 rise-in animation is
  kept.
- Accessible name of a chip is unchanged (planet name / the dw-3 aspect
  phrase); the pressed state is conveyed by `aria-pressed`.

**Local runs** (as dw-3): backend with `ANALYSIS_LLM=claude-cli` and
`CORS_ALLOW_ORIGINS` set to the Vite origin on a free port (not :8000);
`VITE_API_BASE=<that backend> npm run web` (Vite on its own port). Fixture
birth: 1990-06-15 08:30, Beijing. Its chart has Venus opposition Pluto and a
Venus family of Moon sextile Venus, Venus sextile Jupiter, Venus trine
Saturn, Venus trine Neptune, Venus opposition Pluto; Saturn opposes the
Ascendant.

## Architecture

Cites the epic's Built so far (dw-1 wheel attributes, dw-3 hooks), Reuse map
and Dependency rules. Only dw-4's delta is written here.

### Reuse (verified 2026-09-28)

| Need | Existing | Use |
|---|---|---|
| Aspect identity | core `chart-view/aspect-set.ts:17` `aspectKey` | Key of a matched chart aspect; equals the wheel's `data-aspect-key` (`ChartWheel.tsx:173,202`). Not redefined. |
| Planet family | core `chart-view/aspect-set.ts:26` `planetFamily` | The echo tier of a planet ref. |
| Ref type | core `divination/types.ts:22` `ChartRef` (type-only import) | Store and mapping input. |
| Shown chart | `chart/useChart.ts:32` `useChart`, `:37` `useChartStatus` | `ChartStage` already reads them (`ChartStage.tsx:18-20`). |
| Addressable wheel | `ChartWheel.tsx:239` `data-planet` on the planet group, `:180,202` `data-aspect-key` on dots and chords, `:220` `data-aspect-node="Ascendant"` | Receive the tier attributes. |
| Turn events | `chat/useChat.ts:56` `run` (the one consumer, epic) | Clears at start; shows refs after the `done` append (`:86-93`). |
| Chips | `chat/ChatPanel.tsx:71` `ChartRefChips`, rendered from `Entry` (`:136`) | Become buttons. |
| Colours | `theme/tokens.ts` `venus`, `venusGhost`, `themeGhost`, `voice`, `aspect.*` → `--venus`, `--venus-ghost`, `--theme-ghost`, `--voice`, `--aspect-*` (`theme/apply.ts:17`) | No new token. |

### Module map (created / changed only)

```
web-divination/src/
├── chart/
│   ├── wheel-activation.ts      NEW  the highlight store + the pure ref→tier mapping
│   ├── wheel-activation.test.ts NEW
│   ├── ChartWheel.tsx           + optional `activation` prop → data-active / data-lit /
│   │                              data-echo; hub nodes gain data-planet-node
│   ├── ChartStage.tsx           reads the store + shown chart, passes the mapping
│   ├── wheel.css                activation tiers, transitions, reduced motion;
│   │                              reveal fill-mode both → backwards
│   └── ChartWheel.test.tsx / ChartStage.test.tsx   extended
├── chat/
│   ├── useChat.ts               two calls: clear at run start, show on done
│   ├── ChatPanel.tsx            ChartRefChips: li > button[aria-pressed]
│   ├── chat.css                 chip button states
│   └── ChatPanel.test.tsx       dw-3 W4 replaced by the press criteria
└── app/App.test.tsx             + the integration criteria (W1–W3)
```

**Shared files the parallel wave also touches** (landing-conflict surface):
`chat/useChat.ts` (two lines inside `run`), `chat/ChatPanel.tsx` (only the
`ChartRefChips` function and the `Entry` call site), `chat/chat.css` (the
dw-3 chip block only), `chat/ChatPanel.test.tsx` (W4 block),
`app/App.test.tsx` (appended `describe`). NOT touched: `App.tsx`,
`i18n/{en,zh}.ts`, `theme/tokens.ts`, core, server, guards.

### Module contracts

**`chart/wheel-activation.ts`** — owns "what the wheel is showing now".
- State: `Activation = { refs: readonly ChartRef[]; chip: string | null } | null`,
  module-level, page-session only (no KV). `chip` is the pressed chip's id
  (`"<entryIndex>:<refIndex>"`), `null` for a reply-driven activation.
- `showRefs(refs, chip?)`: empty `refs` → same as clear. `clearActivation()`.
  `getActivation()`, `subscribeActivation(listener) → unsubscribe`,
  `useActivation()` (via `useSyncExternalStore`).
- `activationFor(chart: BirthChart | null, refs: readonly ChartRef[]) →
  WheelActivation | null`, pure:
  `WheelActivation = { lit: Tier; echo: Tier }`,
  `Tier = { bodies: ReadonlySet<AspectPoint>; aspectKeys: ReadonlySet<string> }`.
  Planet ref matches when `chart.planets` has the body. Aspect ref matches the
  `chart.aspects` entry with equal `bodyA`/`type`/`bodyB`; its key is
  `aspectKey(entry)`. Echo = union of `planetFamily` per matched planet ref,
  minus lit. Returns `null` when `chart` is null or nothing matched.
- Does NOT: fetch, read KV, touch the DOM, or do longitude/angle maths
  (equality and set membership only — rule 5, guard G4).

**`chart/ChartWheel.tsx`** stays pure: new optional prop
`activation?: WheelActivation | null`. When non-null the `<svg>` carries
`data-active`; each planet group, chord, conjunction dot and hub node carries
`data-lit` or `data-echo` by membership (bodies for planets/nodes, keys for
aspects). Hub node circles gain `data-planet-node="<body>"` (a new name so
dw-1's `[data-planet]` count stays 10). Absent or null → markup identical to
dw-1. No other geometry change.

**`chart/ChartStage.tsx`**: `activationFor(shown, useActivation()?.refs ?? [])`
→ `ChartWheel activation`. The wheel's remount key is unchanged.

**`chat/useChat.ts`**: `clearActivation()` as the first statement of `run`
(covers send and Retry); after appending a finished persona entry with
non-empty refs, `showRefs(chartRefs)`. Nothing else in the state machine
changes.

**`chat/ChatPanel.tsx`**: `ChartRefChips` gains the entry index; each `li`
wraps a `button type="button"` holding the dw-3 content and label, with
`aria-pressed = (activation?.chip === id)`; click → pressed ? `clearActivation()` :
`showRefs([ref], id)`.

**`wheel.css`**: tier rules scoped under `.wheel[data-active]`; the 900ms
transition sits on the base selectors and the 600ms one on the active
selectors (a transition takes the destination state's duration). The reveal
animations change `animation-fill-mode` from `both` to `backwards`: with
`both`, a finished `from`-only animation keeps owning `opacity`, and the
activation transitions would snap instead of fade. The keyframes are
`from`-only, so the reveal looks identical.

### Dependency rules and forbidden edges

- New edge: `chat/` → `chart/wheel-activation.ts` (functions and the hook).
  `chart/` never imports `chat/`.
- `wheel-activation.ts` imports: `react`, `@astrace/core/chart-view`
  (`aspectKey`, `planetFamily`), type-only `@astrace/core/chart` and
  `@astrace/core/divination`. Barrels only (G1); it is not a chart VALUE
  importer, so G5's single importer (`chart/useChart.ts`) holds.
- ❌ No colour literal outside `theme/tokens.ts` (colour guard): glows name
  `var(--…)` only; opacities and widths are not colours.
- ❌ No network outside `platform/` (G3); no longitude operators (G4).
- ❌ The wheel never reads the transcript and chat never reads the chart.
- Guard, CLAUDE.md and epic amendments: **none**. The epic's Target modules
  line for `chart/` already names this feature; docs-sync records the store.

## Acceptance Criteria

Automated tests use fakes only (fake `StreamPost`, stubbed `fetch` returning
`chart/fixtures.ts` `beijingKnownTime.chart`). Run root `npm test` (app-native jest
incl. the guards, then web-divination vitest) and root `npm run typecheck`
(both workspaces). `VENUS` = planet Venus ref;
`VP` = aspect `Venus|opposition|Pluto`.

**Mapping and wheel (vitest)**
- **T1**: `activationFor(fixture, [VENUS])` → lit bodies `{Venus}`, lit keys
  `∅`; echo keys exactly `{Moon|sextile|Venus, Venus|sextile|Jupiter,
  Venus|trine|Saturn, Venus|trine|Neptune, Venus|opposition|Pluto}`, echo
  bodies `{Moon, Jupiter, Saturn, Neptune, Pluto}`.
- **T2**: `[VP]` → lit keys `{Venus|opposition|Pluto}`, lit bodies
  `{Venus, Pluto}`, echo empty. `[VENUS, VP]` → `Venus|opposition|Pluto` and
  Pluto are lit and NOT in echo. `[aspect Saturn|opposition|Ascendant]` → lit
  bodies `{Saturn, Ascendant}`.
- **T3**: `[]`, a `null` chart, and `[aspect Venus|square|Mars]` (absent from
  the fixture) each → `null`. `[aspect Venus|square|Mars, VENUS]` → same
  result as `[VENUS]`. `[VENUS]` against `beijingTimeUnknown` still lights
  Venus.
- **T4**: `ChartWheel` with `activationFor(fixture, [VENUS, VP])`: the `svg`
  has `data-active`; `[data-planet="Venus"]`, `[data-planet="Pluto"]`,
  `[data-aspect-key="Venus|opposition|Pluto"]`,
  `[data-planet-node="Venus"]` have `data-lit`;
  `[data-aspect-key="Venus|trine|Saturn"]` and `[data-planet="Saturn"]` have
  `data-echo`; `[data-planet="Mars"]` and
  `[data-aspect-key="Mars|square|Jupiter"]` have neither. With
  `[aspect Saturn|opposition|Ascendant]` the `[data-aspect-node="Ascendant"]`
  circle has `data-lit`.
- **T5**: `ChartWheel` without the prop (and with `null`) renders no
  `data-active`, `data-lit` or `data-echo` anywhere; the dw-1 ChartWheel
  tests pass unchanged (10 `[data-planet]`).
- **T6**: store: `showRefs([VENUS])` notifies subscribers and `getActivation()`
  is `{refs:[VENUS], chip:null}`; `showRefs([])` and `clearActivation()` give
  `null`; an unsubscribed listener is not called.

**Conversation drives the wheel (vitest, `<App/>` with the fixture birth
saved)**
- **W1**: a reply whose `done` carries `[VENUS, VP]` → after `done`, the
  stage `svg` has `data-active` and `[data-planet="Venus"]` has `data-lit`.
  While that reply is still streaming (before `done`), the `svg` has no
  `data-active`.
- **W2**: sending a second message removes `data-active` before the fake
  stream yields anything. If that turn's `done` has `[]`, the wheel stays
  inactive; if it has `[VP]`, `[data-planet="Mars"]` is not lit and
  `Venus|opposition|Pluto` is lit. Retry after a failed turn and Stop both
  leave the wheel inactive.
- **W3**: with no birth data saved (ring only), a reply with refs and a chip
  press produce no `data-active` and no error; the chip still toggles
  `aria-pressed`.

**Chips (vitest, `ChatPanel` + `ChartStage`, or `<App/>`)**
- **W4** (replaces dw-3 W4): each chip is a `button` inside its `li` with
  `aria-pressed="false"`, reachable by Tab; its accessible name is unchanged
  ("Venus", "Venus opposition Pluto"; zh 金星, 金星冲冥王星).
- **W5**: clicking the `VP` chip → it has `aria-pressed="true"`, the wheel's
  lit set is exactly Venus, Pluto and `Venus|opposition|Pluto`, and no
  `data-echo` exists. Pressing the `VENUS` chip then → `VP`
  `aria-pressed="false"`, `VENUS` `"true"`, the Venus family has `data-echo`.
  Pressing `VENUS` again → no `data-active`, both `"false"`. Enter and Space
  on a focused chip do the same as a click.
- **W6**: after a remount from a KV transcript whose persona entry has
  `chartRefs`, the wheel is inactive; pressing a restored chip lights it.
  A chip on an older reply lights its own ref while a newer reply exists.

**Guards and footprint**
- **G1**: root `npm test` and `npm run typecheck` pass (G1–G9, colour guard,
  one-definition list unchanged); en/zh parity passes with no new key.
- **G2**: `git diff --stat 2f45dfb` (the dw-3 landing) lists no path under `server/`,
  `packages/`, `app-native/`, and not `web-divination/src/app/App.tsx`,
  `theme/tokens.ts` or `i18n/`.
- **G3**: `wheel.css` has a `prefers-reduced-motion: reduce` block setting
  `transition: none` for every activation selector, and no reveal animation
  keeps `both` fill.

**Real app** (Chrome; backend and Vite as in Local runs; fixture birth
entered)
- **A1**: ask "Why do I keep falling for people who are hard to reach?".
  While it streams the wheel is unchanged. Once chips appear, every planet
  or aspect a chip names has `data-lit` on the wheel; after 1 s a lit
  planet's computed `opacity` is `1` and its `filter` contains
  `drop-shadow`; a planet named by no chip and outside every echo set has
  computed opacity `0.18`. A screenshot shows the lit set glowing
  rose-copper over a dimmed wheel.
- **A2**: pressing one aspect chip leaves only that chord and its two ends
  lit (screenshot); the chip shows a `--venus` border. Pressing it again
  returns the wheel to neutral.
- **A3**: sending a follow-up removes `data-active` while "listening" shows,
  and all planets' computed opacity is back to `1` within 1.2 s; the new
  reply's chips then light the new set.
- **A4**: reload: the wheel is neutral, the old chips are there, and
  pressing one lights it.
- **A5**: with DevTools "prefers-reduced-motion: reduce" emulated, a lit
  planet's computed `transition-duration` is `0s` and highlight changes
  apply at once.
- **A6**: in 中, a Chinese reply's chips light the wheel the same way.
