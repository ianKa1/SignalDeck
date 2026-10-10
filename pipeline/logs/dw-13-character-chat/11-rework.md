# 11 rework — user feedback 2026-09-29 (implementing + validating)

Branch: `fix/dw-13-character-chat` from feature/divination_web @ b483a89.

## Feedback applied
(a) Card length was a hard rejection (2,800–3,800); live cards ran 3,900–4,150, all 3 attempts rejected, `POST /api/divination/persona` → 502, header stuck on "<planet> is finding a voice…".
(b) Header read "Your Moon · in Pisces · 8th house".

## Changes
- `server/app/divination/voice.py`: `CARD_MIN/CARD_MAX/GREETING_MAX` → `CARD_TARGET_MIN/CARD_TARGET_MAX/GREETING_TARGET` (targets, prompt-only). `_problems` no longer checks length; it rejects only a blank card/greeting (malformed — decided default, journaled), a non-object answer, and astro-vocabulary hits.
- `voice_role.txt`: "between 2,800 and 3,800 characters" → "aiming for about 2,800 to 3,800 characters"; greeting "at most 200 characters" → "short: about 200 characters or fewer".
- Lab metric L6 (`prompt_lab/divination_chat_metrics.py`): grades vocabulary only, reports length.
- Web `chat/PersonaHeader.tsx`: title is always `{name}`; subtitle = domain (+ finding note while generating) until the card is ready, then the greeting (`.persona__greeting`, aria-label `persona.greetingLabel`). No sign glyph, no placement line, no "Your". `placementText` kept for the picker plates.
- `ChatPanel.tsx`: static opening letter shown only while there is no card (the greeting lives in the header, shown once).
- i18n: `persona.title` removed, `persona.greetingLabel` added (en "What {name} says first", zh "{name}的开场白").
- Tests: persona tests (new `test_k1_length_is_a_target_never_a_rejection` ×3 incl. a 4,150-char card, `test_k1_the_role_states_the_length_as_a_target`; K1 dirty params drop the length cases, add a blank card; K3 asserts no length problem is named; P7 502 case uses a vocab hit), render P5 constant rename, metrics L6, PersonaHeader W2–W5 + css, RosterPicker "never Your Saturn", i18n template list.
- No chat-reply length cap reintroduced (b483a89 untouched: bubbles.py / turn.py unchanged).

## Suites
- `npm test`: jest 90 suites / 1069 passed; vitest 26 files / 272 passed.
- `npm run typecheck`: clean (both workspaces).
- `DATABASE_URL= conda run -n astrology pytest -q` (server/): 1358 passed, 50 skipped.

## Real app (backend :8000 restarted from this branch, `DATABASE_URL=` empty, `--env-file .env` → tokenrouter; Vite :5173 main checkout)
- curl moon/en for 1990-06-15 08:30 Beijing: 202 ×3 → 200. Stored card 3,800 chars; greeting "Hey, you’re here. I’ve got time for you—tell me what’s really going on, even if it comes out tangled." No rejection logged.
- Browser (Chrome, :5173, the user's profile data, active = moon): header = "Moon" over that greeting; no placement line. Screenshot: /var/folders/k8/krp4szdj4dv1_9s_51qq52z00000gn/T/claude-chrome-screenshots-doWsbQ/screenshot-1790707107825-13.png
- Switched to Mars (uncached): header sampled every 5 s → "Mars | Action, anger, the fights worth having | Mars is finding a voice…" → "Mars | There you are. Tell me what’s going on—the real version—and what move you’re tempted to make. …". Card 3,719 chars, first attempt. Active restored to moon.

Status: rework → validating → docs-sync.
