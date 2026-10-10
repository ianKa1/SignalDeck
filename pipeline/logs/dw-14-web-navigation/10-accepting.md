# dw-14-web-navigation — acceptance (fresh-context checker)

Code under test: `/Users/kaimao/Projects/astrology-wt/dw-14-web-navigation`, branch
`feature/dw-14-web-navigation`, HEAD `5f88215` (contains dw-15 via merge `0e17d38`).
Date: 2026-09-29.

## Suite totals

| Suite | Result |
|---|---|
| root `npm test` — app-native jest | 90 suites / 1078 tests passed |
| root `npm test` — web-divination vitest | 42 files / 386 tests passed; exit 0 |
| root `npm run typecheck` | exit 0 |
| `npm --workspace web-divination run build` | exit 0 (only the >500 kB chunk warning) |
| server `DATABASE_URL= conda run -n astrology pytest -q` | 1380 passed, 55 skipped, exit 0 |

## Verdicts

| ID | Verdict | Evidence | Kind |
|---|---|---|---|
| N1 | PASS | `nav/routes.test.ts` covers the full table: `/`, all six `/chat/<id>` from `PERSONA_IDS`, `/sessions`, `/sessions/s-1700000000000`; `/chat/pluto` gives notFound(persona); `/chat`, `/Chat/moon`, `/foo`, `/sessions/a/b` give notFound(path); the `pathFor∘parseRoute` round trip holds; `canonicalPath('/sessions/')==='/sessions'`, `canonicalPath('/sessions')===null`. Green. | test |
| N2 | PASS | `nav/Link.test.tsx`: a plain click gives pushState×1, `defaultPrevented` true, the route re-renders, harness mounts stay 1. Ctrl, Meta, Shift, Alt and button 1 are not prevented and push nothing. A same-path click pushes nothing. App-level S3: the masthead node is identical after a push (no App remount). Green. | test |
| N3 | PASS | `App.test.tsx` N3: a Moon plate click gives `/chat/moon`; `history.back()`+popstate renders Home; `forward()` renders Moon. Green. | test |
| N4 | PASS | `Link.test.tsx` useRoute N4: `/sessions/` becomes `/sessions` and `history.length` is unchanged. Green. | test |
| W1 | PASS | App W1: the "The six" heading is `<h2>` (HomeScreen.tsx:20). The six `/chat/*` hrefs are in roster order, Saturn alone has `.roster__last`, and there is no dialog, `.chat`, `svg.wheel` or stage. The path stays `/`. Green. | test |
| W2 | PASS | App W2: the form shows with no birth data. With birth data, `[data-birth-summary]` shows and Edit opens the form in place with the path still `/`. Green. | test |
| W3 | PASS | App W3: path `/chat/moon`, stage and `.chat` present, KV `moon`, title contains Moon, focus on the Moon heading. Green. | test |
| W4 | PASS | App W4: the Jupiter example link goes to `/chat/jupiter`, the composer holds the question, and `stream.calls` is 0. Green. | test |
| W5 | PASS | App W5: loops all seven paths. Each has a masthead `href="/"`, "Sessions · 1" `href="/sessions"` and Sign out. `aria-current` is on Home only at `/` and on Sessions only at `/sessions`, `/sessions/<id>` and `/sessions/s-0`. The path is unchanged. Green. | test |
| W6 | PASS | App W6: `/nowhere` shows the not-found line and "← The six" `href="/"`. `/chat/pluto` shows the persona line. `/sessions/s-0` shows the list (1 card), the missing line and a `/sessions` link. No path changes. Green. | test |
| W7 | PASS | App W7+W8: one card with `data-persona=moon` (ink via `persona-scope`), "In progress" and question "Will this pass?". It opens `/sessions/s-\d+`, the reader has both entries, and "Continue with Moon →" is `/chat/moon`. End was not pressed. Green. | test |
| W8 | PASS | App W7+W8 checks the same id at `/sessions/<id>`, failed on 503, both entries and Retry, "Sessions · 1", and that a new Moon message gives 2 records with a new id. The shipped test does not assert the intermediate *pending* state or the failed card *in the list*, so the checker added a temporary test (reverted): right after End the record has the same id, `state:'sealed'`, `summary.status:'pending'` (202 stub). With 503 the `.sessions__list .seal-card--failed` card is present and it is the only card. 2/2 green. | test (+ supplemental) |
| W9 | PASS | App W9: "Ask Saturn →" moves to `/chat/saturn`, the composer holds "Should I quit my job?", and 0 stream calls. Back returns to `/chat/venus` with the Venus heading and the transcript. Green. | test |
| W10 | PASS | App W10: `.chat__roster` is an `<A href="/">` reading "The six". `.log-bar` has no Sessions button or link. The body has no "← The chart". Green. | test |
| W11 | PASS | App W11: signed out at `/sessions/s-1000`, the gate shows and every fetch URL is under `/api/auth/`. The stubbed GIS credential renders that reader at the same path. At `/chat/moon`, Sign out shows the gate with the path unchanged. Green. | test |
| W12 | PASS | App W12 (zh): nav label, home link, "往来记录 · 0", not-found heading and home link, title, "In progress" (zh), "继续与月亮交谈 →", the missing-session line. `src/i18n.test.ts` parity is green in the full run. | test |
| C1 | PASS | core-session-log C1: one open record, `/^s-\d+$/`, moon, en, ISO startedAtUtc, entries equal the transcript. The second entry adds no record and entries become 2. The raw KV header has no `entries` key. Green. | test |
| C2 | PASS | C2: `listSessions()` is stable (`toBe`). A new array after `recordEntry`, and the subscriber is called at least once. Green. | test |
| C3 | PASS | C3: same id, sealed, same entries, ISO `endedAtUtc`, `{status:'pending'}`, empty transcript, no open record. The next entry gets a new open id at index 0. Green. | test |
| C4 | PASS | C4: a record with no `state` parses as `{...legacy, state:'sealed'}`. 503 and 502 loops leave it listed, failed, entries intact. Green. | test |
| C5 | PASS | C5: Moon open at 0 plus 49 sealed; `endSession('mars')` gives 50 records, Mars at index 0, Moon's id `s-moon` kept, `s-1…s-48` present, `s-49` gone. Green. | test |
| C6 | PASS | C6: one open Mars record; a second call adds none. Corrupt (moon) and empty (saturn) transcripts are not adopted. Green. | test |
| G1 | PASS | G16/G17 tests exist and pass. **Planted in real files:** `log/x.tsx` `history.pushState(null,'','/')`, `app/x.tsx` `window.location.pathname`, `chat/x.ts` `addEventListener('popstate', f)`: G16 failed listing exactly those 3 files. `chat/y.ts` `appendEntry(`: G17 failed listing it. **Does-not-bite plant** `birth-input/x.tsx` with `data.location.name`, `value?.location.name`, `{ location: initial.location }`: G16/G17 green. The in-suite self-check also covers unchanged birth-input sources. All plants removed. | planted guard |
| G2 | PASS (note) | test, typecheck and build all exit 0. Colour, text-variant and the existing web guards are green inside the full jest run. **Note:** `web-divination/package.json` `dependencies` differs from `8da99b2` by one key, `canvaskit-wasm` (0.41.0). It was added by the landed dw-15 (`8032e68`, the base branch), not by dw-14: `git log 8da99b2..HEAD -- web-divination/package.json` lists only 8032e68. dw-14's own changes add no dependency. Read literally against 8da99b2 this is a mismatch; its provenance is dw-15. | inspection |
| G3 | PASS | The worktree CLAUDE.md web-divination paragraph (lines 27–33) carries the spec's sentence verbatim. It claims only the global form (`history`/`location` bare or via `window.`/`globalThis.`, plus `popstate`). | inspection |
| R1 | PASS | Real Chrome at `/` with active=venus: 6 plates (venus…mercury), no wheel, stage or chat. Venus marked last. A reload stays on `/` with 6 plates. Screenshot `shots/r1-home.png`. | real app |
| R2 | PASS | A Moon click gives `/chat/moon` (title "Moon · Astrace"), `svg.wheel` and chat. Sent "Will this pass?". A real claude-cli reply streamed (`POST /api/divination/turn 200`). Masthead "Astrace" `/` link: `/`. CDP Back: `/chat/moon` with the user and persona entries. Forward: `/`. Back then reload: `/chat/moon` with the exchange and wheel, heading Moon. | real app |
| R3 | PASS | Home, then Sessions: `/sessions` with one Moon card, "Will this pass?", "In progress". Opened: `/sessions/s-1790712512015`, the reader has the exchange and "Continue with Moon →" `/chat/moon`. A reload shows the same. Back: `/sessions`. | real app |
| R4 | PASS | curl: the dev server answers 200 with the app HTML (`id="root"`) for all six URLs. Cold CDP navigation: `/sessions`, the R3 URL, `/chat/saturn` (Saturn chat), `/nowhere` ("No page by that name in this sky"), `/chat/pluto` ("No character by that name"), `/sessions/s-0` ("That session isn't on this device" + list). On each and on `/`, Sign out is visible and one masthead click reaches `/` (6 plates). | real app |
| R5 | PASS | At `/chat/moon`, End: the card is `seal-card--pending`, and the log is `s-1790712512015:sealed:pending`, the SAME id as R3. `/sessions` lists it; the card opens the same URL; the R3 URL still resolves. Sign out there: the gate shows, access token cleared, URL unchanged. Minted a second pair (same script) and wrote it with birth data, then reloaded: `/sessions/s-1790712512015` renders its reader (summary now ready). | real app |

## Real-app setup (recorded)

- **Ports.** The caller directed backend 8022 and Vite 5192, with `CORS_ALLOW_ORIGINS=http://localhost:5192`. The spec text names 8002/5175, which were reserved for other sessions. Vite's port and the CORS origin match, which is the invariant the spec requires.
- **Database.** Throwaway cluster from `~/miniconda3/envs/astrology/bin/initdb` under `scratchpad/acc14/pg`, started with `pg_ctl -o "-p 54352 -k '' -h 127.0.0.1"`, db `dw14`. The backend ran from the worktree WITHOUT `--env-file`: `DATABASE_URL=postgresql://astrace@127.0.0.1:54352/dw14 GOOGLE_CLIENT_ID=placeholder-dw14.apps.googleusercontent.com CORS_ALLOW_ORIGINS=http://localhost:5192 ANALYSIS_LLM=claude-cli python -m uvicorn app.main:app --app-dir server --port 8022 --host 127.0.0.1`. `ps eww` on the listener showed `DATABASE_URL=postgresql://astrace@127.0.0.1:54352/dw14` (host 127.0.0.1). `/api/health` returned `{"status":"ok","db":"ok","ephemeris":"ok"}`.
- **Vite.** `VITE_API_BASE=http://localhost:8022 VITE_GOOGLE_CLIENT_ID=placeholder… npx vite --port 5192 --strictPort` inside `web-divination`.
- **Sign-in.** `scratchpad/acc14/mint.py` asserts `urlparse(DATABASE_URL).hostname == "127.0.0.1"`, then calls `service._upsert_user(conn, "dw14-accept@example.com")` and `service._mint_bearer` through `app.db.connect()`. The pair was written to `astrace.auth.access/.refresh/.expiresAt`, together with `astrology.birthData.v1.traveler` (Beijing 1990-06-15 08:30), then the page was reloaded. R5 used a second pair minted the same way.
- **Browser.** Headless Chrome with `--remote-debugging-port=9232` and a fresh `--user-data-dir`, driven over raw CDP (`scratchpad/acc14/cdp.mjs`): `Page.navigate` for cold loads, `Page.reload`, `Page.navigateToHistoryEntry` for Back/Forward, and `Input.dispatchMouseEvent`/`insertText`/Enter for input.

## Cleanup

- Planted guard files and the temporary App.test.tsx cases were removed or reverted. The worktree `git status --short` is clean.
- Chrome, Vite (5192) and uvicorn (8022) were killed. The cluster was stopped with `pg_ctl stop` and deleted, along with the Chrome profile. Ports 9232, 5192, 8022 and 54352 are free.
- Nothing was committed.

ACCEPTANCE: PASS
