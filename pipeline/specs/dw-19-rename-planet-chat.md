# dw-19-rename-planet-chat — "divination" becomes planet_chat / Planet Chat

## Goal

Rename the feature everywhere in live code, config, guards and current docs from `divination` to `planet_chat`, show it to users as "Planet Chat" / "行星对话", and keep every cached card, summary and local chat loading. QUEUE.md `dw-19-rename-planet-chat` (tier-1 user ruling 2026-09-29); epic `pipeline/epics/divination-web.md`.

## Non-goals

- History: commit messages, `pipeline/` (DECISIONS, logs, specs, plans, the epic FILE NAME), the `dw-*` slugs, and applied migrations `011_divination_summary.sql` / `012_divination_voice.sql` stay byte-identical.
- Behaviour changes of any kind: prompts' wording, wire bodies, events, auth (dw-18), web-account sync (dw-16) and layout (dw-17) behave exactly as before; only names move.
- Old route aliases. `/api/divination/*` is removed, not redirected (nothing is deployed yet; the only client moves in the same commit).
- app-native (it imports no divination code; only its guard files, which walk the trees, change).

## Decided defaults

1. **Names.** Server package `server/app/divination/` → `server/app/planet_chat/` (git mv, history kept); routes `/api/divination/{turn,summary,persona,sheets}` → `/api/planet_chat/{turn,summary,persona,sheets}`; core module `packages/core/src/divination/` → `packages/core/src/planet_chat/` exported as `@astrace/core/planet_chat` (the ruling's spelling, even though other core modules are kebab-case); Python/TS identifiers, test files (`test_divination_*.py` → `test_planet_chat_*.py`, `core-divination*.test.ts` → `core-planet-chat*.test.ts` — kebab-case deliberately, matching the web tree's test file names), guard/test names and constants (e.g. `DIVINATION_ROUTE_TEST_MODULES` → `PLANET_CHAT_ROUTE_TEST_MODULES`), log messages (`planet chat turn: …`), the thread prefix, the 503 detail `planet chat unavailable`, the prompt-lab files, `docs/ARCHITECTURE.md`, `server/app/ARCHITECTURE.md`, CLAUDE.md.
2. **User-facing name.** Wherever the web shows the feature's name — the masthead/running head, `<title>`, the sign-in threshold and any copy that says "divination" or 占卜 — it reads "Planet Chat" / "行星对话". If no such string exists today, the masthead tagline gains no new text; the requirement is that no user-visible string says divination/占卜 (checked by grep over `i18n/` and `index.html`).
3. **Workspace folder stays `web-divination/` (recorded exception).** Renaming it rewrites the npm workspace list, the lockfile, every root script, the guards' walked-tree paths and CLAUDE.md, AND it would pull the directory out from under the user's running Vite dev server (:5173 serves the primary checkout's `web-divination/`) at landing; a `git mv` would also leave the untracked `web-divination/.env*` files behind. It is left for its own queue entry if wanted. The package NAME inside it is also kept.
4. **Env var.** `PLANET_CHAT_TURN_TIMEOUT_S` is read first; `DIVINATION_TURN_TIMEOUT_S` is read as a fallback (one release), with one WARNING per process when only the old name is set. Both named in `.env.example`'s comment only if the old one was there. Recorded exception: the fallback's literal.
5. **Cache keys stay stable (preferred by the ruling).** The prompt topics are renamed (`planet_chat`, `planet_chat_summary`, `planet_chat_voice`) for registration and provenance, but the KEY MATERIAL keeps the old topic strings through frozen constants `SUMMARY_KEY_TOPIC = "divination_summary"` and `VOICE_KEY_TOPIC = "divination_voice"` (each with a comment naming this spec). So `summary_key`/`voice_key` return the same 64-hex for the same inputs as before, and every stored summary and character card is still a hit. Job kinds/keys in `generation.py` (`divination_summary:<key>`, `divination_voice:<key>`) are in-memory and may be renamed. Recorded exception: the two frozen literals.
6. **Main-db tables.** New migration `server/app/db/migrations/013_planet_chat_rename.sql`: `ALTER TABLE divination_summary RENAME TO planet_chat_summary; ALTER TABLE divination_voice RENAME TO planet_chat_voice;` plus `ALTER TABLE … RENAME CONSTRAINT divination_summary_pkey TO planet_chat_summary_pkey` and the same for `divination_voice_pkey` (the implicit primary-key constraints; no other index carries the word). Rows and columns unchanged. The store names only the new tables. The boundary pin reads columns from the new table names (011/012's CREATE TABLE columns still match, as the rename keeps them).
7. **SQLite.** `DB_PATH` becomes `data/planet_chat.db`. On first use, if `planet_chat.db` is absent and `divination.db` exists, the store renames the file, and inside it renames `divination_summary`/`divination_voice` to the new tables when the old names exist (idempotent, one transaction). Recorded exception: the legacy file name and table names in that one migration helper.
8. **Browser keys.** `astrology.divination.transcript.v1.<id>`, `astrology.divination.sessions.v1`, `astrology.divination.active.v1` → `astrology.planet_chat.…` with the same suffixes. A core helper `migrateLegacyKeys()` in `planet_chat/` moves each old key to the new one (only when the new one is absent; the old key is then removed) and runs once per process, lazily, from every reader of those keys (transcript, session log, active character) before the first read. dw-16's wipe list names the new keys (and also removes any leftover old key). Recorded exception: the legacy key literals in that helper.
9. **Guards are renamed, never weakened.** Every `test_boundaries.py` test and `architecture.test.ts` rule that names divination keeps its assertion and self-check, with names, paths and regexes moved to planet_chat. A new guard pins the rename: `rg`-style scan (in a server test and a jest test) of live code for `divination` (case-insensitive) that allows ONLY the recorded exceptions (D3–D8, the historical migrations 011/012, and the `web-divination` path/package name) and goes red on a planted occurrence.
11. **History citations stay (recorded exception).** A `dw-<n>-…` slug that contains the word (e.g. `dw-18-divination-auth`, `dw-12…` citations are fine as they are) is a history reference and is never rewritten, in comments, docstrings, CLAUDE.md or docs. So is the epic file path `pipeline/epics/divination-web.md`. The epic's DISPLAY name in current prose becomes "PLANET CHAT WEB EPIC" (formerly the DIVINATION WEB EPIC — that one parenthetical in CLAUDE.md keeps the old name so readers can find the history). The rename guard allows exactly: the regex `dw-\d+-[a-z0-9-]*divination[a-z0-9-]*`, the literal `epics/divination-web.md`, the phrase `DIVINATION WEB EPIC` in that one parenthetical, plus D3–D8's exceptions.
10. **Docs.** CLAUDE.md (rules 1, 2, 5, 9, 10, 11, 12, 14, the backend paragraph and the web-divination paragraph), `docs/ARCHITECTURE.md`, `server/app/ARCHITECTURE.md`, `.env.example`, and the epic's CONTENT (current-state sections: Built so far, Target modules, dependency rules; historical headings may keep their words) use planet_chat. Per-feature docs under the primary checkout's untracked `docs/features/` are frozen snapshots and are NOT edited.

## Architecture

Pure rename plus four data bridges (D5–D8); no module boundary moves. Every edge rule that names `divination` (rule 10's Tier C package, its store exception, its imports, dw-18's gate, the core/web barrels, G-guards) applies unchanged to `planet_chat`.

| Surface | Old | New | Bridge |
|---|---|---|---|
| Server package | `app/divination` | `app/planet_chat` | — |
| Routes | `/api/divination/*` | `/api/planet_chat/*` | none (no deploy yet) |
| Core barrel | `@astrace/core/divination` | `@astrace/core/planet_chat` | — |
| Env | `DIVINATION_TURN_TIMEOUT_S` | `PLANET_CHAT_TURN_TIMEOUT_S` | old name as fallback |
| Topics | `divination*` | `planet_chat*` | key material frozen to old literals |
| Main-db tables | `divination_summary/voice` | `planet_chat_summary/voice` | migration 013 |
| SQLite | `data/divination.db` | `data/planet_chat.db` | move + table rename on first use |
| KV keys | `astrology.divination.*` | `astrology.planet_chat.*` | migrate on first read |

Forbidden: editing applied migrations; changing a content key's bytes; weakening a guard; renaming `pipeline/` history.

## Acceptance Criteria

Suites: `npm run server:test` (explicit local/empty `DATABASE_URL` and `WEB_DATABASE_URL`; live suites on a throwaway local cluster via `TEST_*` URLs), `npm test`, `npm run typecheck`.

- **N1 (grep)**: `rg -i divination` over live code/config/current docs (everything except `pipeline/`, `docs/features/`, `.git`, `node_modules`, `dist`) lists only the recorded exceptions: `web-divination` paths/package name, migrations 011/012, the D4 fallback literal, the D5 frozen key literals, the D7 SQLite legacy helper, the D8 legacy KV literals, D11's slug citations / epic path / one parenthetical, and the rename guard's own allowlist/self-check (the server and jest guards share ONE allowlist, read from a single JSON file `rename-allowlist.json` at the repo root so they cannot drift). The log records the full list.
- **N2 (rename guard)**: the new server and jest guards pass and each goes red on a planted `divination` identifier in a live file.
- **N3 (routes)**: `/api/planet_chat/{turn,summary,persona,sheets}` behave as the old routes did (existing tests moved, all green, dw-18 gate pinned on the new prefix); `/api/divination/turn` → 404.
- **N4 (keys stable)**: for fixed inputs, `summary_key` and `voice_key` return the same hex as on bd158b2 (golden values recorded from the base commit in the test).
- **N5 (Postgres)**: on a throwaway db migrated to 012 with one summary row and one voice row, applying 013 leaves `planet_chat_summary`/`planet_chat_voice` with those rows, the same columns and the constraints `planet_chat_summary_pkey`/`planet_chat_voice_pkey`; a summary request for that content is a 200 hit with no job.
- **N6 (SQLite)**: with only a `divination.db` holding a summary and a voice row, the first store read creates no empty file but moves it to `planet_chat.db`, renames the tables, and serves both rows as hits; a second start does nothing.
- **N7 (env)**: `PLANET_CHAT_TURN_TIMEOUT_S=5` → 5 s; only `DIVINATION_TURN_TIMEOUT_S=7` → 7 s plus one warning; both set → the new one wins.
- **N8 (browser keys)**: with localStorage seeded under the three old key shapes, the first read returns the data under the new keys and the old keys are gone; a second read is a no-op; new keys already present are never overwritten.
- **N9 (UI name)**: no string in `web-divination/src/i18n/` or `index.html` contains divination/Divination/占卜; wherever the product/feature is named it is "Planet Chat" / "行星对话" (log the strings changed, or "none existed").
- **N10 (docs)**: CLAUDE.md, both ARCHITECTURE.md files, `.env.example` and the epic's current-state sections name planet_chat; guards named in CLAUDE.md exist under their new names.
- **R1 (real app)**: backend from the worktree against the dev cluster (`astrace_dev` main — migration 013 applies at startup; `astrace_web`), explicit local URLs, never the Neon URLs; a browser seeded with old `astrology.divination.*` keys and a minted web pair: the old chats show in Sessions and chat, a new reply streams on `/api/planet_chat/turn` and saves, a character card that was cached before the rename is served as a 200 hit (no new job), and End session gives a summary card.
