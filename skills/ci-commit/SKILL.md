---
name: ci-commit
description: Commit this session's changes as Conventional Commits without stopping for confirmation. Only for when the user explicitly invokes it, or tells /implement-outline or /implement-plan to "commit as you go"; that instruction is the go-ahead. Same message format, staging discipline, and hook policy as gh-commit, minus its confirmation step. For an ordinary commit where the user reviews the message first, use gh-commit.
argument-hint: "[hint about scope or message]"
disable-model-invocation: true
---

# Commit Without Asking (CI-style commit)

Commit the changes made during this session: $ARGUMENTS

The user asked for this, either by invoking `/ci-commit` or by asking an implement run to commit as it goes. Don't stop to ask for feedback; their instruction is the go-ahead. Everything else follows `skills/gh-commit/SKILL.md`.

## Process

1. **Work out what changed.** Review what this session accomplished, then run `git status` and `git diff` to see the changes. Decide whether they form one commit or several logical ones. During an implement run, one commit per completed phase is the default.
2. **Stage specific files.** Use `git add <paths>`, never `-A` or `.`.
   - Leave `.agents/artifacts/` unstaged: CRISPY task documents stay out of history.
   - Leave out files you created for scratch work, such as dummy files, throwaway test scripts, or debug output, unless they are part of the change. The same goes for files that appeared for reasons unrelated to it.
   - Generated files that the change itself produces (lock files, migrations, generated clients) belong in the commit.
3. **Write the message.** Use Conventional Commits, as in gh-commit's "Commit message format": a typed subject saying what changed, and a body saying why. During an implement run, name the phase in the body (for example "Phase 2 of the CSV export outline").
4. **Commit.** Run `git commit --message "<subject>" --message "<body>"` once per logical change.
5. **Report.** Show `git log --oneline -N` for the commits you made.

## Standing rules

These are the same as gh-commit's:

- **Run hooks.** Never pass `--no-verify` or `--no-gpg-sign`. When a hook fails, the commit did not happen. Fix the cause, re-stage, and commit fresh. If the hook still fails after two fixes, stop and report it: an implement run treats that as a bug, not a pass.
- **Never amend.**
- **No AI attribution trailers.**
- **Don't push.** This skill commits only. Pushing and pull requests belong to `/describe-pr` and gh-create-pr.
