---
name: create-prd
description: Write a Product Requirements Document (PRD) for a task by interviewing the user one product decision at a time (the problem, how success is measured, the user-facing solution, and scope) while recording technical questions for the TDD. The PRD phase of CRISPY (flow `prd-tdd`), invoked manually after /research-codebase; reads the task directory's request and research and writes `NN-prd-<desc>` under `.agents/artifacts/<task>/` via output-html or output-markdown (`--format=html|md`, default `html`). Not for the technical approach, schemas, or code structure (use /create-tdd), a combined product-and-technical design for a smaller change (use /design-discussion), or a task breakdown (use /create-spec or the planner agent).
argument-hint: "<task directory or prior artifact path> [--format=html|md] [flow: <flow>]"
disable-model-invocation: true
---

# Product Requirements (CRISPY PRD phase)

Write a PRD for the task at: **$ARGUMENTS**

The PRD defines what to build and why: the problem, the success measure, and the user experience, functionality, and behavior. It separates the user-facing result from the technical approach, which suits a larger feature with open product questions. Technical questions go to the TDD (`/create-tdd`), so this conversation stays on product behavior.

Follow the steps in order and run the interview in the main conversation.

## Step 1: Parse arguments

From `$ARGUMENTS`, extract:

- `--format=html|md` (default `html`). `html` → `Skill('output-html')`, `md` → `Skill('output-markdown')`. Both consume the same render brief, so the format changes only how the document renders.
- `flow: <flow>`. When absent, use `crispy:flow` from the request document; when that is absent too, use `prd-tdd`.
- The remainder: a task directory, the path of an artifact inside one, or inline text describing the task.

## Step 2: Resolve the task directory

All artifacts for one task live in `.agents/artifacts/<task>/` at the repo root.

- A task directory or artifact path in the arguments decides it (an artifact path means its parent directory).
- Otherwise derive `<task>` from the current branch with `/` replaced by `-` (`feat/ENG-123-csv-export` → `feat-ENG-123-csv-export`) when the branch identifies the task. On `main`/`master`, or when the branch doesn't identify the task, use a short kebab-case slug from the request.
- Reuse an existing directory that obviously matches the request or branch without asking. When one looks close but could belong to another task, or several are plausible, ask the user which to use.

State the chosen path in the conversation.

The document is `NN-prd-<desc>.<ext>`, where `NN` is the next available two-digit number in the directory (count every `NN-` file regardless of type or extension; the first file is `01`). When a PRD already exists and the user is iterating or resuming, update it in place, keep its path and number, and pick up the interview where the document leaves off; create a new numbered PRD only when none exists or the user asks for one. When several exist, use the highest-numbered and name it.

## Step 3: Read the inputs

Read these in full (no limit/offset) in the main context, taking the highest-numbered document of each type:

- `NN-request-*` — the desired result, constraints, acceptance criteria, and compatibility posture.
- `NN-research-*` (the `research` type, not `research-questions`) — how the system behaves today.
- `NN-design-discussion-*`, when present — settled choices to carry forward rather than reopen.
- Files and mockups those documents name, as needed.

Reference the inputs for facts instead of repeating them, and turn missing product context into interview questions. When a product decision depends on current behavior the research doesn't establish, dispatch a focused `codebase-analyzer` (or `codebase-locator`) for that one fact, wait for it, and cite the finding. Fold the new facts into the research document in place (same path and format, re-rendered through its output skill with `crispy:last_updated`, `crispy:last_updated_by`, and `crispy:last_updated_note` refreshed), so later phases find them there. A gap larger than that means research is incomplete, so suggest rerunning `/research-codebase`. For UI work, use the research's design-system findings when drawing mockups.

Record the repositories for `crispy:repos`: for each repository the task touches (usually the current one), take the identifier from `gh repo view --json nameWithOwner -q .nameWithOwner` (or the repo directory name when that fails) and the SHA from `git rev-parse HEAD`, formatted as comma-separated `<identifier>@<sha>` entries, or `none`.

## Step 4: Write a small starting document

Write the PRD right away so the interview starts promptly: a first-draft Problem to Solve, with Success, Proposed Solution, and Solution Details present but empty (a one-line "Settled during the interview." intro is enough). Hand the content to the output skill from Step 1 with the full stem `.agents/artifacts/<task>/NN-prd-<desc>` (no extension; the output skill appends `.html` or `.md` and creates the directory if needed). Every later step updates this same file in place through the output skill.

### Slot values

Use these exact slot names; they are the shared CRISPY render-brief vocabulary defined in `skills/output-html/SKILL.md` and `skills/output-markdown/SKILL.md`, and downstream phases parse the metadata.

| Slot | Value |
| --- | --- |
| `PHASE` | `prd` |
| `PHASE_LABEL` | `Product Requirements` |
| `STATUS` | `draft` until the user approves Solution Details; then `ready-for-tdd` |
| `STATUS_CLASS` | derived from `STATUS` per the output skill's status table |
| `TOPIC` | kebab-case topic (the `<desc>` part of the filename) |
| `TITLE` | `Product Requirements: <Topic>` |
| `TICKET` | one-line ticket summary from the request document, or `N/A` |
| `PROMPT_TEXT` | the problem being solved, in 1–2 sentences |
| `META_EXTRA` | `crispy:task_dir`, `crispy:flow`, `crispy:repos`, `crispy:request_doc`, `crispy:research_doc`, and `crispy:design_doc` when a design discussion was read |
| `SUMMARY_EXTRA` | rows for: Request doc (link), Research doc (link), Flow |

Doc-link fields hold `.agents/artifacts/...` paths.

### Body sections

Emit numbered sections in this order. Section and sub-section headers state the result rather than the topic (e.g. "Reviewers comment without signing in"), so a reader can follow the product by skimming them. Use short paragraphs.

1. **Problem to Solve** — the user's problem, their current experience, and what they need. Drafted first.
2. **Success** — the agreed way to tell whether the change helps users after it ships.
3. **Proposed Solution** — the high-level solution, built up as choices settle.
4. **Solution Details** — one sub-section per feature or behavior, each placing its mockup links beside the explanation.
5. **Alternative Solutions Considered** — options set aside and why.
6. **Scope** — agreed boundaries, including what is out of scope.
7. **Deferred to TDD** — technical questions raised during the interview. Omit when there are none.
8. **Open Questions** — product decisions still unsettled. Present only while some remain (for example after an early handoff), so later phases can see the PRD isn't final; omit it otherwise.

Then quote the drafted problem statement in the conversation and ask one question to confirm or correct it.

## Step 5: Settle the problem and the success measure

Agree on the problem first, and rework Problem to Solve once the user settles the wording.

Then discuss how to tell whether the change helps users once it ships. Propose a measure suited to the work: adoption, a benchmark, errors, latency, or a qualitative result. For small work with no useful measure, record "none" in Success along with the user's agreement, so the omission is a decision rather than a gap.

Ask one question per message and wait for the answer, because a stack of questions gets skimmed answers.

## Step 6: Interview the user about the solution

Present one product decision per message with two or three options, their tradeoffs, and a recommendation grounded in the request and research. Ask with `AskUserQuestion`, wait for the answer, and answer clarifying questions until the choice is settled. Then have the output skill update the PRD in place: revise Solution Details, refine Proposed Solution, and record the set-aside options under Alternative Solutions Considered and any boundary changes under Scope, so the document reads as one coherent spec rather than a decision log. Then present the next decision.

Choose and place visuals per `skills/output-html/references/visual-guidance.md`. For UI choices, save a focused `mockup-<desc>.html` in the task directory that matches the user's product (its colors, type, spacing, and components) with realistic labels, and link it with an ordinary relative link beside its explanation, both in the PRD and in the conversation. Update mockups as decisions change.

When a question is technical (schemas, storage, endpoints, code structure), record it under Deferred to TDD and return to product behavior; the TDD settles it with the right context.

## Step 7: Get approval of the whole solution

When the solution is filled out, ask the user to read Solution Details from start to finish and approve it as a whole, because individually settled decisions can still add up to something they didn't intend. Incorporate their fixes and keep the document and mockups current. Offer to open the document for review in VS Code, Cursor, or the browser; artifacts are working documents and are not committed, so review happens on the file itself.

On approval, set `STATUS` to `ready-for-tdd` and remove Open Questions if it is still present.

## Step 8: Hand off

Give the saved path, offer again to open it for review, and name the next command with the task directory and flow. The usual next step is the technical design:

```text
/create-tdd .agents/artifacts/<task> flow: prd-tdd
```

When the PRD already settles everything (no Deferred to TDD items and no real technical choices), the user can skip to `/structure-outline .agents/artifacts/<task> flow: prd-tdd` or implement directly (`/orchestrate .agents/artifacts/<task>`, or in this session for a small change). Say the command can run here, after compaction, or in a new session, and that the user can also ask to revisit part of the solution.

Then wait. The user invokes each phase, so don't start the next one yourself.

If the user asks to stop or move on early, save the settled decisions, list the unsettled ones under Open Questions with status `draft`, and give the handoff for the step they asked for.

## Abort conditions

Stop and tell the user rather than proceeding when:

- The task directory has no research document — the PRD's account of the current experience rests on it; suggest `/research-codebase` first.
- There is no request document and the arguments don't say what result the user wants — ask before drafting.
- A required render-brief slot can't be filled (e.g., no topic derivable) — ask rather than emit a placeholder.
