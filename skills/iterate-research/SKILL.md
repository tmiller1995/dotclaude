---
name: iterate-research
description: Correct or extend an existing CRISPY research document from the user's feedback, or resume an unfinished investigation, dispatching codebase sub-agents and weaving verified findings into the document in place under `.agents/artifacts/<task>/`. The iterate half of the research phase (pairs with /create-research), invoked manually. Keeps the ticket-isolation rule. Not for the first research pass from a questions document (use /create-research), for changing the questions themselves (use /iterate-research-questions), or for design choices (use the design phases).
argument-hint: "<research document or task directory> [feedback or follow-up questions]"
disable-model-invocation: true
---

# Iterate Research (CRISPY research phase)

Revise the research for: **$ARGUMENTS**

The research explains the system as it exists today, with evidence. `skills/create-research/SKILL.md` → "The Ticket Isolation Rule" still applies. The research document, its research-questions document, and the user's feedback are your whole task context. Leave the request and design documents unopened, and give sub-agents only individual questions and their pointers.

## Step 1: Find the document and the feedback

From `$ARGUMENTS`, take a document path or a task directory, plus the feedback or follow-up questions. In a task directory, use the highest-numbered `NN-research-*` that is a research report, not `research-questions`, and name it. With no path, resolve the task directory from the current branch as in `skills/QRSPI-WORKFLOW.md`, and ask when several fit. When no research document exists, name `/create-research` instead.

Read the research document in full in the main context before delegating, along with the source files it or the feedback names. When the document is complete and no feedback was given, ask what the user wants to investigate or change. When it is unfinished, continue from its recorded scope and open questions.

If the feedback describes the change being built rather than the current system, rephrase it as pure questions about the codebase before using it, as the isolation rule requires.

## Step 2: Decide what needs another look

List the findings the feedback affects, the questions still unanswered, and the evidence each needs. Group related investigations into focused areas, and keep each one about current behavior.

## Step 3: Investigate

Dispatch read-only sub-agents in parallel for independent areas: `codebase-locator` to find files, `codebase-analyzer` to trace behavior and data flow, `codebase-pattern-finder` for conventions and test patterns, and `codebase-online-researcher` only when the user asks for external sources (it returns links). Ask each for paths, line references, and testing patterns. Wait for every result. Then check the claims against the live code, resolve conflicts between results, and keep any remaining uncertainty explicit.

When the user's feedback corrects a fact, verify it against the code before recording it.

## Step 4: Update the document in place

Weave the verified findings into the affected sections so the document reads as one coherent explanation. Add a "Follow-up research — [timestamp]" section only for findings that fit nowhere else.

- Section headers state what is true ("Sessions persist before the daemon acknowledges the write"), so the headers alone summarize the findings.
- Explain a concept before citing where it lives, and cite `file:line` ranges.
- Update the testing patterns for each affected component, and say when no tests were found. Keep apart the tests you read and the checks you ran; a claim that a check passed carries its command and result.
- Keep the Summary, Code references, and Open questions consistent with the findings.

Re-render through the same output skill the document was written with (`.html` → `Skill('output-html')`, `.md` → `Skill('output-markdown')`), at the same stem, using the slots and body sections in `skills/create-research/SKILL.md` step 8. Keep the existing metadata. Refresh `crispy:repos`, and set `crispy:last_updated`, `crispy:last_updated_by` (`git config user.name`), and `crispy:last_updated_note`. Sync the visible Summary cells to match.

## Step 5: Hand off

Summarize what changed, with key file references and the saved path, and offer to open the document in VS Code, Cursor, or the browser. For standalone research, stop there and invite further questions. With a flow, name the next command from the table in `skills/create-research/SKILL.md` step 10, or the matching `/iterate-*` command when a later document already exists and the new findings affect it. Then wait.
