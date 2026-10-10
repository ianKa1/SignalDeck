# dw-13-character-chat — 01 designing (2026-09-29)
User added dw-13 to QUEUE.md during the dw-10 run (depends: dw-10, now done) → ready.
Branch `feature/dw-13-character-chat` cut from `feature/divination_web` @ c5b1c7e.
Skills: /feature-spec and /architecture-designer (pipeline mode); /frontend-design already loaded this session (web change limited to the opening letter).
Targeted reads: divination/voice.py, voice_role.txt, personas/{venus,moon,dice}.txt, render.py (fragments + system_prompt + tags), bubbles.py, store.py voice table, main.py persona/turn routes, generation.ensure_divination_voice, core persona.ts, web ChatPanel/PersonaHeader; CJK grep across divination prompts (render lang.zh + tags.rules example, voice lang.zh, summary lang.zh).
Decisions: reuse the dw-7 voice machinery as the card (VERSION 2, {card, greeting}); astro-vocab check with ≤3 attempts; prompt = identity + card + 5 ground rules + rhythm + data + tags + lang; proportion caps (shared ≤1,600 / ≤2,300 with sky); bubbles total sentence ceiling 12/20; lab script in server/tests/prompt_lab with unit-tested metrics; thresholds L1–L7.
Status: designing → spec-review.
