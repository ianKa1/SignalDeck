# 11 U1 prep — merged dw-13 rework, servers left running for the user's live sign-in

- Worktree merged feature/divination_web @ f710c2b (dw-13 rework) → 3e8e9cb (clean merge). Suites: jest 1072, vitest 308, typecheck 0, server db-free 1380 passed / 55 skipped.
- 10-accepting.md (fresh checker, @0305c1c): ACCEPTANCE: PASS (all but U1). The 3e8e9cb merge touched only dw-13 files (voice/header); suites re-run green.
- Throwaway Postgres: /private/tmp/claude-501/-Users-kaimao-Projects-astrology/4cb30d3d-9400-410d-b035-a12dd2fddaa3/scratchpad/u1/pg, 127.0.0.1:54330, db astrace_u1 (users count before U1: 0).
- Backend :8010 from the worktree: env file /private/tmp/claude-501/-Users-kaimao-Projects-astrology/4cb30d3d-9400-410d-b035-a12dd2fddaa3/scratchpad/u1/u1.env = root .env minus DATABASE_URL; shell DATABASE_URL=postgresql://astrace@127.0.0.1:54330/astrace_u1 (verified via ps eww); CORS_ALLOW_ORIGINS=http://localhost:5180; real GOOGLE_CLIENT_ID (72 chars). /api/health → db ok. POST /api/auth/google {credential:"x"} → 401 (not 503 → client id configured). Log: /private/tmp/claude-501/-Users-kaimao-Projects-astrology/4cb30d3d-9400-410d-b035-a12dd2fddaa3/scratchpad/u1/backend.log.
- Vite :5180 from the worktree (VITE_API_BASE=http://localhost:8010); gate renders with the GSI button iframe and the GSI script loaded. Log: /private/tmp/claude-501/-Users-kaimao-Projects-astrology/4cb30d3d-9400-410d-b035-a12dd2fddaa3/scratchpad/u1/vite.log.
- Status: accepting — waiting on U1 (user).
