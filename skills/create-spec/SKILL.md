---
name: create-spec
description: Create a tactical implementation spec — numbered phases, each with implementation steps, tests, and separate Automated and Manual verification — from the highest-precedence design document in a CRISPY task directory (structure outline, else TDD, else PRD, else design discussion). The optional spec step of CRISPY, between the outline (or any design doc) and implementation; a spot-check transcription, not a design pass. Manual-only. Not for decomposing a finished spec into tasks (use the planner agent via /orchestrate) or carving vertical slices with signatures (use /structure-outline). Accepts `--format=html|md` (default `html`).
argument-hint: "<task directory or prior artifact path> [--format=html|md] [flow: <flow>]"
disable-model-invocation: true
---

# Create Spec (CRISPY optional spec step)

You are tasked with creating a tactical implementation spec for the task in: **$ARGUMENTS**

This is the optional **Spec** step of CRISPY. Use it when the user wants a task-ready plan with implementation steps per phase; otherwise the planner decomposes the outline or design document directly. By the time you're here, alignment already happened:

- Research documented the codebase as-is
- The flow's design documents (design discussion, or PRD and TDD) settled what to build and how
- The structure outline, when one exists, carved the feature into vertical slices with signatures

Your job is to turn the governing document into a **tactical spec with phased implementation steps** — not to revisit any of the earlier decisions.

## The Core Principle

> "Because alignment was achieved during Design and Structure, the engineer only needs to spot-check this rather than performing a deep line-by-line review. By the time you reach this stage, the plan is constrained by design decisions and structure that were already validated." — Alex Lavaee

A spec that requires deep review is a sign that a design phase was skipped. If you find yourself needing to make an architectural or product decision here, stop and tell the user to go back to the phase that owns it.

## What This Phase Does

1. Picks the governing document by precedence and reads it with the documents it cites
2. Converts its slices (or scope) into a phased spec with concrete implementation steps
3. Hands a structured render brief to the matching output skill, which writes the spec into the task directory as `NN-spec-<description>.<ext>`
4. Provides an executive summary for quick spot-check

## Owned by Other Phases

Earlier decisions arrive settled, and later work belongs to other agents, so this phase leaves these alone:

- Product and technical decisions — settled in the design discussion, PRD, or TDD
- Slice boundaries — settled in the structure outline when one exists
- Codebase research — the research phase is complete
- Walking the user through open questions with AskUserQuestion — the design phases' job
- Implementation code — the worker agent's job
- Task entries — the planner agent's job

## Workflow

### Step 1: Parse arguments and resolve the task directory

Extract `--format=html|md` (default `html`) and an optional `flow: <flow>` from `$ARGUMENTS`.

- `--format=html` → render via `Skill('output-html')`
- `--format=md` → render via `Skill('output-markdown')`

The remainder is a task directory, a document path inside one (use its directory — a research document's path resolves to its task directory like any other), or empty. When it is empty, look in `.agents/artifacts/` for the task directory: the current branch name with `/` replaced by `-` when the branch identifies the task, otherwise a directory whose name and documents match the request. Reuse an obvious match without asking; when a directory looks close but could belong to another task, or several are plausible, ask the user which to use. State the chosen path.

The flow is the `flow:` argument, else the request document's `crispy:flow` metadata.

Workflow documents are named `NN-<type>-<description>.<ext>`. If the directory already has a `spec` document, update it in place (same path and number) — the user is iterating or resuming. Create a new one only when none exists or the user asks for a new one; it takes the next available two-digit `NN` (count every existing `NN-` file, whatever its type or extension). When several documents of one type exist, use the highest-numbered and name it.

### Step 2: Pick the governing document and read the inputs

The governing document is the highest-precedence one present: **structure outline, else TDD, else PRD, else design discussion**. Read these fully (no limit/offset) in the main context:
- The governing document (primary input — drives everything)
- The documents it cites or that sit below it in the task directory: the other design documents present, the research document (for `file:line` citations), and the request document (for the one-line summary and acceptance criteria)

When documents conflict, the higher-precedence one wins and the lower ones supply context. If the resolved task directory holds no design document or outline — research only — abort; see When to Abort This Phase.

### Step 3: Verify settled decisions

Scan only the governing document for unresolved open questions or a `draft` status — the lower-precedence documents are superseded by it, so their leftovers don't block (matching `/structure-outline`). When a PRD governs, its "Deferred to TDD" items count as open if the spec would have to decide them. If anything is unresolved, abort — see When to Abort This Phase. When the user explicitly asks to proceed anyway, write the spec and carry those items into its Open Questions section (Section 08, status `draft`) instead of aborting.

### Step 4: Convert slices to phases

**From a structure outline:** plan one numbered phase per vertical slice — boundaries, goals, checkpoints, and verification are copied (correcting only commands that don't match the repo).

**From a TDD, PRD, or design discussion (no outline):** carve the scope into vertical phases following the same rules and defaults as `/structure-outline` — usually 3–6 (one for a small change), each a working end-to-end path with a testable checkpoint, dependencies flowing forward, and by default the last phase the hardening phase unless each phase carries its own error paths and tests. Take the shape of the code from the governing document (a TDD's Program Design, for example) rather than redesigning it.

Each phase becomes a **slice-card** (same component as the structure outline's slices) containing:

- A `### Phase N — Name` heading (mirrors structure-outline's `### Slice N — Name`)
- A **goal** line copied from the slice's goal — renders as `.goal` in HTML / `**Goal:**` in MD
- A **files touched** bulleted list, same as the structure outline's file list, each item tagged `NEW` / `MODIFY` / `DELETE` (HTML: `<span class="tag new|mod|del">`; MD: `**NEW** / **MODIFY** / **DELETE**`)
- A **checkpoint** line copied from the slice's checkpoint — this is the acceptance criterion. Renders as `.checkpoint` with a leading `✓` in HTML / `**Checkpoint:** ✓ …` in MD
- **Implementation steps** — a numbered list of concrete steps. Reference research `file:line` where new code touches existing code. Keep them concrete and brief — the worker agent has the task directory's documents as context.
- **Tests** — a bulleted list (HTML `<ul>` / MD `- [ ]` checklist) of test types, e.g. "**Unit:** `ReticulateButton` renders with loading state on click", "**Integration:** clicking button in dev → toast shows → no console errors"
- **Automated verification** — a checklist of literal commands that can be run unattended to prove the phase works: build, test suite, typecheck, lint (e.g. `dotnet test`, `npm run typecheck`). Copy the outline slice's list when there is one, correcting commands that don't match the repository. The worker runs these before marking a task complete.
- **Manual verification** — a checklist of steps only a human can confirm: UI behavior, visual checks, end-to-end flows in a real environment. Write each as an instruction to the human. The orchestrator surfaces these at the phase gate, and only the human checks them off — the implementing agent can't observe what they verify. Every phase needs at least one entry in each verification list; write "None — fully covered by automated checks" only when that is literally true.
- Optional `.chips` for metrics (HTML) / space-separated backticked `Label: Value` pairs with `·` (MD), e.g. size and surfaces, carried from the slice

The output skill renders these via the **slice-card component** — see `skills/output-html/references/components.md` → 'Vertical-slice cards' (or `skills/output-markdown/references/components.md` for the MD variant). The required children are the heading, the goal, the files-touched list, and the checkpoint; Implementation steps, Tests, Automated verification, and Manual verification are labeled sub-blocks inside the same card. Use the slice-card contract exactly as the output skills define it, because new component classes have no styling and no MD equivalent.

### Step 5: Prepare the render brief and delegate

Output path: pass the full stem `.agents/artifacts/<task>/NN-spec-<description>` (no extension), where `<description>` matches the governing document's description. When updating, pass the existing document's stem. The output skill appends the extension (`.html` or `.md`) and creates the directory if needed.

Invoke the matching output skill chosen in Step 1 with the brief below. The slot vocabulary is shared verbatim between `output-html` and `output-markdown` — the same brief renders either format unchanged.

#### Slot values

These slot names match the output skills' schema exactly. `REPO`, `BRANCH`, and `DATE` are derived by the output skill from the shell, so leave them out of the brief.

| Slot | Value |
| --- | --- |
| `PHASE` | `spec` |
| `PHASE_LABEL` | `Implementation Spec` |
| `STATUS` | `ready-for-implementation`; `draft` while Section 08 Open Questions holds carried-over items |
| `STATUS_CLASS` | `ready` (HTML; `draft` while open questions remain) — the MD skill derives the emoji from this |
| `TOPIC` | kebab-case topic — match the governing doc |
| `TITLE` | `<Topic> Implementation Spec` |
| `TICKET` | one-line request summary copied from the request or governing doc |
| `PROMPT_TEXT` | 2-3 sentences copied verbatim from the governing document's summary |
| `META_EXTRA` | `crispy:task_dir`, `crispy:flow`, `crispy:repos`, `crispy:request_doc`, `crispy:research_doc`, the doc-link key for each design document present (`crispy:structure_doc`, `crispy:tdd_doc`, `crispy:prd_doc`, `crispy:design_doc`), `crispy:author`, `crispy:phase_count` |
| `SUMMARY_EXTRA` | rows for: Phases (accent), Governing doc (link), a link row for each other design document present (Structure doc, TDD, PRD, Design doc), Author |

`crispy:repos` lists each repository the spec covers as `<identifier>@<sha>`, comma-separated: the identifier from `gh repo view --json nameWithOwner -q .nameWithOwner` (the repository directory name if that fails), the sha from `git rev-parse HEAD`. Use `none` when no repository applies. Doc-link values are `.agents/artifacts/...` paths.

**Author metadata.** The output skill already stamps the date into both the head metadata and the summary, so leave `crispy:date` and the `Date` row out of the brief — repeating them renders the field twice. The author is not in the template, so carry it explicitly: run `git config user.name` (Bash), put the result in `META_EXTRA` as `crispy:author`, and add a matching `Author` row to `SUMMARY_EXTRA`.

(Consistency rule from the output skills: every `META_EXTRA` value a human should see at a glance must also have a matching `SUMMARY_EXTRA` cell/row.)

#### Body sections

Emit numbered sections in this order. Number monotonically (`01`, `02`, …).

**Section 01 — Summary**
2-3 sentences copied from the governing document. Echoes the prompt-box.

**Section 02 — Inputs**
A 2-column table: Document | Path. Links to every document read in Step 2, governing document first.

**Section 03 — Functional goals**
A sec-intro naming the source ("Copied from the structure outline's desired end state.", or the design document's Desired End State / the PRD's Success and Solution Details) then a bulleted list (HTML `<ul>` / MD `- [ ]` checklist).

**Section 04 — Non-goals (What we're NOT doing)**
Always include this section, because it is the scope fence the worker checks against. Bulleted list copied from the design documents' non-goals and Scope sections, plus anything the structure outline explicitly deferred (e.g. to the hardening slice). End with the line: "Anything not listed in the phases below is out of scope — confirm with the user before adding it." If the documents record no non-goals, state that explicitly rather than dropping the section.

**Section 05 — Implementation phases**
One slice-card per phase, per Step 4. This is the centerpiece of the artifact.

**Section 06 — Test strategy**
Prose summarizing tests from each phase. Tests target observable behavior through public entry points, assert specific expected values (not just "does not throw"), and mock only across process boundaries (network, clock, filesystem) — never the type under test.

**Section 07 — Rollback strategy**
A callout (HTML `.callout` / MD `> [!NOTE]`) containing the rollback strategy copied from the structure outline, or drawn from the governing document when there is no outline.

**Section 08 — Open Questions**
Only on an early handoff (Step 3): the governing document's unresolved items, one per entry. Omit the section otherwise.

### Step 6: Executive summary and handoff

Output to the user:

1. The saved spec path, and an offer to open it for review in VS Code, Cursor, or the browser
2. 3-bullet summary: what's being built, how many phases, the first phase's checkpoint
3. The next command with the task directory and flow, for example `/orchestrate .agents/artifacts/feat-ENG-123-csv-export flow: design` — the planner decomposes the spec's phases into a dependency-wired task list that workers pick up one at a time, with a gate at each phase's Manual verification. For a smaller feature the user may instead implement the phases directly in this session, still stopping at each phase's Manual verification.
4. That the command can run here, after compaction, or in a new session — the spec and the task directory carry everything implementation needs

Then wait for the user; this skill does not start implementation itself.

## Rules

- **This is a spot-check review.** The spec should read as a straightforward transcription of the governing document + research, not a creative exercise.
- **No dates or time estimates in the phases.** Use "Phase 1, Phase 2" instead of "Week 1, Week 2." (The frontmatter `crispy:date` is the artifact's creation timestamp, not a schedule.)
- **Cite research findings** with `file:line` references where implementation steps touch existing code.

## When to Abort This Phase

If any of these are true, stop and tell the user to go back:

1. No structure outline, TDD, PRD, or design discussion exists in the task directory → implement from the research with `/orchestrate <task-dir>`, or run a design phase or `/structure-outline` first
2. The governing document has unresolved open questions or is still `draft` → return to the phase that owns it (`/structure-outline`, `/create-tdd`, `/create-prd`, or `/design-discussion`), unless the user explicitly asks to proceed (Step 3 carries the items into Open Questions)
3. The research document doesn't exist or is stale → run `/research-codebase` first
4. The user passed a raw ticket instead of a task directory or a document path inside one

Leave the gaps to the earlier phase rather than filling them here: each phase's document is a separate human review gate, and doing that work here would skip it.
