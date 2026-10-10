# 07 — docs-sync (2026-09-29, parallel-wave worker)

- `/update-architecture-doc` on `docs/ARCHITECTURE.md` (baseline = cd44a2c, the
  last touch via the dw-17 merge; the diff to sync = f45d28b, 34dac0c, cd6f69e).
  Surgical edits:
  - Overview: the data-core bullet names `/api/web/auth/google` + `WEB_DATABASE_URL`;
    the session-log sentence is no longer "device-local".
  - Repo tree: web-divination `auth/` (ImportCard, useAccountData, AccountChip delete),
    `session.ts` installs web-account; server `accounts/` gains `web/`, `db/` the web door.
  - Layering/boundaries: B1–B4 paragraph.
  - `core/divination`: `replaceTranscript`; session log = the account's cache, no cap,
    the four new writers.
  - NEW section `core/web-account` (cloud / cache / sync).
  - `server/` `app/db/` (the web door + migration 001) and the Google sign-in paragraph
    rewritten around `app/accounts/web/` (service/data/routes, wire, limits, 503 dormancy).
  - web-divination gate (account states, `accountId`, `deleteGoogleAccount`, wipe owner),
    AccountChip, Sessions reader Delete, test inventory.
  - Data flow: the save scheduler beside the turn path; the pull on sign-in.
  - Testing: the two new pytest files + conftest pop; feature-doc index + dw-16 entry.
  - Spot-checked every new path (ls) and ran `npx jest src/architecture.test.ts` → 47 passed.
  - Commit ac2c294.
- `docs/features/dw-16-web-account-db.md` written in the PRIMARY checkout
  (`docs/features/` is gitignored; the other dw feature docs live there too): what was
  actually built, tests, real-app evidence, deviations, known limitations.
- Epic `pipeline/epics/divination-web.md`: Target modules (server `db/`,
  `accounts/web/`, main; core `account/google-session.ts`, `web-account/`, divination
  additions; web `auth/`, `log/`), a dw-16 "Built so far" entry, and the dependency rule
  narrowed: "no session table and nothing keyed by user" now applies to `divination/`
  (the account's chats live in `accounts/web/` + the web db; B3 fences both ways).

Status: docs-sync → accepting (coordinator runs the fresh-context acceptance; U1 is the
user's live-Google hand-back).
