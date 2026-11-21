---
name: iterate-plan
description: Revise an existing CRISPY implementation plan from feedback (reorder or change phases, fix code examples, file paths, or verification commands), updating it in place under `.agents/artifacts/<task>/` after verifying every correction against the code. The iterate half of the optional plan step (pairs with /create-plan), invoked manually. Not for writing the first plan (use /create-plan), design or slice-boundary changes (use the design phases or /iterate-structure-outline), or running the plan (use /implement-plan).
argument-hint: "<plan document or task directory> [feedback]"
disable-model-invocation: true
---

# Iterate a Plan (CRISPY optional plan step)

Revise the implementation plan for: **$ARGUMENTS**

## Step 1: Find the plan and read the context

From `$ARGUMENTS`, take a document path or a task directory, plus any feedback or feedback file. In a task directory, use the highest-numbered `NN-plan-*` (or a legacy `NN-spec-*`) and name it. With no path, resolve the task directory from the current branch as in `skills/QRSPI-WORKFLOW.md`, and ask when several fit. When no plan exists, name `/create-plan` instead.

Read the plan and every other document in the task directory in full: request, research, design discussion, PRD, TDD, and structure outline when present. The precedence is **plan > structure outline > TDD > PRD > design discussion > research > request**.

## Step 2: Verify the feedback before applying it

Don't accept a correction blindly. Read the files and directories the user mentions, check that code examples and paths are accurate, and proceed only once you have verified the facts yourself. When the feedback would change a product or technical decision, or a slice boundary the outline owns, stop. Name the phase that owns it (`/iterate-structure-outline`, `/iterate-tdd`, `/iterate-prd`, or `/iterate-design-discussion`), because the plan is a transcription and not a design pass.

## Step 3: Apply the feedback

- **Phase changes:** reorganize or modify phases as asked, keeping each phase independently testable.
- **Code changes:** update the specific implementation steps and code examples.
- **Errors:** fix inaccurate file paths, code, or descriptions.

Keep each phase's Automated verification as runnable commands and its Manual verification as specific steps for the human. Keep ✅ and checked items for work already verified, and uncheck any item the change invalidates.

## Step 4: Update the plan in place

Re-render through the same output skill the plan was written with (`.html` → `Skill('output-html')`, `.md` → `Skill('output-markdown')`), at the same stem, using the slots and body sections in `skills/create-plan/SKILL.md` Step 5. Keep the existing metadata. Refresh `crispy:repos` and `crispy:phase_count`, and set `crispy:last_updated`, `crispy:last_updated_by` (`git config user.name`), and `crispy:last_updated_note`.

## Step 5: Hand off

Give the saved path and a one-line summary of what changed, and offer to open the plan in VS Code, Cursor, or the browser. Name the next command with the task directory and flow, `/implement-plan .agents/artifacts/<task> flow: <flow>`, and say it can run here, after compaction, or in a new session. Then wait.
