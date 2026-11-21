---
name: iterate-implementation
description: Fix bugs or apply review feedback on CRISPY work that has already been implemented, or continue an implementation stopped mid-outline. It reproduces the issue, fixes it through a worker task with a regression test, updates affected design or outline sections in place, and keeps validation markers accurate. Invoked manually after /implement-outline or /implement-plan. Not for implementing phases from scratch (use /implement-outline or /implement-plan), changing a design before code exists (use the /iterate-* document phases), or diagnosing an error unrelated to a CRISPY task (dispatch debugger).
argument-hint: "<task directory> <bug report or feedback>"
disable-model-invocation: true
---

# Iterate on an Implementation (CRISPY implement phase)

Apply this feedback to the implemented task: **$ARGUMENTS**

## Step 1: Read the current state

Resolve the task directory from the argument or the current branch, as in `skills/QRSPI-WORKFLOW.md`. Read its documents in full, using the precedence **plan > structure outline > TDD > PRD > design discussion > research > request**, along with any sources the user names. Then read:

- `git diff` and `git status` for uncommitted work;
- the commits since the implementation started. The governing document's ✅ markers and the commit bodies' phase names show which phases are done; the feedback may arrive mid-plan.

When the feedback asks for a phase that hasn't started yet, that is not iteration: name `/implement-outline` or `/implement-plan` with that phase as the scope.

## Step 2: Reproduce or check the request

For a bug, reproduce it with a failing test or the observed command output. For review feedback, check the requested change against the code, the tests, and the governing document. When the expected behavior is unclear, or several fixes are viable, ask one targeted question with a recommended answer.

When the feedback changes the agreed result (scope, behavior, or a design decision), confirm it with the user. Then update the affected sections of the governing document and any design document in place, through the output skill each was written with, and refresh `crispy:last_updated*`.

## Step 3: Fix through the worker loop

Create a task for the fix with `TaskCreate` that requires a regression test. When the cause isn't obvious, dispatch `debugger` first and attach its report to the task metadata. Then dispatch a `worker`, following `skills/orchestrate/SKILL.md` → Worker loop and bug handling: debugger dispatch stays in the main context, and mismatch reports go to the user verbatim. Don't implement inline.

## Step 4: Keep the markers accurate and commit

In the outline or plan, uncheck any verification item the fix invalidates, and re-run its automated checks. A phase marked ✅ whose checks now need a manual re-run loses its ✅ until the user confirms. Commit through `Skill('gh-commit')` after the user's go-ahead. When the user asked to commit as you go, follow `skills/ci-commit/SKILL.md` instead.

## Step 5: Report

Report what was wrong, what changed (with file references), the regression test, the checks run with results, and any manual verification to repeat. Name the next step: more feedback through `/iterate-implementation`, or `/describe-pr .agents/artifacts/<task>` to update the pull request.
