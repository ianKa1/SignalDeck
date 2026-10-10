# 09 · final review (auto-finalization, 2026-09-30)

**Built**: The opening page is the sign-in page. `OpeningPrototype` gained a
`still` mode and a lower-region `children` slot; App.tsx composes it with
`SignInGate` (now controls only: buttons, notes, Try again; `revealed` prop; no
wordmark). The buttons appear beneath the words once the words finish (at once
under Reduce Motion). Core `account` exposes a read-only sync phase
(`getAccountSync`/`subscribeAccountSync`: idle/pulling/ready/failed). App shows
setup when signed in ∧ pull ready ∧ no birth data; a failed pull opens the app.
`src/setup/`: Appearance (two plates printed in each ground's GROUND_TOKENS),
Language (English / 中文), Birth (the shared `BirthForm`, lifted out of
`BirthSheet`, submit "Open my chart" / 打开我的星盘), a three-mark step row, and
the resume key `astrology.setup.v1` (wiped at session end). An appearance
change uses the existing setGround + reload and resumes on the Language step
with the opening at rest.

**Deviations from spec/plan** (journaled): AC13 test in its own file
(`App.light-ground.test.tsx`) instead of isolateModules; paint pins repointed to
BirthForm.tsx; gate text ruling strengthened (no wordmark, no title variant);
i18n identical-string allowlist + `setup.english`/`setup.chinese`; setup joins
the raw-literal and paid/card-channel guard walks; new setup import pins.

**Acceptance**: 24/24 PASS (08-accepting.md); suites jest 1186, vitest 447,
typecheck 0, server 1504 passed / 124 skipped. Device evidence 06-validating.md
(harness D14: fake verifier + uncommitted client stub, reverted).

**Known limitations**: the date/time spinners keep `themeVariant="dark"` on the
Light ground (pre-existing sheet behaviour); a failed first profile pull skips
setup (by design, D4); no test taps the BirthSheet scrim (pre-existing gap);
the AC16 test does not assert the PUT body's location.
Landed as ecb505f; worktree removed, branch deleted; :8018/:8098/:54318 stopped; simulator data restored (IDENTICAL) and reopened on :8082.
