# dw-10-phenomenon-pills — 02 spec-review (2026-09-29)

Fresh-context general-purpose subagent; inputs: QUEUE entry, spec (with Architecture), epic file, CLAUDE.md, PIPELINE.md Spec requirements + Decision precedence, last DECISIONS entry (ruling B). Read-only, targeted code reads for citations.

## Verdict (verbatim)

VERDICT: PASS

The spec serves the dw-10 notes faithfully, stays inside ruling B, and every file:line claim I checked is accurate. Nothing below is blocking; the suggestions are for planning/docs-sync.

**Verified against the code (bfcd0f7)**
- Fixture chart F (ran `render.natal_context` for 1990-06-15 08:30 Beijing, Placidus): Venus Taurus 10, Moon Pisces 8, Mars Aries 9, AC Cancer; Venus trine Saturn, Moon sextile Venus, Venus opposition Pluto present; no Venus–Mars aspect; time-unknown chart has no ascendant. S1–S3/T1–T3/W1 are grounded in true facts.
- Citations accurate: `turn.py` stream loop 273–311, `_side_read` :193, `_wire_entry` :227, logger `getLogger(__name__)`; `render.py` `ref_catalogue` :387, `side_prompt` :593, `side_schema` :631, `to_wire_refs` :677; `persona.SHEET_POINTS` :49; `sky.sky_view` :103 with episodes carrying `transiting/target/targetKind/type`; core `turn.ts` guards 77–111; `wheel-activation.showRefs` :34 (empty refs clear); ChatPanel `Slips` :105, `ChartRefChips` :186, `Entry` :287; one-definition enumeration in `architecture.test.ts` (~:245/:298).
- Feasibility: the bubble Segmenter passes text through immediately (T2 achievable); tags contain no terminators/newlines so the sentence cap cannot split one; the web pacer reveals each delta whole, so a pill token is never half-typed; `test_handoff_is_never_parsed_from_the_reply` only walks turn.py/render.py, so a new `tags.py` keeps it intact.
- No existing `ASPECT_TONES`/harmonious-tense table anywhere (no duplicate knowledge).

**Checklist**
1. Serves the notes, right-sized — yes. Closed-vocabulary tags, buffered + checked against the chart, failed → plain text + log, separate natal/sky/dice styles, harmonious/tense tone, display-time translated labels, tap → wheel + one-line meaning, pills as the single chartRefs source (the notes allowed it; the spec decides it). The web `lore` namespace is the necessary means for a zh one-line meaning; legacy chips keep old transcripts working. No invented scope beyond the small Midheaven note below.
2. Checkable — yes. S1–S8, T1–T9, C1–C3, W1–W7 are concrete test assertions; R1–R5 are real-app checks with logged evidence. R4 is the softest (see suggestion 1) but still judgeable from logged reply text.
3. Architecture Contract — no violation. The exception to "side fields never parsed from the prose" is exactly ruling B's scope (DECISIONS 2026-09-29 user ruling); mood/handoff/dice stay structured and the handoff test is kept unchanged. `tags.py` is pure with its own boundary test + planted self-check, no new tier edges; core stays DOM-free; web colours via `var(--aspect-*)`/tokens; the new chart-view symbol `ASPECT_TONES` is added to the enumeration guard. No new routes/stores/jobs/migrations (rules 9/14 untouched). CLAUDE.md amendments (rules 10, 8, 1) are legitimate and land in the same commit; the Supersedes list names the dw-3 refs decision and the dw-5/dw-11 side fragments.
4. Non-goals stated; all ten defaults decided; no open questions.

**Non-blocking suggestions**
1. R4 wording: define "a phrase naming a placement, aspect or transit" operationally (a body name in the same clause as a sign name, a house number/ordinal, or an aspect word, in en or zh; persona self-reference like "I sit in Taurus" counts) so the acceptance agent isn't judging freehand.
2. Empty bubbles: the turn.py contract emits the `bubble` frame right after `boundary()`; if a bubble's only content filters to nothing (e.g. `⟦⟧` or a stray `⟧`), two `bubble` frames go out back-to-back, breaking the stated "just before the first delta OR pill" invariant. Hold the `bubble` frame until the bubble's first non-empty item (or state that an empty bubble is collapsed).
3. Summary card raw tags: the non-goal accepts that an echoed tag "shows as text on the card" — i.e. visible `⟦…⟧` brackets on the dw-6 card. A cheap web-only fix (render `SummaryCard` text through `splitPills` as static pills/labels) would honour CLAUDE.md Design Principle 1 ("visually sufficient") without touching the summary route.
4. Epic file: default 10 only amends the epic's event grammar. The epic's "User rulings (2026-09-28)" bullet still states structured side fields are "NEVER parsed out of the prose" as a user ruling — docs-sync should rewrite that bullet to name the phenomenon-tag exception (and that the premise was a loop derivation, per the 2026-09-29 entry).
5. `isPill` aspect ends: the core contract lists placement bodies (`Body | 'Ascendant'`) and transit ends (`Body`) but not aspect ends; say they reuse `isAspectPoint` (same set as `isChartRef`).
6. `lore` includes Midheaven, but no tag kind can name it — drop it or say which pill's meaning line uses it.
7. T9 implies rewriting (not just keeping green) the dw-3/dw-5/dw-11 side-read tests (`S3_IDS` refs tests, `test_topic_is_registered`'s fragment set, `side.dice`/`side.sky` assertions); the plan should name them so the rewrite is deliberate.
8. CLAUDE.md rule 5 makes `useChart.ts` web-divination's one VALUE-importer of `@astrace/core/chart`; note that `Pill.tsx`/`pill-meaning.ts` may import only types from `@astrace/core/chart` (glyphs via `chart-view`, validation via the `divination` barrel).

## Coordinator action
Folded suggestions 1, 2, 3, 5, 6, 8 into the spec (R4 operational wording; bubble frame held until first non-empty item; SummaryCard renders tokens via PillText static — non-goal reworded, W6 extended; aspect ends reuse isAspectPoint; Midheaven dropped from lore; type-only chart imports). Suggestion 4 → docs-sync; 7 → plan. No re-review needed (non-blocking, PASS).

Status: spec-review → spec-approved → planning.
