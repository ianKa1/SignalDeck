# 07 — validating (rn-appearance-dark-light) — PARTIAL, needs device

Worker run in the worktree `/Users/kaimao/Projects/astrology-wt/rn-appearance-dark-light`
at `7122668`. The simulator and Metro are shared and serialized by the
coordinator, so the worker grades AC-1..AC-12 (all test-graded) here and hands
AC-13/AC-14 (plan steps 8–9) to the coordinator.

## Commands (this stage, fresh runs)

From `app-native/`:

    npx jest src/theme/tokens.test.ts src/theme/ground-store.test.ts src/settings/settings.test.tsx \
      src/shell/shell.test.tsx src/App.test.tsx src/i18n src/color-guard.test.ts \
      src/architecture.test.ts src/text-variant-guard.test.ts src/theme/paint.test.ts \
      src/surface-paint-rulings.test.tsx

(results below); from the repo root `npm test` and `npm run typecheck` (recorded
in 06-implementing.md step 7: run 2 exit 0 — jest 91 suites / 1090 tests,
vitest 47 files / 445 tests; typecheck exit 0).

    PASS src/i18n/lang-store.test.ts
    PASS src/theme/ground-store.test.ts
    PASS src/color-guard.test.ts
    PASS src/text-variant-guard.test.ts
    PASS src/theme/paint.test.ts
    PASS src/i18n/i18n.test.ts
    PASS src/theme/tokens.test.ts
    PASS src/architecture.test.ts
    PASS src/surface-paint-rulings.test.tsx
    PASS src/App.test.tsx
    PASS src/shell/shell.test.tsx
    PASS src/settings/settings.test.tsx
    Test Suites: 12 passed, 12 total
    Tests:       147 passed, 147 total

## Criterion by criterion

| AC | Graded by | Result |
|---|---|---|
| 1 two grounds | `tokens.test.ts` "GROUND_TOKENS is keyed dark, light"; `npm run typecheck` | PASS |
| 2 values unchanged | `tokens.test.ts` "dark deep-equals the pre-rename ink values", "light deep-equals the pre-rename exhibition values" (literals from 06 step 0) | PASS |
| 3 legacy migrates | `ground-store.test.ts` paper/plaster/exhibition → light (tokens.ground, surface.card, writes `[[key,'light']]`); ink → dark (writes `[[key,'dark']]`) | PASS |
| 4 current values don't rewrite | `ground-store.test.ts` light / dark, `writes` = [] | PASS |
| 5 unknown/empty/throw boot dark | `ground-store.test.ts` empty, 'sepia' (left in place), throwing read — all dark `#08090e`, no write | PASS |
| 6 Settings offers Dark/Light | `settings.test.tsx` testIDs, en Dark/Light, zh 深色/浅色, dark selected | PASS |
| 7 switch persists, reloads once | `settings.test.tsx` press dark = no write/no reload; press light = one write 'light', one reload, light selected | PASS |
| 8 texture on Light only | `shell.test.tsx` light mounts `plaster-texture` (pointerEvents none); dark mounts none | PASS |
| 9 status bar follows ground | `App.test.tsx` new describe; mutation-checked (flip → both fail) | PASS |
| 10 contrast floors both grounds | `tokens.test.ts` `describe.each(['dark','light'])` × 3 floors | PASS |
| 11 removed grounds can't return | `ground-store.test.ts` pin (mutation-checked with a probe `'paper'`); en/zh carry no groundInk/Paper/Plaster/Exhibition (`grep` empty; parity test unedited) | PASS |
| 12 guards green, unweakened | six guard suites pass; `git diff --stat 12d403a~1` over them empty; MARKER_TOTAL 61 / RAW_TAG_TOTAL 53 unchanged; root `npm test` + `npm run typecheck` exit 0 | PASS |
| 13 device: Dark/Light render as before | coordinator (plan step 8) | PENDING — needs device |
| 14 device: legacy device opens right | coordinator (plan step 9) | PENDING — needs device |

Note for the skeptical reader: root `npm test` run 1 had one web-divination
failure (`SpotlightLayer.test.tsx` frame counter), outside this feature's diff
(no web-divination or packages/ file changed); it passed alone and the full run 2
was green. Logged verbatim in 06 step 7.

Status: validating — needs device (AC-13, AC-14).
