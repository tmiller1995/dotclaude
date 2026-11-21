---
name: iterate-research-questions
description: Revise an existing CRISPY research-questions document from the user's feedback, or finish a partly written question set, updating it in place under `.agents/artifacts/<task>/`. The iterate half of the questions phase (pairs with /create-research-questions), invoked manually, usually in a fresh session after reviewing the document. Not for writing the first questions document from a ticket (use /create-research-questions) or for answering the questions (use /create-research).
argument-hint: "<research-questions document or task directory> [feedback or feedback file]"
disable-model-invocation: true
---

# Iterate Research Questions (CRISPY questions phase)

Revise the research questions for: **$ARGUMENTS**

## Step 1: Find the document and the feedback

From `$ARGUMENTS`, take a document path or a task directory, plus any feedback text or feedback file. In a task directory, use the highest-numbered `NN-research-questions-*` and name it. With no path, resolve the task directory from the current branch as in `skills/QRSPI-WORKFLOW.md` → Task Directory and File Naming, and ask when several fit. When no research-questions document exists, say so and name `/create-research-questions` instead.

Read the document and every named feedback file in full. Also read the `NN-request-*` document: this phase owns it, and a flow or compatibility change lands there too. When the document is complete and no feedback was given, ask what the user wants to change. When it is partly written, continue from its existing scope.

## Step 2: Refine the questions

Check the feedback against the files it names, and use one small `codebase-locator` pass when a question needs better starting pointers. Keep the questions as `skills/create-research-questions/SKILL.md` → "What good questions look like" defines them: descriptive questions about what exists, where it lives, how it behaves and how the parts interact, each with concrete starting pointers. Usually there are two to seven. For frontend work, cover the design system. Design choices about the future stay out of the questions, and so does ticket content: research must never learn what is being built.

## Step 3: Update the documents in place

Weave the feedback into the questions and context pointers. Keep exact paths, package names, repository names, and URLs intact, and add pointers the feedback supplies.

Re-render through the same output skill the document was written with (`.html` → `Skill('output-html')`, `.md` → `Skill('output-markdown')`), at the same stem, using the slots and body sections in `skills/create-research-questions/SKILL.md` Step 7. Keep the existing metadata. Refresh `crispy:repos`, and set `crispy:last_updated`, `crispy:last_updated_by` (`git config user.name`), and `crispy:last_updated_note` (one line on what changed). When the user changes the flow or the compatibility posture, update `crispy:flow` and the posture keys in both documents.

## Step 4: Hand off

Show the saved path and the revised list of questions, and offer to open the document in VS Code, Cursor, or the browser. Name the next command with the task directory and flow, and say it can run here, after compaction, or in a new session:

```text
/create-research .agents/artifacts/<task> flow: <flow>
```

When a research document already exists and the changed questions need new answers, name `/iterate-research <research document>` instead. Then wait; research starts only when the user runs it.
