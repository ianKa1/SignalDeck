# rn-ask-input-disabled — 05 validating (2026-09-30, worker — partial)

Worktree `/Users/kaimao/Projects/astrology-wt/rn-ask-input-disabled` @ `ffc40d2`.

## AC-1 … AC-9 (jest / tsc) — PASS
Evidence is in 04-implementing.md (verbatim):
- AC-1…AC-6: `npx jest src/ask/ask-gate.test.tsx` → `Tests: 10 passed, 10 total` (real constant, real core ask barrel, spied fetch). Flip sanity and gate-2 sanity both reverted and recorded.
- AC-3 parity: `npx jest src/i18n` → `Tests: 17 passed, 17 total`.
- AC-7: ask.test 48 → 49 (+1 flag-on absence case), ask-flow 6 → 6, text-variant-rulings 28 → 28; 0 removed lines in all three; each carries the flag-ON mock (load-bearing: removing it fails 4 ask-flow cases).
- AC-8: guards + ask + rulings: `Test Suites: 23 passed; Tests: 346 passed`; MARKER_TOTAL 61 / RAW_TAG_TOTAL 53 unchanged; note floor 13 met.
- AC-9: root `npm test` → jest `92 suites / 1091 tests passed`, vitest `47 files / 445 tests passed`; root `npm run typecheck` clean (app-native + web-divination).

## AC-10 (simulator) — NOT RUN by the worker
The iOS simulator is shared and serialized by the coordinator; the worker did not touch it. Status reported: `validating — needs device`. The coordinator's device check appends its evidence as a later log.

Device check must show (per spec AC-10, `.claude/skills/verify/SKILL.md` setup, backend access log visible, dev client built from this worktree's code):
1. Ask tab: tap the question field → no keyboard, no caret.
2. Field wrapper and ASK dimmed (0.5 inert layer; ASK outline lineSoft, label faint), ASK still reads "ASK".
3. `Asking is coming soon.` centred under the field / ASK row.
4. Tap ASK → nothing happens (no "Reading your question…", no plate).
5. Title (expanded face), four starter chips and the ring still on screen; a chip tap swaps the placeholder; the ring still rolls.
6. Switch language to 中文 → `提问即将开放。`.
7. Backend access log for the whole session contains no line with `/api/ask`.
Screenshots + log excerpt into the validating log.
