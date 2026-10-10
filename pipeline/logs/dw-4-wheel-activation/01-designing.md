# 01 designing — dw-4-wheel-activation (2026-09-28)

## Reads
CLAUDE.md; PIPELINE.md (Skills per stage, pipeline-mode overrides, Epic files,
Spec requirements, Auto spec review, Parallel waves); QUEUE.md epic comment +
dw-4 entry; epics/divination-web.md (cited, not re-surveyed); specs/dw-3 +
logs/dw-3/12-final-review.md. Targeted: web-divination/src/chart/{ChartWheel,
ChartStage,useChart,wheel.css,fixtures,ChartWheel.test}, chat/{ChatPanel,
useChat,chat.css (chip block), ChatPanel.test W4}, app/{App.tsx,App.test
harness}, theme/{tokens,apply}.ts; core chart-view/{aspect-set.ts,index.ts},
divination/types.ts (ChartRef, isChartRef); app-native architecture.test.ts
(G1–G9, ONE_DEFINITION_SYMBOLS) and color-guard.test.ts web half. Fixture
aspects listed from server/tests/fixtures/beijing-1990-known-time.json.

## Skills (in order)
frontend-design → feature-spec → architecture-designer, all under the
pipeline-mode overrides (four sections + Architecture; no questions; no
Migration Steps).

## Key choices
- Web only: mapping ref→tiers lives app-side in new chart/wheel-activation.ts
  (equality + set membership over the shown chart via core aspectKey /
  planetFamily; no arithmetic, G4-clean; not a chart value importer, G5 holds).
  Core untouched, per the queue note "Web-only".
- Three tiers: lit (refs + aspect ends), echo (planetFamily of planet refs),
  dim (rest, 0.18). No match → no activation (never all-dim).
- "Current highlight" = a module-level page-session store in
  chart/wheel-activation.ts ({refs, chip}); chat writes, ChartStage reads.
  Chosen over lifting state into App.tsx to keep App.tsx out of the wave's
  conflict surface. Not persisted: reload starts neutral.
- Fade = cleared at send time (incl. Retry); 900ms return transition, 600ms
  entry.
- Glow = CSS drop-shadow on SVG elements (transitionable, colours via
  var(--…)); no new tokens, no i18n keys.
- Chips become li > button[aria-pressed]; press toggles single-ref
  activation. dw-3 W4 ("not buttons") is superseded.
- Implementation risk made a contract: reveal animations' fill-mode
  both → backwards so opacity transitions are not masked.
- No CLAUDE.md, guard or epic amendment.

## Word counts (wc -w)
- spec without Architecture and criteria: 737
- Architecture: 822
- Acceptance Criteria: ~750 (exempt)

## Shared files touched (wave conflict surface)
chat/useChat.ts (two lines in run), chat/ChatPanel.tsx (ChartRefChips +
Entry call site), chat/chat.css (dw-3 chip block), chat/ChatPanel.test.tsx
(W4), app/App.test.tsx (appended describe). Not touched: App.tsx, i18n,
tokens.ts, core, server, guards.

## Transition
designing → spec-review
