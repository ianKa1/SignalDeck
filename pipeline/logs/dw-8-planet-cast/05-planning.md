# 05 planning — dw-8-planet-cast

Skill: `/imple-plan` under the pipeline-mode override (PIPELINE.md, Skills per stage). `/architecture-designer` not re-run.

## Reads
- CLAUDE.md; PIPELINE.md (Skills per stage, pipeline-mode overrides, Parallel waves).
- `specs/dw-8-planet-cast.md`; `logs/dw-8-planet-cast/04-spec-review.md` (N1–N5); `logs/dw-12-google-sign-in/05-validating.md` (throwaway Postgres + mint recipe); `specs/dw-12-google-sign-in.md` (auth KV key names); `plans/dw-7-persona-mirror.md` (precedent); QUEUE.md statuses (dw-9, dw-12 `accepting`; dw-11 `backlog`).
- Targeted code: `web-divination/src/chat/ChatPanel.tsx` (♀ at :65, :79; `useChat('venus')` :200), `log/SessionTranscript.tsx:53`, `log/SessionBar.tsx:19`, `SummaryCard.tsx:122`, `PersonaHeader.tsx:37`; `i18n/en.ts` / `zh.ts` Venus and `persona.finding`/`biasLabel` strings; `server/app/divination/render.py` (`side.role` :72, focus sentence :93, `self.read` :137); `personas/venus.txt` (base and dw-9 worktree, "even when it arrives dressed…" line present in both); `server/tests/fixtures/divination_chartless_{en,zh}.txt`.

## Output
- `pipeline/plans/dw-8-planet-cast.md` — 12 steps (0–9 implementing, 10 validating, 11 docs-sync), acceptance map covering S1–S10, C1–C3, W1–W6, A1–A5; `wc -w` = 1722 (after log-number fix).

## Review notes settled
- N1: ChatPanel eyebrow/caret + SessionTranscript follow the persona glyph; SessionTranscript added to scope; W5 gains a ☽ check.
- N2: en "{name} is finding a voice…" / "{name}'s bias"; zh "{name}正在寻找自己的声音…" / "{name}的偏见".
- N3: `side.role` neutral ("{name}, one of six planet characters"), no temperament.
- N4: `roster.list` governs; `venus.txt` left byte-identical so S5's fixture rule holds; new persona texts omit the "dressed as something else" clause.
- N5: Esc/Back is a no-op when no character is active (first use).

## Deviations
- S5 references stored as fixture files recorded from the unedited (dw-9-containing) base under `server/tests/fixtures/divination_pre_dw8/`, not read from git at test time.

**Transition:** spec-approved → implementing.
