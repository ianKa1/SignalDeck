# 09 — docs-sync (dw-14-web-navigation)

Skill: `/update-architecture-doc` on `docs/ARCHITECTURE.md` (worktree),
baseline = its last touch 8032e68 (dw-15, arrived by the merge); the diff
since is this feature's commits. Sections edited (surgical, present tense):
- Overview (web-divination bullet): conversations logged as they happen; the four routes.
- Repo structure: new `nav/` entry; `app/` (MainNav, HomeScreen, ChatScreen, NotFound),
  `birth-input/BirthCard`, `roster/` (Home plates, "last"), `log/` (open cards, route-driven reader).
- Guards paragraph: G16 and G17.
- `core/divination` → `session-log.ts`: `OpenSession | SealedSession`, header-only open records,
  `recordEntry`, `adoptTranscripts`, seal-in-place End, absent-if-empty, open never evicted,
  snapshot/subscription over transcripts. `roster.ts`: the KV key now means "last spoken with".
- web-divination section: gate keeps the URL; new **Routes** bullet (incl. the edge rules with
  the S4 wording "…except the existing `auth/AuthGate.tsx` → `app/Header` edge"); **Layout**
  rewritten (masthead + route switch, titles, focus after push, seed); Chat (recordEntry);
  Session log (adopt, open card, Links, missing id, Continue); persona header link home;
  The six (Home page, links, "last", route-scoped shell); dw-15 focus now fed by ChatScreen;
  i18n namespaces; Tests list.
- Data flow: recordEntry, seal-in-place End, a Navigation paragraph, The six via routes, hand-off push.
- Testing count 42 files / 386 tests; Feature docs index entry.
Verification: every new path exists (`ls`), the edge claims were grepped
(`from '../app/'` only in `auth/AuthGate.tsx`; `nav/` imports only react,
`@astrace/core/divination`, siblings; roster/chat/log import only `Link`/`pathFor`).
No pre-existing drift found outside the diff.
Commit 5f88215 `(docs): dw-14-web-navigation — architecture doc: …`.

Feature doc: `docs/features/dw-14-web-navigation.md` written in the PRIMARY
checkout (docs/features/ is gitignored — the sibling feature docs live there too).

Epic: `pipeline/epics/divination-web.md` — Target modules gain `nav/`, `app/`,
the core session-log open records and the log's open cards; a dw-14 entry
beside the dw-13/dw-15 entries; a dw-14 dependency-rule bullet (nav/ leaf,
S4 edge wording, G16, G17).

Done-when: `grep -c "nav/" docs/ARCHITECTURE.md pipeline/epics/divination-web.md` → 9 and 6.

Not written here (coordinator is the single writer): DECISIONS.md entries
(D13's three Supersedes, SG1) and QUEUE.md — handed back in the final report.

Status: docs-sync → accepting (coordinator).
