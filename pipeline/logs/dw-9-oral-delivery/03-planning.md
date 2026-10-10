# 03 planning — dw-9-oral-delivery

Skill: `/imple-plan` under the PIPELINE.md pipeline-mode override (steps with
done-when, acceptance map, risks; no Code Structure / Calling Sequence / Data
Flow / Test Plan). `/architecture-designer` not re-run.

Reads: CLAUDE.md; PIPELINE.md (Skills per stage, pipeline-mode overrides,
Parallel waves); spec `specs/dw-9-oral-delivery.md`; review
`logs/dw-9-oral-delivery/02-spec-review.md` (N1–N5); `plans/dw-7-persona-mirror.md`
(landing overlap, chart-less goldens); precedent `plans/dw-6-session-log.md`.
Targeted code: `server/app/divination/turn.py` (`_drain`, `turn_events`),
`render.py` (`lang.zh`, `system_prompt`), `personas/venus.txt`,
`server/tests/test_divination_render.py` (`test_topic_is_registered`,
`DW2_FINGERPRINT`), `web-divination/src/chat/useChat.ts`, `chat.css`
(reduced-motion blocks), package scripts.

Output: `pipeline/plans/dw-9-oral-delivery.md` — 9 steps (0–8: 0–6
implementing, 7 validating on :8002/:5175 with a scratch env without
`DATABASE_URL`, 8 docs-sync reporting the epic delta). `wc -w`: 1853.

Review notes settled in the plan: N1 (T3 asserts the fake's `finally` runs
within 1 s after its event is set), N2 (turn in flight until pacer end;
Stop-after-done stores `stopped`, drops mood/refs), N3 (render set pin gains
four fragments; dw-7 merge hunk), N4 (no empty delta across splits / held
whitespace), N5 (tune `shape.chat`, no server minimum).

Deviations: (1) T7's "unchanged from b308a92" runs as
`git diff feature/divination_web...HEAD` because dw-7 edits `main.py` and
lands first; (2) T6's fingerprint pin is a `DW5_FINGERPRINT` constant
recorded at step 0. No structural decisions beyond the spec.

Transition: spec-approved → implementing (coordinator writes QUEUE.md).
