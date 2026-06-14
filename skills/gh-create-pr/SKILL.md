---
name: gh-create-pr
description: Commit, push, and open or update a GitHub pull request using the Conventional Commits title format and a complete description. Use whenever the user wants to open, update, or draft a PR on a GitHub-hosted repo. Drafts by default, links the related Linear issue, sets reviewers only when named, and reports the PR web URL. Does NOT add AI attribution trailers.
---

# Create Pull Request

Commit changes, push the branch, and open or update a GitHub pull request using the Conventional Commits title format and a complete description: $ARGUMENTS

## Current Repository State

- Git status: !`git status --porcelain`
- Current branch: !`git branch --show-current`
- Default branch: !`git rev-parse --abbrev-ref origin/HEAD 2>/dev/null | sed 's|origin/||' || echo main`
- Staged diff (stat): !`git diff --cached --stat`
- Unstaged diff (stat): !`git diff --stat`
- Recent commits on this branch: !`git log --oneline -10`
- Commits ahead of default: !`git log --oneline origin/$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null | sed 's|origin/||' || echo main)..HEAD 2>/dev/null | head -20`
- Remote URL: !`git remote get-url origin 2>/dev/null || echo "no-remote"`
- Existing PR for branch: !`gh pr view --json number,title,isDraft 2>/dev/null || echo "No existing PR"`

## Tooling

GitHub operations use the `gh` CLI (e.g. `gh pr create`, `gh pr edit`, `gh pr view`) or the equivalent `mcp__github__*` MCP tools (`mcp__github__create_pull_request`, `mcp__github__update_pull_request`, `mcp__github__list_pull_requests`). Linear operations use the `mcp__linear__*` MCP tools. If the `gh` CLI is not authenticated and no `mcp__github__*` tools are loaded, prompt the user to run `gh auth login` first.

## Workflow

### 1. Stage and commit

Follow the **gh-commit** skill for the commit step — Conventional Commits subject format, no AI attribution. Split into multiple commits if the staged diff covers unrelated concerns.

If the user is currently on the default branch (`main` / `master`), switch to a short-lived feature branch *before* committing. Use `feat/<short-topic>` for features and `fix/<short-topic>` for bug fixes (trunk-based — branch off `main`, no `develop`/`release`/`hotfix` flow). If a Linear issue id is known, include it in the branch name (e.g. `feat/ENG-123-jwt-refresh`).

### 2. Push

```bash
git push -u origin "$(git branch --show-current)"
```

`-u` sets upstream tracking so subsequent pushes don't need arguments.

### 3. Gather context for the PR

Read the *full* diff against the base branch, not just the last commit — a PR title needs to summarize the whole branch, not one step of it.

```bash
git diff origin/main...HEAD
```

(Substitute the actual default branch from "Current Repository State" above if it isn't `main`.) Open the files that changed significantly so you can describe the *why* accurately. If there's an existing PR for this branch, fetch it first (see step 5) and edit rather than replace — a human may already have curated the title or description.

### 4. Identify the Linear issue

Scan the branch name and every commit subject/body on the branch (`git log origin/main..HEAD`) for a Linear issue id (e.g. `ENG-123`). If the user mentioned an issue in the prompt, trust that. If the id is uncertain, use `mcp__linear__list_issues` (filter by assignee, team, or project) to surface candidates so the user can confirm — don't guess.

### 5. Check for an existing PR

```bash
gh pr view --json number,title,body,isDraft
```

(Or `mcp__github__list_pull_requests` filtered by `head: <current-branch>`.) If a PR comes back, you're in *update* mode — keep its number and edit in place in step 7. Otherwise you're in *create* mode.

### 6. Generate title and description

**Title** — Conventional Commits format, matching the commit convention:

- Format: `<type>[optional scope]: <description>`
- Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`
- Use `!` after the type/scope for breaking changes: `feat(api)!: change response format`
- Keep the title concise (under 72 characters)
- For a single-commit PR the commit subject works directly; for a multi-commit PR, synthesize a higher-level title that captures the overall theme rather than concatenating commit subjects.

```
feat(auth): add JWT token refresh endpoint
fix(ui): resolve layout shift on mobile navigation
docs: update API reference for v2 endpoints
refactor(db): migrate from raw SQL to query builder
feat(api)!: change pagination response format
chore(deps): bump TypeScript to 5.x
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

Keep a Linear issue reference in the description (`Closes ENG-123` if the PR completes the issue, `Refs ENG-123` if it stays open after merge). You'll *also* attach the PR to the Linear issue in step 8 so the link is first-class, not just string-matched.

### 7. Create or update the PR

**Create (default to draft):**

```bash
gh pr create --draft \
  --base main \
  --title "feat(auth): add JWT token refresh endpoint" \
  --body "<markdown from template>"
```

(Or `mcp__github__create_pull_request` with `draft: true`, `base: "main"`, `head: "<current-branch>"`. Substitute the actual default branch for `main` if different.)

**Update (existing PR):**

```bash
gh pr edit <number> \
  --title "<updated title>" \
  --body "<updated description>"
```

(Or `mcp__github__update_pull_request`.) Respect the existing title/description if they're already meaningful — enhance rather than overwrite. If the existing title already follows Conventional Commits and is accurate, leave it alone.

### 8. Link the Linear issue

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

If the user named reviewers, attach them by GitHub login:

```bash
gh pr create --reviewer <login> [--reviewer <login2>]
```

(Or pass `reviewers` to the `gh pr edit` / MCP update call for an existing PR.)

Don't auto-assign reviewers the user didn't name — guessing logins is a good way to ping the wrong person, and CODEOWNERS / branch protection rules usually handle default reviewers.

### 10. Report back

Print the PR's web URL (from the `gh pr create` / `gh pr view --json url` output, or the MCP response) so the user can click through. Add a one-line summary: branch → target, draft status, linked Linear issue, reviewers added.

## Guidelines

- **Draft by default.** Pass `--draft` (or `draft: true`) unless the user says otherwise. It's easier to mark ready than to walk back a premature review request. When the user is ready, un-draft with `gh pr ready <number>`.
- **CI before ready (optional).** Before un-drafting, you can confirm the branch's checks are green with `gh pr checks <number>`. If checks are red, surface that instead of marking the PR ready.
- **Never skip pre-commit hooks.** They run locally during the commit in step 1. By default, pre-commit checks defined in `.pre-commit-config.yaml` run to ensure code quality. IMPORTANT: DO NOT SKIP pre-commit checks — a hook failure is the hook earning its keep.
- **No AI attribution.** Commits and PRs are authored solely by the engineer — do not add `Co-Authored-By`, `Assistant-model`, "Generated with Claude", or any similar trailer.
- **Respect existing content.** If updating an existing PR, keep what's already curated; only replace sections that are stale or wrong.
- **Holistic title.** The PR title is one line describing the whole branch. Don't concatenate commit subjects.
- **Review the diff first.** Always review the full branch diff before generating the title and description to ensure accuracy.
- Use markdown formatting in the description for readability.
