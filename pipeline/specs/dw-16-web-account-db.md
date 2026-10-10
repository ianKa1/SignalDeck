# dw-16-web-account-db — the web app's data belongs to the account, in its own database

## Goal

web-divination's identity, birth profile and chats move into a SEPARATE web-only Postgres (`WEB_DATABASE_URL`). A signed-in user sees the same chats and birth data in any browser; the browser copy is only a cache. QUEUE.md `dw-16-web-account-db` (tier-1 user rulings 2026-09-29); epic `pipeline/epics/divination-web.md`.

## Non-goals

- Any change to `app-native/` or to the native/main-db auth routes (`/api/auth/*` keep their behaviour; only the dw-12 Google route leaves them, see D2).
- Server-side conversation state in `divination/`. The turn, summary, persona and sheets routes stay unauthenticated, identity-free and stateless; rule 9's caches (summary, voice) stay in the main db.
- Merging web and native identities. The same email on both is two accounts (ruling 1).
- Real-time sync between two open browsers (no push channel, no polling). A browser sees another browser's chats at its next boot or sign-in.
- Server paging of the session list, a server-side cap, retention expiry, export.
- Hosting or a Render change. The hosted Neon `WEB_DATABASE_URL` (already in the root `.env`) is the deploy-time value, set in the Render dashboard, and is NOT used before this feature lands; its value is written nowhere.
- Journal writes. Chat and profile saves write NO journal event (rule 6).

## Decided defaults

1. **Two databases, one owner.** `app/db` stays the only psycopg importer (rule 11) and owns both URLs. `DATABASE_URL` → the main db, unchanged. `WEB_DATABASE_URL` → the web db, through a second door (`web_is_configured`, `connect_web`, `web_health`, `apply_web_migrations`) with its own folder `server/app/db/web_migrations/` and its own ledger table `web_schema_migrations`. Every web table is prefixed `web_`, so even a misconfiguration that points both URLs at one database cannot mix schemas; and if the two URLs are byte-identical the web door stays DORMANT and startup logs one warning. Startup applies pending web migrations when the web db is configured. `/api/health` gains an additive `webDb` field (`unconfigured|ok|error`).
2. **Dormancy.** With `WEB_DATABASE_URL` unset every `/api/web/*` route answers the generic 503 `web accounts unavailable` and nothing else changes: the main-db auth routes, chart, divination and every other route behave exactly as before. dw-12's `POST /api/auth/google` and `accounts/service.sign_in_google` are REMOVED (the Google sign-in moves to the web db); native never called them.
3. **Web schema** (migration `001_web_accounts.sql`): `web_users(id uuid PK, email citext UNIQUE, created_at)`; `web_access_tokens` and `web_refresh_tokens(token_hash PK, user_id FK ON DELETE CASCADE, created_at, expires_at)` — sha256 only, same 7-day/60-day TTLs as native; `web_birth_profiles(user_id PK FK CASCADE, birth_data jsonb, updated_at)`; `web_sessions(user_id FK CASCADE, id text, persona, lang, state CHECK open|sealed, started_at NULL, ended_at NULL, entries jsonb, summary jsonb NULL, updated_at, PRIMARY KEY (user_id, id))`. The key is (user_id, id) because ids are client-generated (`s-<ms>`) and may collide across accounts; every read and write names `user_id = <caller>`, so only the owner can reach a row.
4. **Web auth routes** (`/api/web/auth/*`), same bodies as dw-12's:
   - `POST /google {credential}` → verify with the existing `accounts/google.py`, upsert `web_users` by email, mint a pair → 200 `{email, accountId, accessToken, refreshToken, accessExpiresAt}`; 401 rejected; 503 without the web db, `GOOGLE_CLIENT_ID` or Google's certs; 422 empty/oversize.
   - `POST /token/refresh {refreshToken}` → single-use rotation (same per-token rate gate shape) → 200 triple / 401 / 429 / 503.
   - `GET /whoami` → 200 `{email, accountId}` / 401 / 503.
   - `POST /logout {refreshToken?}` → 204, revokes the access and refresh rows presented.
   - `DELETE /api/web/account` → 204; cascades every web row of the caller; 401 unauthenticated.
   `accountId` is the opaque `web_users.id`; it is the browser cache's owner marker (D8), never PII.
5. **Web data routes** (bearer required; 401 otherwise):
   - `GET /api/web/profile` → `{birthData: BirthData|null}`. `PUT /api/web/profile {birthData: BirthData|null}` → 204 (null deletes the row). BirthData is validated by `models.BirthData` (the `/api/chart` model; 422 on a bad value) and stored as sent.
   - `GET /api/web/sessions` → `{sessions: [record…]}`, every row of the caller (no cap), `started_at` DESC NULLS LAST then `updated_at` DESC. Record = `{id, persona, lang, state, startedAtUtc|null, endedAtUtc|null, entries, summary|null, updatedAtUtc}`.
   - `PUT /api/web/sessions/{id}` with the record minus `updatedAtUtc` → 204, idempotent upsert on (caller, id); last writer wins. id `^[A-Za-z0-9_-]{1,64}$`; persona one of the six; lang en|zh; `sealed` needs `endedAtUtc`; entries 1–2000 objects each with role user|persona and a non-empty text ≤ 20,000 chars (other entry fields kept verbatim); summary is `{status:'pending'|'failed'|'ready', …}` or null. Anything else → 422.
   - `DELETE /api/web/sessions/{id}` → 204, or 404 when the caller has no such row.
6. **Privacy.** The web db holds email, the birth profile and chat transcripts, all account-owned and deleted with the account. Tokens are sha256 at rest; Google's `sub` is never stored. No web module logs a transcript, a birth profile, a credential or a token (source scan + caplog test). The per-user code lives in a new accounts-side package `server/app/accounts/web/`, never in `divination/`.
7. **When the client saves.** The turn route stays stateless. The client PUTs a session record whenever that record changes in the browser log — in practice when the user's line is recorded, when each reply (finished or stopped) lands, at End (sealed, summary pending) and when the summary outcome lands. Saves are serialized and coalesced per record (~300 ms). The device-only summary `cause` is stripped before sending. A save that fails keeps the record in a persisted dirty set (KV) and is retried on the next change and at the next boot, BEFORE the pull. Deletion is always explicit (a tombstone in the dirty set), never inferred from a record vanishing locally.
8. **The browser copy is a cache, owned by one account.** KV key `astrology.web.owner.v1` holds the `accountId` whose data the cache holds. On sign-in or restore:
   - owner = this account → flush dirty saves, then pull and REPLACE the local birth data, transcripts, session log and owner;
   - owner = another account → wipe the local copy silently, then pull;
   - no owner and no local account data → set owner, pull;
   - no owner but local data from before accounts (birth data, any transcript or session record) → ask ONCE (D9).
   While this runs the gate shows "Opening your sky…". If the pull fails but the cache already belongs to this account, the app opens on the cache; otherwise the gate shows "Couldn't load your account — Try again".
9. **Import once.** The gate card asks: eyebrow "This browser remembers"; title "Bring these into your account?"; body "This browser holds {n} conversations and a birth chart from before you signed in to {email}."; buttons **Import** and **Discard**. Import → PUT the local birth data only when the account has none (the account's wins), PUT every local session record, then pull. Discard → wipe the local copy, then pull. Either answer sets the owner, so the question never returns for this browser and account. Pressing neither leaves the app closed (the gate stays).
10. **Pulling.** Pulled sessions replace the log: sealed rows become sealed records; for each character the most recently updated OPEN row becomes its live transcript and open record (same id); any older open row for that character is sealed locally with `endedAtUtc = updatedAtUtc`, summary `pending`, and saved back — exactly what End would have done, so the one-open-per-character invariant of dw-14 holds. Pending summaries resume as today. The pulled profile is written with the existing store (validated); pull writes never trigger saves.
11. **Sign-out clears the cache.** Explicit sign-out, a dead pair at restore and account deletion remove the browser copy: the traveler birth data, the six transcripts, the session log, the active character, the dirty set and the owner. Language and theme stay. Legacy data with NO owner is never wiped by a restore failure (it is kept for the import question). A different account on the same browser therefore sees only its own data.
12. **No cap in the account cache.** Since the server keeps every chat, the browser log no longer evicts (dw-6's 50-record cap is removed). Risk accepted: a very long history could exceed localStorage's quota; a failed write is swallowed as today.
13. **Delete controls.** Each session in the Sessions reader gets a quiet "Delete" text button; a confirm step ("Delete this conversation? It is removed from your account on every browser." — Delete / Keep) guards it. Deleting an open session also clears that character's live transcript. The account chip gains "Delete account" beneath Sign out in a small popover-free inline confirm ("Delete your account and all its chats? This cannot be undone." — Delete account / Keep); on 204 the cache is wiped and the gate returns.
14. **Stale dw-12 tokens.** Tokens a browser stored under dw-12 belong to the main db; the web routes answer them 401, the refresh fails, and the user signs in once more. No migration of main-db web users: the main db is left untouched (its dw-12 rows remain as they are).
15. **Design.** No new colour tokens; the import card reuses the dw-12 threshold card (panel, hairline, eyebrow, display title, one body line, twelve-tick ring). Import is the filled pill action, Discard a text button; delete confirms are inline text rows in `text-dim` with the destructive word in `voice`. Reduced motion: no fades.
16. **Test hermeticity.** `server/tests/conftest.py` pops `WEB_DATABASE_URL` at import. Live web-db tests are guarded on `TEST_WEB_DATABASE_URL`, which a fixture copies into `WEB_DATABASE_URL`, and they refuse any host other than `127.0.0.1`/`localhost`. Every backend run for validation sets `DATABASE_URL` and `WEB_DATABASE_URL` explicitly in the shell (local cluster or empty); the Neon URLs in `.env` are never contacted. Real-app checks use the dev cluster (`server/data/dev-pg`, 127.0.0.1:54320) with a new database `astrace_web`.
17. **Docs.** CLAUDE.md: rule 11 (two URLs, two migration folders, the web door's one importer), rule 12 (rewritten: main db — email is the only PII; web db — email + birth profile + transcripts, account-owned, cascade-deleted, never logged; Google sign-in now on `/api/web/auth/google`), rule 6 (chat saves write no journal events), the backend and Commands paragraphs (`WEB_DATABASE_URL`, local `astrace_web`, the hosted value set in the Render dashboard at deploy), and the dw-12 sentence "chat, logs and caches stay device-local" replaced. `.env.example` gains a commented `WEB_DATABASE_URL`.

### Earlier decisions this revises

- 2026-09-28 · dw-12-google-sign-in · spec-review (choice (a) Google on the main db via `_upsert_user`/`_mint_bearer`; choice (e) "birth data, transcript and session log survive sign-in/out") — overturned by user ruling (tier 1). The dw-12 user ruling entry's scoped default "Chat, logs and caches stay identity-free and device-local" is Claude's intake default, superseded by this ruling.
- 2026-09-28 · dw-6-session-log · spec-review — the 50-record cap and "session log is device-local" (loop decisions).
- CLAUDE.md rule 12's "email is the ONLY PII" for the web tree, and the epic dependency rule "no session table and nothing keyed by user" (narrowed to `divination/`).

## Architecture

Cites `pipeline/epics/divination-web.md` (rulings, reuse map, dependency rules). The epic has no accounts section; dw-16's reuse was verified by targeted reads on 2e6cfe8. Only the modules dw-16 creates or changes are covered.

### Reuse (verified)

| Need | Existing | Use |
|---|---|---|
| Lazy psycopg door, dormancy | `db/__init__.py` `_url` :27, `connect` :35, `health` :47, `apply_migrations` :59 | Mirrored for the web URL (same idiom: URL read at call time, short-lived connection). |
| Migration runner | `db/migrations.py` `apply_pending` :26 (ledger `schema_migrations`, one tx per file) | Parametrized by directory and ledger name; main call byte-identical. |
| Google verification | `accounts/google.py` `verified_email` :99 (sole google-auth importer, cached certs) | Reused unchanged; its app importer moves from `accounts/service.py` to `accounts/web/service.py`. |
| Tokens | `accounts/tokens.py` `new_token`, `hash_token`, `access_expiry`, `refresh_expiry` | Reused; no new token kind. |
| Refresh rate gate | `accounts/ratelimit.py` `SlidingWindow`, `REFRESH_PER_TOKEN`; `routes._REFRESH_GATE` :62 | A second gate instance for the web refresh route. |
| Bearer parsing | `accounts/routes._parse_bearer` :71 | Imported by `accounts/web/routes.py` (same package family). |
| BirthData validation | `models.BirthData` :44 (the `/api/chart` model) | The profile PUT body. |
| Route shapes to retire | `service.sign_in_google` :144, `routes.post_google` :243 + `GoogleBody` | Deleted; the web route copies their body shape. |
| Bearer client | core `platform/api.ts` `apiFetch` :39; web `platform/auth.ts` `webTokenStore` (plain-fetch refresh, single-flight) | Kept; only the refresh URL changes. |
| Session channel | core `account/google-session.ts` (restore/sign-in/sign-out, status channel) | Endpoints move to `/api/web/auth/*`; gains `accountId` and `deleteGoogleAccount`. |
| Session log | core `divination/session-log.ts` `listSessions`, `subscribeSessions`, `recordEntry`, `endSession`, `resumeSummaries`, `write` (cap at :188) | The save scheduler diffs `listSessions()`; the cap is removed; hydrate/delete/clear functions are added here (one owner of the log's KV shape). |
| Transcript | core `divination/transcript.ts` | Gains `replaceTranscript` for hydrate. |
| Birth data | core `birth-data/store.ts` `saveBirthData`, `clearBirthData`, `subscribe` | Pull writes, wipe, and the profile save trigger. |
| Gate | web `auth/AuthGate.tsx`, `SignInScreen.tsx` threshold card | The new states and the import card reuse the threshold card. |
| Live-PG recipe | `tests/test_auth_integration.py` :1-12 | For the live-WEB suite (throwaway cluster). |

### Module map (created or changed only)

```
server/app/
├── db/__init__.py            CHG  + web door: web_is_configured, connect_web, web_health, apply_web_migrations
├── db/migrations.py          CHG  apply_pending(conn, directory=MIGRATIONS_DIR, ledger="schema_migrations")
├── db/web_migrations/        NEW  001_web_accounts.sql (five web_ tables)
├── accounts/web/             NEW  the web account package (per-user web data lives ONLY here)
│   ├── __init__.py
│   ├── service.py            NEW  auth over web_users/web_access_tokens/web_refresh_tokens; WebUnavailable
│   ├── data.py               NEW  profile + sessions SQL, always WHERE user_id = caller
│   └── routes.py             NEW  web_router (/api/web/auth/*, /api/web/account, /api/web/profile, /api/web/sessions)
├── accounts/service.py       CHG  − sign_in_google, − google import
├── accounts/routes.py        CHG  − POST /api/auth/google, − GoogleBody
├── accounts/google.py        CHG  docstring: its one importer is accounts/web/service.py
└── main.py                   CHG  include web_router; lifespan applies web migrations; health + webDb
server/tests/
├── conftest.py               CHG  pop WEB_DATABASE_URL at import
├── test_google_auth.py       CHG  route tests retarget /api/web/auth/google (claim-policy tests unchanged)
├── test_web_accounts.py      NEW  dormancy, validation, fake-db-free tests (D1, A4, S6, S7 scan)
├── test_web_accounts_live.py NEW  TEST_WEB_DATABASE_URL-guarded (D2, D3, A1–A3, S1–S5, S7 caplog)
└── test_boundaries.py        CHG  + B1–B4 tests (appended)
packages/core/
├── package.json              CHG  + "./web-account" export
└── src/
    ├── account/google-session.ts  CHG  /api/web/auth/*; GoogleSession.accountId; deleteGoogleAccount()
    ├── divination/session-log.ts  CHG  − cap; + replaceSessions, deleteSession, clearSessions
    ├── divination/transcript.ts   CHG  + replaceTranscript
    └── web-account/               NEW  cloud.ts (wire client), cache.ts (owner/dirty/wipe/legacy),
                                        sync.ts (status channel, pull, import, save scheduler), index.ts
web-divination/src/
├── platform/auth.ts          CHG  refresh → /api/web/auth/token/refresh
├── session.ts                CHG  installWebAccount() after ensureLocalProfile()
├── auth/AuthGate.tsx         CHG  opens only when session signed-in AND account data ready
├── auth/ImportCard.tsx       NEW  the import-once question (threshold card)
├── auth/useAccountData.ts    NEW  useSyncExternalStore over the web-account channel
├── auth/AccountChip.tsx      CHG  + Delete account inline confirm
├── log/SessionsScreen.tsx    CHG  reader: Delete + inline confirm
├── log/useSessions.ts        CHG  + remove(id) via web-account deleteSessionEverywhere
└── i18n/en.ts, zh.ts         CHG  auth.* (sync/import/delete account) and log.* (delete) keys
CLAUDE.md, .env.example, app-native/src/architecture.test.ts (only if a guard needs the new barrel)
```

### Module contracts

**`db` (web door).** `web_is_configured()` is True iff `WEB_DATABASE_URL` is non-empty AND differs from `DATABASE_URL`. `connect_web()` raises `DBNotConfigured` otherwise; `web_health()` never raises; `apply_web_migrations()` runs `apply_pending(conn, WEB_MIGRATIONS_DIR, "web_schema_migrations")`. `migration_files()` keeps listing only the main folder.

**`accounts/web/service.py`.** `WebUnavailable`; `_require_web()`; `sign_in_google(credential) -> (email, account_id, access, refresh, expires) | None` (require FIRST, then `verified_email`, unconfigured/unavailable → `WebUnavailable`); `refresh_access(raw)`; `user_for(access_raw) -> (user_id, email) | None`; `logout(access_raw, refresh_raw)`; `delete_account(access_raw) -> bool`. Opportunistic expired-row cleanup as native. Only `db.connect_web`, never `db.connect`.

**`accounts/web/data.py`.** `get_profile(uid)`, `put_profile(uid, birth_data|None)`, `list_sessions(uid)`, `put_session(uid, record)` (INSERT … ON CONFLICT (user_id, id) DO UPDATE, `updated_at = now()`), `delete_session(uid, id) -> bool`. Every statement binds `user_id`. No logging.

**`accounts/web/routes.py`.** One `APIRouter(prefix="/api/web")`. Pydantic bodies implement D5's limits. `WebUnavailable` → 503 `web accounts unavailable`, checked before authentication; a missing/invalid bearer → 401. No cookies.

**core `web-account/`** (React-free; imports `../platform`, `../account`, `../divination`, `../birth-data`; never imported by `account`, `divination` or `birth-data`).
- `cloud.ts`: `getProfile`, `putProfile`, `listSessions`, `putSession`, `deleteSession`, all over `apiFetch`, returning typed outcomes (`ok | unauthorized | unavailable | error`) and parsing records with the session-log's parser.
- `cache.ts`: `OWNER_KEY` (`astrology.web.owner.v1`), `DIRTY_KEY` (`astrology.web.dirty.v1`, `{profile, sessions[], deleted[]}`), `hasLegacyData()`, `legacyCount()`, `wipeCache()` (D11 key list; language/theme untouched).
- `sync.ts`: `AccountData = {status: 'idle'|'syncing'|'asking'|'ready'|'error', pending: {count} | null}`; `getAccountData`, `subscribeAccountData`, `installWebAccount()` (idempotent; subscribes to the Google session: signed-in → `open(accountId)`, signed-out → wipe if owned), `answerImport(yes)`, `retryAccountData()`, `deleteSessionEverywhere(id)`. The save scheduler subscribes to `subscribeSessions` and birth-data `subscribe`, diffs against the last-sent JSON per id (seeded by the pull, so a pull never re-PUTs), coalesces 300 ms, one request in flight per id, and records failures in the dirty set. Suppressed while a pull or wipe is writing.

**core `divination/session-log.ts` additions.** `replaceSessions(records: SessionRecord[])` writes sealed records and open headers and sets each open record's transcript (via `replaceTranscript`), dropping every other transcript; `deleteSession(id)` removes a record (and clears the transcript of an open one); `clearSessions()` removes the log and all six transcripts. Open-per-persona and parsing rules unchanged.

**core `account/google-session.ts`.** `GoogleSession = {status, email, accountId}`; restore/sign-in read `accountId` (a missing one is treated as `unavailable`); `deleteGoogleAccount(): Promise<'ok'|'error'>` DELETEs `/api/web/account`, and on 204 clears the tokens and sets `signed-out`. Still imports only `../platform` and `./types`.

**web.** `AuthGate` renders children only for `signed-in` + `ready`; `syncing` → the threshold card with "Opening your sky…"; `asking` → `ImportCard`; `error` → message + Try again. `installWebAccount()` runs in `session.ts`, before any component. Web code never calls session-log's `deleteSession` directly (only `deleteSessionEverywhere`).

### Wire

| Route | Auth | Success | Errors |
|---|---|---|---|
| `POST /api/web/auth/google` `{credential}` | — | 200 `{email, accountId, accessToken, refreshToken, accessExpiresAt}` | 401, 422, 503 |
| `POST /api/web/auth/token/refresh` `{refreshToken}` | — | 200 `{accessToken, refreshToken, accessExpiresAt}` | 401, 429, 503 |
| `GET /api/web/auth/whoami` | bearer | 200 `{email, accountId}` | 401, 503 |
| `POST /api/web/auth/logout` `{refreshToken?}` | bearer | 204 | 503 |
| `DELETE /api/web/account` | bearer | 204 | 401, 503 |
| `GET /api/web/profile` | bearer | 200 `{birthData}` | 401, 503 |
| `PUT /api/web/profile` `{birthData\|null}` | bearer | 204 | 401, 422, 503 |
| `GET /api/web/sessions` | bearer | 200 `{sessions:[…]}` | 401, 503 |
| `PUT /api/web/sessions/{id}` record | bearer | 204 | 401, 422, 503 |
| `DELETE /api/web/sessions/{id}` | bearer | 204 | 401, 404, 503 |

`/api/health` adds `webDb`. `/api/auth/google` is removed; every other `/api/auth/*` and `/api/profiles` route is unchanged.

### Dependency rules and forbidden edges

- ❌ Nothing outside `db/` imports psycopg (unchanged). ❌ Only `accounts/web/` (and `main.py` for wiring) names the web door; `accounts/web/` never uses the main door.
- ❌ `accounts/web/` imports none of: divination, interpretation, cards, chart, dictionary, selection, journal, jobs, generation, llm. It may import `db`, `accounts.google`, `accounts.tokens`, `accounts.ratelimit`, `accounts.routes._parse_bearer`, `models`.
- ❌ `divination/` never imports `accounts` (it stays stateless; epic rule narrowed: "no session table and nothing keyed by user" applies to `divination/`).
- ❌ No web SQL names a non-`web_` table; no main migration names a `web_` table.
- ❌ Core `account`, `divination`, `birth-data` never import `web-account` (one-way). Web imports it only through `@astrace/core/web-account`.
- Web network doors stay in `src/platform/` (G3); the new core module does the fetching.

### CLAUDE.md and guard amendments (same commit)

- Backend paragraph: web-divination's accounts, birth profile and chats live in the web db (`WEB_DATABASE_URL`); the browser copy is a cache cleared at sign-out; the turn route stays stateless. Replaces dw-12's "chat, logs and caches stay device-local".
- Commands: `WEB_DATABASE_URL` (local: `postgresql://astrace@127.0.0.1:54320/astrace_web`; deploy: the hosted value set in the Render dashboard; tests: `TEST_WEB_DATABASE_URL`, local hosts only).
- Rule 6: "web chat and profile saves write NO journal event; `accounts/web/` never imports the journal."
- Rule 11: two URLs, two migration folders and ledgers, `web_` table prefix, the web door's one consumer package; dormancy for each URL independently.
- Rule 12: rewritten per D17; the Google paragraph moves to `/api/web/auth/google` + `web_users`.
- Rule 3: google-auth's one importer unchanged; its app importer is `accounts/web/service.py`.
- Guards: `test_boundaries.py` B1–B4 (each with a planted self-check). The jest barrel-consumption guard needs every new `web-account` barrel export consumed by the web tree (no guard edit expected).

### Earlier decisions superseded

Listed under Decided defaults ("Earlier decisions this revises"); the journal entry at spec approval carries the verbatim **Supersedes** headings.

## Acceptance Criteria

Server tests use a fake Google verifier (monkeypatched `app.accounts.google._verify_token`). "Live-WEB" tests need `TEST_WEB_DATABASE_URL` pointing at a throwaway local cluster; a skip is not a pass. Suites: `npm run server:test`, `npm test`, `npm run typecheck`. **[USER-INPUT]** marks what needs the user's live Google sign-in.

**Server — database layer**
- **D1**: With `WEB_DATABASE_URL` unset: `web_is_configured()` is False, `connect_web()` raises `DBNotConfigured`, `/api/health` has `webDb: "unconfigured"`, and every `/api/web/*` route (the 5 auth/account routes and 5 data routes) answers 503 `web accounts unavailable` — a fake verifier is never called. With `WEB_DATABASE_URL` equal to `DATABASE_URL` the web door is also unconfigured.
- **D2 (live-WEB)**: `apply_web_migrations()` on an empty db creates exactly the five `web_*` tables and `web_schema_migrations`, and a second call applies nothing. The main migration runner's result is unchanged, and `migration_files()` lists no web file.
- **D3 (live, two clusters or two dbs)**: With both URLs set to two distinct local databases, a full web sign-in + profile PUT + session PUT leaves the main db's table list and row counts byte-identical before/after.

**Server — auth**
- **A1 (live-WEB)**: fake verifier email `Dw16.Tester@Example.com`, sub sentinel → `POST /api/web/auth/google` 200 with email, a uuid `accountId`, 43-char tokens, parseable expiry; `whoami` with the bearer → the email and the same accountId; refresh → new pair, the old refresh → 401; logout → whoami 401 and refresh 401.
- **A2 (live-WEB)**: signing in again as `dw16.tester@example.com` yields ONE `web_users` row; a dump of every text/jsonb column of the web db contains neither the sub sentinel, the credential nor a raw token; token columns are 64-hex.
- **A3**: a main-db (native) access token is 401 on `/api/web/auth/whoami`, and a web access token is 401 on `/api/auth/whoami` and `/api/profiles` (live, both dbs).
- **A4**: `POST /api/auth/google` is gone (404/405) and `accounts/service.py` has no `sign_in_google`; the native auth suites still pass unchanged.

**Server — data**
- **S1 (live-WEB)**: `GET /api/web/profile` → `{birthData:null}`; PUT a valid BirthData → 204; GET returns it; PUT `null` → GET null; PUT `{"date":"1990-13-40",…}` → 422.
- **S2 (live-WEB)**: PUT open record `s-1` (2 entries) → 204; PUT again with 4 entries → one row with 4 entries; PUT sealed with summary `{status:"ready",…}` → GET shows `state:"sealed"`, `endedAtUtc`, the summary and a later `updatedAtUtc`; entries' extra fields (`dice`, `chartRefs`, `mood`) round-trip verbatim.
- **S3 (live-WEB)**: 60 records PUT → GET returns 60, ordered by started_at DESC.
- **S4 (live-WEB, isolation)**: users U and V both PUT `s-1`; each GET sees only its own; V's DELETE of U-only id `s-9` → 404 and U's row survives; unauthenticated → 401 on all five data routes.
- **S5 (live-WEB, cascade)**: `DELETE /api/web/account` → 204; that user's profile, sessions, tokens and user rows are gone; the other user's rows remain.
- **S6**: 422 for: bad id (`../x`, 65 chars), unknown persona, lang `fr`, sealed without `endedAtUtc`, 0 entries, 2001 entries, an entry with role `system`, an empty text, a 20,001-char text, summary status `done`.
- **S7 (no logging)**: driving S2 with caplog at DEBUG captures no entry text sentinel and no birth-data city; a source scan of `accounts/web/` finds no log/print call naming `entries`, `birth`, `body`, `credential` or a token.

**Server — boundaries** (`test_boundaries.py`)
- **B1**: `psycopg` still only under `db/`. `connect_web`/`web_is_configured`/`apply_web_migrations` are named only in `db/`, `accounts/web/` and `main.py`; `accounts/web/` never names `db.connect(` or `db.is_configured(`. Bites on a planted `db.connect_web(` in `divination/turn.py`.
- **B2**: every `CREATE TABLE` in `db/web_migrations/` names a `web_` table, no main migration names one, and `accounts/web/` SQL names only `web_` tables. Bites on a planted `INSERT INTO users` in `accounts/web/`.
- **B3**: `accounts/web/` imports nothing from divination, interpretation, cards, chart, dictionary, selection, journal, jobs, generation or llm; `divination/` imports nothing from accounts; existing `test_divination_keeps_no_state` passes unchanged.
- **B4**: google-auth is still imported only by `accounts/google.py`, whose one app importer is `accounts/web/service.py`.

**Core + web (vitest; stubbed fetch, real KV)**
- **C1**: sign-in stores the pair and the email; `getGoogleSession()` carries `accountId`; the sign-in, whoami, logout and refresh requests go to `/api/web/auth/*` (the refresh via plain `fetch`, single-flight).
- **C2 (owner match)**: cache owned by account X, dirty set holds `s-3` → on restore the PUT of `s-3` is sent BEFORE the GETs; then local birth data and sessions equal the pulled ones.
- **C3 (other owner)**: cache owned by Y, restore as X → no import question, Y's birth data/transcripts/log are gone, X's pulled data is shown, no PUT sent.
- **C4 (import yes)**: no owner, local birth data + 2 sessions (one open, one sealed), server profile null → the gate shows the question with n = 2; Import → PUT profile, PUT both records, then the pull; owner set; a second restore does not ask again.
- **C5 (import yes, server has a profile)**: the local birth data is NOT sent and the account's profile is what the app shows.
- **C6 (import no)**: Discard → no PUT, local copy wiped, pulled data shown, owner set.
- **C7 (pull)**: two open rows for venus (updated t1 < t2) → venus's transcript is the t2 row's entries under the t2 id; the t1 row is a sealed pending record, PUT back as sealed, and its summary loop starts.
- **C8 (saves)**: `recordEntry` of a user line then a persona reply → PUTs of that record (coalesced, never concurrent for one id), body without `cause`; End → PUT sealed pending; the summary outcome → PUT with the ready summary. A save answering 500 or a rejected fetch leaves the id in the persisted dirty set; the next successful save clears it.
- **C9 (sign-out)**: after `signOutGoogle()` (even with a rejected fetch), the traveler birth data, the six transcripts, the session log, the active character, dirty set and owner keys are absent, and `astrology.lang.v1` remains. A restore that ends signed-out (dead pair) wipes an OWNED cache but keeps an unowned one.
- **C10 (no cap)**: 60 sealed records stay 60 after another `recordEntry`.
- **W1 (gate states)**: signed-in + syncing → "Opening your sky…" and no app; ready → the app; pull failure without an owned cache → "Couldn't load your account" with Try again re-running the pull; pull failure with an owned cache → the app.
- **W2 (import card)**: the question card shows the eyebrow, title, the count and email, Import and Discard; the zh copy has parity (existing parity test).
- **W3 (delete)**: in the Sessions reader, Delete → confirm → Delete removes the record from the list and sends `DELETE /api/web/sessions/<id>`; Keep does nothing; deleting an open record clears that character's transcript.
- **W4 (account delete)**: account chip → Delete account → confirm → `DELETE /api/web/account`; on 204 the cache is wiped and the gate shows.
- **G1**: architecture, colour and text guards pass; no new colour literal; `npm test` and `npm run typecheck` green.
- **G2**: the CLAUDE.md amendments of D17 are present, and `.env.example` names `WEB_DATABASE_URL` without a value.

**Real app** (dev cluster 127.0.0.1:54320: main `astrace_dev`, web `astrace_web`; backend with both URLs set explicitly in the shell and CORS for the Vite origin; bearer pairs minted by a log-recorded script into `astrace_web` stand in for Google; two isolated headless-Chrome profiles as browsers A and B)
- **R1**: `/api/health` → `db:"ok"`, `webDb:"ok"`; the process env shows both URLs on 127.0.0.1; `astrace_web` has the five tables.
- **R2 (loop closed, minted)**: A (user U) saves birth data and has one Venus reply; `web_sessions` holds the row after the reply, `web_birth_profiles` the profile. B (a fresh profile, a second pair for U) opens with the same birth data, wheel and the conversation in Sessions.
- **R3**: B signed in as user V sees no birth data and no sessions; after signing V out, B's localStorage holds no birth-data, transcript, session-log, owner or dirty key.
- **R4 (import)**: a browser with pre-seeded legacy chats and birth data (no owner) signing in as a fresh user W is asked once; Import → the rows appear in `astrace_web`; a reload does not ask again.
- **R5 (main untouched)**: `astrace_dev`'s table list and `users`/`sessions`/`refresh_tokens` row counts are identical before and after R1–R4.
- **U1 [USER-INPUT: the user's live Google sign-in in two browsers]**: in browser A, "Sign in with Google" → the app; chat one reply with any character; in a second browser (another Chrome profile or a private window) sign in with the SAME Google account → the chat and birth data are there; sign out in B → B's local copy is cleared. Verified from the backend log (google 200 ×2 on `/api/web/auth/google`, the session PUT) and `astrace_web` (one `web_users` row for that email, the session row, no sub).
