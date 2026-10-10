# 08 — docs-sync (2026-09-29, worker)

- /update-architecture-doc on docs/ARCHITECTURE.md (baseline bd158b2; the scripted rename landed in 13e1f40):
  surgical additions in 461ea8e — repo-tree comments (tables renamed by 013), the Guards section (rename guard + shared
  allowlist), core `planet_chat/legacy-keys.ts` bullet, `wipeCache` clears pre-rename keys, `turn_timeout_s` fallback,
  summary/voice keys' frozen topic, store.py's 013 + SQLite adoption, 012 renamed by 013, features-index entry.
  Written without the old word (the rename guard scans the doc). Paths/symbols spot-checked; guards + architecture.test
  green (pytest 2 passed; jest 49 passed). server/app/ARCHITECTURE.md: renamed in step 1, makes no store claims — unchanged.
- Feature doc written: /Users/kaimao/Projects/astrology/docs/features/dw-19-rename-planet-chat.md (untracked, frozen snapshot).
- Epic /Users/kaimao/Projects/astrology/pipeline/epics/divination-web.md: current-state sections renamed and the dw-19
  Built entry + dependency line added (during step 5; see 06-implementing.md).

## N1 — final `rg -i divination` residue (live files = git-tracked + untracked-not-ignored, minus pipeline/, docs/features/)
55 files, 357 occurrences, every one covered by rename-allowlist.json (tally from the guard's own matcher):
- web-divination folder/package (D3): 216
- dw-* slug citations (D11): 24; epic path (D11): 3; CLAUDE.md "formerly the DIVINATION WEB EPIC" (D11/NB2): 1
- applied migrations: file-name citations 9; 011 body 4; 012 body 3
- D6 migration 013: 4
- D5 frozen key literals: summary.py 1, voice.py 1
- D7 SQLite bridge (store.py): 3
- D4 env fallback (turn.py): 1
- D8 browser-key bridge (legacy-keys.ts): 2
- tests of the bridges/history: test_planet_chat_rename.py 22, test_boundaries.py 3, test_planet_chat_summary.py 1,
  test_planet_chat_persona.py 1, test_planet_chat_turn.py 1, core-planet-chat-legacy-keys.test.ts 3,
  core-web-account.test.ts 3
- the rename guard itself: test_rename_guard.py 11, rename-guard.test.ts 12, rename-allowlist.json 28

## N10
CLAUDE.md (rules 1/2 intro, 5, 9, 10, 11, 12, 14, backend + web paragraphs), docs/ARCHITECTURE.md, server/app/ARCHITECTURE.md
and the epic's current-state sections name planet_chat. .env.example never named the old word except web-divination (D3).
Guards named in CLAUDE.md exist: test_planet_chat_borrows_only_the_restate_helper, test_s5_every_planet_chat_route_requires_a_web_account,
server/tests/test_rename_guard.py, app-native/src/rename-guard.test.ts.

Status: docs-sync → accepting.
