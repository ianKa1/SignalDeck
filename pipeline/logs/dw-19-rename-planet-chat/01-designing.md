# 01 — designing (2026-09-29)
- Ready after dw-18 landed (bd158b2). Worktree ../astrology-wt/dw-19-rename-planet-chat, branch feature/dw-19-rename-planet-chat.
- Survey: 114 live files / ~1115 occurrences outside pipeline/; key material embeds topic NAME (summary.py:88, voice.py:199); store DB_PATH data/divination.db, tables divination_summary/voice (migrations 011/012); env DIVINATION_TURN_TIMEOUT_S (turn.py:112); KV keys astrology.divination.{transcript.v1.<id>,sessions.v1,active.v1}.
- Skills: /feature-spec and /architecture-designer applied under pipeline-mode overrides (loaded earlier this session).
- Decided: keep web-divination folder (breaks the user running Vite + lockfile/scripts churn), freeze key literals, migration 013 renames tables, SQLite move-on-first-use, KV migrate-on-first-read, env fallback, rename guard with an allowlist.
- Spec: pipeline/specs/dw-19-rename-planet-chat.md. Status → spec-review.
