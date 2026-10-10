# 02 — spec-review (round 1)

**Verdict: FAIL.** There is one blocking item, and it is a small fix. Everything else holds up.

## Verified against the code (base bd158b2, the worktree)

- **The key material embeds the topic NAME, so freezing it is needed (D5).** `summary_key` puts `"topic": NAME` into its material (`divination/summary.py:88`, where NAME = `"divination_summary"`), and `voice_key` does the same (`voice.py:199`). Renaming NAME without D5's frozen literals would change every key.
- **The prompt-topic rename touches nothing persisted besides the keys.** The FINGERPRINT (stored as `doctrine`) is `fingerprint_of(fragments)` (`prompts.py:37-43, 118-122`). It hashes fragment names and texts only, never the topic name, and no `.txt` asset or `declare()` text contains "divination". So doctrine provenance is byte-identical. The job keys (`generation.py:215,238`) are in-memory and never reach the client. `test_topic_keys_match_the_shared_core_copy` pins transit `TOPIC_KEYS` (`selection` against `transit-day/types.ts`) and is unaffected. The one test that names topics, the `TOPICS` tuple at `test_divination_render.py:517`, is covered by D1.
- **The data bridges cover all persisted state.**
  - Main database: tables from 011/012 → 013 (D6).
  - SQLite `data/divination.db` → D7.
  - Browser storage: the only divination keys are the three in D8 (`transcript.ts:19`, `session-log.ts:46`, `roster.ts:35`). dw-16's `astrology.web.*` keys and `web_sessions` hold no divination-named data.
  - Deployed state: `main`/`dev` (and the origin copies) carry no divination migrations or package, so nothing is deployed and the env fallback (D4) is precautionary. That is consistent with D-"no route aliases".
- **The epic and contract fit.** It is a pure rename with guards renamed rather than weakened. `BARREL_DEEP_IMPORT_RE` (`architecture.test.ts:196`) is an alternation list, so swapping in `planet_chat` keeps the rule. D1 follows the ruling's `planet_chat` spelling.

## BLOCKING

**B1 — The exception list in N1 and D9 is incomplete, and it contradicts the ruling and the spec's own Non-goals.**

- The ruling and the Non-goals keep the `dw-*` slugs.
- Live code, however, cites `dw-18-divination-auth` 22 times in comments and docstrings, for example `platform/auth.ts:64`, `accounts/web/routes.py:127` and `main.py:5`. CLAUDE.md and docs/ARCHITECTURE.md cite it too.
- The kept epic file path `pipeline/epics/divination-web.md` and the epic name "DIVINATION WEB EPIC" also appear in CLAUDE.md and docs/ARCHITECTURE.md.
- None of these is in N1's list or in D9's guard allowlist.

As written, the implementer has two options, and both are wrong:
- rewrite the slugs, which breaks the ruling, or
- fail N1/N2 at acceptance, which checks only this list.

**Fix:**
- Add "dw-* slug citations" (a pattern such as `dw-\d+-[a-z-]+`) and references to the epic's file path to D9's allowlist and N1's list.
- Decide the epic's display name in current docs: either rename it (e.g. "PLANET CHAT WEB EPIC", with the path kept) or record it as an exception.

## Non-blocking

- **N-a (D6/N5).** The implicit primary keys `divination_summary_pkey` and `divination_voice_pkey` DO exist, because 011/012 declare `summary_key`/`voice_key text PRIMARY KEY`. `ALTER TABLE … RENAME` does not rename them. Say "rename the two `_pkey` constraints" rather than "if any", and have N5 assert the constraint names.
- **N-b (D10/N1).** `docs/features/` does not exist in the repo. Drop the reference, or say "if present".
- **N-c (D7).** The first-use file move can race: the job thread and the request thread may both hit "first use" at once. Leave this to the plan's risks (a lock or an atomic rename plus an existence re-check), not to the spec.
- **N-d (D3).** The case for keeping `web-divination/` is adequate: the running Vite dev server serves from it, plus the workspace, lockfile and guard churn. It can be strengthened: `git mv` would also leave untracked local files (`web-divination/.env*`) behind. The choice is recorded, as the ruling requires.
- **N-e (D9).** The rename guard is duplicated in a server test and a jest test, both scanning the whole repo. That is heavier than needed. One repo-wide scan plus its planted self-check would satisfy N2. The duplication is acceptable if the plan keeps the two allowlists identical, e.g. one allowlist file that both suites read.
- **N-f (D1).** The core test files become `core-planet-chat*.test.ts` (kebab-case), while the module is `planet_chat`. That is fine, but state that the kebab-case in those file names is deliberate, so N1/N2 do not flag the mismatch.

## Checklist

1. **Serves the ruling, right-sized: PASS.** It covers every scope item and every data bridge, and the key-stability choice is recorded. The only extra is the D9 guard, which is justified by the ruling's "loop closed" grep.
2. **Criteria concretely checkable: PASS.** N1–N10 and R1 are runnable. N4 uses golden values from the base commit.
3. **No contract violation, consistent with the epic: PASS.** No boundary moves, guards are renamed and not weakened, and applied migrations are untouched.
4. **Non-goals and decided defaults complete: FAIL on B1** (the slug and epic-reference exceptions are undecided in N1/D9).
