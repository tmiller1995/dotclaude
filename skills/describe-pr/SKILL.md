---
name: describe-pr
description: Open or update the pull request for an implemented CRISPY task, then watch CI until it passes. Reads the task directory and the full diff, checks the diff against the governing document, writes `<task>/pr-description.md` from the shared template, and publishes it through gh-create-pr with `--body-file`. The template has Why, Merge danger, Special things to note, and a diff-style Change outline. Then it watches checks, fixing failures this PR caused. Invoked manually as the last CRISPY step after /implement-outline or /implement-plan and review. Not for a PR without a CRISPY task (use gh-create-pr) or for committing alone (use gh-commit).
argument-hint: "[task directory] [--ready] [--reviewer <login>]"
disable-model-invocation: true
---

# Describe the PR (CRISPY PR step)

Open or update the pull request for: **$ARGUMENTS**

gh-create-pr does the git and GitHub work. This step adds the task context, the deviation check, the saved description, and CI watching.

## Step 1: Gather the context

1. Resolve the task directory from the argument or the current branch, as in `skills/QRSPI-WORKFLOW.md`. Without one, say so and use gh-create-pr directly.
2. Read the request and the governing document in full, using the precedence **plan > structure outline > TDD > PRD > design discussion > research > request**. Read other task documents only as needed.
3. Read the full branch diff (`git diff origin/<base>...HEAD`), plus enough surrounding code to understand behavior and ownership.
4. Read `skills/gh-create-pr/references/pr-description-template.md` and `skills/output-html/references/visual-guidance.md`.

## Step 2: Check the diff against the governing document

List the differences between what was built and what the governing document says, such as a phase skipped, a shape changed, or extra scope. Also list the manual verification items still unchecked. These go in your report to the user (Step 5), not in the PR body. When a deviation looks unintended, raise it before publishing.

## Step 3: Write the description

Fill in the template, following its rules:

- **Why the change:** one sentence, taken from the request's desired result.
- **Merge danger:** one line. Use the TDD's or outline's migration and contract changes to decide between a one-way and a two-way door.
- **Special things to note:** 1–3 bullets.
- **Change outline:** diff-style views, which the outline's target shapes and the TDD's Program Design usually already sketch. Build these views from the actual diff, not from the design.

Save it to `<task-dir>/pr-description.md`, overwriting any earlier version.

## Step 4: Publish through gh-create-pr

Follow `skills/gh-create-pr/SKILL.md` for committing anything outstanding (with gh-commit's confirmation), branching off `main` when needed, pushing, finding the Linear issue, creating a draft or updating the PR, attaching it to Linear, and adding reviewers. Use the saved file as `--body-file` and skip that skill's own description step. In update mode, keep a curated title.

## Step 5: Report, then watch CI

Report the PR URL, the saved description path, a short list of the changed files, and Step 2's deviations and unchecked manual items. Then keep going in the same turn.

1. **Conflicts first.** Run `gh pr view <n> --json mergeable,mergeStateStatus`, and ask again shortly if it says `UNKNOWN`. If `CONFLICTING`, don't merge, rebase, or edit files. Instead:
   - Fetch the base branch and list the conflicting files with `git merge-tree --write-tree --name-only HEAD origin/<base>`.
   - Compare what each side changed.
   - Propose a merge plan: for each file, whether to keep ours, keep theirs, or combine, and why, plus the checks to run afterwards.
   - Stop until the user approves it. Many checks don't run while conflicts exist.
2. **Watch.** Run `gh pr checks <n> --watch --fail-fast` with Bash `run_in_background`, so you are notified when it exits. Don't use a foreground sleep. If no checks have registered yet, check again a few minutes apart (use a Monitor until-loop), at most 3 times. If there are still none, tell the user and stop.
3. **When a check fails:**
   - Read the failure with `gh run view <run-id> --log-failed`.
   - If this PR caused it, fix it, run the matching local check, commit through gh-commit (or ci-commit if the user said to commit as you go), push, and watch again.
   - If it is flaky or unrelated, rerun it once with `gh run rerun <run-id> --failed`. If it fails again, stop and explain.
   - Stop and ask after 3 fix attempts on the same check.
4. **When everything passes,** say so with the PR URL. With `--ready`, un-draft it with `gh pr ready <n>` now.
