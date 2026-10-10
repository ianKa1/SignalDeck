# rn-appearance-dark-light — 01 designing (2026-09-30)

## Skills invoked (Skill tool, pipeline-mode overrides)
1. `frontend-design`: loaded first because the feature is frontend-facing.
   The visual bar it set: no new visuals. The two surviving grounds keep
   their values, and the Settings row keeps its segment grammar.
2. `feature-spec`: wrote Goal, Non-goals, Decided defaults (14) and
   Acceptance Criteria (14). It asked no questions.
3. `architecture-designer`: wrote the Architecture section of the same
   spec (reuse with file:line, the ground-store contract, dependency rules,
   and the guard, test and CLAUDE.md amendments). It wrote no migration
   steps.

## Surveyed
- CLAUDE.md; PIPELINE.md (skills per stage, pipeline-mode overrides, spec
  requirements, decision precedence); the QUEUE entry.
- `app-native/src/theme/tokens.ts`: the Ground union, the four tables, the
  `tokens` copy and `applyGround`.
- `app-native/src/theme/ground-store.ts` (+ test).
- `app-native/src/theme/index.ts` and `app-native/src/theme/reload.ts`.
- `app-native/src/theme/tokens.test.ts`.
- `app-native/src/platform/boot.ts:97-108` (MMKV-backed seed).
- `app-native/src/settings/SettingsScreen.tsx` (+ settings.test
  appearance row).
- `app-native/src/shell/AppShell.tsx:41-48,94` (the plaster texture on
  plaster|exhibition) and `app-native/src/shell/shell.test.tsx:202-231`.
- `app-native/src/App.tsx:39-45` (status bar).
- `app-native/src/i18n/en.ts:141-146` and `app-native/src/i18n/zh.ts:114-117`.
- Tests that set grounds: `ask/card-back.test.tsx`,
  `ask/draw-ring.test.tsx`, `ask/ask-wheel.test.tsx`, `App.test.tsx`,
  `theme/typography.test.tsx` and `brand.test.ts` (reads the default
  ground).
- Greps over the guards: `color-guard`, `architecture`,
  `text-variant-guard`, `paint`, `surface-paint-rulings` and
  `text-variant-rulings` name no ground.
- `docs/text-variant-census.md` E4 (mentions exhibition);
  `docs/ARCHITECTURE.md` and `docs/DESIGN.md` (both handled in
  docs-sync); `.claude/skills/verify/SKILL.md` (taps name Ink, Paper and
  Plaster).
- web-divination: `paper` appears only as a chat-slip metaphor, and `INK`
  only in provenance comments, so web is out of scope.
- DECISIONS.md headings grepped for paper, plaster, exhibition, ground
  and museum.
- WCAG ratios computed (python3):
  - light: text 15.6, textDim 9.5, theme 19.9
  - dark: text 16.4, textDim 9.4, theme 9.1

## Key decisions (all written into the spec as decided defaults)
- Only the ground VALUES are renamed (`dark`, `light`) along with what
  derives from them: the INK/EXHIBITION tables, the i18n keys and the
  testIDs. The API vocabulary keeps the word "ground".
- Labels: en Dark/Light; zh 深色/浅色.
- The storage key `astrology.ground.v1` is kept. On first read, the ground
  store maps ink→dark and paper/plaster/exhibition→light, then writes the
  mapped value back. An unknown or empty value boots dark with no write.
- A fresh device defaults to dark (today's ink default).
- The plaster texture stays on Light, and the texture keeps its material
  names.
- Light shares `PLANET_PERSONALITY` (identical values) and is frozen by
  deep-equal like dark.
- Contrast floors now run on both grounds. The sandbox tests are retired
  and replaced by the light freeze. A new comment-stripped pin keeps
  legacy literals inside ground-store only.
- CLAUDE.md rule 13's "native INK" becomes "native DARK (formerly ink)".
- Superseded: `### 2026-08-19 · museum-white-mode · spec-review — approved on the first round; the palette was contrast-checked by the reviewer, not asserted by the maker`

## Output
- pipeline/specs/rn-appearance-dark-light.md

designing → spec-review
