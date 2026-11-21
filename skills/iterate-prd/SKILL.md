---
name: iterate-prd
description: Revise an existing CRISPY Product Requirements Document from feedback, or resume its product interview one decision at a time, updating it in place under `.agents/artifacts/<task>/`. The iterate half of the PRD phase (flow `prd-tdd`, pairs with /create-prd), invoked manually. Not for writing the first PRD (use /create-prd), technical choices such as schemas, endpoints, or code structure (use /iterate-tdd or /create-tdd), or a combined design for a smaller change (use /iterate-design-discussion).
argument-hint: "<PRD document or task directory> [feedback]"
disable-model-invocation: true
---

# Iterate a PRD (CRISPY PRD phase)

Revise the PRD for: **$ARGUMENTS**

## Step 1: Find the PRD and read the context

From `$ARGUMENTS`, take a document path or a task directory, plus any feedback. In a task directory, use the highest-numbered `NN-prd-*` and name it. With no path, resolve the task directory from the current branch as in `skills/QRSPI-WORKFLOW.md`, and ask when several fit. When no PRD exists, name `/create-prd` instead.

Read the PRD, the request, research, and design-discussion documents present, and any named sources, all in full. Read linked mockups when they bear on the current decision. Note the problem, the success measure, the agreed solution, and what is still unfinished.

## Step 2: Choose the next product question

Use the user's feedback or the interview direction they asked for. For unfinished work, continue with the next unsettled product choice. For a complete PRD with no feedback, offer a choice between revising it and exploring further product questions.

Keep the conversation on user experience, functionality, and behavior. Record implementation questions under **Deferred to TDD**.

## Step 3: Verify the context the decision needs

Check factual claims against the relevant code and docs. Dispatch a focused `codebase-analyzer` or `codebase-locator` when a fact is missing, and wait for its findings before presenting options. Add new facts to the research document in place, through its output skill, with `crispy:last_updated*` refreshed. When an answer corrects a fact about current behavior, verify it before recording it.

## Step 4: Settle the decision and rework the PRD

Ask one question per message, with options, tradeoffs, and a recommendation, using `AskUserQuestion`. Work through clarifications until the user settles it. No stacked follow-ups and no vague "any feedback?".

Then edit the PRD in place so it describes the current agreed solution as one coherent spec rather than a decision log. Reflect the change in Problem to Solve, Success, Proposed Solution, Solution Details, Alternative Solutions Considered, and Scope where relevant. Headers state the result. For visual decisions, update the focused `mockup-*.html` files and their links beside the explanation. When the user asks for mockup changes, iterate on the mockup until they approve it, then resume.

Re-render through the same output skill the document was written with (`.html` → `Skill('output-html')`, `.md` → `Skill('output-markdown')`), at the same stem, using the slots and body sections in `skills/create-prd/SKILL.md` Step 4. Keep the existing metadata. Refresh `crispy:repos`, and set `crispy:last_updated`, `crispy:last_updated_by` (`git config user.name`), and `crispy:last_updated_note`.

When the user asked to continue the interview, present the next unsettled choice. After applying one specific piece of feedback, hand control back to the user.

## Step 5: Review and hand off

Offer to open the document in VS Code, Cursor, or the browser. When the solution is ready, ask the user to read **Solution Details** as a whole and approve it. On approval, set `STATUS` to `ready-for-tdd` and drop Open Questions. Then give the handoff from `skills/create-prd/SKILL.md` Step 8. That is usually `/create-tdd .agents/artifacts/<task> flow: prd-tdd`, or `/iterate-tdd` when a TDD already exists and the product change affects it. Then wait.
