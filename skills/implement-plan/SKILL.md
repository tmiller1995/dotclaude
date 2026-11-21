---
name: implement-plan
description: Implement a CRISPY task from its highest-precedence document, phase by phase. That document is the plan (or legacy spec). Without one it is the TDD, PRD, design discussion, research, or the request alone (HumanLayer's Oneshot), built as a single design-scope phase. The planner and worker sub-agents build it, with a gate at each phase's Manual verification. Invoked manually after /create-plan, or for an early handoff from any design step. Say "commit as you go" for a continuous run that commits each phase. Not for running a structure outline when no plan exists (use /implement-outline), post-implementation fixes (use /iterate-implementation), or general sub-agent orchestration (orchestrate).
argument-hint: "<task directory or plan path> [phase or scope] [flow: <flow>]"
disable-model-invocation: true
---

# Implement a Plan (CRISPY implement phase)

Implement the task at: **$ARGUMENTS**

## Step 1: Pick the governing document

From `$ARGUMENTS`, take a task directory or a document path, an optional scope (a phase number or "all phases"), and an optional `flow:`. With no path, resolve the task directory from the current branch as in `skills/QRSPI-WORKFLOW.md`, and ask when several fit.

The governing document is the highest-precedence document present: **plan > structure outline > TDD > PRD > design discussion > research > request**, taking the highest-numbered of each type. A legacy `NN-spec-*` counts as a plan. State which document governs.

- **Plan:** each of its numbered phases is a phase.
- **Structure outline, no plan:** say that `/implement-outline` is the matching command, then proceed the same way if the user invoked this one.
- **TDD, PRD, design discussion, research, or request only:** this is an early handoff (Oneshot when only the request exists). The scope becomes one design-scope phase, with a single gate at the end built from the request's acceptance criteria and the design document's verification expectations.

When the governing document still has Open Questions or `draft` status, say so and stop, unless the user explicitly asks to proceed. When a request alone is too vague to build from, suggest `/create-research-questions` first.

## Step 2: Run the worker loop

Read `skills/orchestrate/SKILL.md` and follow its **Worker loop and bug handling** with that governing document. Dispatch `planner` with the task directory, the governing document's path, the requested scope, and any user instructions that change the agreed result. Let it read the documents itself. It skips phases already marked ✅, so a new session resumes from the first incomplete one. After the workers report, run any automated checks they may have missed before calling a phase's checks passed.

## Step 3: Gates, commits, and continuous runs

Gates, commits, and continuous runs work exactly as in `skills/implement-outline/SKILL.md` Step 3:

- the gate report opens with **What was done**;
- the default is to stop for manual verification, then commit through gh-commit;
- on "commit as you go", commit each phase by following `skills/ci-commit/SKILL.md` and leave manual checks for the final report.

## Step 4: Final report

When every phase is done, report what changed, the checks run with their results, and any manual verification still pending, plus any deviation from the plan and why. Offer to open the governing document in VS Code, Cursor, or the browser. Name the next steps:

- review with the `reviewer` and `code-simplifier` agents;
- `/describe-pr .agents/artifacts/<task>` to open or update the pull request;
- `/iterate-implementation .agents/artifacts/<task>` for bugs or feedback.
