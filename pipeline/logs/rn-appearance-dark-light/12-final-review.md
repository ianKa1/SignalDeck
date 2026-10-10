# 12 · final review (auto-finalization)

**Built**: `Ground = 'dark' | 'light'`; `GROUND_TOKENS` keyed dark/light with the old ink/exhibition values (frozen by deep-equal); PAPER/PLASTER deleted; `LIGHT.planet` shares `PLANET_PERSONALITY`. `theme/ground-store.ts` owns the only legacy table (ink→dark; paper/plaster/exhibition→light), applies it on first read and writes the new name back once; unknown/empty/unreadable boots dark with no write. Settings shows Dark/Light (深色/浅色). Plaster wall texture mounts on light only. Status bar keyed on dark. New comment-stripped pin keeps the old literals out of app-native/src outside ground-store. Contrast floors run on both grounds. CLAUDE.md rule 13 wording, ARCHITECTURE/DESIGN/census/verify skill (taps Dark(45,525) / Light(96,525)) updated.

**Deviations from spec**: none of substance (worker choices journaled 2026-09-30 implementing entry). The verify skill's appearance row y was 525, not 446.

**Known limitations**: devices on paper/plaster move to the light ground on first launch (intended). A user who downgrades to a pre-feature build sees Ink (it does not know `dark`/`light`). One vitest frame-counter flake (`SpotlightLayer.test.tsx`) seen once under load, unrelated.

**Acceptance**: 14/14 PASS (11-accepting.md), incl. device AC-13/14 on its own Metro/backend. Landed on dev as d35517f; worktree and branch removed.

## Coordinator note (after landing)
The user later reported that the Metro on :8081 — used as the "pre-feature" bundle in 09-validating and 11-accepting — was serving /Users/kaimao/Projects/astrology2 (branch main), not the primary checkout on dev. Both runs proved by whole-word bundle counts that it was pre-feature (four grounds: `groundPlaster` 3, `groundLight` 0), so AC-13's before-shots and AC-14's legacy-value seeding remain valid pre-feature evidence; only the label "dev" in those logs is inaccurate.
