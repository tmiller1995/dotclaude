---
name: create-worktree
description: "Create a git worktree for a Linear issue and make it fully ready for development in one shot: branch off the target base (default `main`), mirror the live `.claude` directory (skills, agents, settings) into the new worktree, and build a fresh CodeGraph index there. Use this whenever the user wants to set up a worktree, start an issue in an isolated working copy, spin up a parallel checkout, or says things like 'create a worktree', 'new worktree for ENG-123', 'set up a worktree for this issue', 'worktree off main', or 'spin up a worktree'. Follows the <repo>-<id> sibling-directory convention and runs codegraph init -i automatically."
---

# Create Worktree

Set up a git worktree that is *immediately ready to work in*. A bare `git worktree add` leaves you with a checkout that's missing two things this team relies on:

1. **Your live `.claude` directory** — your local skill edits and `settings.local.json` are not what a fresh `main` checkout contains. `.claude` is tracked, so the *committed* version arrives with the checkout, but your uncommitted skill changes and your gitignored local settings do not. We mirror the working copy so the new worktree has the exact tooling you're using right now.
2. **A CodeGraph index** — `.codegraph/codegraph.db` is gitignored and local to each worktree (~150 MB). Without it, the codegraph MCP server in the new session has nothing to query. We build it up front so the first session is fast.

This skill does both, following the conventions already visible in the repo: worktrees are sibling directories named `<repo>-<id>` (e.g. for repo root `C:/Repos/<repo>` and issue `ENG-123`, the worktree is `C:/Repos/<repo>-ENG-123`) on `prefix/ENG-123-slug` branches.

## Inputs

Get these from the user (ask only for what's missing):

- **Issue identifier** (e.g. `ENG-123`) — required. Drives both the branch name and the directory name. Preserve its casing exactly.
- **Branch type** — `feat/`, `fix/`, or `chore/`. Infer from the user's wording using the git-branch-namer keyword rules; only ask if genuinely ambiguous.
- **Base branch** — defaults to `main`. Use whatever the user names if they specify one (some repos may still override with `develop`).
- **Title** — only needed to build the slug. If the user didn't give it, fetch it from Linear (see step 2). If Linear is unavailable, ask the user for a short description.

## Quick reference

The full flow for issue `ENG-123` off `main`, with repo root `C:/Repos/<repo>`:

```bash
SRC=C:/Repos/<repo>                 # repo root  (git rev-parse --show-toplevel)
DEST=C:/Repos/<repo>-ENG-123        # sibling worktree
BRANCH=feat/ENG-123-<slug>

git -C "$SRC" fetch origin main
git -C "$SRC" worktree add -b "$BRANCH" "$DEST" origin/main

rm -rf "$DEST/.claude" && cp -r "$SRC/.claude" "$DEST/.claude"
rm -f "$DEST/.claude/scheduled_tasks.lock"

cmd.exe //c "codegraph init -i $DEST"      # blocks until indexed
cmd.exe //c "codegraph status $DEST"       # verify
```

Work through the steps below carefully the first time / when anything is non-standard.

## Steps

### 1. Resolve paths and the source repo

Run `git rev-parse --show-toplevel` to get the **source repo root** (`$SRC`). The `.claude` directory you copy comes from here — i.e. the working copy you're invoking the skill from, so it reflects your current tooling.

Derive the worktree directory as a **sibling** of the repo root: `<parent-of-SRC>/<repo-basename>-<id>`. For repo `C:/Repos/<repo>` and issue `ENG-123`, that's `C:/Repos/<repo>-ENG-123`. Deriving the prefix from the repo's own folder name (`basename "$SRC"`) keeps this correct even if the repo is cloned elsewhere.

Use **forward-slash absolute paths** throughout — git-bash and the codegraph Node CLI both accept them on Windows, and they avoid backslash-escaping headaches.

### 2. Build the branch name

Follow the `git-branch-namer` skill so names are consistent with the rest of the team's branches (see `C:/Users/skinn/.claude/skills/git-branch-namer/` for the full rules). The essentials, inlined so this skill is self-contained:

- **Prefix**: `feat/` (features/enhancements), `fix/` (bug fixes), or `chore/` (maintenance, deps, tooling, refactors). Auto-detect from the user's wording; only ask if genuinely ambiguous.
- **Append the issue identifier** (e.g. `ENG-123`), followed by a hyphen. **Preserve the identifier's casing** — it's exempt from kebab-lowercasing, so `ENG-123` stays `ENG-123`.
- **Convert the title to kebab-case**: lowercase the title portion; replace spaces, underscores, and any non-alphanumeric run (except hyphens) with a single hyphen; collapse consecutive hyphens; trim leading/trailing hyphens.
- Result: `feat/ENG-123-admin-edit-website-save-publish-button-remains-disabled`.

If you only have the issue identifier, fetch the title from Linear before building the slug:

- Call the `mcp__linear__get_issue` MCP tool with the identifier (e.g. `ENG-123`) or a Linear issue URL.
- Use the returned `title` for the slug. If Linear can't be reached, ask the user for a short description and slugify that.

### 3. Pre-flight checks (don't clobber existing work)

Before creating anything, confirm the names are free — colliding with an existing worktree or branch is the most common failure:

```bash
git -C "$SRC" worktree list                 # is $DEST already a worktree?
git -C "$SRC" show-ref --verify --quiet refs/heads/"$BRANCH"   # does the branch exist?
```

If the directory already exists or the branch is already checked out, **stop and report** rather than forcing it. Offer the user the options: reuse it (`cd` in), pick a different issue/name, or clean up the old one (`git worktree remove <path>` and/or `git branch -D <branch>`).

### 4. Create the worktree from the latest base

Fetch first so the new branch starts from the current remote tip, then create the worktree branching off the remote base:

```bash
git -C "$SRC" fetch origin main
git -C "$SRC" worktree add -b "$BRANCH" "$DEST" origin/main
```

Substitute the user's base branch for `main` if they named one (e.g. a repo that still uses `develop`). If the fetch fails (e.g. offline), fall back to the local base branch (`git worktree add -b "$BRANCH" "$DEST" main`) and tell the user it's based on local, possibly-stale `main`.

### 5. Mirror the live `.claude` directory

Replace the worktree's checked-out `.claude` with your current working copy, so it has your latest skills, agents, and local settings:

```bash
rm -rf "$DEST/.claude"
cp -r "$SRC/.claude" "$DEST/.claude"
rm -f "$DEST/.claude/scheduled_tasks.lock"
```

Why each line:
- **`rm -rf` then `cp -r`** rather than copying over the top — a plain overlay would leave behind files that exist in `main` but you've since deleted locally (e.g. retired commands). Mirroring gives the worktree exactly what you have now. Only ever run this against the validated `$DEST` you created in step 4; never against an empty or unverified path.
- **Drop `scheduled_tasks.lock`** — it's a runtime lock holding a stale session id/pid. Copying it into a fresh worktree would carry a lock that doesn't belong to that session.
- **`settings.local.json` is intentionally kept** — it's gitignored, so it would *not* arrive via the git checkout, yet it holds your local permission allowlist. Copying `.claude` wholesale brings it along, which is what you want.

Do **not** copy `.codegraph/` — it's per-worktree, ~150 MB, and would point at the wrong root. Step 6 builds a fresh one.

### 6. Initialize and index CodeGraph

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

If `codegraph` is missing (`command not found` / non-zero from `where codegraph`), the worktree is still fully usable — note that indexing was skipped and how to run it later (`codegraph init -i <path>`), and continue.

> Optional — preserve custom index config: if `$SRC/.codegraph/config.json` has non-default include/exclude rules you want to carry over, init without indexing first, copy the config, then index: `cmd.exe //c "codegraph init $DEST"` → `cp "$SRC/.codegraph/config.json" "$DEST/.codegraph/config.json"` → `cmd.exe //c "codegraph index $DEST"`. The default config covers this repo's languages, so the one-line `init -i` above is normally fine.

### 7. Report the next step

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

- Worktrees share the one `.git` directory, so commits and fetches are visible across all of them.
- The codegraph MCP server resolves its database from the session's working directory, so each worktree must have its own `.codegraph` — that's why step 6 indexes in the worktree rather than reusing the main repo's index.
- This skill is Windows-oriented (paths, `cmd.exe` invocation of `codegraph`). On a POSIX host, drop the `cmd.exe //c` wrapper and call `codegraph` directly.
