# dw-14-web-navigation — 01 designing

- Date: 2026-09-29. Branch: feature/divination_web @ 8da99b2 (no switch, no code edit, no commit — pipeline files only).
- Status transition: designing → spec-review (the coordinator writes QUEUE.md).
- Output: `pipeline/specs/dw-14-web-navigation.md`. Word counts: Goal + Non-goals + Decided defaults ≈ 1,650 (a little over the ~1,500 budget: D1 keeps its rejected alternatives, and D13 lists the superseded decisions); Architecture ≈ 1,450; Acceptance Criteria ≈ 1,470 (these are never trimmed).

## Inputs read
- CLAUDE.md; pipeline/PIPELINE.md, including Skills per stage, the pipeline-mode overrides, Spec requirements and Decision precedence; the QUEUE.md `dw-14-web-navigation` entry; `pipeline/epics/divination-web.md`.
- Tier-1 user confirmation, relayed by the coordinator (2026-09-29): HOME is the six-planet picker.
- Targeted code reads, all in web-divination/src unless marked:
  - `main.tsx`, `app/App.tsx`, `app/Header.tsx`, `auth/AuthGate.tsx`, `auth/AccountChip.tsx`;
  - `roster/RosterPicker.tsx`, `roster/useRoster.ts`;
  - `log/SessionBar.tsx`, `log/SessionsScreen.tsx`, `log/useSessions.ts`, `log/SessionTranscript.tsx`, `log/SummaryCard.tsx`;
  - `chat/useChat.ts` (the three `appendEntry` sites), the ChatPanel props, `PersonaHeader`, `chart/ChartStage.tsx`;
  - `vite.config.ts`, `package.json`, `index.html`, `platform/auth.ts` (the KV key names);
  - core `divination/{index,session-log,transcript,roster}.ts`;
  - `app-native/src/architecture.test.ts` (the web guards and the public-api orphan guard);
  - dw-12's spec R2 and `logs/dw-12-google-sign-in/10-accepting.md` (the minting method);
  - dw-15's spec (the App.tsx/ChartStage overlap);
  - DECISIONS.md dw-6 entries.
- Router availability: `ls node_modules | grep -iE "router|wouter|history|navigation|tanstack"`, run at the root, in `web-divination/` and in `app-native/`, found nothing. No router is installed anywhere.

## Skills invoked (in order)
1. `frontend-design`, loaded first because the feature is frontend-facing. It set D12's visual register: a running-head nav in small caps, Home as a frontispiece, and a not-found screen of one engraved line, all inside the existing almanac language.
2. `feature-spec`, in pipeline mode. It wrote the Goal, the Non-goals, the Decided defaults D1–D13 and the Acceptance Criteria, and asked no questions.
3. `architecture-designer`, in pipeline mode. It wrote the Architecture section as this feature's delta only, citing the epic, with no Migration Steps.

## Key decisions (detail in the spec)
- **Router (D1)**: in-house, about 150 lines in the new `web-divination/src/nav/`. react-router was rejected on size and churn, and wouter because it adds a dependency to replace code this small.
- **URLs (D2)**: `/`, `/chat/<id>`, `/sessions`, `/sessions/<id>`, and not-found for everything else. A trailing slash is canonicalized with `replaceState`.
- **Home (D3)**: the picker is a page, not a dialog. The stored active character never redirects. The KV key now means "last spoken with".
- **Birth entry (D4)**: on Home and on the chat routes, through the same components and store. The wheel is on chat routes only.
- **Masthead (D5)**: every route has a home link, the Sessions link and Sign out. The gate's masthead has no nav, so dw-12 W1 still holds.
- **Sessions (D8)**: open sessions are recorded as they happen. The live transcript is the open record's body, so there is one copy of the text. End seals the SAME id. Only core writes the transcript, through `recordEntry`, which is guarded by G15. Old transcripts are adopted on load.
- **History fallback (D11)**: Vite's default SPA fallback is enough, and the config does not change. Session ids never contain a dot.
- **New guards**: G14 (only `nav/history.ts` names history/location/popstate) and G15 (no web `appendEntry(`), plus one CLAUDE.md sentence.
- **Overlap**: with dw-15, `<ChartStage persona>` moves into `app/ChatScreen.tsx`, and whichever feature lands second moves the prop.

## Superseded loop decisions (tier 3; to journal under Supersedes)
- "### 2026-09-28 · dw-6-session-log · spec-review — spec auto-approved (round 1); content-keyed summary store, device-local session log, fingerprint kept OUT of the key". Choice (f): a session enters the log only on End. D8 supersedes it.
- dw-6 D11: Sessions is a view swap with no router, and a reload opens on the chart. D2 supersedes it.
- dw-8: the picker is a modal over everything when no character is stored, and otherwise an overlay closed by Esc or "← Back to …". D3 supersedes it.

No tier-1 conflict was found. The dw-12 forced-sign-in ruling is honored: the gate wraps every route (D6).
- 2026-09-29 coordinator: guards renumbered G14→G16 (history owner), G15→G17 (appendEntry) to avoid collision with dw-15's approved G14/G15.

## Amendment (2026-09-29, coordinator request)
- dw-14's guards were renumbered to avoid a clash with dw-15-wheel-spotlight's approved G14 ("one shader text") and G15 ("one canvaskit importer"). The history-owner guard is now **G16**, and the no-web-`appendEntry(` guard is now **G17**. Every reference in the spec was updated (Architecture and criterion G1). The CLAUDE.md sentence names no guard number.
- The part before Architecture was trimmed from about 1,650 to about 1,535 words: D1's rejected alternatives are one line each, and the Non-goals, the header and D12 were condensed. The acceptance criteria were not changed.
