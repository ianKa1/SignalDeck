# Plan — dw-17-web-two-pane-layout

Spec: `pipeline/specs/dw-17-web-two-pane-layout.md`. Worktree `../astrology-wt/dw-17-web-two-pane-layout`. Ports: backend 8002, Vite 5175, CDP 9318. Web-only.

Review notes settled: N1 the jump controls are BUTTONS calling `scrollIntoView` (no `#hash` link, so no history entry); the spec's `a[href="#chart-pane"]` becomes `button[data-jump="chart"|"chat"]`. N2 no visibility gating for the spotlight (the spec's "only when visible" clause is dropped). N3 close on `mousedown` outside; CityPicker's list is inside the popover. N4 delete only i18n keys unreferenced once Placements goes; keep `chart/format.ts`; W1 asserts on `.placements`/`.big-three` classes and text, not `[data-big-three]`. N5 audit App/ChartStage tests that assert the empty-ring state on chat routes; move them to the form-in-stage behaviour. N6 the wheel's square leaves room for the focus toggle and status line. N7 BirthCard keeps reading via `useBirthData()` (dw-16 merge touches presentation only). N8 R3 uses `ANALYSIS_LLM=claude-cli` and a seed question likely to produce a pill, one retry allowed.

## Steps

- [x] **0. Baseline.** `npm test`, `npm run typecheck` in the worktree; counts logged. Done-when: green.
- [x] **1. Remove Placements.** Delete `chart/Placements.tsx`, its test, `.big-three`/`.placements` CSS; drop the render in `app/ChatScreen.tsx`; delete now-unreferenced i18n keys in en/zh. Done-when: `npx vitest run` green; `grep -rn "bigThree\|Placements" web-divination/src` empty.
- [x] **2. Birth chip + popover.** New `birth-input/BirthChip.tsx`; `BirthCard.tsx` chip + anchored non-modal dialog over `BirthForm` (focus in/out, Escape, Cancel, mousedown-outside); delete `BirthSummary.tsx`; CSS in `birth-input.css`; i18n keys. Tests W2, W3, W5 (new `birth-input/BirthCard.test.tsx`; update BirthForm/Home tests). Done-when: those tests green.
- [x] **3. Two panes.** `app/ChatScreen.tsx` (chart pane `#chart-pane`: BirthCard + ChartStage or the inline form when nothing is saved; chat pane `#chat-pane`: SessionBar + ChatPanel; jump buttons), `app/app.css` (equal columns ≥ 960 px, 100dvh shell column on chat routes, chat-first stacking < 960 px, divider rule), `chat/chat.css` (flex-filled transcript, drop 60vh, composer pinned). Tests W1, W4, W7, W8 (fix App/ChartStage tests per N5). Done-when: `npm test` + `npm run typecheck` green; colour/text guards green.
- [x] **4. Validate on the real app** (validating stage): local backend :8002 with `DATABASE_URL` set to a throwaway local cluster db and `WEB_DATABASE_URL=` empty set explicitly (never `--env-file .env`; never the Neon URLs), `CORS_ALLOW_ORIGINS=http://localhost:5175`, `ANALYSIS_LLM=claude-cli`; Vite :5175 with `VITE_API_BASE=http://localhost:8002`; minted bearer pair (dw-12 recipe) in localStorage; headless Chrome over CDP at 1440×900 and 390×844. R1–R5 with screenshots. Done-when: evidence in the validating log.

## Acceptance map

| Criterion | Step |
|---|---|
| W6 | 1 |
| W2, W3, W5 | 2 |
| W1, W4, W7, W8 | 3 |
| G1 | 1–3 |
| R1–R5 | 4 |

## Risks for the implementer

- dw-16 (parallel) changes the sign-in gate and the birth-data sync; this branch sees dw-12's gate. Conflicts in `birth-input/`, `i18n/`, `app/` are expected at landing and resolved by the coordinator.
- `100dvh` + the shell's padding: measure `scrollHeight === innerHeight` in R1, not by eye.
- The chat panel's autoscroll-to-bottom logic assumed the 60vh box; check it still pins to the newest slip in a flex-filled container.
