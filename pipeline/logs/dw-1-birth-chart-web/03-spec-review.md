# dw-1-birth-chart-web · 03 · spec-review (round 2) — 2026-09-28

Spec revised by the designer (Revision 1 changelog at spec end) per round-1 FAIL (02-spec-review.md).
Designer deviation: the typed Record binding for T4 lives in the test file (src/i18n.test.ts), not the i18n Dict type,
because rule 8 bars i18n/ from any import but react (type-only included).

New fresh-context reviewer (did not see round 1 conversation).

## Verdict (verbatim, condensed only in list layout)

VERDICT: PASS

1. Serves the notes, right-sized: PASS. Every notes item mapped (§4.1–4.6, §4.8–4.9, T4, T8, A4, §4.2 web:server). Extras small and reasoned (placements list = screen-reader twin; motion = "visually sufficient"; midLongitude/SIGN_SECTORS forced by rule 5 + P17 deletion, confirmed). §4.10 seams are only named slots/data attributes. LOCAL ONLY respected.
2. ACs checkable: PASS. A1–A9 DOM selectors/localStorage/getBoundingClientRect/computed styles; T1–T8 commands; G-a..G-i planted violations. Fixture: 10 planets, Sun Gemini 23°38′ H11, Moon Pisces, Asc Cancer 28°05′, 19/20 non-conjunction aspects. GeoNames Beijing (39.9075,116.3972,Asia/Shanghai) ~0.01° from fixture — A3 holds. storageKeyFor → astrology.birthData.v1.traveler. Core chart seam uses fetch(apiUrl('/api/chart')). r1 fixes sound: T8 merge-base = e157aed; G5/G6 vs T4 resolved; T4 splits type-only unions vs runtime lists.
3. Architecture contract: PASS. Amendments to rules 13, 8, 1, 2, 5 add a second tree each with a real test — at least as strong, needed for user-requested workspace. Rule 4 (G5), rule 5 (G3 incl. XHR/EventSource/WebSocket; G4 stricter), rule 7 (G8), rule 2 (G1 + G9). angularDelta signed → midLongitude(10,350)=0. Public-API guard polices value exports; both new core values get a web consumer via G10. uvicorn --env-file load_dotenv without override → shell CORS_ALLOW_ORIGINS wins. react-dom not hoisted; 19.2.3 pin makes T7 achievable.
4. Non-goals and defaults: PASS. §6 non-goals; §7 12 decided defaults; nothing open.

Required changes: none.

Optional suggestions (first should go into the plan):
- §4.8/T4 factual slip: ValidationErrorCode is NOT exported from @astrace/core/birth-data barrel (only BirthData, BirthLocation, ValidationErrors types). Fix: add it to the barrel's export type line (list in §4.6 Core additions) OR derive in the test as NonNullable<ValidationErrors[keyof ValidationErrors]>. Journal the choice.
- §3 atmosphere vs colour guard: semi-transparent chromatic washes cannot be rgba(...) in CSS; plan should give tokens.ts alpha variants or channel-triplet tokens used as rgb(var(--gold-rgb) / .1).
- §4.2 web:server inline VAR=value is POSIX-only (fine, local-only).
- A7: say Retry path renders without page reload in the same tab.

Transition: spec-review → spec-approved.
