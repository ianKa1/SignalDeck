# Plan — rn-appearance-dark-light

Spec: `pipeline/specs/rn-appearance-dark-light.md` (Decided defaults + Architecture are the source of truth; this plan only orders them). Reviews: `pipeline/logs/rn-appearance-dark-light/02-spec-review.md`, `04-spec-review.md` (non-blocking notes folded into steps 2 and 10). Commands run from `app-native/` unless stated. Frontend-facing: load `/frontend-design` before step 4. Steps 1–5 change the `Ground` union and its consumers together, so `npm run typecheck` is only expected green from step 5; commit steps 1–5 as one milestone (or per step with jest-only done-whens), via `/git-commit`.

## Steps

- [x] **0. Baseline.** Confirm the tree is green and record the legacy-literal inventory (the files AC-11 must clear; the reviewer listed ten). Before touching `tokens.ts`, copy today's `INK` and `EXHIBITION` literal values into the implementing log — step 1's freezes are written from them, not from the renamed tables. Done-when: `npx jest src/theme src/settings src/shell src/ask/card-back.test.tsx src/ask/draw-ring.test.tsx src/App.test.tsx` green; inventory + values in the log.

- [x] **1. Token home: two grounds.** `src/theme/tokens.ts`: `Ground` → `'dark' | 'light'`; `INK`→`DARK`, `EXHIBITION`→`LIGHT` (values untouched), `LIGHT.planet` → shared `PLANET_PERSONALITY` (default 9); delete `PAPER`/`PLASTER`; `GROUND_TOKENS` keys in order dark, light; initial `tokens`/`activeGround` on dark; rewrite four-ground header/doc comments. `src/theme/tokens.test.ts` per default 11: key list, dark + light deep-equal freezes, contrast floors on both, seed pins (accent=theme on dark; artBed=wheelRim on both); retire plaster/paper/sandbox cases. Done-when: `npx jest src/theme/tokens.test.ts src/brand.test.ts` green.

- [x] **2. Ground store migration.** `src/theme/ground-store.ts`: `isGround` narrows; module-private legacy table + resolver; `configureGroundPersistence` applies, writes back only for legacy, swallows read/write failures (Architecture → Module contract). Imports stay `./tokens` only. `src/theme/ground-store.test.ts`: re-point seeding to AC-3/4/5 cells (read panel via `GROUND_TOKENS.light.panel` — `LIGHT` is private), `afterEach` restores dark, plus the AC-11 literal pin over `src/**/*.{ts,tsx}` minus the two exempt files. Done-when: `npx jest src/theme/ground-store.test.ts` green, and the pin fails if a quoted `'paper'` is temporarily added to a non-exempt file (reverted).

- [x] **3. i18n.** `src/i18n/en.ts`, `src/i18n/zh.ts`: `groundInk`/`groundExhibition` → `groundDark`/`groundLight` with `Dark`/`Light` and `深色`/`浅色`; delete `groundPaper`/`groundPlaster` (default 3). Done-when: `npx jest src/i18n` green (parity test unedited).

- [x] **4. Consumers.** `src/settings/SettingsScreen.tsx` (`GROUNDS`, `GROUND_LABEL`, stale comments; the `text-variant: local` markers stay), `src/shell/AppShell.tsx:48` (texture on `'light'` only), `src/App.tsx:45` (status bar names `'dark'`). No other source edit. Done-when: `grep -rn "groundInk\|groundPaper\|groundPlaster\|groundExhibition" src` empty.

- [x] **5. Re-key the remaining tests; add the status-bar test.** `src/settings/settings.test.tsx:293-384` (AC-6/AC-7 as worded, incl. zh labels and the no-op press), `src/shell/shell.test.tsx:202-231` (AC-8), `src/ask/card-back.test.tsx:106-119`, `src/ask/draw-ring.test.tsx:116-127`, `src/App.test.tsx:28` restore → dark, plus a new AC-9 case (StatusBar `style` `'light'` on dark, `'dark'` on light), `src/theme/typography.test.tsx:31` title only. Done-when: `npx jest src/settings src/shell src/ask src/App.test.tsx src/theme` green and `npm run typecheck` green.

- [x] **6. CLAUDE.md rule 13 wording.** Replace "copied from native INK" with "copied from native DARK (the ground formerly named ink)"; no other CLAUDE.md edit (the rule-15 "50/57" drift is out of scope). Done-when: `grep -n "native INK" CLAUDE.md` empty from the repo root.

- [x] **7. Guards and whole suites.** Done-when: `npx jest src/color-guard.test.ts src/architecture.test.ts src/text-variant-guard.test.ts src/theme/paint.test.ts src/surface-paint-rulings.test.tsx src/i18n` green with `git diff --stat` showing none of those files edited (`RAW_TAG_TOTAL` 53, `MARKER_TOTAL` 61, `RESIDUE_FLOORS` untouched); then from the REPO ROOT `npm test` and `npm run typecheck` green. Commit via `/git-commit`, set `validating`.

- [ ] **8. Validate AC-13 on the simulator** (validating; the implementer reports `validating — needs device` to the coordinator, who drives it per `.claude/skills/verify/SKILL.md`). Only one Metro may own :8081, so the two bundles are served in turn. (a) BEFORE: serve the pre-feature `dev` commit (the primary checkout, or a throwaway `git worktree add --detach … dev` with `npm install` at its root); prove freshness (bundle contains `groundPlaster`, not `groundLight`); screenshot Ink and Exhibition at one fixed empty-margin spot. (b) AFTER: serve the feature branch; prove freshness (`groundLight` present); screenshot the appearance row in en and 中文; tap Light, then Dark; sample the margin with PIL (mean within 3 of 249,249,247 plus >1 shade across the patch on Light; `#08090e` on Dark), check chrome colour and status-bar glyphs, and diff each against its before shot (mean channel diff ≤ 3). Record the two-segment tap coordinates for step 10. Done-when: numbers + screenshots in the validating log.

- [ ] **9. Validate AC-14 (legacy devices)** — same coordinator hand-off. Do NOT reinstall or erase the dev client between bundles (MMKV must survive). For each legacy value in order Paper, Plaster, Exhibition, Ink: serve the pre-feature bundle (freshness as 8a) → cold-launch → Settings → tap that segment (the app reloads; confirm it is selected) → `simctl terminate` → stop Metro → serve the feature branch (freshness as 8b) → `terminate` + `launch` → sample the margin (Light for the first three, `#08090e` for Ink) → open Settings and screenshot the selected segment (`Light` ×3, `Dark` ×1). Optional: a second cold launch on the feature bundle shows the same ground (write-back held). Done-when: four before/after pairs with samples in the validating log.

- [x] **10. Docs-sync.** `docs/ARCHITECTURE.md` via `/update-architecture-doc` (Settings row 墨/纸/垩 at ~:84-85 and ~:357, theme tree "four grounds" at ~:255-257, the store's migration); write `docs/features/rn-appearance-dark-light.md` from what was built; `docs/DESIGN.md` §4 names native Dark/Light (web-era paper history stays as history); `docs/text-variant-census.md` E4 (~:342) one-clause amendment `light (then exhibition)`; `.claude/skills/verify/SKILL.md:65` replace Ink/Paper/Plaster taps with the two coordinates RE-DERIVED in step 8, not renamed; append a DECISIONS.md entry recording that museum-white-mode's third-ground What is superseded and its floors re-pointed (default 14). Done-when: `git diff --stat` lists all six files and `grep -n "Plaster(" .claude/skills/verify/SKILL.md` is empty.

## Acceptance map

| Criterion | Made to pass by | Graded in |
|---|---|---|
| AC-1 two grounds | 1, 5 | `tokens.test.ts`; typecheck (step 7) |
| AC-2 values unchanged | 0 (values captured), 1 | `tokens.test.ts` |
| AC-3 legacy migrates | 2 | `ground-store.test.ts` |
| AC-4 current values don't rewrite | 2 | `ground-store.test.ts` |
| AC-5 unknown/empty/throw boot dark | 2 | `ground-store.test.ts` |
| AC-6 Settings offers Dark/Light | 3, 4, 5 | `settings.test.tsx` |
| AC-7 switch persists, reloads once | 4, 5 | `settings.test.tsx` |
| AC-8 texture on Light only | 4, 5 | `shell.test.tsx` |
| AC-9 status bar follows ground | 4, 5 | `App.test.tsx` new case |
| AC-10 contrast floors both grounds | 1 | `tokens.test.ts` |
| AC-11 removed grounds can't return | 1–5 (clear sites), 2 (pin), 3 (keys) | `ground-store.test.ts` pin; `i18n.test.ts` |
| AC-12 guards green, unweakened | 6, 7 | step 7 commands + diff |
| AC-13 device: Dark/Light render as before | 8 | validating log |
| AC-14 device: legacy device opens right | 9 | validating log |

## Risks for the implementer

- The pin must strip COMMENTS only. `architecture.test.ts:58` `stripCommentsAndStrings` also strips string literals, which would make the pin vacuous — borrow the comment half, not the helper. Match both quote styles; exempt exactly `theme/ground-store.ts` and `theme/ground-store.test.ts`.
- Token objects are module-scoped mutable state shared per jest worker: every test that applies light or configures a store must restore dark (`applyGround('dark')`) in `afterEach`, or unrelated style assertions fail far away.
- AC-3 needs `tokens.ground`, `surface.card` and the write-back all asserted in one cell per legacy value; AC-4/AC-5 need a write-spy port (count writes), not just a final-value check, or "no write" passes vacuously.
- The resolver must apply before writing back; a write failure must not skip the apply (default 5).
- AC-9: `expo-status-bar` may render nothing in jest-expo; read the element's `style` prop via the test renderer's type query rather than the host tree.
- AC-14 is only meaningful if the pre-feature bundle is really pre-feature: a stale bundle that is already the feature code "passes" by writing `'light'` directly. Prove freshness on every swap.
