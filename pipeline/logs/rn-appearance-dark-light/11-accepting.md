# rn-appearance-dark-light — 11 accepting (fresh-context acceptance)

Checker: fresh context, has not seen the implementation. Scope: the
Acceptance Criteria section of `pipeline/specs/rn-appearance-dark-light.md`
only. No code edits. Two temporary probes (below) were restored, and
`git status --short` in the worktree printed nothing afterwards.

Code under test: worktree `/Users/kaimao/Projects/astrology-wt/rn-appearance-dark-light`,
branch `feature/rn-appearance-dark-light` (HEAD d00b3b5, merge of dev; feature
commits 12d403a, 7122668, fd4a88c, 70b0f10).

## Commands and verbatim results

Worktree root:

```
npm test
  (app-native jest)   Test Suites: 92 passed, 92 total
                      Tests:       1101 passed, 1101 total
  (web-divination)    Test Files  47 passed (47)
                      Tests  445 passed (445)
npm run typecheck
  > app-native@0.1.0 typecheck > tsc --noEmit          (no errors)
  > web-divination@0.1.0 typecheck > tsc --noEmit      (no errors)
```

From `app-native/`, the named suites:

```
npx jest src/color-guard.test.ts src/architecture.test.ts src/text-variant-guard.test.ts \
  src/theme/paint.test.ts src/surface-paint-rulings.test.tsx src/i18n/i18n.test.ts \
  src/theme/tokens.test.ts src/theme/ground-store.test.ts src/settings/settings.test.tsx \
  src/shell/shell.test.tsx src/App.test.tsx
PASS (all 11 suites)   Tests: 139 passed, 139 total
```

`git diff --stat dev...HEAD` on the six guard files (color-guard,
architecture, text-variant-guard, paint, surface-paint-rulings, i18n.test)
printed nothing, so they are unchanged. text-variant-guard.test.ts:220-222
still reads `RESIDUE_FLOORS = { local: 45, exempt: 13, inherit: 3 }`,
`MARKER_TOTAL = 61`, `RAW_TAG_TOTAL = 53`.

Probe A (AC-2, independent of the test's own literals): I wrote dev's
`tokens.ts` (`git show dev:…`) into a temp module and added a temp test
asserting `GROUND_TOKENS.dark` toEqual dev `GROUND_TOKENS.ink` and
`GROUND_TOKENS.light` toEqual dev `GROUND_TOKENS.exhibition`. Result:
`✓ dark == dev ink`, `✓ light == dev exhibition`. Both temp files were
removed and the tree was clean afterwards.

Probe B (AC-11, the pin has teeth): I appended `export const __probe = "plaster"`
to `src/App.tsx` and ran the pin. Result: `✕ no quoted ink/paper/plaster/exhibition
literal … + "App.tsx: \"plaster\""`. I restored the file with `git checkout
src/App.tsx` and the tree was clean.

Independent AC-11 scan (TypeScript AST, string and no-substitution template
literals, every .ts/.tsx file under app-native/src except the two exempt
files): `AST offenders: []`. `grep -rnE
"groundInk|groundPaper|groundPlaster|groundExhibition" src/i18n` found no
matches.

## Device run (iPhone 17, udid 7DB5C491-…, com.astrace.app.dev)

- My backend was on :8004 (DB and LLM env set explicitly, all keys blank) and
  my Metro on :8094, both started from the worktree. The user's Metro :8081,
  backend :8000 and Vite :5173 were not touched.
- Bundle freshness, whole-word counts in the fetched non-bytecode bundles
  (`/app-native/index.ts.bundle?platform=ios&dev=true&…`):
  - `:8081` (dev, pre-feature): 11965229 bytes, groundLight=0, groundPlaster=3
  - `:8094` (feature): 12004964 bytes, groundLight=3, groundPlaster=0
  - The metro.log on :8094 recorded `iOS Bundled … app-native/index.ts (1388 modules)`.
- The user's state before I started, read from the :8081 Settings screen and
  the app's MMKV cells (read-only): appearance Ink (cell `ink`), language EN
  (cell `en`).
- Sample patch: screenshot px box (150,1950)-(450,2150), the empty margin
  below the Appearance row on Settings. Statistics are the mean RGB and the
  number of distinct colours. Scratch dir: `…/scratchpad/appearance-accept/`.

| shot | bundle | state | patch mean | distinct |
|---|---|---|---|---|
| 01 | pre :8081 | Ink (reference) | (8.0, 9.0, 14.0) | 1 |
| 03 | pre :8081 | Exhibition (reference) | (246.9, 246.9, 244.9) | 25 |
| 11 | feat :8094 | cold from stored `exhibition` | (246.9, 246.9, 244.9) | 25 |
| 13 | feat | after tapping Dark | (8.0, 9.0, 14.0) | 1 |
| 15 | feat | after tapping Light | (246.9, 246.9, 244.9) | 25 |
| 21 | pre | Paper stored | (191.5, 189.9, 178.6) (the paper ground) | — |
| 23 | feat | cold from stored `paper` | (246.9, 246.9, 244.9) | 25 |
| 31 | pre | Plaster stored | (239.9, 237.0, 231.1) (the plaster ground) | 27 |
| 33 | feat | cold from stored `plaster` | (246.9, 246.9, 244.9) | 25 |
| 40→41 | pre | Paper, then Ink (so `ink` was really stored) | (231,225,209) → (8.0, 9.0, 14.0) | — |
| 43 | feat | cold from stored `ink` | (8.0, 9.0, 14.0) | 1 |

Diffs (`px.py diff`, patch mean absolute channel difference):
- 15 (feature Light) vs 03 (pre Exhibition): 0.00
- 13 (feature Dark) vs 01 (pre Ink): 0.00
- 11 vs 03: 0.00

The Light patch mean is 2.1 below (249,249,247) on every channel, which is
within 3. On the dark ground `#08090e` is (8,9,14) exactly.

## Per-criterion verdict

1. **Two grounds, exactly: PASS.** tokens.test.ts asserts `Object.keys(GROUND_TOKENS)`
   toEqual `['dark','light']` and it passes. `Ground = 'dark' | 'light'`
   (tokens.ts:39). Typecheck is green.
2. **Values unchanged: PASS.** tokens.test.ts deep-equals both blocks to
   literal copies and passes. Probe A also shows dark === dev ink and
   light === dev exhibition, compared against dev's own objects.
3. **Legacy values migrate on first read: PASS.** In ground-store.test.ts,
   `it.each(['paper','plaster','exhibition'])` gives `'light'`, tokens.ground
   `#f9f9f7`, surface.card = `withAlpha(GROUND_TOKENS.light.panel, 0.82)`
   (LIGHT is that same object), and the port receives exactly one write of
   `'light'` under `astrology.ground.v1`. `'ink'` gives `'dark'` and writes
   back `'dark'`. All pass.
4. **Current values do not rewrite: PASS.** Ports holding `'light'` or `'dark'`
   apply that ground, and `writes` equals `[]` in both cases.
5. **Unknown and empty boot dark: PASS.** The empty port, the `'sepia'` port
   and the throwing `read` all give `'dark'` and `#08090e` with no write. The
   sepia cell is still `'sepia'`.
6. **Settings offers exactly Dark and Light: PASS.** settings.test.tsx checks
   the testIDs `['ground-dark','ground-light']`, the labels Dark/Light, and
   深色/浅色 after `setLanguage('zh')`. `ground-dark` has `selected: true` on
   the unconfigured world.
7. **Switching persists and reloads once: PASS.** Pressing `ground-dark` while
   it is active gives writes `[]` and no reload. Pressing `ground-light` gives
   writes `[[key,'light']]`, `reloads` called once, and ground-light selected.
8. **The texture follows Light only: PASS.** shell.test.tsx: `applyGround('light')`
   mounts `plaster-texture` with `pointerEvents: 'none'`, and dark mounts no
   such node.
9. **The status bar follows the ground: PASS.** App.test.tsx renders `App` and
   reads the StatusBar props: `style` is `'light'` on dark and `'dark'` on light.
10. **Contrast floors hold on both grounds: PASS.** tokens.test.ts computes WCAG
    ratios with `describe.each(['dark','light'])`: text ≥ 7.0, textDim ≥ 4.5,
    theme ≥ 3.0. All pass.
11. **Removed grounds cannot return: PASS.** The pin passes, and Probe B shows it
    fails on an injected literal. My independent AST scan found no offenders,
    and no legacy i18n keys remain.
12. **The guards are green and unweakened: PASS.** The six guard suites are
    unedited (empty diff), the text-variant constants are as specified and all
    six pass. Full `npm test` (app-native 1101/1101, web-divination 445/445)
    and `npm run typecheck` pass.
13. **Device, Settings shows Dark and Light: PASS.** The feature Settings row
    shows exactly two segments, `Dark` and `Light` (shot 11/15), and `深色` and
    `浅色` after switching to 中文 (shot 16; switched back to EN afterwards,
    shot 17).
    - Tapping Light reloaded the app (it landed on the Chart tab, shot 14).
      The margin measured (246.9, 246.9, 244.9), within 3 of (249,249,247),
      with 25 distinct shades of grain. Chrome is black and the status-bar
      glyphs are dark (time-region min luminance 0).
    - Tapping Dark reloaded the app onto (8,9,14) = `#08090e` (shot 12/13),
      with gold chrome (Dark segment, Sign in, the Anchor pill and the
      Settings rail in gold) and white status-bar glyphs.
    - Against the pre-feature references at the same patch: Light vs
      Exhibition 0.00 and Dark vs Ink 0.00, both within 3.
14. **Device, a paper or plaster device opens in Light: PASS.** On the
    pre-feature bundle I stored each value, then terminated the app and
    launched it cold on :8094:
    - Exhibition: Light (shot 10/11; the MMKV cell then held `light`)
    - Paper: Light (shot 22/23)
    - Plaster: Light (shot 32/33)
    - Ink: Dark (shot 42/43)

    Settings showed the matching segment selected in each case (Light for the
    first three, Dark for Ink). Each margin sample matched as in 13.

Note (not an AC failure): with image keys blanked, my backend drew
"Artwork is resting" placeholders on the Chart card band. That is expected
and does not affect any criterion.

## Cleanup

- Restored on the pre-feature bundle (:8081) with Paper, then Ink, so the
  stored value is really `ink`.
- Language is EN.
- I terminated the app and reopened it on :8081. Settings shows the
  four-segment pre-feature row with Ink selected and EN (shot 52).
- I stopped only my own processes: Metro (pids 96277/96250/96248) and the
  backend (96371/96247/96245). `pgrep` then found none left, and :8081 still
  reports `packager-status:running`.
- The worktree is clean. No reinstall or erase was done.

All 14 criteria pass.

Transition: accepting → done
