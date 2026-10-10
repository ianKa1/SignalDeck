# 06 — implementing (cycle 1: fix for validating run 1's A3(a))

- Cause (05-validating.md): the voice role never asked the BIAS to name the sign, so
  chart B's bias ("I measure worth by what can be trusted, …") did not name Scorpio;
  and its Taurus examples ("I'm your Venus, in Taurus, in your tenth house.", "I look for
  what will last before I look for what thrills …") were copied near-verbatim by the
  Taurus voice.
- Fix: `server/app/divination/voice_role.txt` — the bias now opens with the planet and
  its sign ("As your Venus in <sign>, …", in the request language, sign named as the
  intro names it) and ends by telling them to weigh it; "write it fresh … do not reuse
  wording from these instructions"; the intro example and the opening line are
  `<sign>`/`<nth>` templates. No code change; `divination_voice` FINGERPRINT moves
  (provenance only). VERSION stays 1: no voice was ever stored outside this worktree's
  own gitignored SQLite, which was deleted before the rerun so the rerun writes fresh
  voices (see 07).
- New test `test_voice_role_asks_the_bias_to_name_the_sign` (role text: bias clause
  present; no "Taurus" before the style section).
- `pytest tests/test_divination_persona.py -q` → `38 passed`; full server suite
  `1169 passed, 50 skipped, 1 warning in 105.80s`. Web/root suites untouched by this
  change (last green at 270a80b: 1069 + 181).
