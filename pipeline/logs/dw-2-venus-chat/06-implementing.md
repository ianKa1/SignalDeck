# 06 — implementing, cycle 1 (validating → implementing) — dw-2-venus-chat

Trigger: 05-validating.md, A2 FAIL (4 paragraphs against the 1–3 rule; voice generic) under claude-cli.

## Experiment (before changing code)
Ran `claude -p --output-format json --model opus --system-prompt "<venus.txt + lang.en>" --tools ""` from /private/tmp twice, with the same flattened conversation. Result: 3 paragraphs / 162 words and 3 paragraphs / 160 words; the second includes a Venus "I" ("I've watched many people cling to friends…").

## Fix
- `server/app/llm.py` `LocalClaudeProvider.stream`: the system prompt now rides `--system-prompt` (replacing Claude Code's default agent prompt) instead of the top of stdin. `--tools ""` is added, and the CLI runs with `cwd=tempfile.gettempdir()` so the repo's CLAUDE.md is not in the persona's context. `_flatten_turn(messages)` now carries only the conversation.
- `server/app/divination/personas/venus.txt`: "never more than three" paragraphs, and a closing question belongs inside the last paragraph. One new line asks for a light touch of Venus's own voice (an "I" who has watched lovers, or one image from her world), "never a costume".
- `server/tests/test_llm_stream.py`: asserts `--system-prompt <system>`, `--tools ""`, a non-repo cwd, and that the system text is not in stdin.
- Deviation for journaling (D8): the spec's CLI argv listed `claude -p --output-format stream-json --verbose --include-partial-messages --model <m>` with the transcript flattened on stdin. The stdin flattening stays; `--system-prompt`, `--tools ""` and a neutral cwd are added. Why: real-app evidence that the persona is not honoured under the default agent prompt.
- Check: `pytest tests/test_llm_stream.py tests/test_divination_render.py tests/test_divination_turn.py tests/test_boundaries.py -q` → `68 passed, 1 warning in 1.75s`.

## Follow-up within cycle 1: the zh paragraph rule
- The re-validation showed the en fix holding (3 paragraphs), but a zh reply still came back in 4, with a lone closing question.
- Experiment: `lang.zh` plus the rule restated in Chinese (最多三段；问句写在最后一段末尾，不要单独成段), 3 runs of 分手之后还能做朋友吗？ → 3/3/3 paragraphs.
- Fix: `server/app/divination/render.py` `lang.zh` carries that sentence. `pytest tests/test_divination_render.py tests/test_divination_turn.py -q` → `31 passed`.
