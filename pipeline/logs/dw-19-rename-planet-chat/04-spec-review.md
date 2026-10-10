# 04 — spec-review (round 2)

**Verdict: PASS.** B1 is fixed, and every round-1 note is either addressed or correctly left to the plan. Nothing is blocking.

## B1: fixed

- **New decided default "11. History citations stay".** It records three exceptions:
  - `dw-*` slug citations, as the regex `dw-\d+-[a-z0-9-]*divination[a-z0-9-]*`;
  - the literal epic path `epics/divination-web.md`;
  - the epic's display name, which becomes "PLANET CHAT WEB EPIC", with one old-name parenthetical kept in CLAUDE.md.
- **N1 and D9 agree with it.** N1 lists the D11 exceptions, and D9's allowlist cites them.
- **Checked against the worktree at bd158b2.** After removing `web-divination` paths and slug citations from an `rg -i divination` sweep, the only matches left are renameable identifiers such as `DivinationPersona` and `Divination*Request`. The only other files that match `divination` are:
  - `package.json` and `package-lock.json`, only through `web-divination` (D3);
  - `server/tests/fixtures/divination_chartless_{en,zh}.txt`, whose names are test assets under D1 and whose contents contain no "divination".
- **No user-visible string needs to change.** `i18n/` and `index.html` contain no divination or 占卜 today, so N9 will log "none existed".

## Notes from round 1

- **N-a: addressed.** D6 renames both `_pkey` constraints, and N5 asserts them.
- **N-b: addressed.** `docs/features/` is described as untracked and frozen, and N1 excludes it.
- **N-c: left to the plan's risks, as advised.**
- **N-d: addressed.** D3 cites the untracked `.env*` files.
- **N-e: addressed.** Both suites read one allowlist, `rename-allowlist.json`.
- **N-f: addressed.** D1 states the kebab-case test file names are deliberate.

## Non-blocking

- **NB1.** The decided defaults are numbered 1–9, 11, 10. Renumber them so D11 comes last, or leave it; the cross-references still resolve.
- **NB2.** D11 allows `DIVINATION WEB EPIC` "in that one parenthetical", but a flat regex allowlist cannot express that. The plan should anchor this entry to the file and the exact string, i.e. CLAUDE.md with `formerly the DIVINATION WEB EPIC`, so the old name cannot come back elsewhere in prose.
- **NB3.** N1 excludes `pipeline/`, while D10 edits the epic's content. N10 covers that edit, so the plan should verify the epic's current-state sections under N10, not N1.

## Checklist

1. **Serves the ruling, right-sized: PASS.** It covers every scope item. The cache keys stay stable (the preferred option), the workspace-folder choice is recorded, and the slugs and history are kept.
2. **Criteria concretely checkable: PASS.** N1–N10 and R1 can all be run. N2 includes a planted-occurrence self-check, and N4 uses golden hex values from the base commit.
3. **Contract/epic: PASS.** No boundary moves, the guards are renamed rather than weakened, applied migrations 011/012 are untouched, and dw-16/17/18 behaviour is unchanged.
4. **Non-goals and decided defaults: PASS.** The exception set is now closed and matches the actual contents of the tree.
