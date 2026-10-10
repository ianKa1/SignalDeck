# rn-appearance-dark-light — 05 planning (2026-09-30)

## Inputs read
- CLAUDE.md (rules 2, 8, 13, 15), pipeline/PIPELINE.md ("Skills per stage", `/imple-plan` pipeline-mode override, Git granularity).
- `pipeline/specs/rn-appearance-dark-light.md` (Decided defaults 1–14, Architecture, AC-1…AC-14).
- `pipeline/logs/rn-appearance-dark-light/02-spec-review.md` (FAIL D1, fixed in 03) and `04-spec-review.md` (PASS; two non-blocking notes).
- Targeted confirmations: `app-native/src/theme/ground-store.test.ts` (current seeding cases, restore idiom), `app-native/src/App.tsx:45` + `App.test.tsx` (no StatusBar assertion exists today, so AC-9 is a new case), `app-native/src/architecture.test.ts:58` (`stripCommentsAndStrings` strips strings too — unusable as-is for the AC-11 pin), `app-native/src/color-guard.test.ts` (names no ground), legacy-literal files under `app-native/src` (matches the reviewer's list), `docs/ARCHITECTURE.md` ground mentions (~:84, :255, :357), `docs/DESIGN.md` §4, `docs/text-variant-census.md:342`, `.claude/skills/verify/SKILL.md:65`.

## Skills invoked
- `imple-plan` (Skill tool) under the pipeline-mode override: ordered `- [ ]` steps with files, intent and a done-when; Acceptance map; short Risks. Code Structure / Calling Sequence / Data Flow / Test Plan dropped. `/architecture-designer` not re-run.

## Output
- `pipeline/plans/rn-appearance-dark-light.md` — 11 steps (0 baseline → 10 docs-sync), acceptance map covering AC-1…AC-14, 6 risks.
- Review notes folded in: `GROUND_TOKENS.light.panel` for AC-3 (step 2); verify-skill tap coordinates re-derived from the step-8 screenshot, not renamed (steps 8, 10).
- Validating (steps 8–9) needs the iOS simulator: the implementer reports `validating — needs device` to the coordinator. AC-14's procedure is spelled out: serve the pre-feature `dev` bundle, set Paper/Plaster/Exhibition/Ink in turn, swap Metro to the feature branch without reinstalling, prove freshness on every swap, cold-relaunch, sample and check Settings.

## Spec gaps
None. Every step maps to a decided default or the Architecture section. Notes: the DECISIONS.md supersession (default 14) is recorded as a new appended entry at docs-sync, because DECISIONS.md is append-only. CLAUDE.md rule 15's stale "50/57" stays out of scope, as the spec says.

Transition: spec-approved → implementing
