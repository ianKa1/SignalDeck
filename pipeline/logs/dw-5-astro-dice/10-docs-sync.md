# 10 docs-sync — dw-5-astro-dice

Skill `/update-architecture-doc`. The baseline was docs/ARCHITECTURE.md's
last commit, 2f45dfb (dw-3). The diff since then is dw-5's 7 commits. The
doc was edited in place, section by section:
- Tech stack, web-divination bullet: the Cast flow in one sentence.
- Repo map (core domains, web `chat/`, server `divination/`): Dice, the cast
  action, DiceCard, `dice.py`, and the dice fragments.
- `core/divination`: `Dice`/`isDice`/`TurnAction`, entry `dice`/`cast`,
  `WireEntry.dice`, the dice gates in `streamTurn`, and sanitize/toWire.
- Server Tier C `divination/`: the dice fragments and the brief;
  `system_prompt`/`turn_messages` (recall fold)/`side_prompt(dice_in_view)`;
  the new `dice.py` paragraph; the `turn_events` dice-first frame plus
  `side.dice`; the wire (`action`, persona `dice`, StrictInt); the tests.
- web-divination Chat + i18n + Tests: useChat actions/dice, the Cast
  button, DiceCard, and the new i18n keys.
- Data-flow chain: the cast branch and the recall.
- Feature index: a dw-5 entry.
I checked every path I named: `server/app/divination/dice.py`,
`personas/venus-dice.txt`, `web-divination/src/chat/DiceCard.tsx` and
`DiceCard.test.tsx` all exist.

`docs/features/dw-5-astro-dice.md` was written in the worktree. It is
gitignored and not force-added.

As instructed, the epic file was NOT edited. The exact changes are handed
to the coordinator in the worker report.

Transition: docs-sync done → coordinator (accepting).
