---
name: implement-outline
description: Implement a CRISPY structure outline slice by slice. The planner turns the outline's slices into tasks, worker sub-agents build them one at a time, and the run stops at each slice's Manual verification gate, recording progress in the outline. Resumes from the first slice without ✅. Invoked manually after /create-structure-outline; say "do all the phases, committing as you go" for a continuous run that commits each slice. Not for implementing from a plan, a design document, or the request alone (use /implement-plan), fixing bugs or applying feedback after implementation (use /iterate-implementation), or general sub-agent orchestration (orchestrate).
argument-hint: "<task directory or structure-outline path> [slice or scope] [flow: <flow>]"
disable-model-invocation: true
---

# Implement an Outline (CRISPY implement phase)

Implement the structure outline for: **$ARGUMENTS**

## Step 1: Pick the outline

From `$ARGUMENTS`, take a task directory or an outline path, an optional scope (a slice number or "all phases"), and an optional `flow:`. With no path, resolve the task directory from the current branch as in `skills/QRSPI-WORKFLOW.md`, and ask when several fit. Use the highest-numbered `NN-structure-outline-*` and name it.

- When the directory also holds a `plan` (or legacy `spec`), it outranks the outline. Say so and name `/implement-plan` instead, unless the user explicitly wants the outline.
- When there is no outline, name `/create-structure-outline`, or `/implement-plan` to build from the highest-precedence document present.
- When the outline still has Open Questions or `draft` status, say so and stop, unless the user explicitly asks to proceed.

## Step 2: Run the worker loop

Read `skills/orchestrate/SKILL.md` and follow its **Worker loop and bug handling** with the outline as the governing document. The precedence is **structure outline > TDD > PRD > design discussion > research > request**, and the user's latest instructions win when they change the agreed result.

Dispatch `planner` with the task directory, the outline path, the requested scope, and any user instructions that change the agreed result. Let it read the documents itself, and don't paste them into the prompt. Each slice becomes a phase. The planner skips slices already marked ✅, so a new session resumes from the first incomplete one. Workers build one task at a time, and phase gates come from each slice's Automated and Manual verification.

## Step 3: Gates, commits, and continuous runs

At each slice gate, use orchestrate's gate report, which opens with **What was done**. The default is to stop for manual verification and to commit through `Skill('gh-commit')` once the user confirms.

When the user asks to run several slices or all of them without pausing ("just do all the phases, committing as you go, and I'll check it at the end"), take that as a continuous run:

- Between slices, confirm the automated checks passed.
- Commit each slice by following `skills/ci-commit/SKILL.md`. The instruction to commit as you go is the go-ahead, so don't ask per slice. Without that instruction, the slices stay uncommitted for one gh-commit at the end.
- Leave unconfirmed manual checks for the final report.

A mismatch report, a failing automated check you can't fix, or a hook that keeps failing still stops the run.

## Step 4: Final report

When every slice is done, report what changed, the checks run with their results, and any manual verification still pending. Offer to open the outline in VS Code, Cursor, or the browser. Name the next steps:

- review with the `reviewer` and `code-simplifier` agents;
- `/describe-pr .agents/artifacts/<task>` to open or update the pull request;
- `/iterate-implementation .agents/artifacts/<task>` for bugs or feedback.
