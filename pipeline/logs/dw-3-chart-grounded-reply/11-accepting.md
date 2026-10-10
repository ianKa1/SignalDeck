# 11 accepting — fresh-context acceptance check

Checker: fresh context, did not see the implementation before grading. Branch
`feature/dw-3-chart-grounded-reply` @ 8aa9252.

Suites (run by the checker): `npm run server:test` → 1035 passed, 50 skipped,
exit 0. `npm test` → app-native 90 suites / 1069 tests + web-divination 13
files / 72 tests, exit 0. `npm run typecheck` → exit 0 (both workspaces).

Real app: backend on :8001 (`ANALYSIS_LLM=claude-cli`,
`CORS_ALLOW_ORIGINS=http://localhost:5173`), web on :5173 with
`VITE_API_BASE=http://localhost:8001`, driven in Chrome. Birth entered through
the form: 1990-06-15 08:30, China / Beijing (GeoNames 39.9075 / 116.3972),
Asia/Shanghai. localStorage was cleared first to start from a fresh profile.
Request bodies were captured by wrapping `window.fetch` in the page. Chart
facts come from the Placements panel and a replay of the page's own
`/api/chart` body: Sun Gemini H11, Moon Pisces H8, Mercury Gemini H11, Venus
Taurus H10, Mars Aries H9, Jupiter Cancer H12, Saturn/Uranus/Neptune Capricorn
H6, Pluto Scorpio H4. Asc Cancer 28°04', DSC/7th cusp Capricorn 28°04', 11th
cusp Taurus 19°. The aspect list includes Venus☍Pluto, Venus△Saturn,
Saturn☍Ascendant and Moon sextile Venus.

| ID | Verdict | Evidence | Checked on |
|---|---|---|---|
| S1 | PASS | `test_dw3_s1_grounded_turn_prompt` (via TestClient, fake `stream_turn`) checks this order: venus.txt, chart.read, marker, lang line. It also checks that the JSON after the marker parses; `chart == _restate(r.chart, r.structure)`; `meanings == relevant_meanings(...)`; Venus is Taurus/10; the Venus–Pluto opposition is present; `chart.none` is absent. `render.system_prompt` code matches. | TESTS/CODE |
| S2 | PASS | `test_dw3_s2_no_chart` covers both `birthData` absent and `null`: prompt has `chart.none` and no marker; schema `is MOOD_SCHEMA`; done is `{"mood":"tender","chartRefs":[]}` even though the fake returned refs. | TESTS/CODE |
| S3 | PASS | `test_dw3_s3_refs_are_validated` first asserts there is no Venus/Mars square in either order. The full SSE is then exactly `[delta, done {"mood":"candid","chartRefs":[planet Venus, aspect Venus\|opposition\|Pluto]}]`. `render.to_wire_refs` keeps catalogue ids only, deduplicated. | TESTS/CODE |
| S4 | PASS | `test_dw3_s4_cap_end_to_end` gives 8 planets and gets the first 6, in order. `test_s4_to_wire_refs_caps_at_six_in_order` does the same at the builder level. `REFS_MAX = 6`. | TESTS/CODE |
| S5 | PASS | `test_dw3_s5_side_read_gets_the_catalogue`: enum equals the ten `planet:` ids plus every planet/Ascendant aspect, in chart order. No Chiron/NorthNode/Midheaven. The user JSON has `question`, `reply` and `catalogue`. | TESTS/CODE |
| S6 | PASS | `test_dw3_s6_degradation`: `AnalysisUnavailable` → `{"mood":null,"chartRefs":[]}`, and non-list `"planet:Venus"` → `{"mood":"tender","chartRefs":[]}`. `test_dw3_s6_side_read_timeout` (`DIVINATION_TURN_TIMEOUT_S=1.5`, side read sleeps 3 s) → `{"mood":null,"chartRefs":[]}`. Deltas are unchanged in every case. | TESTS/CODE |
| S7 | PASS | `test_dw3_s7_bad_birth_data_is_422`, parametrised over date `1990-13-40`, `Mars/Base` and missing `location`: 422, and the `called` list stays empty. `birthData: BirthData \| None` on the pydantic model validates before the stream opens. | TESTS/CODE |
| S8 | PASS | `test_dw3_s8_time_unknown`: `time_unknown` is true, every house is null, `rising_sign` is null, and no Ascendant id is in the enum. | TESTS/CODE |
| S9 | PASS | `test_dw3_s9_every_ref_is_in_the_chart`: planet refs are in `POST /api/chart` planets, and each aspect ref matches exactly one aspects entry. | TESTS/CODE |
| S10 | PASS | `test_divination_borrows_only_the_restate_helper`, `test_divination_keeps_no_state`, `test_no_tier_imports_divination` and `test_main_names_the_synchronous_exceptions` all PASSED. grep finds no `def test_divination_imports_only_llm_prompts_chart_dictionary`. The six old self-checks are present. `DIVINATION_FORBIDDEN_RE` is byte-identical to 53af7d8 (`cmp` of the definition lines). **Planted for real:** appending `from app.interpretation.prompt import _LANG_INSTRUCTIONS` to render.py → test FAILED; appending the `_restate` import to turn.py → test FAILED. Both reverted with `git checkout`, and the test is green again. | TESTS/CODE (+ planted edits) |
| S11 | PASS | Current FINGERPRINT is `37324c3309a4a6dc`. dw-2's FINGERPRINT, computed independently in a detached 53af7d8 worktree (since removed), is `5c9f50cbc874475f`, so it differs. The fragment set includes chart.read, chart.none and side.refs. `test_s11_fingerprint_moved_and_persona_no_longer_disclaims_the_chart` pins that "have not read" is absent from venus.txt. | TESTS/CODE |
| C1 | PASS | `core-divination.test.ts` "streamTurn chartRefs (dw-3 C1)": refs pass through; a missing field gives `[]`; house, Chiron and quincunx items are dropped; the body carries the given `birthData` or `null`. | TESTS/CODE |
| C2 | PASS | Round-trip survives a fresh KV read. `[{kind:"house"}]`, `"x"` and `[]` read back with no `chartRefs` key. `toWire` has no `chartRefs`. | TESTS/CODE |
| C3 | PASS | app-native `architecture.test.ts` and `color-guard.test.ts` both walk `web-divination`, and both pass. The i18n parity tests pass, with `chat.refsLabel` and `chat.aspects` in en and zh. Root `npm test` and `npm run typecheck` exit 0. | TESTS/CODE |
| W1 | PASS | `ChatPanel.test.tsx` W1: body `birthData` deep-equals the saved record, then `null` after `clearBirthData()`. | TESTS/CODE (also seen on real app, A1) |
| W2 | PASS | W2 en: the list has aria-label "read in your chart", sits after the prose and holds 2 items in order. Item 1 has ♀ and "Venus"; item 2 has aria-label "Venus opposition Pluto" and contains ♀☍♇. W2 zh: 金星, and aria-label 金星冲冥王星. | TESTS/CODE |
| W3 | PASS | Empty refs → no list and nothing stored. A stopped reply → no list. A KV remount renders chips only on the entry that has the field. | TESTS/CODE (remount also on real app, A4) |
| W4 | PASS | No `button`, `[tabindex]`, `a`, `input` or `[role=button]` in the list. | TESTS/CODE (real app: 0 buttons/tabindex, li.tabIndex = -1 default) |
| A1 | PASS | The captured `POST http://localhost:8001/api/divination/turn` body has `birthData = {"date":"1990-06-15","time":"08:30","location":{"name":"Beijing","latitude":39.9075,"longitude":116.3972},"timezone":"Asia/Shanghai","schemaVersion":1}`, identical to the `/api/chart` request body. | REAL APP |
| A2 | PASS | The reply streamed (length grew 308→712→961 over successive polls). Each claim against the chart: "seventh house … opens in Capricorn" = 7th cusp Capricorn 28°04' ✓. "Saturn stands right at that doorway" = Saturn Capricorn 24°04', Saturn☍Ascendant in the aspect list, i.e. about 4° from the DSC ✓ (it does not claim Saturn is in H7). "Venus opposite Pluto" = Venus☍Pluto ✓. "Moon in Pisces in the eighth house" = Moon Pisces H8 ✓. It explains relevance (guarded partners read as seriousness, Pluto's pull, Moon filling in the silence). Nothing invented. | REAL APP |
| A3 | PASS | During streaming, polls show chips = 0. The list appeared only after streaming ended. Chips: planet Saturn, aspect Saturn\|opposition\|Ascendant, aspect Venus\|opposition\|Pluto, planet Moon. All four match `[data-planet]` / `[data-aspect-key]` elements (non-null). All four are named in the reply. The chip `border-top-color` is `rgba(211, 169, 79, 0.28)`, which equals `--line` resolved. | REAL APP |
| A4 | PASS | After reload, the last persona entry's prose text and chip texts are identical to before the reload: `["♄Saturn","♄☍↑Saturn–Ascendant","♀☍♇Venus–Pluto","☽Moon"]`. | REAL APP |
| A5 | PASS | Language 中, request `lang:"zh"` with the birth data. The reply is in Chinese. Claims: Sun and Mercury Gemini H11 ✓; 11th-house ruler is Venus (11th cusp Taurus) ✓; Venus Taurus H10 ✓; chart ruler Moon (Cancer Asc) ✓; Moon Pisces H8 ✓. The list is labelled 星盘所见, with chips 太阳, 水星, 金星, 月亮. | REAL APP |
| A6 | PASS | Fresh profile (localStorage cleared, no birth data). Request body has `birthData: null`. The reply opens "I haven't read your chart…", names no sign or placement, and has 0 chip lists (mood tag "candid" present). | REAL APP |
| A7 | PASS | Fixture re-entered with "I don't know my birth time" (request `time:null`). Partnership question: the reply cites Venus in Taurus, Venus trine Saturn ✓ and Venus opposite Pluto ✓. It names no house number and no rising sign, and says "your birth time is unknown, so I can't see your house of partnership". Chips: Venus, Venus–Saturn, Venus–Pluto, with no Ascendant. | REAL APP |

Notes (not failures): the city picker's Beijing coordinates (39.9075/116.3972)
differ slightly from the server fixture (39.9042/116.4074). A1 compares against
the entered birth as specified, and the chart facts above come from the app's
own chart for that entry.

Cleanup: both planted edits reverted (`git status --short` clean). The
temporary 53af7d8 worktree was removed. The Chrome tab was closed. The :8001
and :5173 servers were stopped, and `lsof` shows both free. :8000 (pid 34607)
and :5180 (pid 77138) were never touched.

ACCEPTANCE: PASS
