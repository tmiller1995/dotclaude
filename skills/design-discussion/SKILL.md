---
name: design-discussion
description: Produce a ~200-line design discussion for a task (current state, desired end state, and contrastive design decisions with rationale) and walk the user through each open decision one at a time. The Design phase of CRISPY (flow `design`), invoked manually after /research-codebase; reads the task directory's request, research-questions, and research documents and writes `NN-design-discussion-<desc>` under `.agents/artifacts/<task>/` via output-html or output-markdown (`--format=html|md`, default `html`). Not for separate product requirements or technical design documents (use /create-prd or /create-tdd), signatures and vertical slices (use /structure-outline), a task-level implementation plan (use /create-spec), or investigating the codebase (use /research-codebase).
argument-hint: "<task directory or prior artifact path> [--format=html|md] [flow: <flow>]"
disable-model-invocation: true
---

# Design Discussion (CRISPY design phase)

Produce a design discussion for the task at: **$ARGUMENTS**

This phase settles product and technical choices together, before anything is outlined or built. It fits a change with a few clear options; larger features with open product questions go through `/create-prd` and `/create-tdd` instead.

## Why this phase, and why ~200 lines

Dex Horthy calls design "the highest-leverage stage": the agent brain-dumps everything it found, everything it wants to do, and everything it does not know, and the human performs brain surgery on that mental model before anything downstream is built. The reader catches wrong pattern choices, wrong assumptions about the data model, bad tradeoffs, and missing concerns (security, tenancy, migration).

The ~200-line target keeps the prose short enough to read carefully and long enough to surface every meaningful decision; the Proposed architecture views don't count toward it. A 1,000-line plan has as many surprises as 1,000 lines of code, because persuasive narrative hides wrong technical assumptions. A draft past ~300 lines means the plan is being written prematurely; cut it.

Corrections are easy to make when the document shows its reasoning rather than only conclusions, names the rejected options, puts the most important decisions first, and can be skimmed: each decision card's title states the point (once chosen, the outcome, e.g. "Exports run as a background job, not inline"), so the titles alone convey the design.

## Workflow

### Step 1: Parse arguments

From `$ARGUMENTS`, extract:

- `--format=html|md` (default `html`). It selects the renderer in Step 6: `html` → `Skill('output-html')`, `md` → `Skill('output-markdown')`. Both consume the same render brief and decision-card contract, so the format changes only how the document renders.
- `flow: <flow>` — `design`, `prd-tdd`, `tdd`, or `research-only`. When absent, use `crispy:flow` from the request document; when that is absent too, use `design`.
- The remainder: a task directory, the path of an artifact inside one, or inline text describing the task.

### Step 2: Resolve the task directory

All artifacts for one task live in `.agents/artifacts/<task>/` at the repo root.

- A task directory or artifact path in the arguments decides it (an artifact path means its parent directory).
- Otherwise derive `<task>` from the current branch with `/` replaced by `-` (`feat/ENG-123-csv-export` → `feat-ENG-123-csv-export`) when the branch identifies the task. On `main`/`master`, or when the branch doesn't identify the task, use a short kebab-case slug from the request.
- Reuse an existing directory that obviously matches the request or branch without asking. When one looks close but could belong to another task, or several are plausible, ask the user which to use.

State the chosen path in the conversation.

The document is `NN-design-discussion-<desc>.<ext>`, where `NN` is the next available two-digit number in the directory (count every `NN-` file regardless of type or extension; the first file is `01`) and `<desc>` is short kebab-case. When a design-discussion document already exists and the user is iterating or resuming, update it in place and keep its path and number; create a new numbered document only when none exists or the user asks for one. When several exist, use the highest-numbered and name it.

### Step 3: Read the inputs

Read these in full (no limit/offset) in the main context, taking the highest-numbered document of each type:

- `NN-request-*` — the desired result, constraints, acceptance criteria, and compatibility posture. It is the source for Desired End State.
- `NN-research-questions-*` — what research was asked to establish.
- `NN-research-*` (the `research` type, not `research-questions`) — the factual map of the code as it exists today, the source for Current State.
- Supporting mockups or diagrams those documents link, as needed.

Work from these documents rather than re-researching. When a choice depends on a fact the research lacks, dispatch a focused `codebase-locator`, `codebase-analyzer`, or `codebase-pattern-finder` for that fact (independent lookups in one message), wait for the findings, and verify the relevant code before presenting options. Fold the new facts into the research document in place (same path and format, re-rendered through its output skill with `crispy:last_updated`, `crispy:last_updated_by`, and `crispy:last_updated_note` refreshed), so later phases find them there. A gap larger than that means research is incomplete, so suggest rerunning `/research-codebase`. When there is no request document and the arguments don't make the desired result clear, ask the user what result they want before drafting.

Record the repositories for `crispy:repos`: for each repository the design touches (usually the current one), take the identifier from `gh repo view --json nameWithOwner -q .nameWithOwner` (or the repo directory name when that fails) and the SHA from `git rev-parse HEAD`, formatted as comma-separated `<identifier>@<sha>` entries, or `none`.

### Step 4: Brain dump (draft)

Write a first draft covering everything learned from research and everything the solution should look like. Ignore the line count for now.

**Current State** — what users see and can do today (2–5 bullets grounded in the research, citing file:line where a claim needs it), the constraints that apply, and what works well and should stay unchanged.

**Desired End State** — what users will see and be able to do after the change, what "done" looks like from their perspective, and the invariants that must hold.

**Proposed Architecture** — how the pieces fit together, as focused before/after views: component or file trees, contracts, call trees, or pseudocode, and `diff` blocks when the point is what changes. Code structure lives here rather than in the state sections. Choose and place views per `skills/output-html/references/visual-guidance.md`, and mark which parts depend on a still-open question.

**Open Questions** — every real choice, drafted with contrastive options, their tradeoffs, and a Recommendation grounded in the research (cite the supporting file:line). The user makes these choices, so the draft recommends rather than picks:

```
Q1: [The choice to make]

- (A) [Option] — [tradeoff]
- (B) [Option] — [tradeoff]
- (C) [Option] — [tradeoff]

Recommendation: [best guess and the codebase evidence for it]
```

**Design Decisions** — only choices the user already settled or the request fixes; otherwise this starts empty. Step 7 promotes each answered question here as a decision card:

```
Decision: [The point, stated: what is being decided, or once chosen, the outcome]

- (A) [Option 1] — [pros] — [cons]
- (B) [Option 2] — [pros] — [cons]
- (C) [Option 3] — [pros] — [cons]

Chosen: (B) — [one-line rationale]
Why not (A): [specific reason]
Why not (C): [specific reason]
```

Use a two-sided pros/cons comparison instead of A/B/C when the choice is what a single approach gains versus gives up. Concrete options with concrete tradeoffs are what let the human correct you; "I chose X because it seems best" is a preference, not a decision, so give the specific reason each alternative lost.

**Patterns to Reuse** — the existing patterns (from research) the new code adopts: for each, its `file:line`, a short example from the existing code, which file the new code will resemble, and how that area is tested today (test location and style). Use a table for 3+ patterns, with the examples beneath it.

**Non-Goals** — what this design does not address, as a bulleted list. Non-goals are binding downstream, so they prevent scope creep.

### Step 5: Cut to ~200 lines

Cut redundant explanations, implementation code samples outside Proposed architecture and file-by-file change lists (those belong in the structure outline), speculative future features, task breakdowns and detailed migration steps (those belong in the spec or the planner), and long prose in favor of bullets.

Target 150–250 lines, with a ceiling of 300, not counting the Proposed architecture views. If it doesn't fit, the scope is too large; tell the user to split the feature.

### Step 6: Prepare the render brief and delegate

Hand the structured content to the output skill chosen in Step 1 and let it write the file; it owns the template, the component vocabulary, and slot substitution. Pass the full stem `.agents/artifacts/<task>/NN-design-discussion-<desc>` with no extension. The output skill appends `.html` or `.md` and creates the directory if needed.

#### Slot values

Use these exact slot names; they are the shared CRISPY render-brief vocabulary defined in `skills/output-html/SKILL.md` and `skills/output-markdown/SKILL.md`, and downstream phases parse the metadata.

| Slot | Value |
| --- | --- |
| `PHASE` | `design` |
| `PHASE_LABEL` | `Design Discussion` |
| `STATUS` | `draft` while questions are open; `ready-for-structure` once Step 7 resolves all of them |
| `STATUS_CLASS` | derived from `STATUS` per the output skill's status table |
| `TOPIC` | kebab-case topic (the `<desc>` part of the filename) |
| `TITLE` | `Design Discussion: <Topic>` |
| `TICKET` | one-line ticket summary from the request document, or `N/A` |
| `PROMPT_TEXT` | TL;DR of what's being designed (2–3 sentences) |
| `META_EXTRA` | `crispy:task_dir`, `crispy:flow`, `crispy:repos`, `crispy:request_doc`, `crispy:questions_doc`, `crispy:research_doc`, `crispy:author`, `crispy:decisions_resolved` (count) |
| `SUMMARY_EXTRA` | rows for: Research doc (link), Decisions resolved (count, accent), Flow, Author |

Doc-link fields hold `.agents/artifacts/...` paths.

#### Body sections

Emit numbered sections in this order (the output skill numbers them `01`, `02`, ...):

1. **Summary** — 2–3 sentences on what is being designed and why. The header's prompt box already echoes the TL;DR, so keep it short.
2. **Current state** — a sec-intro ("What users see and can do today, drawn from research.") then bullets, citing file:line references where they back a claim. Use a collapsible `<details>` deep dive past 10 lines.
3. **Desired end state** — bullets of what users will see and be able to do.
4. **Proposed architecture** — the before/after views from Step 4, each beside a short explanation. In Markdown, trees and pseudocode are fenced blocks and flows may be Mermaid; in HTML, use the inline-SVG diagram component from `skills/output-html/references/components.md` or a linked `diagram-<desc>.html`.
5. **Design decisions** — one decision card per settled decision, in the Step 4 format. Empty in a first draft unless the user or request already settled something.
6. **Patterns to reuse** — table with columns Pattern | Lives in (file:line) | New code mirrors (file) | Tested by, followed by a short code example per pattern.
7. **Open questions** — one card per open choice, with options, tradeoffs, and a Recommendation. Delete the section once Step 7 has promoted every card into Design decisions.
8. **Non-goals** — bulleted list.

When a choice is visual (layout, UI states, a dense flow), save a focused `mockup-<desc>.html` or `diagram-<desc>.html` beside the document in the task directory, matching the project's visual conventions with real labels, and link it from the relevant card with an ordinary relative link.

### Step 7: Resolve open questions one at a time

This is the brain-surgery moment, and it happens by default with no trigger phrase. Run it in the main conversation, one question per message, because batched questions get skimmed answers. For each open question:

1. Present the options, their tradeoffs, and your recommendation with the codebase evidence behind it.
2. Ask for the answer with `AskUserQuestion` and wait for it before presenting the next question. Answer clarifying questions until the choice is settled.
3. Have the output skill update the document in place: move the card from Open questions to Design decisions, mark the chosen option, capture the rationale (including the user's reasoning), add a why-not line for each alternative set aside, and retitle the card so it states the outcome. Bring Proposed architecture and the state sections in line with the decision.
4. Update `crispy:decisions_resolved` and its visible Summary cell so the count tracks progress.

Every open question gets this treatment; none are skipped.

If the user wants to stop while questions remain, save the settled decisions, leave the rest under Open questions with status `draft`, and give the handoff. If the user explicitly asks to move on to a later step anyway, save the settled and open choices the same way, then give the handoff for the step they asked for; that step carries the open items into its own Open Questions rather than stopping.

### Step 8: Hand off

After all questions are resolved:

1. Set `STATUS` to `ready-for-structure` and re-render the Status cell with the matching badge.
2. Give a 3-sentence summary of the design and the saved path.
3. Offer to open the document for review in VS Code, Cursor, or the browser. Artifacts are working documents and are not committed, so review happens on the file itself.
4. Name the next command for the flow, including the task directory and flow:
   - `design`: optionally `/structure-outline .agents/artifacts/<task> flow: design` to divide the work into testable slices, or implement directly from this design (`/orchestrate .agents/artifacts/<task>`, or in this session for a small change). `/create-spec` is available when the user wants a task-ready plan.
   - `prd-tdd` or `tdd` (a design discussion was run anyway): `/create-prd` or `/create-tdd` with the same task directory and flow.
5. Say it can run here, after compaction, or in a new session; the task directory carries everything the next phase needs.

Then wait. The user invokes each phase, so don't start the next one yourself.

## Forking to explore competing designs

This phase is the natural forking checkpoint: the research context is loaded and nothing downstream exists yet. When two directions are both viable and the tradeoff cards can't settle it, suggest the user fork rather than forcing a pick: fork the conversation (`/rewind`, a duplicated session, or a second worktree), draft Design decisions once per direction, compare the documents side by side, and continue from the winner. A wrong architecture caught here costs one re-rendered document; caught mid-implementation it costs the whole downstream chain. Reserve forking for genuinely divergent architectures; a tradeoffs card settles preferences.

## Abort conditions

Stop and tell the user rather than proceeding when:

- The task directory has no research document, or it is empty — there is nothing to design against; suggest `/research-codebase`.
- The research is too thin to ground a design (no file:line references, no current-state map) — ask the user to run `/research-codebase` first rather than researching here.
- The scope won't fit in ~300 lines even after cutting — suggest splitting the feature.
- A required render-brief slot can't be filled (e.g., no topic derivable) — ask rather than emit a placeholder.
