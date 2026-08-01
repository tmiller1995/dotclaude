---
name: create-worktree
description: "Create a git worktree for a Linear issue and make it fully ready for development in one shot: branch off the target base (default `main`), mirror the live `.claude` directory (skills, agents, settings) into the new worktree, and build a fresh CodeGraph index there. Use this whenever the user wants to set up a worktree, start an issue in an isolated working copy, spin up a parallel checkout, or says things like 'create a worktree', 'new worktree for ENG-123', 'set up a worktree for this issue', 'worktree off main', or 'spin up a worktree'. Names the worktree as a sibling directory combining repo name and issue id (e.g. myrepo-ENG-123) and runs codegraph init -i automatically."
argument-hint: "<ENG-123> [base-branch]"
---

# Create Worktree

Set up a git worktree that is *immediately ready to work in*. A bare `git worktree add` leaves a checkout that's missing two things this team relies on:

1. **The live `.claude` directory** — uncommitted skill edits and `settings.local.json` are not what a fresh `main` checkout contains. `.claude` is tracked, so the *committed* version arrives with the checkout, but uncommitted skill changes and gitignored local settings do not. Mirroring the working copy gives the new worktree the exact tooling in use right now.
2. **A CodeGraph index** — `.codegraph/codegraph.db` is gitignored and local to each worktree (~150 MB). Without it, the codegraph MCP server in the new session has nothing to query. Building it up front keeps the first session fast.

This skill does both, following the conventions already visible in the repo: worktrees are sibling directories named `<repo>-<id>` (e.g. for repo root `C:/Repos/<repo>` and issue `ENG-123`, the worktree is `C:/Repos/<repo>-ENG-123`) on `prefix/ENG-123-slug` branches.

## Inputs

Get these from the user (ask only for what's missing):

- **Issue identifier** (e.g. `ENG-123`) — required. Drives both the branch name and the directory name. Preserve its casing exactly.
- **Branch type** — `feat/`, `fix/`, or `chore/`. Infer from the user's wording using the git-branch-namer keyword rules; only ask if genuinely ambiguous.
- **Base branch** — defaults to `main`. Use whatever the user names if they specify one (some repos may still override with `develop`).
- **Title** — only needed to build the slug. If the user didn't give it, fetch it from Linear (see step 2). If Linear is unavailable, ask the user for a short description.

## Steps

### 1. Resolve paths and the source repo

Run `git rev-parse --show-toplevel` to get the **source repo root** (`$SRC`). The mirrored `.claude` directory comes from here — the working copy the skill was invoked from, so it reflects the current tooling.

Derive the worktree directory as a **sibling** of the repo root: `<parent-of-SRC>/<repo-basename>-<id>`. For repo `C:/Repos/<repo>` and issue `ENG-123`, that's `C:/Repos/<repo>-ENG-123`. Deriving the prefix from the repo's own folder name (`basename "$SRC"`) keeps this correct even if the repo is cloned elsewhere.

Use **forward-slash absolute paths** throughout — git-bash and the codegraph Node CLI both accept them on Windows, and they avoid backslash-escaping headaches.

### 2. Build the branch name

Follow the `git-branch-namer` skill so names are consistent with the rest of the team's branches. Two facts matter here:

- **Prefix**: `feat/` (features/enhancements), `fix/` (bug fixes), or `chore/` (maintenance, deps, tooling, refactors). Auto-detect from the user's wording; only ask if genuinely ambiguous.
- **The issue identifier keeps its exact casing** — it's exempt from kebab-lowercasing, so `ENG-123` stays `ENG-123`.

For the full kebab-case conversion rules, read `~/.claude/skills/git-branch-namer/SKILL.md`.

If only the issue identifier is available, fetch the title from Linear before building the slug:

- Call the `mcp__linear__get_issue` MCP tool with the identifier (e.g. `ENG-123`) or a Linear issue URL.
- Use the returned `title` for the slug. If Linear can't be reached, ask the user for a short description and slugify that.

### 3. Create the worktree and mirror `.claude`

Run the bundled script — it is **executed, not read**:

```bash
bash ~/.claude/skills/create-worktree/scripts/create-worktree.sh "$SRC" "$DEST" "$BRANCH" "$BASE"
```

It performs, in order: pre-flight collision checks (destination path, registered worktree, existing branch), a `fetch` of the base branch, `git worktree add -b` off `origin/$BASE`, a guarded mirror of `.claude`, and removal of the stale runtime lock. `$BASE` defaults to `main`; pass whatever base the user named (e.g. a repo that still uses `develop`).

On a collision the script exits non-zero and names the specific conflict — colliding with an existing worktree or branch is the most common failure. **Stop and report** rather than forcing it. Offer the user the options: reuse the existing worktree (`cd` in), pick a different issue/name, or clean up the old one (`git worktree remove <path>` and/or `git branch -D <branch>`).

If the fetch fails (e.g. offline), the script falls back to the local base branch and says so on stderr — pass that on, since the worktree is then based on a possibly-stale local base.

Why the mirror works the way it does:
- **`rm -rf` then `cp -r`** rather than copying over the top — a plain overlay would leave behind files that exist in the base branch but have since been deleted locally (e.g. retired commands). Mirroring gives the worktree exactly what the source has now. The script validates that the destination is a real git worktree before deleting anything, so an empty or mistyped path cannot reach `/.claude`.
- **Drop `scheduled_tasks.lock`** — it's a runtime lock holding a stale session id/pid. Copying it into a fresh worktree would carry a lock that doesn't belong to that session.
- **`settings.local.json` is intentionally kept** — it's gitignored, so it would *not* arrive via the git checkout, yet it holds the local permission allowlist. Copying `.claude` wholesale is what carries it across.

Do **not** copy `.codegraph/` — it's per-worktree, ~150 MB, and would point at the wrong root. Step 4 builds a fresh one.

### 4. Initialize and index CodeGraph

The `codegraph` binary is a Windows `.cmd` and is **not on the bash PATH**, so invoke it through `cmd.exe`. Pass the worktree path as an argument (don't `cd` — a `cd` inside a compound command can trigger a permission prompt):

```bash
cmd.exe //c "codegraph init -i $DEST"
```

`init -i` initializes `.codegraph/` and runs the initial index in one go (`-i` / `--index`). This is the slow part — indexing a repo this size builds a large database and can take several minutes. Run it with a long timeout, or run it in the background and poll. It needs to finish before the worktree is genuinely "ready," which is the whole point of doing it now instead of on first query.

When it returns, verify the index is populated:

```bash
cmd.exe //c "codegraph status $DEST"
```

Report the file/symbol counts so the user can see indexing actually happened.

If `codegraph` is missing (`command not found` / non-zero from `where codegraph`), the worktree is still fully usable — note that indexing was skipped, how to install it (`npm i -g @colbymchenry/codegraph`), and how to run it afterwards (`codegraph init -i <path>`), then continue.

> Optional — preserve custom index config: if `$SRC/.codegraph/config.json` has non-default include/exclude rules worth carrying over, init without indexing first, copy the config, then index: `cmd.exe //c "codegraph init $DEST"` → `cp "$SRC/.codegraph/config.json" "$DEST/.codegraph/config.json"` → `cmd.exe //c "codegraph index $DEST"`. The default config covers this repo's languages, so the one-line `init -i` above is normally fine.

### 5. Report the next step

Finish by printing the worktree details and the command to open a session there. Don't auto-launch — the user opens the new session themselves:

```
Worktree ready:

  path:    C:/Repos/<repo>-ENG-123
  branch:  feat/ENG-123-<slug>
  base:    origin/main
  .claude: mirrored from C:/Repos/<repo> (live skills + local settings)
  codegraph: indexed (<N> files, <M> symbols)

Open a session there:

    cd C:/Repos/<repo>-ENG-123
    claude
```

## Cleanup (for reference)

When the issue is done and merged, remove the worktree and optionally the branch:

```bash
git -C "$SRC" worktree remove C:/Repos/<repo>-ENG-123
git -C "$SRC" branch -d feat/ENG-123-<slug>
```

## Notes

- The codegraph MCP server resolves its database from the session's working directory, so each worktree must have its own `.codegraph` — that's why step 4 indexes in the worktree rather than reusing the main repo's index.
- This skill is Windows-oriented (paths, `cmd.exe` invocation of `codegraph`). On a POSIX host, drop the `cmd.exe //c` wrapper and call `codegraph` directly.
