# dw-14-web-navigation — auto spec review, round 2 (fresh context)

Reviewer inputs:
- the QUEUE.md `dw-14-web-navigation` entry, plus the tier-1 user confirmation (2026-09-29) that HOME is the six-planet picker;
- the revised spec, including its Architecture section;
- `pipeline/epics/divination-web.md`;
- CLAUDE.md;
- PIPELINE.md: Spec requirements, pipeline-mode overrides, Decision precedence, and the `depends:` rule;
- the round-1 review (02) and the revision log (03).

I checked claims against the code with targeted reads at `8da99b2`:
- G16's pattern, run with perl over every non-test `.ts`/`.tsx` under `web-divination/src` with comments stripped, gave **0 hits**.
- The current `appendEntry(` callers are `chat/useChat.ts:173,177,198` only. These are the calls D8 replaces with `recordEntry`.
- `session-log.ts` has `SESSION_LIMITS.sessions = 50`, a raw-keyed snapshot at `:107/:147`, and `canEndSession` at `:170`.
- `App.tsx:74-103` is the chat layout, and `<ChartStage />` sits at `:76`.
- `AuthGate.tsx` renders `Header` when signed out and children when signed in.
- `accounts/service.py:46` has `_upsert_user` and `:59` has `_mint_bearer`.
- `platform/auth.ts:25-27` defines the `astrace.auth.*` keys.
- `test-setup.ts` does not stub `scrollTo` yet. The spec adds that stub.
- DECISIONS.md shows that dw-6 choice f, dw-6 D11 and dw-8's modal picker are loop decisions, not user rulings.

## Round-1 required changes: both resolved

1. **G16 is now defined on the browser globals.** Resolved.
   - The pattern `(?<![\w.$])(?:(?:window|globalThis)\.)?(?:history|location)\s*\.` or `\bpopstate\b` is stated in §Guard amendments.
   - The `history.ts` contract and the forbidden-edges bullet use the same wording.
   - The pattern bites on `history.pushState(...)` and `window.location.pathname`. It does not bite on `data.location.name`, `value?.location.name` or `{ location: initial.location }`, because each of those identifiers is preceded by `.` or is followed by `:` rather than `.`.
   - G1 carries both self-checks: three offenders that must bite and three shapes that must not.
   - I confirmed the 0-hit claim on the current tree.
   - The CLAUDE.md sentence and G3 now claim only the global form. That makes the sentence true.
2. **C5 is now coherent.** Resolved.
   - The start state is reachable and fully seeded: 1 open Moon header over a non-empty Moon transcript, plus sealed `s-1` … `s-49`, for 50 records. A Mars transcript ending on a persona reply has no header.
   - `endSession('mars','en')` passes `canEndSession` and prepends a sealed record (51 records). The `write()` rule keeps open headers and the newest sealed records, which evicts exactly `s-49`.
   - The expected survivors are named.
   - The Moon transcript is seeded non-empty, so the new "empty-transcript header is absent" rule cannot interfere.

## 1. Serves the notes, right-sized: PASS

Every clause of the notes maps to a decided default and a criterion:
- Home is the picker: D3, W1, R1.
- The four URL shapes: D2, N1.
- Back, Forward and reload: N3, R2, R3.
- A way home everywhere: D5, W5, R4.
- The gate wraps every route: D6, W11, R5.
- Sign out everywhere: W5, R4.
- Chats are logged as they happen: D8, W7, C1, C2.
- End only seals and summarizes: W8, C3.
- A failed summary is still listed: W8, C4.
- The router is chosen by reuse and size: D1. No router package is installed, so the in-house choice is justified.
- "Loop closed": R3.

The extras stay small, and each follows from the notes:
- the not-found screens;
- the title and focus handling;
- the "last" mark;
- legacy-transcript adoption, which is needed for chats begun before the upgrade;
- treating an empty-transcript header as absent.

`depends:` names only the functional dependencies (dw-12, dw-13). The dw-15 overlap is handled as a landing concern (§Overlap), which is correct.

## 2. Criteria are concrete and not flaky: PASS

- N, W, C and G are all observable in vitest/jsdom.
- The start URL is set with `replaceState` before mount.
- `scrollTo` is stubbed.
- N3 awaits `popstate`.
- N4 compares `history.length` relatively.
- W8 stubs the summary at 503.
- W4 asserts that no `streamPost` call is made.
- The R tier has a reproducible setup:
  - a throwaway Postgres on 127.0.0.1, with the root `.env` never used;
  - explicit ports 8002/5175, with CORS naming the same Vite port;
  - dw-12 R2's bearer-minting method, whose helpers exist.

## 3. Contract compliance: PASS

- Core stays platform-agnostic: `session-log.ts` gains no Web global.
- Barrel exports are added for `recordEntry` and `adoptTranscripts`.
- The History API is confined to `nav/history.ts`.
- There is no network outside `platform/` (G3 is unchanged).
- There is no server change, so rules 6, 9 and 14 are untouched. The log stays device-local and identity-free.
- There is no new package (G2 pins the dependency keys).
- Rule 13 holds: colour comes only from tokens.
- Rule 8 holds: new copy goes into the web i18n under the parity test.
- G16 and G17 only tighten. Their ids do not collide with dw-15's G14/G15.
- The proposed CLAUDE.md sentence is true as worded.
- The three superseded decisions (D13) are tier-3 loop decisions, are named, and are marked for **Supersedes** journaling.
- The spec agrees with the epic's "client owns the transcript / no server conversation state" rule.

## 4. Non-goals, decided defaults, pipeline-mode shape: PASS

- Non-goals are explicit.
- D1–D13 settle every open point, and there is no open-questions section.
- The Goal is 3 lines and cites the queue entry.
- Word counts are about 1,534 for Goal through Decided defaults and about 1,600 for Architecture. Both are within "about 1,500".
- The Architecture section cites the epic, writes only the delta and has no migration steps.

## Optional notes (non-blocking)

1. The forbidden-edges bullet "No feature folder … imports `app/`" is false against today's tree: `auth/AuthGate.tsx:9` imports `../app/Header`, and the spec keeps that edge on purpose (D5, and the Header `nav` slot that "AuthGate does not" fill). It is not proposed as a guard or for CLAUDE.md, so it does not block. Reword it to "…except `auth/AuthGate` → `app/Header`", or move `Header` out of `app/`.
2. W1 asks for "six links whose `href`s are `/chat/venus` … `/chat/mercury`". Under D3, the name, the seal and every example are all anchors to `/chat/<id>`, so a naive count will find more than six. The test should select the name links, or assert the distinct hrefs in roster order.
3. C3 relies on "C1's state (a persona reply last)", but C1 does not say which role its second `recordEntry` has. Make it explicit: user, then persona.
4. N2's "without a remount of `App`" needs a probe, such as a mount counter or a stable ref. The plan should name the probe.
5. On the gate screen, the wordmark `Link` to `/` is harmless because it is inside `Header`, but it does push a history entry while signed out. That is acceptable. Mention it only if a test counts history entries on the gate.

VERDICT: PASS
