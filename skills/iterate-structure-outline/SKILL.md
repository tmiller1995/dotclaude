---
name: iterate-structure-outline
description: Revise the slice order, scope, code shapes, and verification of an existing CRISPY structure outline, or finish a partly written one, updating it in place under `.agents/artifacts/<task>/` while preserving completion markers for verified work. The iterate half of the outline phase (pairs with /create-structure-outline), invoked manually. Treats feedback as outline edits, never as a request to implement. Not for writing the first outline (use /create-structure-outline), running it (use /implement-outline), or a phased task-ready plan (use /create-plan or /iterate-plan).
argument-hint: "<structure-outline document or task directory> [feedback]"
disable-model-invocation: true
---

# Iterate a Structure Outline (CRISPY outline phase)

Revise the structure outline for: **$ARGUMENTS**

## Step 1: Find the outline and read the context

From `$ARGUMENTS`, take a document path or a task directory, plus any feedback. In a task directory, use the highest-numbered `NN-structure-outline-*` and name it. With no path, resolve the task directory from the current branch as in `skills/QRSPI-WORKFLOW.md`, and ask when several fit. When no outline exists, name `/create-structure-outline` instead.

Read the outline, the request, research, and every design document present (design discussion, PRD, TDD), plus files the feedback names, all in full. Note the agreed behavior, the existing ✅ and checkbox progress markers, and the user's feedback. When the outline is finished and no feedback was given, ask what the user wants to revise. When it is unfinished, resume its remaining scope and questions.

## Step 2: Verify the affected code and commands

Check the feedback against the source files and existing tests. Dispatch `codebase-locator`, `codebase-analyzer`, or `codebase-pattern-finder` for gaps, and wait for the results. Verify factual corrections against the code before recording them. Confirm the repository's real verification commands before changing any Automated verification list.

## Step 3: Rework the slices

Apply the rules in `skills/create-structure-outline/SKILL.md` Steps 4–5. Slices are vertical, end-to-end and independently testable, never horizontal layers. Each slice's checks must work with the code completed by that point. Each slice carries its change outline (focused diffs for changed shapes, full target shapes for new code), tests, checkpoint, and separate Automated and Manual verification.

Apply scope and ordering feedback to the slices and the Implementation Overview together, so overview items match slice titles. Fold answered Open Questions into the relevant sections. Keep ✅ and checked items for work already verified. When the scope of a completed slice changes, uncheck the items the change invalidates and say which checks need another run.

## Step 4: Update the outline in place

Run the check in `skills/create-structure-outline/SKILL.md` Step 8a. Then re-render through the same output skill the outline was written with (`.html` → `Skill('output-html')`, `.md` → `Skill('output-markdown')`), at the same stem, using the slots and body sections in its Step 8. Keep the existing metadata. Refresh `crispy:repos` and `crispy:slice_count`, and set `crispy:last_updated`, `crispy:last_updated_by` (`git config user.name`), and `crispy:last_updated_note`.

Treat feedback as a request to update the outline. When the user asks to implement, that is `/implement-outline`: name it rather than starting.

## Step 5: Hand off

Give the saved path and a one-line summary of what changed, and offer to open the outline in VS Code, Cursor, or the browser. Name the next command with the task directory and flow: `/implement-outline .agents/artifacts/<task> flow: <flow>`, or `/create-plan` (or `/iterate-plan` when a plan already exists and the outline change affects it) when the user wants implementation steps per phase. Then wait.
