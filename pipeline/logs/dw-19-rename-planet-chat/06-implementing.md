# 06 — implementing (2026-09-29, worker, worktree ../astrology-wt/dw-19-rename-planet-chat)

## Step 0 — golden values + baseline (base bd158b2)
- Throwaway dbs created on 127.0.0.1:54316: dw19_web, dw19_main.
- Goldens (scratchpad dw19_golden.py, base code, DATABASE_URL= WEB_DATABASE_URL=):
  - summary_key(persona=venus, lang=en, transcript=[user "Will I find love?", persona "Look to your fifth house." dice Venus/Leo/5])
    = 41f0a83ee31c92f0dfe246a0a113e9be9863c944b358e85d79c3e6351dbcc6cf
  - voice_key({planet:venus, sign:Taurus, house:7, dignity:domicile, retrograde:False, aspects:[], meanings:{x:y}}, venus, zh)
    = e370a2011e63b8d1e7258caadde162787958e19d955ce78f0345e64ec92ebcbc
- Baseline suites:
  - server (DATABASE_URL= WEB_DATABASE_URL=, TEST_WEB_DATABASE_URL/TEST_DATABASE_URL → dw19_web/dw19_main): 1478 passed, 50 skipped.
    The 50 skips are all pre-existing DATABASE_URL/LLM-live suites (auth_integration 6, card_store_pg 3, db_integration 5,
    explain_store_pg 6, native_tokens 6, otp_auth 8, profiles_integration 4, synastry* 6, …) — none divination.
  - npm test: app-native jest 1078/1078; web-divination vitest 438 passed, 1 failed (SpotlightLayer.test.tsx — passes 5/5
    run alone; load flake at base, pre-existing).
  - typecheck: green.

## Steps 1 + 2 — server rename and data bridges (one commit: the store's table rename needs 013 for the suite to be green)
- git mv server/app/divination → server/app/planet_chat; tests test_divination_* → test_planet_chat_* (chat_metrics →
  test_planet_chat_metrics.py); fixtures planet_chat_chartless_{en,zh}.txt; prompt_lab planet_chat_lab.py / planet_chat_metrics.py.
- Scripted rename (scratchpad dw19_rename.py): protects web-divination, dw-N-…divination… slugs, epics/divination-web.md,
  011/012 file names; identifiers → planet_chat / PlanetChat / PLANET_CHAT; prose → "planet chat"; kebab → planet-chat
  (thread prefix planet-chat-turn). Code-context prose hits hand-fixed in test_boundaries.py (import regex, B3 regex, S5 variable).
- D4: turn.py reads PLANET_CHAT_TURN_TIMEOUT_S, falls back to _LEGACY_TIMEOUT_ENV with one log WARNING per process.
- D5: summary.SUMMARY_KEY_TOPIC / voice.VOICE_KEY_TOPIC frozen literals used as key material; NAME renamed.
- D6: migration 013_planet_chat_rename.sql. DEVIATION: PostgreSQL 18 (local clusters) records NOT NULL constraints in
  pg_constraint as <table>_<col>_not_null, so they carried the old name too (first N5 run failed:
  "Extra items … 'divination_summary_lang_not_null' …"). Explicit RENAME CONSTRAINT of those would FAIL on older servers
  (Neon), so 013 renames the tables and then, in a DO block, every constraint of each table whose name starts with the old
  table prefix (pkey on every server; NOT NULLs where they exist). N5 asserts pkey present, every constraint and index named
  under the new table.
- D7: store._adopt_legacy_file (module lock, once per path per process, re-checks both paths inside the lock; ALTER in one
  BEGIN IMMEDIATE transaction; "no such table" tolerated).
- Guards: test_planet_chat_store_is_two_identity_free_tables reads 011/012 columns under their created-as names and now also
  pins that store.py and 013 carry exactly the two ALTER … RENAME TO pairs (self-check: a planted third pair goes red).
  test_p11 (012 sorts last) → 012 keeps its CREATE TABLE divination_voice (013 now sorts last).
- New tests/test_planet_chat_rename.py: N3 (old prefix 404 ×4), N4 (goldens), N5 (LIVE, creates+drops its own db on :54316),
  N6 (move/rename/serve; second start no-op; fresh; other file names untouched), N7 (new / legacy+1 warning / both).
- Results: server 1493 passed, 50 skipped (the same pre-existing DATABASE_URL/LLM-live skips as baseline; 0 planet_chat skips).
  Extra: the DATABASE_URL-live suites (db_integration, *_pg, auth/otp/native/profiles integration, + planet_chat summary/persona)
  on a fresh local db: 15 failed / 133 passed, the IDENTICAL failure list as the base commit on its own fresh db (pre-existing:
  stale pg column pins, psycopg DELETE fetch, route tests that assume SQLite) — test_db_integration applies 001–013 from zero.

## Step 3 — core + web rename, browser-key bridge (D8)
- git mv packages/core/src/divination → planet_chat; package.json export "./planet_chat" (Vite alias maps
  @astrace/core/<x> wholesale — no alias change needed); web core tests core-divination*.test.ts → core-planet-chat*.test.ts.
- Script over packages/, app-native/src, web-divination (package.json name excluded). Hand fixes: architecture.test.ts:196
  barrel-deep-import alternation `planet_chat`; ChartStage.focus.test.tsx variable `planetChat`.
- D8: new core planet_chat/legacy-keys.ts — migrateLegacyKeys() (once per process; moves each of sessions.v1, active.v1,
  transcript.v1.<six ids> only when the new key is absent; old key removed either way) and clearLegacyKeys(). transcript.ts,
  session-log.ts, roster.ts route EVERY KV touch through a local kv() that runs the migrator first (so a clear before any read
  cannot leave an old copy to be resurrected). web-account wipeCache() also calls clearLegacyKeys().
- Tests: web-divination/src/chat/core-planet-chat-legacy-keys.test.ts (5: first read moves all three with real core-written
  values; any one reader migrates all; second read no-op; new key never overwritten; nothing written when no old keys);
  core-web-account.test.ts C9 "dw-19: the wipe also removes a pre-rename key left behind" — verified it FAILS with the
  clearLegacyKeys() call commented out, passes with it.
- Results: npm test → app-native jest 1078/1078; web-divination vitest 47 files, 445/445. npm run typecheck clean.

## Step 4 — UI name (N9) + rename guards (N2)
- N9: `rg -i "divination|占卜|planet chat|行星对话" web-divination/src/i18n web-divination/index.html` → no matches;
  `rg 占卜` repo-wide (minus pipeline/) → none. NONE EXISTED: the product name shown is "Astrace" (<title> "Astrace — the
  natal sky", page titles "… · Astrace"); per D2 no new tagline text was added.
- rename-allowlist.json (repo root, 25 {path_glob, pattern, why} entries) read by BOTH guards:
  server/tests/test_rename_guard.py (test_no_divination_in_live_code, test_rename_guard_bites) and
  app-native/src/rename-guard.test.ts (same two). Same algorithm: `git ls-files --cached --others --exclude-standard`
  minus pipeline/ and docs/features/, text files only; every case-insensitive occurrence must lie inside a match of an
  entry whose glob matches the path; every entry must be used at least once (closed list). NB2: the epic-name entry is
  bound to CLAUDE.md AND the exact string `formerly the DIVINATION WEB EPIC`.
- Bite evidence: (a) in-test plants (identifier, prose name, route, KV key, env read outside its bridge files → red;
  slug / parenthetical / frozen literal → green); (b) real files: appended `divination_turn = None` to
  server/app/generation.py and created untracked web-divination/src/planted-dw19.ts with an old KV key → pytest guard
  "1 failed … 'server/app/generation.py:249: divination_turn = None'", jest guard lists both files; reverted, green again.
  The guard also caught my own first CLAUDE.md sentence ("formerly named divination") — rephrased.
- DEVIATION (order): the guards need the docs renamed to go green, so step 5's docs edits were made before step 4's commit;
  commits land docs first, then guards, so each commit is green.

## Step 5 — docs
- Script over CLAUDE.md, docs/ARCHITECTURE.md (server/app/ARCHITECTURE.md done in step 1); .env.example had only
  web-divination mentions and no old timeout var → unchanged (D4 "only if the old one was there").
- CLAUDE.md: D11 parenthetical "(formerly the DIVINATION WEB EPIC, `pipeline/epics/divination-web.md`; …)" on one line;
  rule 9 notes the frozen key topics; rule 11 notes migration 013; the Architecture Contract intro names the rename guard
  and the shared allowlist. Code-name fixes: "may import planet_chat for the summary job", "and planet_chat (the summary job)".
- Epic /Users/kaimao/Projects/astrology/pipeline/epics/divination-web.md: script over lines 35→end (Built so far, Reuse map,
  Target modules, Dependency rules); title and the User-rulings record left as history; added the dw-19 Built entry and a
  dw-19 dependency-rules line. Leftover check over lines >34 minus web-divination/slugs → none.
- Suites: server 1495 passed / 50 skipped (pre-existing); npm test jest 1080/1080, vitest 445/445; typecheck 0 errors.
