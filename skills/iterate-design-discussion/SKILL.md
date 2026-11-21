---
name: iterate-design-discussion
description: Apply feedback to an existing CRISPY design discussion, or resume its open choices one decision at a time, keeping the document under `.agents/artifacts/<task>/` a coherent description of the agreed design. The iterate half of the design-discussion phase (flow `design`, pairs with /create-design-discussion), invoked manually. Not for writing the first design discussion (use /create-design-discussion), separate product and technical documents (use /iterate-prd or /iterate-tdd), or the implementation skeleton (use /create-structure-outline).
argument-hint: "<design-discussion document or task directory> [feedback]"
disable-model-invocation: true
---

# Iterate a Design Discussion (CRISPY design phase)

Revise the design discussion for: **$ARGUMENTS**

## Step 1: Find the document and read the context

From `$ARGUMENTS`, take a document path or a task directory, plus any feedback. In a task directory, use the highest-numbered `NN-design-discussion-*` and name it. With no path, resolve the task directory from the current branch as in `skills/QRSPI-WORKFLOW.md`, and ask when several fit. When none exists, name `/create-design-discussion` instead.

Read the discussion, the request and research documents, linked mockups and diagrams, and any files the feedback names, all in full and in the main conversation. Note which choices are settled and which are still open.

## Step 2: Pick the next decision

Start from the user's feedback. When resuming unfinished work, take the open choice that most affects the rest of the design. When the discussion is finished and no feedback was given, ask whether the user wants to change a choice or explore the design further.

## Step 3: Verify the facts the choice depends on

Read the relevant source, and dispatch a focused `codebase-locator`, `codebase-analyzer`, or `codebase-pattern-finder` when a fact is missing. Wait for the findings. Fold new facts into the research document in place, through its output skill, with `crispy:last_updated*` refreshed. When an answer corrects a fact about the code, verify it before recording it.

## Step 4: Settle one choice, then update the document

Treat an explicit choice in the feedback as settled. For a choice that still needs an answer, present two or three options with their tradeoffs and a recommendation grounded in the codebase, using `AskUserQuestion`, and wait. One decision per message: no stacked follow-ups and no vague "any feedback?".

Then update the document in place. Rework the current state, desired end state, proposed architecture, patterns to reuse, and non-goals as the decision requires. Move the answered card from Open questions to Design decisions, with the user's rationale and a why-not line for each alternative. Keep new choices open for the user. Update diagrams and linked `mockup-*.html` files beside the prose they support, and keep the document near its ~200-line budget.

Re-render through the same output skill the document was written with (`.html` → `Skill('output-html')`, `.md` → `Skill('output-markdown')`), at the same stem, using the slots and body sections in `skills/create-design-discussion/SKILL.md` Step 6. Keep the existing metadata. Refresh `crispy:repos` and `crispy:decisions_resolved`, and set `crispy:last_updated`, `crispy:last_updated_by` (`git config user.name`), and `crispy:last_updated_note`.

## Step 5: Continue or hand off

Offer to open the document in VS Code, Cursor, or the browser. When choices remain and the user wants to continue, present the next one. After applying one specific piece of feedback, hand control back to the user.

When every choice is settled, set the status as Step 6 of `skills/create-design-discussion/SKILL.md` defines it. Then give the handoff from its Step 8: the optional `/create-structure-outline .agents/artifacts/<task> flow: design` (or `/iterate-structure-outline` when an outline already exists and the change affects it), or direct implementation. For an early handoff, save the agreed decisions, leave the remaining choices under Open questions with status `draft`, and give the step the user asked for. Then wait.
