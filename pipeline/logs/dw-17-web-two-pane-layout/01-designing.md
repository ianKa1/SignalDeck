# 01 — designing (2026-09-29)
- Wave member 2 (coordinator: dw-16 worker already dispatched). Worktree ../astrology-wt/dw-17-web-two-pane-layout, branch feature/dw-17-web-two-pane-layout from feature/divination_web @ 2e6cfe8; .env + .se1 symlinked; npm install ok.
- Skills: /frontend-design, /feature-spec and /architecture-designer were loaded earlier in this same coordinator session (for dw-16) and applied here under the pipeline-mode overrides; not re-invoked to avoid reloading identical text.
- Reads: app/ChatScreen.tsx, HomeScreen.tsx, app.css (layout), birth-input/BirthCard/BirthSummary, chart/Placements(+test), chat/chat.css, ChatPanel header comment.
- Decided: equal-column grid, pure-CSS 100dvh shell on chat routes, Placements deleted (wheel aria-label + pills remain), birth chip + anchored non-modal popover, no-data → form in the wheel's place, < 960 px chat-first stacking with jump links (no tabs), Home uses the chip.
- Overlap with dw-16: BirthCard/birth-input files and i18n — resolved at landing.
- Spec: pipeline/specs/dw-17-web-two-pane-layout.md. Status: designing → spec-review.
