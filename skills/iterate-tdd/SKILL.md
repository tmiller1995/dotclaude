---
name: iterate-tdd
description: Revise an existing CRISPY Technical Design Document from feedback, or resume its System Design and Program Design interviews one decision at a time, updating it in place under `.agents/artifacts/<task>/`. The iterate half of the TDD phase (flows `prd-tdd` and `tdd`, pairs with /create-tdd), invoked manually. Not for writing the first TDD (use /create-tdd), product behavior (use /iterate-prd), or the sliced implementation skeleton (use /create-structure-outline or /iterate-structure-outline).
argument-hint: "<TDD document or task directory> [feedback]"
disable-model-invocation: true
---

# Iterate a TDD (CRISPY technical design phase)

Revise the TDD for: **$ARGUMENTS**

Keep System Design (how components interact) and Program Design (the in-code shape) distinct, and settle one choice at a time in the main conversation.

## Step 1: Find the TDD and read the context

From `$ARGUMENTS`, take a document path or a task directory, plus any feedback. In a task directory, use the highest-numbered `NN-tdd-*` and name it. With no path, resolve the task directory from the current branch as in `skills/QRSPI-WORKFLOW.md`, and ask when several fit. When no TDD exists, name `/create-tdd` instead.

Read the TDD, the request, research, PRD, and design-discussion documents present, and any named sources, all in full. Note the settled system and program choices and any recorded approvals.

## Step 2: Pick the next technical decision

Use the user's feedback, or resume unfinished design. For a finished TDD with no feedback, offer a choice between revising it and exploring further technical questions. When resuming an interview, settle and get approval for System Design before opening Program Design. Feedback can revise either half, and an architecture change can force the code shape to change too.

## Step 3: Verify current behavior and patterns

Read the relevant code, and dispatch `codebase-locator`, `codebase-analyzer`, or `codebase-pattern-finder` where a fact or pattern is missing. Use `codebase-online-researcher` for external questions. Wait for the findings, and add new facts to the research document in place, through its output skill. When an answer corrects a fact about the code, verify it against the source before recording it. Decisions are the user's, but facts are checked.

## Step 4: Settle the choice and update the TDD

Present one decision with options, tradeoffs, and a recommendation, using `AskUserQuestion`. For system choices, show diagrams or contracts across components. For program choices, show each concrete code-shape option in its own code block. Wait for the user to settle the choice before editing.

Rework the affected sections in place. Current behavior and the proposed change go in **System Design**, the in-code structure in **Program Design**, and test seams in Patterns to Follow. Headers state the agreed behavior. With the user's agreement, update the PRD and mockups too when a technical choice changes product behavior.

Re-render through the same output skill the document was written with (`.html` → `Skill('output-html')`, `.md` → `Skill('output-markdown')`), at the same stem, using the slots and body sections in `skills/create-tdd/SKILL.md` Step 4. Keep the existing metadata. Refresh `crispy:repos`, and set `crispy:last_updated`, `crispy:last_updated_by` (`git config user.name`), and `crispy:last_updated_note`.

## Step 5: Continue, review, and hand off

At each section review, offer to open the document in VS Code, Cursor, or the browser. When the interview is continuing, ask the next unresolved question. After applying one specific piece of feedback, hand control back to the user. When a revision touches a half, get that half approved again: System Design first, then Program Design.

Once both halves are approved, set the status as `skills/create-tdd/SKILL.md` Step 4 defines it and give the handoff from its Step 9. That is the optional `/create-structure-outline .agents/artifacts/<task> flow: <flow>` (or `/iterate-structure-outline` when an outline already exists and the change affects it), or direct implementation. Then wait.
