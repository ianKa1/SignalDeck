# 06 — implementing (rn-appearance-dark-light)

Worker: parallel-wave worker, worktree
`/Users/kaimao/Projects/astrology-wt/rn-appearance-dark-light`
(branch `feature/rn-appearance-dark-light`, base `04ae600`).

## Step 0 — Baseline

Command (from `app-native/`):

    npx jest src/theme src/settings src/shell src/ask/card-back.test.tsx src/ask/draw-ring.test.tsx src/App.test.tsx

Result:

    Test Suites: 13 passed, 13 total
    Tests:       160 passed, 160 total

Legacy-literal inventory (`grep -rnE "['\"](ink|paper|plaster|exhibition)['\"]" src --include='*.ts' --include='*.tsx'`):

    src/App.tsx:45                 StatusBar style={getGround() === 'ink' ? ...}
    src/App.test.tsx:28            applyGround('ink')
    src/settings/settings.test.tsx:344,352,373,381
    src/settings/SettingsScreen.tsx:9 (comment), :43 GROUNDS
    src/ask/draw-ring.test.tsx:117
    src/ask/card-back.test.tsx:107
    src/shell/shell.test.tsx:207,212,226
    src/shell/AppShell.tsx:48
    src/theme/ground-store.ts:36   (isGround)
    src/theme/tokens.test.ts:25,64,65,92,102,103,124
    src/theme/tokens.ts:39,205 (comment),393
    src/theme/ground-store.test.ts:29..87

i.e. the ten non-exempt files AC-11 must clear: App.tsx, App.test.tsx,
settings/SettingsScreen.tsx, settings/settings.test.tsx, ask/draw-ring.test.tsx,
ask/card-back.test.tsx, shell/shell.test.tsx, shell/AppShell.tsx,
theme/tokens.ts, theme/tokens.test.ts.

Today's values, captured BEFORE touching tokens.ts (the step-1 freezes are
written from these):

INK (→ DARK):

    ground '#08090e'  wheelCore '#16233a'  wheelMid '#101a2a'  wheelRim '#0c0e18'
    artBed '#0c0e18'  aura 'rgba(150, 112, 52, 0.13)'
    theme '#d3a94f'  themeSoft '#b8934a'  themeGhost 'rgba(211, 169, 79, 0.12)'
    line 'rgba(211, 169, 79, 0.28)'  lineSoft 'rgba(211, 169, 79, 0.16)'
    accent '#d3a94f'  accentGhost 'rgba(211, 169, 79, 0.12)'
    text '#f0e9d8'  textDim '#b9b2a0'  textFaint '#8a8577'
    danger '#e08b8b'  dangerGhost 'rgba(224, 139, 139, 0.12)'
    panel '#0d1122'  panelDeep '#0a0d1a'
    aspect { conjunction '#dcb058', sextile '#4fc3b4', trine '#7f95dd', square '#e39a4a', opposition '#c73a4a' }
    element { fire 'rgba(224, 139, 96, 0.1)', earth 'rgba(157, 187, 121, 0.09)', air 'rgba(196, 211, 235, 0.08)', water 'rgba(118, 168, 214, 0.1)' }
    planet PLANET_PERSONALITY

EXHIBITION (→ LIGHT):

    ground '#f9f9f7'  wheelCore '#e4e2db'  wheelMid '#edebe5'  wheelRim '#f3f2ee'
    artBed '#f3f2ee'  aura 'rgba(150, 138, 114, 0.05)'
    theme '#000000'  themeSoft '#514c44'  themeGhost 'rgba(38, 35, 31, 0.09)'
    line 'rgba(38, 35, 31, 0.30)'  lineSoft 'rgba(38, 35, 31, 0.16)'
    accent '#26231f'  accentGhost 'rgba(38, 35, 31, 0.09)'
    text '#211f1c'  textDim '#454239'  textFaint '#5e5a53'
    danger '#9c4a44'  dangerGhost 'rgba(156, 74, 68, 0.10)'
    panel '#fdfdfc'  panelDeep '#ffffff'
    aspect { conjunction '#a2802b', sextile '#177d70', trine '#2e4187', square '#b56e26', opposition '#8a323e' }
    element { fire 'rgba(160, 78, 44, 0.09)', earth 'rgba(88, 116, 56, 0.09)', air 'rgba(64, 92, 138, 0.07)', water 'rgba(38, 88, 136, 0.09)' }
    planet (re-typed) Sun '#e0a93e' Moon '#cfd5e1' Mercury '#e3d27a' Venus '#dd8fa5'
      Mars '#d64f3f' Jupiter '#7f95dd' Saturn '#9a8f7a' Uranus '#5fc9d8'
      Neptune '#9a8fd0' Pluto '#8e3a4a'   (identical to PLANET_PERSONALITY)

## Step 1 — Token home: two grounds

`app-native/src/theme/tokens.ts`: `Ground = 'dark' | 'light'`; `INK`→`DARK`,
`EXHIBITION`→`LIGHT` (values untouched), `LIGHT.planet` → shared
`PLANET_PERSONALITY`; `PAPER`/`PLASTER` deleted; `GROUND_TOKENS` = `{ dark, light }`;
`tokens = { ...DARK }`, `activeGround = 'dark'`; four-ground header/doc comments
rewritten. `tokens.test.ts` rewritten per default 11 (key list, dark + light
deep-equal freezes from the step-0 values, contrast floors via
`describe.each(['dark','light'])`, accent=theme on dark, artBed=wheelRim on both;
plaster/paper/sandbox cases retired).

    npx jest src/theme/tokens.test.ts src/brand.test.ts
    PASS src/theme/tokens.test.ts
    PASS src/brand.test.ts
    Tests:       22 passed, 22 total

## Step 2 — Ground store migration

`ground-store.ts`: `isGround` narrows to dark/light; module-private
`LEGACY_GROUNDS` (ink→dark; paper, plaster, exhibition→light) + `resolveStored`;
`configureGroundPersistence` reads (read failure swallowed), applies, then writes
back ONLY for a legacy value (write failure swallowed, apply already done).
Imports still only `./tokens`. `ground-store.test.ts` rewritten: write-counting
memory port; AC-3 (each of paper/plaster/exhibition → light with tokens.ground
`#f9f9f7`, surface.card = withAlpha(GROUND_TOKENS.light.panel, 0.82), writes
`[[key,'light']]`; ink → dark with `[[key,'dark']]`; at-most-once; failed
write-back still applies), AC-4 (light/dark → no write), AC-5 (empty / 'sepia'
left in place / throwing read → dark, no write), setGround, and the AC-11 pin
(comments stripped, strings kept, both quote styles, exempt exactly
theme/ground-store.ts + theme/ground-store.test.ts, walk-size guard > 50 files).

First run (before steps 4–5 cleared the sites) — the pin failing as designed:

    ✕ no quoted ink/paper/plaster/exhibition literal outside the migration table
    + "App.test.tsx: 'ink'", "App.tsx: 'ink'", "ask/card-back.test.tsx: 'ink'",
    + "ask/card-back.test.tsx: 'exhibition'", "ask/draw-ring.test.tsx: 'ink'", ...
    + "shell/shell.test.tsx: 'paper'"   (19 offenders, all in the step-0 inventory)
    Tests:       1 failed, 12 passed, 13 total

Mutation check after step 5 (appended `export const probe = 'paper'` to
shell/AppShell.tsx, then reverted — `grep -c probe` → 0):

    +   "shell/AppShell.tsx: 'paper'",

## Step 3 — i18n

en: `groundDark: 'Dark'`, `groundLight: 'Light'`; zh: `'深色'`, `'浅色'`;
groundInk/Paper/Plaster/Exhibition deleted.

    npx jest src/i18n
    Test Suites: 2 passed, 2 total
    Tests:       17 passed, 17 total

## Step 4 — Consumers

(`frontend-design` skill loaded first; no visual change — spec forbids a row
redesign.) SettingsScreen: `GROUNDS = ['dark','light']`,
`GROUND_LABEL = { dark:'groundDark', light:'groundLight' }`, stale comments
rewritten, text-variant markers untouched. AppShell: `getGround() === 'light'`.
App.tsx: `getGround() === 'dark' ? 'light' : 'dark'`.

    grep -rn "groundInk\|groundPaper\|groundPlaster\|groundExhibition" src   → (empty, exit 1)

## Step 5 — Re-keyed tests + AC-9

settings.test.tsx appearance row → AC-6 (testIDs `['ground-dark','ground-light']`,
en Dark/Light, zh 深色/浅色, dark selected) and AC-7 (write-counting port: press
dark = no write/no reload; press light = writes `[[key,'light']]`, one reload,
light selected); shell.test.tsx → AC-8 (texture on light, pointerEvents none;
none on dark); card-back / draw-ring loops over `['dark','light']`; App.test
restores dark + new AC-9 describe (`UNSAFE_getByType(StatusBar).props.style`
'light' on dark, 'dark' on light); typography.test title only.

    npx jest src/settings src/shell src/ask src/App.test.tsx src/theme
    Test Suites: 25 passed, 25 total
    Tests:       348 passed, 348 total
    npm run typecheck (repo root)  → exit 0 (app-native + web-divination tsc --noEmit)

AC-9 mutation check (flipped App.tsx to `=== 'light'`, reverted): both status-bar
cases failed (`Tests: 3 failed, 13 passed` together with the pin probe above).

Commit: `12d403a` (feat) — steps 1–5 as one milestone.

## Step 6 — CLAUDE.md rule 13

"copied from native INK" → "copied from native DARK (the ground formerly named ink)".

    grep -n "native INK" CLAUDE.md   → (empty)

## Step 7 — Guards and whole suites

    npx jest src/color-guard.test.ts src/architecture.test.ts src/text-variant-guard.test.ts \
      src/theme/paint.test.ts src/surface-paint-rulings.test.tsx src/i18n
    Test Suites: 7 passed, 7 total
    Tests:       93 passed, 93 total
    git diff --stat 12d403a~1 -- <those six files>   → (empty: none edited)
    text-variant-guard.test.ts:221-222  MARKER_TOTAL = 61, RAW_TAG_TOTAL = 53 (unchanged)

Repo root `npm test`, run 1:

    Test Suites: 91 passed, 91 total          (app-native jest)
    Tests:       1090 passed, 1090 total
     FAIL  src/chart/spotlight/SpotlightLayer.test.tsx > SpotlightLayer > writes a frame counter onto the canvas without re-rendering
     Test Files  1 failed | 46 passed (47)    (web-divination vitest)

The failure is in web-divination, which this feature does not touch
(`git diff --stat 04ae600 -- web-divination packages` → empty). Alone:

    npx vitest run src/chart/spotlight/SpotlightLayer.test.tsx
    Test Files  1 passed (1)   Tests  5 passed (5)

i.e. a frame-timing test flaking under machine load (parallel wave). Run 2 of the
full root suite:

    npm test → exit=0
    Test Suites: 91 passed, 91 total   Tests: 1090 passed, 1090 total
    Test Files  47 passed (47)         Tests  445 passed (445)
    npm run typecheck → exit=0

Commit: `7122668` (docs, CLAUDE.md).

Status transition: implementing → validating.
