# rn-appearance-dark-light — two appearance modes, Dark and Light

## Goal

Serve QUEUE.md `rn-appearance-dark-light` (user-requested 2026-09-30). The
app-native appearance drops from four grounds to two. `paper` and `plaster`
are removed. `ink` becomes `dark` and `exhibition` becomes `light`, with
their colour values unchanged. Stored legacy preferences migrate on first
read.

## Non-goals

- **No colour change.** Dark uses today's ink values byte for byte, and
  Light uses today's exhibition values byte for byte. The plaster wall
  texture stays on Light.
- **No live restyle.** A ground change still persists and reloads the JS
  world (`theme/reload.ts`). No hook rewrite of the module-scope `tokens.*`
  captures.
- **No system (OS) appearance following.** There is no "Auto" option, and
  `useColorScheme` is not read.
- **web-divination/ is out of scope.** Its token home
  (`web-divination/src/theme/tokens.ts`) is a separate rule-13 home with no
  grounds and no Settings. Its "paper slip" wording in `chat/` is a visual
  metaphor, not a ground. Its two provenance comments say "native's INK
  ground". They are left as they are: they record history, and the web
  workspace is not touched.
- **No onboarding picker.** That is `rn-onboarding-after-signin`, which
  depends on this entry.
- **No redesign of the Settings row, and no new type or paint roles.** The
  appearance row keeps its segment grammar and local `type.micro` label
  (the marker stays; census residue totals are unchanged).
- **The native date picker's hard-coded `themeVariant="dark"`**
  (`birth-input/BirthSheet.tsx:183,212`) is not changed. Light renders
  exactly as exhibition did before.
- **Frozen snapshots in `docs/features/*.md` are not rewritten**, and
  DECISIONS.md stays append-only.

## Decided defaults

1. **The ground values are exactly `'dark' | 'light'`,** in that order,
   everywhere they are listed: the `Ground` union, `GROUND_TOKENS` keys and
   the Settings segments.
2. **The API vocabulary is kept.** The concept is still called a *ground*:
   `Ground`, `GROUND_TOKENS`, `applyGround`, `getGround`, `setGround`,
   `subscribeGround`, `useGround`, `configureGroundPersistence` and
   `GROUND_STORAGE_KEY` keep their names. Only the members and the things
   derived from members are renamed:

   | before | after |
   |---|---|
   | `'ink'` / `'exhibition'` (ground values, stored values) | `'dark'` / `'light'` |
   | `INK` / `EXHIBITION` (token tables in `theme/tokens.ts`) | `DARK` / `LIGHT` |
   | `PAPER`, `PLASTER` tables | deleted |
   | i18n keys `groundInk` / `groundExhibition` | `groundDark` / `groundLight` |
   | i18n keys `groundPaper`, `groundPlaster` | deleted (en and zh) |
   | testIDs `ground-ink` / `ground-exhibition` | `ground-dark` / `ground-light` |
   | testIDs `ground-paper`, `ground-plaster` | gone |

3. **What users see.** en: `Dark` / `Light`. zh: `深色` / `浅色`, which
   replaces the one-character 墨/展 labels. The two-character pair is the
   standard iOS zh wording and cannot be misread as ink or exhibition.
4. **The storage key stays `astrology.ground.v1`.** Only its value space
   changes. A new key would orphan every existing preference and force a
   two-key read.
5. **Migration happens in the ground store on first read,** inside
   `configureGroundPersistence`:
   - `'dark'` or `'light'` is applied as is, with no write.
   - A legacy `'ink'` maps to `'dark'`. A legacy `'paper'`, `'plaster'` or
     `'exhibition'` maps to `'light'`. The mapped value is applied and
     written back to the same key, best-effort (a write failure is
     swallowed, as it is today). The next boot then reads a current value,
     so the migration runs at most once per device.
   - A missing value, an unreadable store, or any other string (for
     example `'sepia'`) boots the default. Nothing is written, and the
     stored garbage is left alone, exactly as an empty store is handled
     today.
6. **A fresh device defaults to `dark`,** which is today's default (`ink`)
   under its new name. `tokens` starts as a copy of `DARK`, and the initial
   active ground is `dark`. The jest world (unconfigured) therefore stays
   on dark, and `brand.test.ts`'s icon-corner check keeps reading
   `#08090e`.
7. **The status bar.** Light status-bar content shows on `dark`, and dark
   content shows on `light`. The comparison in `App.tsx` names `'dark'`.
8. **The plaster wall texture.** `AppShell` mounts it when the ground is
   `'light'`, and on no other ground. It no longer reads a two-value
   disjunction. The texture keeps its material names (`PlasterWall`,
   testID `plaster-texture`, `assets/textures/plaster-tile.png`,
   `scripts/gen-plaster-tile.py`), because they name what the tile
   depicts, not a ground. Renaming the asset and its generator buys
   nothing that users can see.
9. **Light shares the common planet block.** `LIGHT.planet` becomes the
   shared `PLANET_PERSONALITY` instead of a re-typed copy, because the
   copy existed only to keep a *sandbox* from leaking. The values are
   identical, and the freeze test (below) proves it. With that, Light
   stops being a sandbox. It is a shipped ground, frozen by value like
   Dark.
10. **The colour guard stays at full strength.** Rule 13 is unchanged:
    `tokens.ts` stays the sole native home, and removing two tables only
    removes literals. PAINT and TEXT_VARIANTS (rule 15) bind colour by
    role key and name no ground, so both stay untouched.
11. **Tests are amended, and none is weakened.** Each test that names a
    removed ground is re-pointed or retired, with its reason:
    - *Plaster palette applies (museum-white-mode AC-1):* retired with
      plaster. Its "applies through `applyGround`, derived exports
      included" assertion carries over to `light` (re-pointed from the
      exhibition test).
    - *Plaster contrast floors (AC-2):* re-pointed. The same three floors
      (text ≥ 7.0, textDim ≥ 4.5, theme ≥ 3.0 against the ground) now run
      on both remaining grounds, which strengthens the test. Measured:
      light 15.6 / 9.5 / 19.9, dark 16.4 / 9.4 / 9.1.
    - *roles-not-pigments seeds:* `accent = theme` is pinned on `dark` (the
      split stays exempt on `light`, where accent ≠ theme today).
      `artBed = wheelRim` is pinned on both grounds (true on light today,
      so pinning it there is new).
    - *exhibition sandbox (no shared refs, "does not pin exhibition"):*
      retired, because the sandbox ends. It is replaced by a key-list
      assertion `['dark','light']` plus a deep-equal freeze of `light` at
      today's exhibition values. That freeze is the rename's
      value-identity proof.
    - *"ink and paper untouched" freeze:* the ink deep-equal carries over
      as the `dark` deep-equal with identical values. The paper deep-equal
      is retired with paper.
    - *ground-store seeding tests:* re-pointed to the migration table (AC-3
      to AC-5).
    - *settings appearance row, shell texture tests, card-back/draw-ring
      "both grounds" tests, `App.test` / `typography.test` ink restores:*
      re-keyed to dark/light.
12. **A new pin stops removed grounds coming back.** It lives in
    `theme/ground-store.test.ts` and strips comments (the
    `architecture.test.ts` idiom). No quoted literal `'ink'`, `'paper'`,
    `'plaster'` or `'exhibition'` may appear in any `.ts`/`.tsx` under
    `app-native/src`, except in `theme/ground-store.ts` (the migration
    table) and `theme/ground-store.test.ts`.
13. **Rulings and census notes.** `docs/text-variant-census.md` E4 ("if a
    ground ever splits accent from theme (exhibition tried it …)") gets a
    one-clause amendment naming the ground `light (then exhibition)`. The
    ruling itself is unchanged. `docs/DESIGN.md`, `docs/ARCHITECTURE.md`
    and `.claude/skills/verify/SKILL.md` (Settings taps
    "Ink/Paper/Plaster") are updated in docs-sync to name Dark/Light.
    Surface-paint and text-variant rulings name no ground, so nothing
    there changes.
14. **Superseded DECISIONS.md entry.** It is a tier-3 loop decision, so it
    is revised rather than blocking:
    `### 2026-08-19 · museum-white-mode · spec-review — approved on the first round; the palette was contrast-checked by the reviewer, not asserted by the maker`
    Its What ("a third `Ground` `plaster` … beside ink/paper") is retired.
    Its contrast floors survive, re-pointed (default 11). The
    museum-white-mode planning entry (the render-time `getGround()` read in
    AppShell) and the step-9 entry (screens carry no root fill) stay in
    force. The exhibition sandbox (2026-08-28, user-directed) and
    native-paper-mode have no heading in the current DECISIONS.md: the
    history cleanup removed them, and the sandbox is documented only in
    code. The queue entry, a user request, retires both.

## Architecture

### Reuse (verified by targeted reads)

- `app-native/src/theme/tokens.ts`:
  - `:39` the `Ground` union
  - `:156-201` the `INK` table, which becomes `DARK` unchanged
  - `:203-301` the `PAPER` and `PLASTER` tables, deleted
  - `:303-375` the `EXHIBITION` table, which becomes `LIGHT` (default 9)
  - `:377-382` `GROUND_TOKENS`
  - `:391` `tokens = { ...INK }`, which becomes `{ ...DARK }`
  - `:393` `activeGround = 'ink'`, which becomes `'dark'`
  - `:408-413` `applyGround`, which stays as it is and still re-derives
    `surface` and `overlay`

  The header and doc comments that describe four grounds are rewritten to
  describe two.
- `app-native/src/theme/ground-store.ts`:
  - `:20` the key, kept
  - `:35-37` `isGround`, now two values
  - `:43-51` `configureGroundPersistence`, which gains the migration step
  - `:55-65` `setGround`, unchanged
- `app-native/src/theme/index.ts:8-37`: barrel and `useGround`. Only the
  exported type narrows; there are no new exports.
- `app-native/src/platform/boot.ts:104`: `configureGroundPersistence` is
  already called once, after the MMKV KV is installed, so the migration
  inherits that ordering and needs no boot change.
- `app-native/src/settings/SettingsScreen.tsx`:
  - `:43` the `GROUNDS` list, which becomes `['dark','light']`
  - `:47-55` `GROUND_LABEL`, which becomes `{dark:'groundDark', light:'groundLight'}`
  - `:155-162` the segment map, unchanged in shape
  - `:191` the testID template `ground-${ground}`, unchanged, which yields
    the new testIDs

  The stale header and row comments are rewritten.
- `app-native/src/shell/AppShell.tsx:48`: the texture condition, which
  becomes `=== 'light'`. `:94` `PlasterWall` is kept.
- `app-native/src/App.tsx:45`: the status-bar comparison, which becomes
  `'dark'`.
- `app-native/src/i18n/en.ts:141-146` and `app-native/src/i18n/zh.ts:114-117`:
  the key rename and deletion. The `Dict` type makes en and zh parity a
  tsc fact, and `i18n.test.ts` pins leaf-path parity.

### Module contract: `theme/ground-store` (the only behavioural change)

- **Purpose**: which ground is active, how it persists, and who to tell.
- **Public API**: unchanged. `configureGroundPersistence(port)`,
  `setGround(next: Ground)`, `subscribeGround(listener)`, `getGround()`,
  `GROUND_STORAGE_KEY`, `type Ground`.
- **New internal**: one module-private migration table. It is the ONLY
  place in the app that names a legacy value:

  ```
  ink → dark
  paper, plaster, exhibition → light
  ```

  It also holds a resolver from a raw string to one of three results:
  `Ground`, "legacy mapped to a `Ground`", or "unrecognised".
- **Behaviour of `configureGroundPersistence`**: read the key, resolve it,
  apply the result if it differs from the active ground, then write back
  the mapped value, but only when the raw value was legacy. It is
  best-effort throughout: read and write failures are swallowed, and an
  unrecognised value falls through to the default.
- **Imports**: still ONLY `./tokens`. The leaf discipline is unchanged,
  and persistence still arrives by injection from `platform/boot.ts`.
- **Does NOT**: listen for OS appearance, restyle live, or migrate any key
  other than `astrology.ground.v1`.

### Dependency rules and forbidden edges

The dependency rules are unchanged. `theme/` imports no feature folder.
`i18n/` imports only `react`. Core is untouched: the feature has no
`packages/core` or server edit and no wire change. `web-divination/` is
not imported or edited.

### Guard, test and CLAUDE.md amendments

- **The guards are unchanged in strength.** `color-guard.test.ts`,
  `architecture.test.ts`, `text-variant-guard.test.ts`, `paint.test.ts`
  and `surface-paint-rulings.test.tsx` name no ground. They pass with no
  edit, and none is weakened.
- **One pin is added:** the removed-grounds literal pin (default 12) in
  `theme/ground-store.test.ts`.
- **Tests amended as in default 11:**
  - `theme/tokens.test.ts`
  - `theme/ground-store.test.ts`
  - `settings/settings.test.tsx:293-384`
  - `shell/shell.test.tsx:202-231`
  - `ask/card-back.test.tsx:106-119`
  - `ask/draw-ring.test.tsx:116-127`
  - `App.test.tsx:28`
  - `theme/typography.test.tsx:31` (title only; the values are unchanged)

  `ask/ask-wheel.test.tsx:98` iterates `GROUND_TOKENS`' keys, so it covers
  both grounds with no edit.
- **CLAUDE.md, rule 13:** "the web values were copied from native INK"
  becomes "…copied from native DARK (the ground formerly named ink)". No
  other rule names a ground, so no other CLAUDE.md edit is needed.

## Acceptance Criteria

Every test criterion runs under `npm test --workspace app-native`, or as
`npx jest <file>` from `app-native/`. Every device criterion follows
`.claude/skills/verify/SKILL.md` (iPhone 17 simulator, dev client, Metro
serving the feature branch, with bundle freshness proven by grepping the
bundle for `groundLight`).

1. **Two grounds, exactly.** `tokens.test.ts` asserts
   `Object.keys(GROUND_TOKENS)` equals `['dark','light']`. `npm run
   typecheck` passes with `Ground = 'dark' | 'light'`.
2. **Values unchanged.** `tokens.test.ts` deep-equals `GROUND_TOKENS.dark`
   to today's ink literal values (ground `#08090e` … planet block), and
   deep-equals `GROUND_TOKENS.light` to today's exhibition literal values
   (ground `#f9f9f7`, theme `#000000`, accent `#26231f`, textDim `#454239`,
   textFaint `#5e5a53`, panelDeep `#ffffff`, … planet block). Both
   assertions pass.
3. **Legacy values migrate on first read.** In `ground-store.test.ts`, a
   memory port primed with each of `'paper'`, `'plaster'` and
   `'exhibition'` makes `configureGroundPersistence` leave `getGround()`
   at `'light'`. `tokens.ground` is `#f9f9f7`, `surface.card` is
   `withAlpha(LIGHT.panel, 0.82)`, and the port now holds `'light'` under
   `astrology.ground.v1`. A port primed with `'ink'` gives `'dark'`, with
   `'dark'` written back.
4. **Current values do not rewrite.** A port primed with `'light'` (or
   `'dark'`) applies that ground and receives no write.
5. **Unknown and empty boot dark.** An empty port, a port primed with
   `'sepia'`, and a port whose `read` throws each give
   `getGround() === 'dark'` and `tokens.ground === '#08090e'`, with no
   write. The `'sepia'` cell is left unchanged.
6. **Settings offers exactly Dark and Light.** In `settings.test.tsx`,
   `queryAllByTestId(/^ground-/)` yields `['ground-dark','ground-light']`.
   Under en the labels are `Dark` and `Light`. After `setLanguage('zh')`
   they are `深色` and `浅色`. On the unconfigured jest world,
   `ground-dark` is `selected: true`.
7. **Switching persists and reloads once.** Pressing `ground-light` from
   dark writes `'light'` to the port, calls the reload seam exactly once,
   and marks `ground-light` selected. Pressing the already-active segment
   writes nothing and does not reload.
8. **The texture follows Light only.** In `shell.test.tsx`,
   `applyGround('light')` mounts `plaster-texture` with `pointerEvents:
   'none'`, and `applyGround('dark')` mounts no `plaster-texture` node.
9. **The status bar follows the ground.** A test renders `App` (or reads
   the StatusBar element): its `style` is `'light'` on dark and `'dark'`
   on light.
10. **Contrast floors hold on both grounds.** For each of `dark` and
    `light`: text/ground ≥ 7.0, textDim/ground ≥ 4.5 and theme/ground ≥
    3.0, computed in `tokens.test.ts`.
11. **Removed grounds cannot return.** The new pin in
    `ground-store.test.ts` passes. After comments are stripped, no quoted
    `'ink'|'paper'|'plaster'|'exhibition'` literal (either quote style)
    appears under `app-native/src` outside `theme/ground-store.ts` and
    `theme/ground-store.test.ts`. The i18n dictionaries carry no
    `groundInk`, `groundPaper`, `groundPlaster` or `groundExhibition` key.
12. **The guards are green and unweakened.** `color-guard.test.ts`,
    `architecture.test.ts`, `text-variant-guard.test.ts` (`RAW_TAG_TOTAL` (53),
    `MARKER_TOTAL` (61) and `RESIDUE_FLOORS` unedited,
    text-variant-guard.test.ts:220-222; the "50/57" in CLAUDE.md rule 15
    and the test title's "48/55" are pre-existing drift, not this
    feature's), `paint.test.ts`,
    `surface-paint-rulings.test.tsx` and `i18n.test.ts` pass with no edit
    to their assertions. The full `npm test` (app-native and
    web-divination) and `npm run typecheck` pass.
13. **Device: Settings shows Dark and Light.** On the simulator, the
    Settings appearance row shows exactly two segments reading `Dark` and
    `Light` (`深色` and `浅色` after switching the language to 中文).
    Tapping Light reloads the app onto a near-white ground: a
    pixel-sampled empty margin averages within 3 of `#f9f9f7` (249 249
    247), with grain visible (more than one shade across the patch), black
    chrome and dark status-bar glyphs. Tapping Dark reloads onto
    `#08090e` with gold chrome and light status-bar glyphs. Both match a
    before-screenshot of ink and of exhibition taken on the pre-feature
    `dev` bundle at the same spot, within a mean channel difference of 3.
14. **Device: a paper or plaster device opens in Light.** On the
    pre-feature `dev` bundle, select Paper in Settings. Then serve the
    feature branch and cold-relaunch (terminate, then launch). The app
    opens on the Light ground (margin sample as in 13), and Settings shows
    `Light` selected. Repeat with Plaster and with Exhibition, expecting
    Light each time. Repeat with Ink, expecting Dark.
