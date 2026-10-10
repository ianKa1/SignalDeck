# 09 · final review (auto-finalization)

**Built**: `app-native/src/ask/ask-gate.ts` exports `ASK_INPUT_ENABLED: boolean = false`, read only by `AskScreen.tsx`. `QuestionField` takes a required `disabled` prop folded into `canSubmit` (input `editable` false, ASK disabled, inert paint + `waiting` tone). `AskScreen.submit` returns before `checkFitness`. A `note` line `ask-coming-soon` (en "Asking is coming soon." / zh "提问即将开放。") shows under the field while the flag is off. Title, starter chips and ring stay live. Three existing suites mock the gate ON (no case deleted); new `ask-gate.test.tsx` (10 cases) spies `globalThis.fetch` over the real core. Guards: note floor 12→13, AskScreen import allowlist + `./ask-gate`.

**Deviations from spec**: the constant is annotated `: boolean` (keeps both states type-identical); `disabled` folded into `canSubmit` rather than OR-ed at four sites; census `n` column kept at census-time value (member list grows 12→13).

**Known limitations**: on device the ASK button already looked inert on `dev` with an empty field, so the gate visibly dims mainly the field itself (acceptor observation, not a failure). The simulator has a hardware keyboard, so "no keyboard" is proven by no caret + rejected typing. CLAUDE.md rule 15's residue figure (50/57) and the guard test title (48/55) are stale vs the pinned 53/61 — pre-existing drift.

**Acceptance**: 10/10 PASS (08-accepting.md). Landed on dev as d47d24a; worktree and branch removed.
