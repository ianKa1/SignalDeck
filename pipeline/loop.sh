#!/usr/bin/env bash
# Fully-unattended pipeline driver.
#
# Each iteration runs in a FRESH headless Claude session (`claude -p`),
# which is the automatic equivalent of /clear between iterations — no
# human ever runs /compact or /clear (see PIPELINE.md "Context hygiene").
#
# Usage:   bash pipeline/loop.sh [max_iterations]   (default 30)
#
# Permissions: `--permission-mode acceptEdits` auto-approves file edits but
# may still prompt for some Bash commands in stricter setups; for truly
# unattended runs either allowlist the needed commands in
# .claude/settings.json permissions, or (at your own risk, sandboxed
# machines only) replace the flag with --dangerously-skip-permissions.
set -euo pipefail
cd "$(dirname "$0")/.."

MAX_ITER="${1:-30}"

# BASE BRANCH (user-directed 2026-08-29). PIPELINE.md says feature branches
# fork from `main` and squash-land onto `main`. `main` is the PRODUCTION
# deploy branch (Render) and receives work only by PR from `dev`; an epic
# built on top of unlanded dev work (the ASK epic sits on the UI redesign +
# the tarot register, neither of which is on main) must fork from and land
# onto the branch that HAS that work. So the base is the branch the loop is
# started from, unless BASE_BRANCH says otherwise — wherever PIPELINE.md's
# Git-granularity section says `main`, the iteration reads this branch.
BASE_BRANCH="${BASE_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}"
if [[ "$BASE_BRANCH" == "main" ]]; then
  echo "refusing to run the loop with main as the base branch (production deploy branch); start it from dev or an epic branch, or set BASE_BRANCH" >&2
  exit 1
fi
# A restart made while the tree sits on a FEATURE branch (feature/<slug> for
# a QUEUE.md entry) must not adopt that branch as the base: it is deleted
# when its slice lands, and every later iteration would name a dead ref.
# (Happened 2026-08-30 after a mid-feature restart; the iterations coped
# through DECISIONS.md, but the prompt was lying.) Refuse and say so.
if grep -qx "## ${BASE_BRANCH#feature/}" pipeline/QUEUE.md 2>/dev/null; then
  echo "refusing: $BASE_BRANCH is a queue feature branch, not the epic base; set BASE_BRANCH=<epic branch> (e.g. feature/asking_golden_dawn)" >&2
  exit 1
fi
echo "base branch: $BASE_BRANCH"

PROMPT="Read pipeline/PIPELINE.md and pipeline/QUEUE.md, then execute exactly ONE pipeline iteration (one stage transition, or one implementing step), following every rule (skills per stage, logging, decision journal, commit via /git-commit). BASE BRANCH OVERRIDE: this epic's base branch is \`$BASE_BRANCH\`, not \`main\` — create feature/<slug> from \`$BASE_BRANCH\`, squash-land onto \`$BASE_BRANCH\`, and never check out, commit to, or merge into \`main\` (it is the production deploy branch). Then stop. If nothing is actionable, say so and include the line LOOP-IDLE."

# MODEL POLICY (user-directed 2026-08-29: "Use FABLE first and if it runs out,
# use OPUS"). Two mechanisms, because they cover different failures:
#   --fallback-model  handles OVERLOADED / UNAVAILABLE only, per its own help
#                     text, and re-tries the primary each turn.
#   the retry below   handles USAGE EXHAUSTION, which --fallback-model does
#                     NOT catch. Proven 2026-08-30 07:45: the run died on
#                     "You've reached your Fable 5 limit" with the fallback
#                     flag set. On that message the SAME iteration is re-run
#                     on $FALLBACK_MODEL, and the run stays there — a spent
#                     window does not reopen within a run, so re-probing the
#                     primary every iteration would just burn a failed call.
MODEL="${MODEL:-fable}"
FALLBACK_MODEL="${FALLBACK_MODEL:-opus}"

is_limit_message() {
  grep -qiE "reached your .*limit|usage limit|limit reached|out of .*credits" <<<"$1"
}

for i in $(seq 1 "$MAX_ITER"); do
  echo "════ loop iteration $i — $(date '+%H:%M:%S') ════ [$MODEL]"
  set +e
  out="$(claude -p "$PROMPT" --model "$MODEL" --fallback-model "$FALLBACK_MODEL" \
        --permission-mode acceptEdits 2>&1)"
  rc=$?
  set -e
  if is_limit_message "$out" && [[ "$MODEL" != "$FALLBACK_MODEL" ]]; then
    echo "  ↯ $MODEL is out of usage window — re-running this iteration on $FALLBACK_MODEL (and staying there)"
    MODEL="$FALLBACK_MODEL"
    set +e
    out="$(claude -p "$PROMPT" --model "$MODEL" --permission-mode acceptEdits 2>&1)"
    rc=$?
    set -e
  fi
  if [[ $rc -ne 0 ]] || is_limit_message "$out"; then
    printf '%s\n' "$out" | tail -n 15
    echo "claude exited non-zero or hit a usage limit on $MODEL — stopping loop." >&2
    exit 1
  fi
  printf '%s\n' "$out" | tail -n 25
  # Anchored to a whole line: an iteration that merely MENTIONS the sentinel
  # ("this is not LOOP-IDLE") must not stop the loop — PIPELINE.md requires
  # the exact line, so the runner demands it too.
  if grep -qE '^[[:space:]]*LOOP-IDLE[[:space:]]*$' <<<"$out"; then
    echo "Queue idle — loop finished after $i iteration(s)."
    exit 0
  fi
done
echo "Reached max iterations ($MAX_ITER) — stopping. Re-run to continue."
