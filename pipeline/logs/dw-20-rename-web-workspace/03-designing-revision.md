# 03 designing (revision 1) — dw-20-rename-web-workspace (2026-09-29)

Review 02 FAIL: R4 said the live-file sweep prints only the migration, but D5
(planted self-check in both rename guards) and D6 (allowlist entry) make it
four files.

Change: R4 now names the four expected files and the one reason each may
match; the epic-file check is unchanged. Minor note taken for implementation:
the epic's dw-19 line ("the folder and package keep …") is reworded as
history ("kept until dw-20-rename-web-workspace renamed it"), not name-swapped.
Transition: spec-review (revision) → spec-review (round 2).
