# dw-18-divination-auth — the divination routes need a signed-in web account

## Goal

Every web-only server route (`POST /api/divination/turn`, `/summary`, `/persona`, `/sheets`) requires a valid web bearer from dw-16's web database: 401 before any chart or LLM work, 503 when `WEB_DATABASE_URL` is unset. The web client sends the bearer and treats a 401 as signed out. QUEUE.md `dw-18-divination-auth` (user request 2026-09-29, before deploy); epic `pipeline/epics/divination-web.md`.

## Non-goals

- Native routes and every route native shares: `/api/chart`, `/api/transits*`, `/api/analysis*`, `/api/ask/fitness`, `/api/auth/*`, `/api/profiles`, `/api/health` stay exactly as they are. (`/api/chart` is also called by the web but is shared and does no LLM work.)
- Per-user quotas, rate limits on divination, billing, or usage accounting.
- Any identity inside `divination/`, any identity in a cache key, or a change to the turn/summary/persona/sheets wire bodies.
- Deploy work (Render env, CORS for a hosted origin).

## Decided defaults

1. **Where the check lives.** In the HTTP layer only. `accounts/web/routes.py` exports one FastAPI dependency, `require_web_account`, built on the existing `_caller` (`service.user_for` + `_parse_bearer`): 503 `web accounts unavailable` when the web door is dormant, 401 `not signed in` for a missing, malformed, expired or unknown bearer. `main.py` attaches it to the four divination routes as `dependencies=[Depends(require_web_account)]` — a decorator-level dependency whose return value no handler receives, so no identity can reach `divination/`, a job, a store or a cache key.
2. **Order.** FastAPI 0.139 parses the request body as JSON before it solves dependencies, but it runs the decorator dependency BEFORE it validates that JSON against the model, and before the handler. So: well-formed JSON with no valid bearer → 401/503 (even when it fails the schema); malformed JSON → 422 `json_invalid` from the framework — in every case before `_person` (chart work), the voice/summary store reads, `turn_available`, `ensure_*` enqueues or the stream opens. A cached summary or voice hit is ALSO refused without a bearer.
3. **Which routes.** Exactly the four `/api/divination/*` routes — the complete list of routes only web-divination calls (verified: the web tree and core's divination module name no other non-`/api/web` path except the shared `/api/chart`). A boundary test pins that EVERY route whose path starts with `/api/divination/` carries the dependency, so a fifth divination route cannot be added open.
4. **Client transport.** Core `platform` already has the bearer transport: `apiFetch` (`platform/api.ts`) adds `Authorization: Bearer` from the installed `AuthTokenProvider` and refreshes ONCE on a 401. `postJson` gains an options object as its 5th argument, `{auth?: boolean}`; with `auth: true` it sends through `apiFetch` (same timeout/abort composition) instead of bare `fetch`, and when the final answer is still 401 it calls `reportUnauthorized()`. A new `platform/auth.ts` pair `onUnauthorized(cb)` / `reportUnauthorized()` carries that signal. `streamTurn` sends the same header through the StreamPost port; on a 401 it releases the first response's chunks, refreshes once through the provider and retries; a final 401 yields `error {code:'unauthorized'}` (new `TurnErrorCode`) and reports. `summary.ts`, `persona.ts` and `roster.ts` (sheets) pass `{auth: true}` (with `undefined` for the timeout, or the plan may switch postJson's trailing parameters to one options object — its choice, callers identical). Native callers of `postJson` pass nothing and are byte-identical; `apiFetch`'s header comment is updated.
5. **401 means signed out.** `account/google-session.ts` subscribes to `onUnauthorized` at module load (it also loads on native through the `account` barrel, where nothing reports, so it is inert there): it clears the provider's tokens and sets `signed-out`, so the gate returns and dw-16's wipe of the owned cache runs. The chat shows no separate error for `unauthorized` (the gate replaces the screen); summary and persona treat it as a failure.
6. **Tests keep their meaning.** Existing divination route tests (and the uncollected prompt lab `server/tests/prompt_lab/divination_chat_lab.py`, which drives `/persona` and `/turn` through a TestClient) run under an autouse fixture (in those modules or conftest) that overrides `require_web_account` with a stub; the new auth tests run with no override. A test asserts the override is not installed globally for the auth module.
7. **Docs.** CLAUDE.md: the backend paragraph ("The gate is a UI gate: identity-free routes stay unauthenticated") becomes "the web's divination routes require a web bearer (dw-18); identity-free native routes stay unauthenticated"; rule 10's divination paragraph gains "its four routes are gated in main.py by `accounts/web`'s `require_web_account`; no identity enters the package"; rule 12's web paragraph names the gate. The epic's dependency rules gain the same line.

### Earlier decisions this revises

- 2026-09-28 · dw-12-google-sign-in · spec-review (choice (c): "chart and divination routes stay unauthenticated", "the forced sign-in is the user's product gate, not access control") — a loop decision, superseded by the user's request.
- The epic's forbidden edge "`divination/`, `chart/` and main.py's non-auth routes never read `Authorization` or call `session_user_id`" (dw-12 spec) — narrowed: `divination/` and `chart/` still never do; main.py's divination routes do, via the dependency.

## Architecture

Cites the epic and dw-16's `accounts/web` (see `docs/ARCHITECTURE.md`).

### Reuse (verified on 4a74364)

| Need | Existing | Use |
|---|---|---|
| Bearer → web user | `accounts/web/routes.py` `_caller` :115, `service.user_for` :102, `_UNAVAILABLE`/`_UNAUTHORIZED` :32-33 | Wrapped as `require_web_account`. |
| The four routes | `main.py` :447 turn, :488 summary, :515 persona, :548 sheets | Decorators gain the dependency; bodies unchanged. |
| Client POST | core `platform/poll.ts` `postJson` :31 | Gains `opts.auth`. |
| Stream | core `divination/turn.ts` `streamTurn` :50, `platform/stream.ts` port | Header + one refresh retry. |
| Provider / refresh | core `platform/auth.ts` `getAuthTokenProvider` :60; web `platform/auth.ts` single-flight refresh | Reused. |
| Signed-out transition | core `account/google-session.ts` `setSession`, provider `clear` | Subscribes to `onUnauthorized`. |

### Module map

```
server/app/accounts/web/routes.py   CHG  + require_web_account (public dependency)
server/app/main.py                  CHG  four divination decorators gain dependencies=[Depends(require_web_account)]
server/tests/test_divination_auth.py NEW  dormant 503, 401 cases, no chart/LLM work, valid bearer passes, route pin
server/tests/test_boundaries.py     CHG  + every /api/divination/* route carries the dependency (+ self-check);
                                          divination/ still imports no accounts
server/tests/(divination route tests) CHG autouse override fixture
server/tests/prompt_lab/divination_chat_lab.py CHG dependency override stub
packages/core/src/platform/auth.ts  CHG  + onUnauthorized / reportUnauthorized
packages/core/src/platform/poll.ts  CHG  postJson opts.auth (bearer, one refresh, report)
packages/core/src/platform/index.ts CHG  exports
packages/core/src/divination/{turn,types,summary,persona,roster}.ts CHG  auth on; 'unauthorized' code
packages/core/src/account/google-session.ts CHG  onUnauthorized → clear + signed-out
web-divination/src/chat/useChat.ts  CHG  only if the new error code needs a no-op branch
CLAUDE.md, pipeline epic            CHG  per D7
```

### Contracts and forbidden edges

- `require_web_account(authorization: str | None = Header(default=None)) -> None` raises 503/401 or returns None.
- ❌ No handler under `/api/divination/` takes a user parameter; ❌ `divination/` imports nothing from `accounts`; ❌ the token or user id never reaches `generation`, a store or a key function.
- ❌ Core `divination` never imports `account` (the signed-out signal travels through `platform`).
- Native `postJson` callers pass no `opts`; the no-`auth` path is byte-identical.

## Acceptance Criteria

Suites: `npm run server:test`, `npm test`, `npm run typecheck`. Every backend/pytest run sets `DATABASE_URL` and `WEB_DATABASE_URL` explicitly (local or empty); live tests use `TEST_WEB_DATABASE_URL` on a throwaway local cluster (a skip is not a pass).

**Server**
- **S1 (dormant)**: with the web door dormant, each of the four routes with a valid body → 503 `web accounts unavailable`; spies on `_person`, `divination_turn.turn_events`, `generation.ensure_divination_summary`, `generation.ensure_divination_voice`, `summary_topic.cached_summary`, `persona_voice.cached_voice`, `persona_voice.cached_for` and `llm.stream_turn` record ZERO calls.
- **S2 (401)**: web door configured (live-WEB), for each route: no header, `Bearer ` empty, `Basic x`, an unknown token, an expired token, and a main-db (native) access token → 401 `not signed in`, with the same zero-call spies; a well-formed JSON body that fails the schema (`{}`) without a bearer → 401 (not 422); malformed JSON without a bearer → 422 with the same zero-call spies.
- **S3 (cache hit still gated)**: with a summary and a voice stored for the request, `/summary` and `/persona` without a bearer → 401, and the stored rows are not read (spy).
- **S4 (valid bearer)**: live-WEB, a minted web pair: `/sheets` → 200 with six sheets; `/persona` → 200/202; `/summary` → 200/202; `/turn` (fake `stream_turn`) → 200 `text/event-stream` with `delta … done`. Byte-identical bodies to the same requests with the dependency overridden.
- **S5 (pin)**: a boundary test lists every `app.routes` path starting `/api/divination/` (exactly the four) and asserts each has `require_web_account` among its dependencies; it goes red on a planted route without it. `/api/chart`, `/api/ask/fitness` and `/api/auth/whoami` do NOT carry it.
- **S6 (no identity flows)**: the four handler signatures contain no parameter besides the request body (and `response`); `divination/` imports nothing from `accounts` (existing guard still green).

**Core + web (vitest)**
- **C1**: `postJson(..., {auth:true})` sends `Authorization: Bearer <access>`; without `opts` no Authorization header is sent (native path unchanged).
- **C2**: a 401 then refresh 200 then 200 → one retry with the rotated token; 401, refresh fails → `reportUnauthorized` fires once, the tokens are cleared and the Google session is `signed-out`.
- **C3**: `streamTurn` sends the bearer; a final 401 yields `{type:'error', code:'unauthorized'}` and reports; a 200 stream parses as before.
- **C4**: `fetchSummary`, `fetchPersona` and `fetchSheets` requests carry the bearer.
- **C5**: in the app, a divination 401 returns the screen to the sign-in gate and the owned cache is wiped: `astrology.birthData.v1.traveler`, the six `astrology.divination.transcript.v1.<id>`, `astrology.divination.sessions.v1`, `astrology.divination.active.v1`, `astrology.web.dirty.v1` and `astrology.web.owner.v1` are absent.
- **G1**: architecture/colour/text guards green; `npm test` + typecheck green; CLAUDE.md and epic amendments of D7 present.

**Real app** (local backend from the worktree with `WEB_DATABASE_URL` on a local db, never the Neon URLs; a minted web pair in a headless browser)
- **R1**: `curl` each of the four routes with a valid body and no header → 401 (web db set) and, on a second backend with `WEB_DATABASE_URL=` empty, 503; the backend log shows no chart computation or claude-cli spawn for them (no `divination` log lines, no child process).
- **R2**: the signed-in web app works as before: the picker's sheets load, a character's card/greeting loads, one reply streams and is saved, End session produces a summary card — every divination request in the network log carries `Authorization`.
- **R3**: deleting the browser's access and refresh rows in the web db, then sending a message → the app returns to the sign-in gate.
