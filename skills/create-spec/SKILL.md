---
name: create-spec
description: Create a tactical implementation plan (spec) from a completed structure outline. Use this as the SIXTH phase of CRISPY (Questions → Research → Design → Structure → PLAN → Implement → Review). This phase is a SPOT-CHECK, not a deep review — alignment happened in design-discussion and structure-outline. Trigger after /structure-outline has produced a structure document. Accepts `--format=html|md` to select output format (default `html`).
argument-hint: "<path to structure file> [--format=html|md]"
---

# Create Spec (CRISPY P Phase)

You are tasked with creating a tactical implementation plan from the structure outline at: **$ARGUMENTS**

This is the **Plan (P)** phase of CRISPY. By the time you're here, alignment already happened:

- Questions phase identified unknowns
- Research phase documented the codebase as-is
- Design Discussion phase locked in architectural decisions
- Structure Outline phase carved the feature into vertical slices with signatures

Your job is to turn the structure outline into a **tactical spec with phased implementation steps** — not to revisit any of the earlier decisions.

## The Core Principle

> "Because alignment was achieved during Design and Structure, the engineer only needs to spot-check this rather than performing a deep line-by-line review. By the time you reach this stage, the plan is constrained by design decisions and structure that were already validated." — Alex Lavaee

A spec that requires deep review is a sign that Design or Structure was skipped. If you find yourself needing to make architectural decisions here, **STOP and tell the user to go back**.

## What This Phase Does

1. Reads the structure outline (and optionally, the design + research docs for citation)
2. Converts the vertical slices into a phased spec with concrete implementation steps
3. Hands a structured render brief to the matching output skill, which writes the spec to `research/specs/YYYY-MM-DD-topic.<ext>`
4. Provides an executive summary for quick spot-check

## What This Phase Does NOT Do

- Re-open design decisions (they were frozen in design-discussion)
- Change the slice boundaries (they were frozen in structure-outline)
- Re-research the codebase (research phase is complete)
- Walk the user through open questions with AskUserQuestion (that's design-discussion's job)
- Write implementation code (that's the worker agent's job)
- Create task entries (that's the planner agent's job)

## Workflow

### Step 1: Parse arguments and pick the output format

Extract `--format=html|md` from `$ARGUMENTS`. Default to `html` when the flag is absent. The remainder of `$ARGUMENTS` (with the flag stripped) is the path to the structure outline.

- `--format=html` → render via `Skill('output-html')`
- `--format=md` → render via `Skill('output-markdown')`

### Step 2: Read the Inputs

Read these files fully (no limit/offset):
- The structure outline at the given path (primary input — drives everything)
- The design document it references (for decision rationale to cite)
- The research document(s) the design references (for file:line citations)

If the structure outline does not exist or the user passed you a research doc instead, STOP and tell them to run `/design-discussion` and `/structure-outline` first.

### Step 3: Verify Frozen Decisions

Quickly scan the design document. Are all open questions resolved? If the design doc still has unresolved `## Open Questions`, STOP and tell the user to return to `/design-discussion`.

### Step 4: Convert Slices to Phases

For each vertical slice in the structure outline, plan a numbered phase. Each phase becomes a **slice-card** (same component as Structure Outline's slices, with two extra sub-blocks) containing:

- A `### Phase N — Name` heading (mirrors structure-outline's `### Slice N — Name`)
- A **goal** line copied from the slice's goal — renders as `.goal` in HTML / `**Goal:**` in MD
- A **files touched** bulleted list, same as the structure outline's file list, each item tagged `NEW` / `MODIFY` / `DELETE` (HTML: `<span class="tag new|mod|del">`; MD: `**NEW** / **MODIFY** / **DELETE**`)
- A **checkpoint** line copied from the slice's checkpoint — this is the acceptance criterion. Renders as `.checkpoint` with a leading `✓` in HTML / `**Checkpoint:** ✓ …` in MD
- **Implementation steps** — a numbered list of concrete steps. Reference research `file:line` where new code touches existing code. Keep concrete but NOT verbose — the worker agent has the structure outline and research doc as context.
- **Tests** — a bulleted list (HTML `<ul>` / MD `- [ ]` checklist) of test types, e.g. "**Unit:** `ReticulateButton` renders with loading state on click", "**Integration:** clicking button in dev → toast shows → no console errors"
- **Automated verification** — a checklist of literal commands that can be run unattended to prove the phase works: build, test suite, typecheck, lint (e.g. `dotnet test`, `npm run typecheck`). The worker runs these before marking a task complete.
- **Manual verification** — a checklist of steps only a human can confirm: UI behavior, visual checks, end-to-end flows in a real environment. Write each as an instruction to the human. The orchestrator surfaces these at the phase gate; the implementing agent NEVER checks them off itself. Every phase needs at least one entry in each verification list — write "None — fully covered by automated checks" only when that is literally true, never as a shortcut.
- Optional `.chips` for metrics (HTML) / space-separated backticked `Label: Value` pairs with `·` (MD), e.g. size and surfaces, carried from the slice

The output skill renders these via the **slice-card component** — see its `components.md` for the HTML and MD variants. The required children are the heading, the goal, the files-touched list, and the checkpoint; Implementation steps, Tests, Automated verification, and Manual verification are the create-spec-specific additions. Do NOT invent new component classes — use the slice-card contract exactly as the output skills define it.

### Step 5: Prepare the Render Brief and Delegate

Output path (the standard CRISPY convention — ALL workflow artifacts live under `research/`):
- Stem: `research/specs/YYYY-MM-DD-<topic>` where `<topic>` is the kebab-case topic copied from the structure doc
- Extension: appended by the output skill (`.html` or `.md`)

This is the output skill's default CRISPY directory for the spec phase — pass the stem through unchanged, no path override needed.

Invoke the matching output skill chosen in Step 1 with the brief below. The slot vocabulary is shared verbatim between `output-html` and `output-markdown` — the same brief renders either format unchanged.

#### Slot values

These slot names match the output skills' schema exactly. `REPO`, `BRANCH`, and `DATE` are derived by the output skill from the shell; do not hand-fill them.

| Slot | Value |
| --- | --- |
| `PHASE` | `spec` |
| `PHASE_LABEL` | `Implementation Spec` |
| `STATUS` | `ready-for-implementation` |
| `STATUS_CLASS` | `ready` (HTML) — the MD skill derives the ✅ emoji from this) |
| `TOPIC` | kebab-case topic — match the structure doc |
| `TITLE` | `<Topic> Implementation Spec` |
| `TICKET` | one-line ticket summary copied from the structure/design doc |
| `PROMPT_TEXT` | 2-3 sentences copied from the structure outline summary — do NOT reinvent |
| `META_EXTRA` | `crispy:structure_doc`, `crispy:design_doc`, `crispy:research_doc`, `crispy:author`, `crispy:date`, `crispy:phase_count` |
| `SUMMARY_EXTRA` | rows for: Phases (accent), Structure doc (link), Design doc (link), Author, Date |

**Personal date/author metadata.** The output skill derives `DATE` from `date '+%Y-%m-%d %H:%M:%S %Z'` and stamps it in the base header. Additionally carry the author into the brief so it survives in both head metadata and the human-visible summary:

- Run `git config user.name` (Bash) to resolve the author. Put it in `META_EXTRA` as `crispy:author` and add a matching `Author` row to `SUMMARY_EXTRA`.
- Echo the rendered `DATE` value into `META_EXTRA` as `crispy:date` and a `Date` row in `SUMMARY_EXTRA` so the spec retains the shell-substituted date and git author exactly as the prior plain-Markdown frontmatter did (`date: !\`date ...\``, `author: !\`git config user.name\``).

(Consistency rule from the output skills: every `META_EXTRA` value a human should see at a glance must also have a matching `SUMMARY_EXTRA` cell/row.)

#### Body sections

Emit numbered sections in this order. Number monotonically (`01`, `02`, …).

**Section 01 — Summary**
2-3 sentences copied from the structure outline. Echoes the prompt-box.

**Section 02 — Inputs**
A 2-column table: Document | Path. Links to the structure outline, design discussion, and research doc.

**Section 03 — Functional goals**
A sec-intro ("Copied from the design doc's Desired End State.") then a bulleted list (HTML `<ul>` / MD `- [ ]` checklist).

**Section 04 — Non-goals (What we're NOT doing)**
REQUIRED — never omit this section. Bulleted list copied from the design doc's non-goals, plus anything the structure outline explicitly deferred (e.g. to the hardening slice). End with the line: "Anything not listed in the phases below is out of scope — confirm with the user before adding it." If the design doc records no non-goals, state that explicitly rather than dropping the section.

**Section 05 — Implementation phases**
One slice-card per phase, per Step 4. This is the centerpiece of the artifact.

**Section 06 — Test strategy**
Prose summarizing tests from each phase. Reference the `testing-anti-patterns` skill to avoid common mistakes.

**Section 07 — Rollback strategy**
A callout (HTML `.callout` / MD `> [!NOTE]`) containing the rollback strategy copied from the structure outline.

### Step 6: Executive Summary to User

Output to the user:

1. Path to the spec file (under `research/specs/`)
2. 3-bullet summary: what's being built, how many phases, the first phase's checkpoint
3. Offer to commit the artifact via `Skill('gh-commit')` — committed CRISPY artifacts survive worktree teardown and are reviewable in PRs
4. Suggest next command: `Use the planner agent to decompose research/specs/YYYY-MM-DD-topic.<ext> into tasks` (or `/implement` to skip the planner)

## Critical Rules

- **DO NOT re-design.** The design is frozen. If you find yourself making architectural decisions, STOP.
- **DO NOT re-research.** Trust the research document. Cite its `file:line` references for context, don't re-verify them.
- **DO NOT change slice boundaries.** Copy them from the structure outline.
- **DO NOT ask the user questions** — open questions were handled in design-discussion.
- **DO NOT invent render slots or component classes.** Use the slot vocabulary and slice-card contract exactly as `output-html` / `output-markdown` define them.
- **This is a spot-check review.** The spec should feel like a straightforward transcription of structure + research, not a creative exercise.
- **No dates or time estimates in the phases.** Use "Phase 1, Phase 2" instead of "Week 1, Week 2." (The frontmatter `crispy:date` is the artifact's creation timestamp, not a schedule.)
- **Cite research findings** with `file:line` references where implementation steps touch existing code.

## When to Abort This Phase

If ANY of these are true, STOP and tell the user to go back:

1. Structure outline doesn't exist → run `/structure-outline` first
2. Design doc has unresolved open questions → run `/design-discussion` first
3. Research doc doesn't exist or is stale → run `/research-codebase` first
4. User passed you a raw ticket or research doc instead of a structure outline

Do NOT try to fill in gaps by doing the earlier phases yourself. Each phase runs in its own context for a reason.

## What Happens Next

The spec you produce is consumed by one of two things:

1. **The planner agent** — decomposes the spec into tasks with dependencies via `TaskCreate`. Use this when you want the worker agent to pick up tasks one at a time in a loop.
2. **`/implement`** (the worker agent directly) — executes the phases one at a time without a task list. Use this for smaller features.

Either way, the spec is the handoff point from **alignment work** (Questions → Design → Structure → Plan) to **execution work** (Implement → Review).
