# 10 — final review (auto-finalization, 2026-09-29)
- Built: `require_web_account` (accounts/web) as a decorator dependency on the four /api/divination routes (503 dormant / 401), pinned by a flattened route walk; core postJson {auth:true} via apiFetch, streamTurn bearer + one refresh, platform onUnauthorized → google-session signs out (dw-16 wipes); `unauthorized` turn code hidden in chat; conftest gate stub for six divination route-test modules; CLAUDE.md backend/rule 10/rule 12, epic rule.
- Deviations: flattened walk (private FastAPI API), stub on both app objects, canRetry hiding.
- Limitations: malformed JSON still 422 (no work done); /api/chart stays open (shared, no LLM).
- Acceptance PASS 15/15 (09-accepting.md). Landed bd158b2; worktree and branch removed.
