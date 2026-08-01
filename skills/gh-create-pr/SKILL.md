---
name: gh-create-pr
argument-hint: "[PR title or focus] [--ready] [--reviewer <login>]"
description: Commits, pushes, and opens or updates a GitHub pull request with a Conventional Commits title and a structured description. Use whenever the user wants a PR raised, updated, re-titled, or marked ready to review - including implicit phrasings like "put this up for review", "ship this", "raise a PR", "PR this branch", or "update the PR description", and when the user asks to push work and get it reviewed without naming a PR at all. Opens as a draft by default, fills the repository's PR template when one exists, links the related Linear issue, requests reviewers only when the user names them, and reports the PR web URL. For committing without opening a PR use gh-commit; for choosing a branch name use git-branch-namer. Does not add AI attribution trailers.
---

# Create Pull Request

Commit changes, push the branch, and open or update a GitHub pull request using the Conventional Commits title format and a complete description: $ARGUMENTS

## Current Repository State

- Git status: !`git status --porcelain`
- Current branch: !`git branch --show-current`
- Default branch: !`{ git symbolic-ref --quiet --short refs/remotes/origin/HEAD || echo origin/main; } | sed 's|^origin/||'`
- Staged diff (stat): !`git diff --cached --stat`
- Unstaged diff (stat): !`git diff --stat`
- Recent commits on this branch: !`git log --oneline -10`
- Commits ahead of default: !`base=$( { git symbolic-ref --quiet --short refs/remotes/origin/HEAD || echo origin/main; } ); git log --oneline "$base..HEAD" 2>/dev/null | head -20`
- Remote URL: !`git remote get-url origin 2>/dev/null || echo "no-remote"`
- Existing PR for branch: !`gh pr view --json number,title,body,isDraft 2>/dev/null || echo "No existing PR"`

## Tooling

Use the `gh` CLI throughout. If `gh` is missing or unauthenticated, the `mcp__github__*` tools are equivalent — `create_pull_request`, `update_pull_request`, and `list_pull_requests` map to `gh pr create`, `gh pr edit`, and `gh pr view`. If neither is available, prompt the user to run `gh auth login` first. Linear operations use the `mcp__linear__*` MCP tools.

## Workflow

Throughout the workflow, `<base>` means the "Default branch" value from "Current Repository State" above — substitute it, never assume `main`.

### 1. Stage and commit

Follow the **gh-commit** skill for the commit step — Conventional Commits subject format, no AI attribution, and its hook policy: a failed hook means the commit did not happen. Split into multiple commits if the staged diff covers unrelated concerns.

If the user is currently on the default branch (`main` / `master`), switch to a short-lived feature branch *before* committing. Use `feat/<short-topic>` for features and `fix/<short-topic>` for bug fixes (trunk-based — branch off `main`, no `develop`/`release`/`hotfix` flow). If a Linear issue id is known, include it in the branch name (e.g. `feat/ENG-123-jwt-refresh`).

### 2. Push

```bash
git push -u origin "$(git branch --show-current)"
```

`-u` sets upstream tracking so subsequent pushes don't need arguments.

### 3. Gather context for the PR

Read the *full* diff against the base branch, not just the last commit — a PR title needs to summarize the whole branch, not one step of it.

```bash
git diff origin/<base>...HEAD
```

Open the files that changed significantly to describe the *why* accurately. If there's an existing PR for this branch, edit rather than replace — a human may already have curated the title or description.

### 4. Identify the Linear issue

Scan the branch name and every commit subject/body on the branch (`git log origin/<base>..HEAD`) for a Linear issue id (e.g. `ENG-123`). If the user mentioned an issue in the prompt, trust that. If the id is uncertain, use `mcp__linear__list_issues` (filter by assignee, team, or project) to surface candidates so the user can confirm — don't guess.

### 5. Check for an existing PR

If "Existing PR for branch" in the state block returned a PR, this is *update* mode — keep its number and edit in place in step 7. Otherwise this is *create* mode.

### 6. Generate title and description

If the repo provides a PR template, fill that out instead of the template below. Check `.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE/*.md`, `docs/pull_request_template.md`, and a root `pull_request_template.md`. The bundled template applies only when the repo provides none.

**Title** — Conventional Commits format, matching the commit convention:

- Format: `<type>[optional scope]: <description>`
- Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`
- Keep the title concise (under 72 characters)
- For a single-commit PR the commit subject works directly; for a multi-commit PR, synthesize a higher-level title that captures the overall theme rather than concatenating commit subjects.

```
feat(auth): add JWT token refresh endpoint
feat(api)!: change pagination response format
docs: update API reference for v2 endpoints
```

**Description** — use this template, omitting sections that don't apply:

```markdown
## Summary

[1-2 sentences on what this PR does and why]

## Changes

- [Key change 1]
- [Key change 2]

## Breaking Changes

[What breaks and the migration step — delete this section if none]

## Test Plan

- [Commands run to verify, e.g. `dotnet test`, `npm test`]
- [Manual checks performed]
- [Screenshots for UI changes, if any]

## Related Issue

Closes ENG-123
```

Keep a Linear issue reference in the description (`Closes ENG-123` if the PR completes the issue, `Refs ENG-123` if it stays open after merge). Step 8 *also* attaches the PR to the Linear issue so the link is first-class, not just string-matched.

### 7. Create or update the PR

**Create (default to draft):**

```bash
gh pr create --draft \
  --base <base> \
  --title "feat(auth): add JWT token refresh endpoint" \
  --body "<markdown from template>" \
  --reviewer "<login>"          # only if the user named reviewers; repeatable
```

**Update (existing PR):**

```bash
gh pr edit <number> \
  --title "<updated title>" \
  --body "<updated description>" \
  --add-reviewer "<login1>,<login2>"    # only if the user named reviewers
```

Respect the existing title/description if they're already meaningful — enhance rather than overwrite. If the existing title already follows Conventional Commits and is accurate, leave it alone.

### 8. Link the Linear issue

If the Linear MCP tools are unavailable, the `Closes ENG-123` reference in the description already links the issue — report that the first-class attachment was skipped and continue.

Even though the description references the issue, attach the PR to the Linear issue so it shows as a structured relationship:

```
mcp__linear__create_attachment {
  issueId: "<linear-issue-id>",
  url: "<pr-web-url>",
  title: "<pr-title>"
}
```

Optionally post a short note on the issue so watchers see it async:

```
mcp__linear__save_comment {
  issueId: "<linear-issue-id>",
  body: "Opened PR: <pr-web-url>"
}
```

### 9. Reviewers (optional)

Reviewers are set by the flags in step 7 — `--reviewer` on create, `--add-reviewer` on edit. To request a review on a PR that already exists and was not touched in step 7, run `gh pr edit <number> --add-reviewer <login1>,<login2>`.

Don't auto-assign reviewers the user didn't name — guessing logins is a good way to ping the wrong person, and CODEOWNERS / branch protection rules usually handle default reviewers.

### 10. Report back

Print the PR's web URL (from the `gh pr create` / `gh pr view --json url` output, or the MCP response) so the user can click through. Add a one-line summary: branch → target, draft status, linked Linear issue, reviewers added.

## Guidelines

- **Un-drafting.** When the user is ready for review, un-draft with `gh pr ready <number>`.
- **CI before ready (optional).** Before un-drafting, confirm the branch's checks are green with `gh pr checks <number>`. If checks are red, surface that instead of marking the PR ready.
- **No AI attribution.** Commits and PRs are authored solely by the engineer — do not add `Co-Authored-By`, `Assistant-model`, "Generated with Claude", or any similar trailer.
