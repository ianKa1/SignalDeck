# 09 — U1 preparation (2026-09-29)
- Acceptance 08: every criterion PASS except U1 (not run, user input).
- Started from the worktree (ac2c294), leaving the user's :8000/:5173 untouched:
  - backend :8001 — env: DATABASE_URL=…54320/astrace_dev, WEB_DATABASE_URL=…54320/astrace_web (verified with `ps eww`), GOOGLE_CLIENT_ID exported from the root .env (value not printed), CORS_ALLOW_ORIGINS=http://localhost:5180, ANALYSIS_LLM=claude-cli, no --env-file. Log: scratchpad/u1-backend.log. Health: {"db":"ok","webDb":"ok"}.
  - Vite :5180 (authorized Google origin), VITE_API_BASE=http://localhost:8001; client id via the Vite loadEnv of the root .env.
- Baseline astrace_web: 6 web_users (dw16.{u,v,w}@example.com, acc16.{u,v,w}@example.com — test users), 6 web_sessions. astrace_dev users/sessions/refresh_tokens = 1/1/1.
- Handed back to the user for the live two-browser Google sign-in.
