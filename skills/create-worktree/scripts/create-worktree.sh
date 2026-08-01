#!/usr/bin/env bash
#
# Create a git worktree off a base branch, then mirror the live .claude
# directory into it.
#
# Usage:
#   bash create-worktree.sh <src-repo-root> <dest-worktree-path> <branch> <base-branch>
#
# Exits non-zero, naming the specific collision, rather than clobbering an
# existing worktree, directory, or branch.

set -euo pipefail

SRC="${1:?source repo root required (git rev-parse --show-toplevel)}"
DEST="${2:?destination worktree path required}"
BRANCH="${3:?branch name required (e.g. feat/ENG-123-slug)}"
BASE="${4:?base branch required (e.g. main)}"

fail() {
  printf 'create-worktree: %s\n' "$1" >&2
  exit 1
}

# --- Pre-flight: never clobber existing work --------------------------------

if ! git -C "$SRC" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  fail "source path is not a git repository: $SRC"
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

# --- Create the worktree from the latest base -------------------------------

if git -C "$SRC" fetch origin "$BASE"; then
  START="origin/$BASE"
else
  START="$BASE"
  printf 'create-worktree: fetch failed; branching from local (possibly stale) %s\n' "$BASE" >&2
fi

git -C "$SRC" worktree add -b "$BRANCH" "$DEST" "$START"

# --- Mirror the live .claude directory --------------------------------------
# Positive validation before any rm -rf: refuse to delete under a path that is
# not a real worktree, so an empty or mistyped DEST cannot reach '/.claude'.

if ! git -C "$DEST" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  fail "refusing to modify a path that is not a git worktree: $DEST"
fi

if [ ! -d "$SRC/.claude" ]; then
  fail "no .claude directory to mirror at: $SRC/.claude"
fi

rm -rf "$DEST/.claude"
cp -r "$SRC/.claude" "$DEST/.claude"
rm -f "$DEST/.claude/scheduled_tasks.lock"

printf 'create-worktree: %s ready on %s (from %s); .claude mirrored from %s\n' \
  "$DEST" "$BRANCH" "$START" "$SRC"
