---
name: gh-commit
description: Stage, review, and create well-formed Conventional Commits from the current working tree — reads the staged diff, splits unrelated changes into separate commits, drafts a typed subject and a why-focused body, and confirms with the user before committing. Use whenever the user wants to commit work or needs a commit message written (e.g. "commit this", "write a commit message", "split this into separate commits"), including choosing a type, scope, or BREAKING CHANGE marker. Stops at the commit — use gh-create-pr instead when the request also involves pushing the branch or opening a pull request. Never skips hooks, never amends, and never adds AI attribution trailers.
argument-hint: "[paths to stage, or a hint about the message]"
---

# Git Commit

Create well-formatted commit: $ARGUMENTS

## Current Repository State

- Git status: !`git status --porcelain`
- Current branch: !`git branch --show-current`
- Staged changes: !`git diff --cached --stat`
- Unstaged changes: !`git diff --stat`
- Recent commits: !`git log --oneline -5`

## Workflow

1. **Stage.** Name the files to commit explicitly with `git add <paths>` rather than `git add -A` / `git add .`, because blind wildcards can sweep in secrets, build artifacts, and editor scratch files. If specific files are already staged, commit only those. Stage all modified and new files only as a fallback, when no explicit paths are obvious. Leave anything under `.agents/artifacts/` unstaged unless the user explicitly asks to commit it, because those are CRISPY working documents that stay out of history.
2. **Read the diff.** Run `git diff --cached` and read it. The subject describes *what changed and why*, not *which files changed*.
3. **Split if needed.** If the staged diff covers multiple unrelated logical changes, propose separate commits: one commit per logical change.
4. **Draft the message.** Use Conventional Commits format (below): a subject line, and a body as bullets or a short paragraph explaining *why*.
5. **Present the plan** to the user — the exact files to be committed, subject, and body — and wait for their go-ahead before running `git commit`, because the user owns the history and should see what goes into it. On multi-commit splits, list each commit's files and subject.
6. **Commit** with `git commit --message "<subject>" --message "<body>"`. On multi-commit splits, stage and commit each change separately.
7. **Show the result** with `git log -1` (or `git log --oneline -N` for multi-commit splits) so the user can confirm.

## Commit message format

Conventional Commits 1.0.0:

```
<type>[optional scope][!]: <description>

[optional body]

[optional footer(s)]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`. A `feat` is a MINOR bump and a `fix` is a PATCH bump; a breaking change is MAJOR regardless of type.

Mark a breaking change with a `!` immediately before the colon (`feat(api)!: send an email when a product ships`), with a `BREAKING CHANGE: <description>` footer, or with both.

Read `references/conventional-commits.md` for the full 1.0.0 specification when you need footer token rules, the revert convention, or an unusual breaking-change case.

## Putting it together

```bash
git add src/auth/refresh.ts src/auth/refresh.test.ts   # specific paths preferred
git diff --cached --stat                               # sanity check
git commit --message "feat(auth): add JWT refresh endpoint" --message "- Added POST /auth/refresh accepting a refresh token
- Rotated refresh tokens on use; invalidated on password change
- Unit tests cover expired and reused-token paths"
git log -1
```

## Standing rules

- **Run hooks.** Don't pass `--no-verify` or `--no-gpg-sign`. Pre-commit checks (e.g. defined in `.pre-commit-config.yaml`) are signal: if a hook fails, the commit did not happen. Fix the underlying issue, re-stage, and create a new commit.
- **Don't amend.** After a failed hook there is nothing to amend, and `--amend` would rewrite the *previous* commit instead. Stage and commit fresh.
- **No AI attribution.** Commits are authored by the engineer, so write the message as if the user wrote it, with no `Co-Authored-By`, `Assistant-model`, "Generated with Claude", or other AI/co-authorship trailer.
