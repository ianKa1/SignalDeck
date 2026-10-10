# dw-1-birth-chart-web · 02 · spec-review (round 1) — 2026-09-28

Fresh-context reviewer subagent (inputs: QUEUE entry + epic comment, spec, CLAUDE.md, PIPELINE.md spec sections; read-only repo access).

## Verdict (verbatim)

VERDICT: FAIL

The spec is strong and nearly ready. It fails on one acceptance criterion (T8) that cannot pass on this branch, and on one gap where the guards and the tests contradict each other. Both are small fixes.

### 1. Serves the user's notes and is right-sized — PASS (with minor notes)
- Every clause in the queue notes is covered: workspace, root workspace entry, boot → configureApiBase, sole colour home, en/zh i18n (§4.1–4.3); form over core/birth-data with validation and city index (§4.4); SVG wheel adapted from d0e36b1 to today's chart-view (§4.6); no server changes, reusing POST /api/chart (§6); guard extension in the same commit (§4.8); CORS_ALLOW_ORIGINS=http://localhost:5173 (§4.2 web:server); data survives reload (A4).
- Epic ground rules hold: barrels only, anonymous, LOCAL ONLY (§6 non-goals).
- Scope beyond notes small and justified: placements list/big-three = screen-reader twin (§3); midLongitude + SIGN_SECTORS forced by P17 deletion of houseMidLongitude and SIGNS not in chart barrel (verified); G9 workspace isolation cheap and protective; motion/atmosphere backed by "visually sufficient", no AC depends on it.

### 2. Every AC concretely checkable — FAIL (T8), otherwise good
- T8 cannot pass as written. `git diff main -- server/` already non-empty: branch is 34 commits ahead of main, `git diff --stat main...HEAD -- server/` shows 91 files changed.
- Other criteria concrete; checked vs real data: fixture beijing-1990-known-time.json Sun Gemini 23°38′ H11, Moon Pisces, Asc Cancer 28°05′, 20 aspects (19 non-conjunction); time-unknown fixture no houses/asc; cities.ts Beijing coords match; midLongitude(350,10)=(10,350)=0, (0,30)=15; React 19.2.3 hoisted at root, no root react-dom, T7 achievable; .env lacks CORS_ALLOW_ORIGINS so web:server approach works.
- T4 only partly runtime-checkable: ValidationErrorCode and ZodiacSign are types with no runtime list; must say Record<…, string> + typecheck, or runtime via BODIES / SIGN_GLYPHS keys.
- T4 conflicts with G5 and G6: a parity test value-importing BODIES from @astrace/core/chart and importing vitest trips G5 (web value-importers of core/chart must be exactly useChart.ts; tests not excluded) and G6 (i18n/** imports nothing but react and ./) if in i18n/. Forced choice = where a guard gets quietly weakened.

### 3. No violation of Architecture Contract — PASS
- "Do not re-create without explicit ask" met: epic is user-directed (2026-09-28), §4.9 records it.
- Rule 13 amendment (two token homes) necessary and keeps strength: web can't reuse RN-shaped tokens.ts, G9 forbids cross-workspace imports; each home test-enforced incl. .css and index.html; findColorLiterals catches hex in CSS; no parity = honest non-goal.
- Rules 1,2,4,5 strengthened for new tree (G1 barrel walk, G2 one-definition extended, G3 network incl. XHR/EventSource/WebSocket, G4 LONGITUDE_ARITH_RE stricter than COMPUTATION_RE, G5 chart-source twin). Vite alias …/$1/index.ts makes deep imports unresolvable.
- Web-global ban and text-variant/paint/type guards excluded for web with stated reason — scoping, not weakening.
- New core symbols correctly placed in chart-view.
- Rule 8 amendment in §4.9 incomplete: rule 8 says native dictionary is ONLY lore dictionary and app-native i18n.test.ts pins parity; landed contract would contradict itself.

### 4. Non-goals stated, open questions decided — PASS
- §6 explicit; §7 12 decided defaults. One behaviour left to chance: empty time with "time unknown" unticked → validateTime('') returns 'time-format'; spec should decide what user sees.

### Required changes
1. T8 (§8): diff against the feature's actual base, not main (e.g. `git diff <base> -- server/` empty where base = e157aed, or git merge-base HEAD <integration branch>).
2. G5/G6 vs T4 (§4.8): state which web files guards skip and where parity test lives (e.g. G3/G4/G5 exclude *.test.ts(x) and fixtures mirroring APP_NATIVE_TEST_FILE_RE; parity test at src/i18n.test.ts outside i18n/, or G6 allows vitest for tests only). State how T4 enumerates ValidationErrorCode and ZodiacSign: typed Record in dictionary type enforced by typecheck + runtime iteration over BODIES / SIGN_SECTORS keys.

### Optional suggestions
- §4.9: rewrite rule 8's "ONLY lore dictionary" and "i18n.test.ts pins parity" clauses to name both.
- §4.6: pseudo-code omits ascendant arg in wheelPoint(radius, longitude, ascendant); write asc everywhere.
- §4.4: decide empty-time case explicitly.
- A8: define above/side-by-side as getBoundingClientRect comparisons (375px: stage bottom ≤ side top; 1280px: stage right ≤ side left).
- §4.8: hex-letter-only CSS id selectors (#add, #face) false-positive in findColorLiterals; note class selectors only.
- A2: say "at least" these two messages.

Transition: spec-review FAIL → revise spec (revision round 1 of 2), then re-review.
