# dw-12-google-sign-in — 09 merge of feature/divination_web (2026-09-29)

Worktree: /Users/kaimao/Projects/astrology-wt/dw-12-google-sign-in
Branch: feature/dw-12-google-sign-in, parked at 05fd511.
Merged in: feature/divination_web @ b483a89 (fc38893 dw-8-planet-cast, e81006d dw-11-sky-now,
bfcd0f7 pipeline docs, c5b1c7e dw-10-phenomenon-pills, ba48028 + b483a89 dw-13-character-chat).
Merge base: c4342d6.

**Merge commit: 0305c1cf539bd97869c40153f8d97408420cfd98** (parents 05fd511, b483a89).

## Conflicts (3 textual + 1 semantic)

1. `web-divination/vite.config.ts`: HEAD had turned the config into a `({ mode }) =>` function
   with `loadEnv(mode, repoRoot, 'GOOGLE_CLIENT_ID')` and one `define` (guard G13's shape).
   It also listed `/auth\.css/` in `test.css.include`. The incoming side (dw-8) widened
   `css.include` to `[/\.css/]` (every stylesheet). Resolution: kept dw-12's function form and
   define unchanged, and took dw-8's `[/\.css/]`, which already covers auth.css. I added a
   comment saying so.
2. `server/tests/test_boundaries.py`: both sides appended tests at the same spot. dw-12 added
   the google-auth single-importer pin and its self-check. dw-8/dw-11 added persona-list
   agreement, sheets route purity, handoff-never-parsed, divination-reads-no-clock and
   sky-personas. Resolution: kept both, dw-12's block first. There were no name collisions.
3. `docs/ARCHITECTURE.md` had 4 hunks:
   - i18n namespaces: merged into one list. It now has dw-10's `pills` / `lore` and dw-12's `auth`.
   - Web test inventory: dw-8's roster tests and dw-12's auth tests both listed.
   - Web test count: updated to "30 files / 308 tests as of the dw-12-google-sign-in merge of
     dw-8/dw-10/dw-11/dw-13". The two sides had said 26/248 and 24/248.
   - Per-feature index: dw-10 entry first, then dw-12.
4. SEMANTIC: `web-divination/src/auth/AuthGate.test.tsx` W2 failed after the merge.
   dw-8 mounts ChatPanel/SessionBar only when an active character is stored. With none
   stored, the RosterPicker opens instead. W2 asserted `.chat`/`.log-bar` present after
   sign-in and seeded no active persona. Fix: W2 seeds `astrology.divination.active.v1 =
   venus` (with a comment), and `gateIsUp()` now also asserts `.roster` is absent. That
   makes the threshold's claim cover the picker too. Test intent is unchanged.

Auto-merged files touched by both sides (checked, no action needed): CLAUDE.md (both sides'
amendments present: dw-12's rule 3 google-auth pin, rule 12 Google sign-in paragraph and
GOOGLE_CLIENT_ID note, next to dw-8/10/11/13's rule 10 text), `app-native/src/architecture.test.ts`
(incoming side only added `ASPECT_TONES` to the one-definition list; no G-id collision, so
dw-12's G12/G13 stay as they are, **no renumbering**), `web-divination/src/i18n/en.ts` and `zh.ts`
(parity test green). `server/app/main.py`, `requirements.txt` and `App.tsx` were changed on
one side only.

## Commands

    git merge feature/divination_web
    (resolve; python/sed edits on the 3 files + AuthGate.test.tsx)
    npm install                                  # worktree root
    env -u DATABASE_URL npm run typecheck        # clean (app-native, web-divination)
    env -u DATABASE_URL npm test
    cd server && DATABASE_URL= conda run -n astrology pytest -q -p no:cacheprovider
    initdb -D <scratch>/pg12 -U pg -A trust; pg_ctl start -p 54320 -k '' (TCP only: the
      scratch path exceeds the 103-byte unix-socket limit); createdb astrace_dw12
    DATABASE_URL=postgresql://pg@127.0.0.1:54320/astrace_dw12 conda run -n astrology pytest -q \
      tests/test_google_auth.py tests/test_boundaries.py tests/test_auth_integration.py tests/test_native_tokens.py
    pg_ctl stop; rm -rf cluster + log
    git add docs/ARCHITECTURE.md server/tests/test_boundaries.py web-divination/vite.config.ts \
      web-divination/src/auth/AuthGate.test.tsx; git commit

Symlinks were checked and intact: `.env` and `server/data/{seas,semo,sepl}_18.se1` point to the primary checkout.

## Suite totals (verbatim)

- typecheck: `tsc --noEmit` clean in app-native and web-divination
- jest: `Test Suites: 90 passed, 90 total` / `Tests:       1072 passed, 1072 total`
- vitest (before the W2 fix): `Test Files  1 failed | 29 passed (30)` / `Tests  1 failed | 307 passed (308)`
- vitest (after): `Test Files  30 passed (30)` / `Tests  308 passed (308)`
- pytest db-free: `1378 passed, 55 skipped, 1 warning in 132.33s (0:02:12)`
- pytest live PG (4 files): `85 passed, 1 warning in 1.07s` (0 skipped)
