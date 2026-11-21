#!/usr/bin/env bash
#
# Create a git worktree off a base branch, then mirror the live .claude
# directory into it.
#
# Usage:
#   bash setup-worktree.sh <src-repo-root> <dest-worktree-path> <branch> <base-branch> [task-dir]
#
# Also copies the gitignored root files a fresh checkout lacks (.env*,
# CLAUDE.local.md) and, when task-dir names an existing CRISPY task directory
# under <src>/.agents/artifacts/, copies it to the worktree under the
# branch-derived name (/ -> -) so the phase skills find it there.
#
# Exits non-zero, naming the specific collision, rather than clobbering an
# existing worktree, directory, or branch.

set -euo pipefail

SRC="${1:?source repo root required (git rev-parse --show-toplevel)}"
DEST="${2:?destination worktree path required}"
BRANCH="${3:?branch name required (e.g. feat/ENG-123-slug)}"
BASE="${4:?base branch required (e.g. main)}"
TASK_DIR="${5:-}"

fail() {
  printf 'setup-worktree: %s\n' "$1" >&2
  exit 1
}

# --- Pre-flight: never clobber existing work --------------------------------

if ! git -C "$SRC" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  fail "source path is not a git repository: $SRC"
fi

case "$(git -C "$SRC" rev-parse --git-dir)" in
  */worktrees/*) fail "source is itself a worktree: $SRC (run from the main checkout)" ;;
esac

if [ -n "$TASK_DIR" ] && [ ! -d "$SRC/$TASK_DIR" ]; then
  fail "task directory not found: $SRC/$TASK_DIR"
fi

if [ -e "$DEST" ]; then
  fail "destination already exists: $DEST (reuse it, choose another name, or 'git worktree remove $DEST')"
fi

if git -C "$SRC" worktree list --porcelain | grep -qxF "worktree $DEST"; then
  fail "a worktree is already registered at: $DEST"
fi

if git -C "$SRC" show-ref --verify --quiet "refs/heads/$BRANCH"; then
  fail "branch already exists: $BRANCH (choose another name, or 'git branch -D $BRANCH')"
fi

if [ ! -d "$SRC/.claude" ]; then
  fail "no .claude directory to mirror at: $SRC/.claude"
fi

# --- Create the worktree from the latest base -------------------------------

if git -C "$SRC" fetch origin "$BASE"; then
  START="origin/$BASE"
else
  START="$BASE"
  printf 'setup-worktree: fetch failed; branching from local (possibly stale) %s\n' "$BASE" >&2
fi

git -C "$SRC" worktree add -b "$BRANCH" "$DEST" "$START"

# --- Mirror the live .claude directory --------------------------------------
# Positive validation before any rm -rf: refuse to delete under a path that is
# not a real worktree, so an empty or mistyped DEST cannot reach '/.claude'.

if ! git -C "$DEST" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  fail "refusing to modify a path that is not a git worktree: $DEST"
fi

rm -rf "$DEST/.claude"
cp -r "$SRC/.claude" "$DEST/.claude"
rm -f "$DEST/.claude/scheduled_tasks.lock"

# --- Copy gitignored root files and the CRISPY task directory --------------

for f in "$SRC"/.env* "$SRC/CLAUDE.local.md"; do
  if [ -f "$f" ]; then cp "$f" "$DEST/"; fi
done

if [ -n "$TASK_DIR" ]; then
  TASK_DEST="$DEST/.agents/artifacts/${BRANCH//\//-}"
  mkdir -p "$(dirname "$TASK_DEST")"
  cp -r "$SRC/$TASK_DIR" "$TASK_DEST"
  printf 'setup-worktree: task directory copied to %s
' "$TASK_DEST"
fi

printf 'setup-worktree: %s ready on %s (from %s); .claude mirrored from %s\n' \
  "$DEST" "$BRANCH" "$START" "$SRC"
