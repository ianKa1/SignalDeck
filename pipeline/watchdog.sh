#!/usr/bin/env bash
# Watchdog for the headless pipeline runner (loop.sh).
#
# Every CHECK_INTERVAL seconds: if loop.sh is not running AND QUEUE.md still
# has actionable entries (any status other than done/blocked), restart the
# runner. If the queue is fully done/blocked and the runner is stopped, the
# watchdog retires. A restart cap prevents a crash-restart spiral (e.g. the
# claude CLI failing instantly every time).
#
# Usage: bash pipeline/watchdog.sh   (run in background; logs to stdout)
set -uo pipefail
cd "$(dirname "$0")/.."

CHECK_INTERVAL=120
MAX_RESTARTS=10
LOOP_BUDGET=75
LOOP_LOG="pipeline/loop-run-2026-08-19.log"

restarts=0

log() { echo "[watchdog $(date '+%Y-%m-%d %H:%M:%S')] $*"; }

loop_running() {
  pgrep -f "bash pipeline/loop.sh" >/dev/null 2>&1
}

queue_actionable() {
  grep -E '^status:' pipeline/QUEUE.md | grep -qvE 'done|blocked'
}

log "started — watching loop.sh (interval ${CHECK_INTERVAL}s, max ${MAX_RESTARTS} restarts)"

while true; do
  if loop_running; then
    : # healthy, nothing to do
  elif queue_actionable; then
    if [ "$restarts" -ge "$MAX_RESTARTS" ]; then
      log "runner is down and queue is actionable, but restart cap ($MAX_RESTARTS) reached — giving up. Inspect $LOOP_LOG."
      exit 1
    fi
    restarts=$((restarts + 1))
    log "runner is down with actionable queue entries — restart #$restarts"
    nohup bash pipeline/loop.sh "$LOOP_BUDGET" >> "$LOOP_LOG" 2>&1 &
    sleep 15
    if loop_running; then
      log "restart #$restarts confirmed alive"
    else
      log "restart #$restarts died within 15s — see $LOOP_LOG"
    fi
  else
    log "runner stopped and queue is fully done/blocked — retiring. ($restarts restart(s) performed)"
    exit 0
  fi
  sleep "$CHECK_INTERVAL"
done
