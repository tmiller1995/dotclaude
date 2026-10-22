---
name: create-tdd
description: Write a Technical Design Document (TDD) for a task by settling the system design (component interactions, contracts, schemas) and then the program design (call trees, file trees, signatures, pseudocode) with the user, one technical decision at a time and with a separate approval for each. The TDD phase of CRISPY (flows `prd-tdd` and `tdd`), invoked manually after /create-prd or straight after /research-codebase; reads the task directory's request, research, and PRD when present and writes `NN-tdd-<desc>` under `.agents/artifacts/<task>/` via output-html or output-markdown (`--format=html|md`, default `html`). Not for product requirements or user-facing behavior (use /create-prd), a combined product-and-technical design for a smaller change (use /design-discussion), or vertical slices with a file inventory (use /structure-outline).
argument-hint: "<task directory or prior artifact path> [--format=html|md] [flow: <flow>]"
disable-model-invocation: true
---

# Technical Design (CRISPY TDD phase)

Write a TDD for the task at: **$ARGUMENTS**

The TDD turns the available product context into a technical design. System Design comes first (how components interact), then Program Design (the code shape that implements it), each approved by the user separately, because a code shape built on an unapproved architecture gets rebuilt. A PRD is useful when present; a request plus research is enough to start, which suits fixes, cleanup, and refactors where the desired behavior is already clear.

Follow the steps in order and run the interview in the main conversation.

## Step 1: Parse arguments

From `$ARGUMENTS`, extract:

- `--format=html|md` (default `html`). `html` → `Skill('output-html')`, `md` → `Skill('output-markdown')`. Both consume the same render brief, so the format changes only how the document renders.
- `flow: <flow>`. When absent, use `crispy:flow` from the request document; when that is absent too, use `prd-tdd` if the task directory holds a PRD and `tdd` otherwise.
- The remainder: a task directory, the path of an artifact inside one, or inline text describing the task.

## Step 2: Resolve the task directory

All artifacts for one task live in `.agents/artifacts/<task>/` at the repo root.

- A task directory or artifact path in the arguments decides it (an artifact path means its parent directory).
- Otherwise derive `<task>` from the current branch with `/` replaced by `-` (`feat/ENG-123-csv-export` → `feat-ENG-123-csv-export`) when the branch identifies the task. On `main`/`master`, or when the branch doesn't identify the task, use a short kebab-case slug from the request.
- Reuse an existing directory that obviously matches the request or branch without asking. When one looks close but could belong to another task, or several are plausible, ask the user which to use.

State the chosen path in the conversation.

The document is `NN-tdd-<desc>.<ext>`, where `NN` is the next available two-digit number in the directory (count every `NN-` file regardless of type or extension; the first file is `01`). When a TDD already exists and the user is iterating or resuming, update it in place, keep its path and number, and pick up where the document leaves off; create a new numbered TDD only when none exists or the user asks for one. When several exist, use the highest-numbered and name it.

## Step 3: Read the inputs

Read these in full (no limit/offset) in the main context, taking the highest-numbered document of each type:

- `NN-request-*` — the desired result, constraints, acceptance criteria, and compatibility posture.
- `NN-research-*` (the `research` type, not `research-questions`) — how the system works today.
- `NN-prd-*`, when present — the agreed product behavior, plus its Deferred to TDD items, which this document must settle.
- `NN-design-discussion-*`, when present — settled choices carry forward rather than reopen.
- Files, mockups, and diagrams those documents name, as needed.

Reference the inputs rather than repeating them, and ask about missing behavior when needed. When a decision depends on a fact or pattern the research doesn't establish, dispatch a focused `codebase-analyzer`, `codebase-locator`, or `codebase-pattern-finder` for it (independent lookups in one message, so they run in parallel), wait for the findings, and verify the relevant code before presenting options. Fold the new facts into the research document in place (same path and format, re-rendered through its output skill with `crispy:last_updated`, `crispy:last_updated_by`, and `crispy:last_updated_note` refreshed), so later phases find them there. A gap larger than that means research is incomplete, so suggest rerunning `/research-codebase`.

Record the repositories for `crispy:repos`: for each repository the design touches (usually the current one), take the identifier from `gh repo view --json nameWithOwner -q .nameWithOwner` (or the repo directory name when that fails) and the SHA from `git rev-parse HEAD`, formatted as comma-separated `<identifier>@<sha>` entries, or `none`.

## Step 4: Write a small starting document

Write the TDD right away: System Design and Program Design present but empty (a one-line "Settled during the interview." intro is enough), Patterns to Follow drafted from the research, and Scope if the request already sets boundaries. Hand the content to the output skill from Step 1 with the full stem `.agents/artifacts/<task>/NN-tdd-<desc>` (no extension; the output skill appends `.html` or `.md` and creates the directory if needed). Every later step updates this same file in place through the output skill.

### Slot values

Use these exact slot names; they are the shared CRISPY render-brief vocabulary defined in `skills/output-html/SKILL.md` and `skills/output-markdown/SKILL.md`, and downstream phases parse the metadata.

| Slot | Value |
| --- | --- |
| `PHASE` | `tdd` |
| `PHASE_LABEL` | `Technical Design` |
| `STATUS` | `draft` until both System Design and Program Design are approved; then `ready-for-structure` |
| `STATUS_CLASS` | derived from `STATUS` per the output skill's status table |
| `TOPIC` | kebab-case topic (the `<desc>` part of the filename) |
| `TITLE` | `Technical Design: <Topic>` |
| `TICKET` | one-line ticket summary from the request document, or `N/A` |
| `PROMPT_TEXT` | what is being built and the technical question it answers, in 1–2 sentences |
| `META_EXTRA` | `crispy:task_dir`, `crispy:flow`, `crispy:repos`, `crispy:request_doc`, `crispy:research_doc`, `crispy:prd_doc` when a PRD was read, and `crispy:design_doc` when a design discussion was read |
| `SUMMARY_EXTRA` | rows for: Research doc (link), PRD (link, when present), Flow |

Doc-link fields hold `.agents/artifacts/...` paths.

### Body sections

Emit numbered sections in this order. Headers state the main point (e.g. "The worker receives a clock so retry timing is testable"), so a reader can follow the design by skimming them, and each diagram or code view sits beside the explanation it supports.

1. **System Design** — cross-component behavior and how it changes from today: services, endpoints, schemas, queues, stores, and external systems, with the contracts that matter (endpoint or message shapes, high-level signatures, schemas in the project's language or ORM).
2. **Program Design** — the in-code shape: call trees, component trees with state and package boundaries, file-tree changes, dependency-injection maps, method signatures, or pseudocode. Keep the views selective; the outline carries the detailed file list.
3. **Patterns to Follow** — existing patterns with source paths (`file:line`) and short examples, including the test seams new code should use.
4. **Scope** — technical boundaries agreed during the discussion. Omit when nothing beyond the PRD or request needs stating.
5. **Open Questions** — technical decisions still unsettled. Present only while some remain (for example after an early handoff), so `/structure-outline` and `/create-spec` can see the TDD isn't final; omit it otherwise.

Choose and place views per `skills/output-html/references/visual-guidance.md`. Draw flows (data flow, control flow, sequences) as Mermaid blocks in Markdown output; in HTML output, use the inline-SVG diagram component from `skills/output-html/references/components.md`, since output-html files load no Mermaid script. When a diagram needs more room, save a focused `diagram-<desc>.html` in the task directory using the project's visual conventions and real labels, and link it with an ordinary relative link beside its explanation.

Then open the interview with the first system-design decision: a short explanation, the options, their tradeoffs, and one question.

## Step 5: Discuss System Design

Show current behavior and the proposed change within this section. Present one decision per message with two or three options, their tradeoffs, and a recommendation grounded in the codebase; ask with `AskUserQuestion`, wait for the answer, and work through clarifications until it is settled. Then have the output skill rework System Design in place so its prose and diagrams stay a coherent description of the architecture, recording the chosen approach, the rationale, and why the alternatives were set aside. Then present the next decision.

## Step 6: Get System Design approval

Ask the user to review System Design from start to finish and approve it, and offer to open the document in VS Code, Cursor, or the browser (artifacts are working documents and are not committed, so review happens on the file itself). Incorporate their feedback. Move on to Program Design only after approval.

## Step 7: Discuss Program Design

Show the code shape that implements the approved system. When comparing options, give each its own code block: a focused diff for changes to an existing shape, and the complete target shape for new code or when omitted context would hide ownership or order. Choose the views that expose the decision rather than every view available.

Ask one question at a time, wait for the decision, and then rework Program Design in place. Fill in Patterns to Follow as patterns come up. If a technical choice changes product scope or user experience, discuss it with the user and, when a PRD exists, update the PRD (and its mockups) in place through the output skill so the two documents agree.

## Step 8: Get Program Design approval

Ask the user to review Program Design and approve the code shape, offering again to open the document for review. Incorporate their fixes. Once both sections are approved, set `STATUS` to `ready-for-structure` and remove Open Questions if it is still present.

## Step 9: Hand off

Give the saved path, offer to open it for review, and name the next command with the task directory and flow:

```text
/structure-outline .agents/artifacts/<task> flow: <flow>
```

The outline is optional: the user can implement directly from the TDD (`/orchestrate .agents/artifacts/<task>`, or in this session for a small change), and `/create-spec` is available when they want a task-ready plan. Say the command can run here, after compaction, or in a new session, and that the user can also ask to revisit a technical choice.

Then wait. The user invokes each phase, so don't start the next one yourself.

If the user asks to stop or move on early, save the settled decisions, list the unsettled ones under Open Questions with status `draft`, and give the handoff for the step they asked for.

## Abort conditions

Stop and tell the user rather than proceeding when:

- The task directory has no research document — the design rests on how the code works today; suggest `/research-codebase` first.
- There is no request document or PRD and the arguments don't say what result the user wants — ask before drafting.
- A required render-brief slot can't be filled (e.g., no topic derivable) — ask rather than emit a placeholder.
