#!/usr/bin/env bash
# Context-efficient backpressure wrapper (HumanLayer pattern, Dec 2025).
# Runs a verbose command, writes the FULL output to a log file, and prints
# only a compact summary so the agent's context window stays lean.
#
# Usage:  backpressure.sh <command> [args...]
# Env:    BACKPRESSURE_LOG_DIR  override the log directory
#         BACKPRESSURE_TAIL     lines of tail context to print (default 20)
#
# Exit code mirrors the wrapped command's exit code.

set -u
if [ $# -eq 0 ]; then
  echo "usage: backpressure.sh <command> [args...]" >&2
  exit 2
fi

LOG_DIR="${BACKPRESSURE_LOG_DIR:-$HOME/.claude/logs/backpressure}"
mkdir -p "$LOG_DIR"

slug=$(printf '%s' "$*" | tr -cs '[:alnum:]' '-' | cut -c1-48)
slug=${slug#-}; slug=${slug%-}
log="$LOG_DIR/$(date +%Y%m%d-%H%M%S)-${slug:-cmd}.log"

"$@" >"$log" 2>&1
status=$?

tail_n="${BACKPRESSURE_TAIL:-20}"
echo "command: $*"
echo "exit_code: $status"
echo "full_log: $log ($(wc -l <"$log" | tr -d ' ') lines)"
echo "--- last $tail_n lines ---"
tail -n "$tail_n" "$log"
if [ "$status" -ne 0 ]; then
  echo "--- error/fail lines (first 40 matches) ---"
  grep -inE '\b(error|fail|failed|failure|exception|fatal|assert)' "$log" | head -n 40
fi
exit $status
