# 08 — docs-sync (rn-appearance-dark-light)

Run by the parallel-wave worker in the worktree
`/Users/kaimao/Projects/astrology-wt/rn-appearance-dark-light` before the
device check. The coordinator runs AC-13 and AC-14 on the shared simulator.
Plan step 10.

## /update-architecture-doc (diff-driven)

Baseline: the doc was last touched at 04ae600's ancestry. The only commits
since are this feature's 12d403a (feat) and 7122668 (CLAUDE.md). Triage:
theme/settings/shell/App changes are local to structural (the `Ground` type,
the Settings row and the store's behaviour). No module moved, no dependency
edge changed, and no diagrams needed an edit.

Sections updated in `docs/ARCHITECTURE.md`:
- native overview: the Settings row now reads Dark / Light (深色 / 浅色)
- repo tree: `theme/` now says "two grounds: dark + light"; the `settings/`
  segments now read Dark/Light
- App.tsx status bar: dark gets light content, light gets dark content
- `src/theme/` bullet: two grounds, both frozen by value, the accent split on
  light, "COPY of DARK", "freeze DARK"
- ground-store: the validator takes only dark/light, plus the legacy
  migration table and its behaviour, the floors on both grounds and the pin
- PLANET_PERSONALITY is now "both grounds"
- AppShell texture: mounted on light, absent on dark
- tests paragraph: card-back setGround('dark'/'light'), ask-wheel "every
  ground", the Settings APPEARANCE pair (testIDs and keys), brand "dark
  ground", the shell texture line, the tokens and ground-store descriptions,
  and the App.test status-bar case
- web-divination Theme & i18n: "copies native DARK values (the ground
  formerly named ink …)"
- Feature docs index: a new rn-appearance-dark-light entry

Confirmed still accurate or left on purpose: `plaster-tile.png` and
`gen-plaster-tile.py` (material names kept by default 8); the 2026-08-13
`tokens.ink` / paper-ground history at ~:4435 (history); the brand
"ink background" lines (they describe icon art); the museum-white-mode
feature-index entry (frozen snapshot).

Other docs:
- `docs/DESIGN.md` §4: a "Native, today" paragraph naming Dark (深色) and
  Light (浅色). The web-era Ink/Paper tables stay as history.
- `docs/text-variant-census.md` E4: "(light (then exhibition) tried it
  2026-08-28 and reverted)"
- `.claude/skills/verify/SKILL.md:65`: the Ink/Paper/Plaster taps are
  replaced with `Dark(TODO,446) / Light(TODO,446)`. The x coordinates must
  be RE-DERIVED from a screenshot (plan step 8), and y=446 must be confirmed
  there too. The worker has no simulator access, so it did not guess them.
- `docs/features/rn-appearance-dark-light.md` was written in the PRIMARY
  checkout, because `docs/features/` is gitignored (`.gitignore:17`) and only
  exists there.
- The DECISIONS.md entry for default 14 is drafted in the worker's report.
  The coordinator is the single writer.

Evidence:

    git diff --stat 7122668 fd4a88c
     .claude/skills/verify/SKILL.md |  4 +-
     docs/ARCHITECTURE.md           | 93 +++++++++++++++++++++++-------------------
     docs/DESIGN.md                 |  9 ++++
     docs/text-variant-census.md    |  4 +-
     4 files changed, 66 insertions(+), 44 deletions(-)
    grep -n "Plaster(" .claude/skills/verify/SKILL.md   → (empty, exit 1)

Commit: fd4a88c (docs). With CLAUDE.md (7122668) and the ignored feature
doc, that is 6 of the plan's 6 targets. DECISIONS goes through the
coordinator.

Remaining for the coordinator: fill the two TODO x coordinates in
`.claude/skills/verify/SKILL.md:65` from the step-8 screenshot, then commit
in the worktree.

Status: docs-sync done except the tap coordinates. The feature is at
`validating — needs device`, and `accepting` waits on AC-13 and AC-14.
