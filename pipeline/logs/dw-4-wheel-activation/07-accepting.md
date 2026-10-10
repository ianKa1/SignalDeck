# 07 accepting — fresh-context acceptance check

Worktree `/Users/kaimao/Projects/astrology-wt/dw-4-wheel-activation` @ `3e36cfa`
(branch `feature/dw-4-wheel-activation`). Checked 2026-09-28 by a checker that had not seen
the implementation. Root `npm test`: app-native jest 90 suites / 1069 tests pass, then
web-divination vitest 14 files / 87 tests pass. Root `npm run typecheck`: both workspaces clean.
Real app: backend on :8001 (`ANALYSIS_LLM=claude-cli`, CORS for :5174) and Vite on :5174, driven
by headless Chrome over CDP with a fresh profile (script
`scratchpad/dw4-accept.mjs`, output `scratchpad/dw4-run.log`, screenshots
`dw4-A1-lit.png`, `dw4-A2-aspect-chip.png`, `dw4-A3-followup.png`, `dw4-A6-zh.png`). Birth data
(1990-06-15 08:30, CN → Beijing) was entered through the form. There were no page exceptions and
no console errors. No planted edits were needed.

| ID | Verdict | Evidence | Source |
|----|---------|----------|--------|
| T1 | PASS | `wheel-activation.test.ts` "T1": lit bodies `[Venus]`, lit keys size 0, echo keys are the exact 5-key set, echo bodies `{Jupiter, Moon, Neptune, Pluto, Saturn}`. The test passes. | TESTS/CODE |
| T2 | PASS | "T2" asserts `[VP]` → lit key VP, lit bodies `{Pluto, Venus}`, echo empty. `[VENUS,VP]` puts VP and Pluto in lit and not in echo. `[Sat opp Asc]` → lit `{Ascendant, Saturn}`. The code removes lit entries from echo. | TESTS/CODE |
| T3 | PASS | "T3" checks that `[]`, a null chart and `[Venus square Mars]` give null, that `[VM, VENUS]` toEqual `[VENUS]`, and that `beijingTimeUnknown` lights Venus. | TESTS/CODE |
| T4 | PASS | `ChartWheel.test.tsx` "T4" (two tests) cover every selector the criterion lists, including `[data-aspect-node="Ascendant"]` `data-lit`. | TESTS/CODE |
| T5 | PASS | "T5" loops over undefined and null and asserts no `[data-active],[data-lit],[data-echo]` and 10 `[data-planet]`. The dw-1 ChartWheel tests are unchanged in the diff and pass. | TESTS/CODE |
| T6 | PASS | "T6": the listener is called once, `getActivation()` is `{refs:[VENUS],chip:null}`, `showRefs([])` and `clearActivation()` give null, and an unsubscribed listener's call count is unchanged. | TESTS/CODE |
| W1 | PASS | `App.test.tsx` "W1" uses a gated fake stream. After a delta the svg has no `data-active`; after done `[VENUS,VP]` it has `data-active` and Venus has `data-lit`. | TESTS/CODE |
| W2 | PASS | "W2": `data-active` is gone right after the second send, before any frame. done `[]` leaves it inactive. done `[VP]` does not light Mars and lights VP. After an error, and after Retry and then Stop, it stays inactive. `useChat.run` calls `clearActivation()` first. | TESTS/CODE |
| W3 | PASS | "W3" mounts with no birth data. A reply with `[VENUS]` and a chip press produce no `data-active`, and the chip's `aria-pressed` becomes "true". | TESTS/CODE |
| W4 | PASS | `ChatPanel.test.tsx` "W4 (dw-4)": each `li` holds a `button[type=button][aria-pressed=false]`, Tab reaches Venus and then VP, and the names are "Venus" and "Venus opposition Pluto". The zh variant has 金星 and 金星冲冥王星. | TESTS/CODE |
| W5 | PASS | `App.test.tsx` "W5": after pressing VP, the lit set is exactly `{Venus, Pluto, VP key, node:Venus, node:Pluto}` with no `data-echo`. Pressing VENUS flips the pressed states and shows the echo. Pressing VENUS again leaves no `data-active` and both chips "false". Enter and Space toggle. | TESTS/CODE |
| W6 | PASS | "W6" loads a KV transcript with two persona entries (older VP, newer Mars) and starts inactive. The older VP chip lights VP (Mars not lit) and the newer chip lights Mars. | TESTS/CODE |
| G1 | PASS | Root `npm test` (1069 jest incl. architecture and colour guards, 87 vitest) and `npm run typecheck` exit 0. No `packages/` or `i18n/` path changed, so the one-definition list and en/zh parity are unchanged, and parity passes. | TESTS/CODE |
| G2 | PASS | `git diff --stat 2f45dfb` lists 13 files: `docs/ARCHITECTURE.md` plus `web-divination/src/{app/App.test.tsx, chart/*, chat/*}`. Nothing is under server/, packages/ or app-native/, and neither App.tsx, tokens.ts nor i18n/ appears. | TESTS/CODE |
| G3 | PASS | `wheel.css` has an `@media (prefers-reduced-motion: reduce)` block that sets `transition: none !important` on all 8 base and 8 `[data-active]` activation selectors, which covers the lit and echo variants. All 5 reveal animations use `backwards`, and `grep both` hits only a comment. | TESTS/CODE |
| A1 | PASS | While the reply streamed (180 samples over 18.5 s) `data-active` never appeared. Chips were Venus, Venus opposition Pluto and Saturn opposition Ascendant, and every one was lit (Venus, Pluto, Saturn, both chord keys, and the Ascendant node). After 1 s, Venus had opacity `1` and filter `drop-shadow(rgb(217,150,124) 0 0 3px) drop-shadow(rgba(217,150,124,.35) 0 0 9px)`. Sun, which is neither lit nor echo, had opacity `0.18`. Screenshot `dw4-A1-lit.png` shows rose-copper glyphs over a dimmed wheel. The lit chords glow in their aspect colour, as specified in the CSS. | REAL APP |
| A2 | PASS | Pressing "Venus opposition Pluto" left the lit set exactly `{Venus, Pluto, VP key, node:Venus, node:Pluto}` with 0 echo (`dw4-A2-aspect-chip.png`). The chip had `aria-pressed=true` and border `rgb(217,150,124)`, which equals `--venus` `#d9967c`. Pressing it again gave no `data-active`, 0 lit or echo, and all planets at opacity 1 after 1.2 s. | REAL APP |
| A3 | PASS | With the wheel active from a chip press, sending a follow-up removed `data-active` while "listening" showed. All planets were back at opacity `1` 915 ms after send (≤ 1200). The new chips (Venus, Venus trine Saturn, Saturn, Moon) all lit: Venus, Saturn, Moon, and the `Venus|trine|Saturn` key. | REAL APP |
| A4 | PASS | After a reload the wheel had no `data-active`, 7 chips were restored with 0 pressed, and pressing "Venus" lit Venus and node:Venus. | REAL APP |
| A5 | PASS | With `prefers-reduced-motion: reduce` emulated through CDP (the media query matched), lit Venus had `transition-duration` `0s`, and chords and nodes were also `0s`. Two frames after the press, Venus was at opacity 1 and Sun at 0.18. Two frames after unpressing, every planet was at 1. | REAL APP |
| A6 | PASS | After switching to 中 and asking 为什么我总是爱上难以接近的人？, the reply came back in Chinese and `data-active` stayed off while it streamed. The chips were 金星, 金星冲冥王星 and 土星冲上升点, and they lit Venus, Pluto, Saturn, the Ascendant node and both keys. Lit Venus had opacity 1 and a drop-shadow glow (`dw4-A6-zh.png`). | REAL APP |

Cleanup: the backend (:8001), Vite (:5174) and headless Chrome (:9347) that I started were
stopped; `lsof` shows nothing listening on 8001, 5174 or 9347. `git status --short` in the
worktree is clean. Other worktrees and ports were not touched.

ACCEPTANCE: PASS
