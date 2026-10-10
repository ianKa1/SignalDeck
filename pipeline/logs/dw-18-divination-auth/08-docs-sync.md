# 08 — docs-sync (2026-09-29, worker)

- /update-architecture-doc (baseline 4a74364, diff 4a74364..HEAD): 13 surgical edits in docs/ARCHITECTURE.md —
  - platform `apiFetch` paragraph gains `postJson`'s `{auth:true}` path and the `same-origin` note;
  - `auth.ts` gains the `onUnauthorized`/`reportUnauthorized` signal;
  - `TurnErrorCode` gains `unauthorized`;
  - `streamTurn` gains the bearer/drain/refresh/`unauthorized` mapping;
  - fetchSummary/fetchPersona/fetchSheets name `{auth:true}`;
  - `accounts/web` names `require_web_account` and what it refuses;
  - the turn wire notes the gate;
  - the web gate paragraph is no longer "a UI gate, not access control";
  - google-session gains the subscription and `useChat`'s `canRetry` rule;
  - the boundary summary gains S5;
  - data flow gains the gate hop;
  - the feature index gains the dw-18 line.
  Symbols spot-checked by grep in the tree (require_web_account, onUnauthorized, reportUnauthorized, PostJsonOptions, effective_candidates, canRetry). Commit 9b70741.
- Other sections, no change needed: native surface (native passes no opts), Deployment (no env change; the gate needs WEB_DATABASE_URL, which dw-16 already documents), Testing.
- docs/features/dw-18-divination-auth.md written (primary checkout, gitignored).
- Epic: dependency-rule bullet (step 5) + "Built so far" dw-18 entry.
- CLAUDE.md amended at step 5 (54f76e9).
- Status: docs-sync done → ready for accepting.
