# rn-ask-input-disabled — 06 docs-sync (2026-09-30, worker)

Run BEFORE the device check (AC-10), by coordinator instruction. The device
check does not change code. If it forces a code change, re-sync.

## Skills invoked
- `update-architecture-doc`: baseline `git log -1 -- docs/ARCHITECTURE.md` → 067ee47. The diff since then is this feature's two commits (b88cebf, ffc40d2), all under `app-native/src/ask`, `i18n`, and three test files. Triage: local, no module or dependency move.

## Edits
- `docs/ARCHITECTURE.md` (+35/−6):
  - the repo-structure `ask/` comment names `ask-gate`, which is read by AskScreen alone;
  - the `AskScreen.tsx` bullet gains a THE GATE paragraph (the constant, its one reader, the note, the early `submit` return, what stays live, and the one-line re-enable);
  - the `QuestionField.tsx` bullet now gives `editable={!checking && !disabled}` and `accessibilityState`, and says ASK is disabled on empty text OR under the `disabled` prop;
  - the tests paragraph names the three flag-ON suites and `ask/ask-gate.test.tsx`.
  - Sections confirmed still accurate: every other part of the Ask section. No drift found outside the diff.
- `docs/text-variant-census.md` (+25/−1): the §D `note` row appends the coming-soon member, so the listed members go from 12 to 13. The `n` column keeps its census-time value, as every earlier ask section left it. New §S records the added site, adds §A row 163 and states that the residue is unchanged (local 45 / markers 61 / raw tags 53). These figures were checked against `text-variant-guard.test.ts:220-222`.
- `docs/features/rn-ask-input-disabled.md` (new). `docs/features/` is gitignored (`.gitignore:17`) and exists only in the primary checkout, so the file was written to `/Users/kaimao/Projects/astrology/docs/features/` and is not in any commit.

## Verification
`git diff --stat docs/` (before commit):
```
 docs/ARCHITECTURE.md        | 41 +++++++++++++++++++++++++++++++++++------
 docs/text-variant-census.md | 26 +++++++++++++++++++++++++-
 2 files changed, 60 insertions(+), 7 deletions(-)
```
Only two files are listed, because the third lives in the gitignored feature-doc directory (see above).
`cd app-native && npx jest src/theme` → `Test Suites: 7 passed, 7 total; Tests: 115 passed, 115 total`.

Commit `f8f8fb4`.

Status: docs-sync done except for AC-10. The worker reports `validating — needs device` to the coordinator.
