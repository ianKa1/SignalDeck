# 08 — implementing (cycle 2: the bias must fit the 200-char cut)

- Cause (07): cycle 1's longer bias shape overran `BIAS_MAX = 200`; the P7 cut
  (served as the first 200 characters) then bit mid-word in the UI.
- Fix: `voice_role.txt` — intro "at most about thirty words and never more than 180
  characters"; bias "at most about twenty-five words, and never more than 180
  characters (anything longer is cut off mid-sentence)". The cut itself is unchanged
  (P7 pins it).
- New test `test_voice_role_keeps_intro_and_bias_inside_the_cut`.
- `pytest tests/test_divination_persona.py -q` → `39 passed`; full server suite
  `1170 passed, 50 skipped, 1 warning in 105.60s`.
