# dw-6-session-log — 01 designing

Date: 2026-09-28. Stage worker for the coordinator (wave member 3 of 3,
primary checkout, branch feature/divination_web at 2f45dfb). No code edited,
nothing committed, QUEUE.md / DECISIONS.md untouched.

## Reads
- CLAUDE.md (rules 6, 9, 10, 11, 14); PIPELINE.md (Skills per stage,
  pipeline-mode overrides, Epic files, Spec requirements, Auto spec review,
  Parallel waves); QUEUE.md dw-6 entry + epic comment;
  pipeline/epics/divination-web.md.
- dw-4 and dw-5 specs (shared-file footprint sections, dw-5 wire/contract delta).
- Server: generation.py (ensure_* shapes), jobs/__init__.py,
  interpretation/store.py, ask/store.py, db/__init__.py, db/migrations.py,
  migrations/ (highest = 010_analysis_doctrine.sql), main.py (analysis
  200/202 route, turn route), models.py (divination models),
  divination/{__init__,render,turn}.py, prompts.py (register_topic,
  FINGERPRINT doctrine), interpretation/service.cache_key doc,
  tests/test_boundaries.py (fence, no-state, importers, delivery,
  synchronous-exception pins), tests/test_db.py, tests/conftest.py.
- Core: platform/{poll,index,api,storage}.ts, analysis/service.ts poll loop,
  divination/{index,types,transcript}.ts, cards/shown-store.ts (device log
  precedent; it lives in core, not app-native).
- Web: app/App.tsx, Header.tsx, app.css, chat/{useChat.ts,ChatPanel.tsx},
  i18n/{en,index}.ts, theme/tokens.ts; app-native/src/architecture.test.ts
  web guards G3–G9.

## Skills (in order, pipeline mode)
1. frontend-design → D12 "the sealed plate" (wax-seal press, question as
   display-serif hero, glyph seal rows, ledger screen with list+reader).
2. feature-spec → Goal / Non-goals / Decided defaults / Acceptance Criteria.
3. architecture-designer → Architecture (delta over the epic; no Migration Steps).

## Key choices
- Server generates only question/tone/toneNote; persona, chart refs and dice
  derived on device from archived entries (no echo round trip).
- Request reuses DivinationTranscriptEntry + core toWire, key/prompt use
  model_dump(exclude_none=True): dw-5's dice flow through with no dw-6 edit;
  device reads dice structurally.
- Content key = sha256(topic name, VERSION, persona, lang, entries);
  FINGERPRINT recorded as `doctrine`, NOT key material — follows the
  2026-08-13 ruling stated in prompts.py:21 / interpretation/service.py:88,
  overriding the brief's and epic's "fingerprint in key" (code wins).
- Summary is its own prompt topic `divination_summary` → render.py untouched.
- Migration 011_divination_summary.sql (verified 010 is highest).
- No-state pin evolves: store.py is the one exempt file, with its column list
  pinned (and 011's); turn/render may not import summary/store; importers of
  divination = {main.py, generation.py}; generate_summary joins
  GENERATE_ON_REQUEST_RE.
- End enabled iff last stored entry is persona (no chat-state coupling);
  web log/ never imports chat/; history is a view swap in App.tsx.

## Word counts (wc -w)
- Goal + Non-goals + Decided defaults: 1,165 (budget ~1,500)
- Architecture: 1,354 (budget ~1,500)
- Acceptance Criteria: 1,315 (exempt)

## Shared files touched (wave)
- with dw-5: server/app/models.py (EOF append), divination/__init__.py
  (docstring), core divination/index.ts (appended block), i18n/{en,zh}.ts
  (`log` block before `chat`), CLAUDE.md rule 10.
- with dw-4: none.
- dw-6 only: App.tsx, main.py, generation.py, test_boundaries.py,
  conftest.py, transcript.ts (EOF append; dw-5 edits sanitize/toWire).

## Transition
designing → spec-review. Spec: pipeline/specs/dw-6-session-log.md
