# 03 — designing (revision, 2026-09-29)
- Round-1 FAIL on B1 (FastAPI parses JSON before dependencies; malformed JSON → 422). D2 rewritten; S2 pinned to well-formed `{}` → 401, malformed → 422 with zero work.
- Notes applied: N1 postJson delegates to apiFetch (no second refresh path); N2 prompt lab gets an override stub; N3 native inertness stated; N4 options-object left to the plan; N5 release the first stream on retry; N6 C5 names the keys; N7 cached_for added to S1 spies.
- Status: re-review (round 2).
