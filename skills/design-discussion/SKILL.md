---
name: design-discussion
description: Produce a ~200-line 'brain dump' design discussion artifact covering current state, desired end state, and design decisions with contrastive options and rationale. Use this as the FOURTH phase of CRISPY (Questions → Research → DESIGN → Structure → Plan → Implement → Review), the highest-leverage review phase where the human performs 'brain surgery' on the agent's mental model before any code is planned. Trigger after /research-codebase has produced a research document, and when the user says 'let's design this', 'talk me through the approach', 'what are the options here', or asks to weigh architectural trade-offs before planning. Not for producing signatures, types, or vertical slices (use structure-outline), the task-level implementation plan (use create-spec), or investigating the codebase (use research-codebase). Accepts `--format=html|md` to select output format (default `html`).
argument-hint: "<path to research file> [--format=html|md]"
disable-model-invocation: true
---

# Design Discussion (CRISPY D Phase)

Produce a design discussion artifact for the feature described by the research document at: **$ARGUMENTS**

This is the **Design Discussion (D)** phase of CRISPY — the last chance to align on architecture before the plan is written.

## Why This Phase, and Why ~200 Lines

Dex Horthy calls this "the highest-leverage stage": the agent brain-dumps everything it found, everything it wants to do, and everything it does not know, and the human gets to do brain surgery on that mental model before anything downstream is built.

The 200-line target is intentional:
- Small enough that a human will actually read it carefully
- Large enough to surface every meaningful decision
- A 1,000-line plan has "as many surprises as 1,000 lines of code" — persuasive narratives hide wrong technical assumptions
- Reading 200 lines of design decisions is strictly higher leverage than reading 1,000 lines of plan

If the draft exceeds ~300 lines, the plan is being written prematurely. Cut.

The human reading this artifact will:
- Catch wrong pattern choices ("we stopped using that legacy pattern, use this one")
- Correct wrong assumptions about the data model
- Reject bad architectural trade-offs
- Identify missing concerns (security, tenancy, migration)

The artifact must make those corrections **easy to make**. That means:
- Show the reasoning explicitly — do not hide it behind conclusions
- Name the rejected options, not just the chosen one
- Keep it short enough to read in one sitting
- Put the most important decisions at the top

## Workflow

### Step 1: Parse arguments and pick the output format

Extract `--format=html|md` from `$ARGUMENTS`. Default to `html`. The remainder is the path to the research document. This format choice selects which output skill renders the artifact in Step 5:
- `--format=html` → `Skill('output-html')`
- `--format=md` → `Skill('output-markdown')`

Both output skills consume the **same render brief** — the slot vocabulary and the decision-card / slice-card contract are identical across formats, so the format choice never changes what gets written, only how it renders.

### Step 2: Read the Research Document

Read the research document at the path **fully** (no limit/offset). This contains the factual map of the codebase as it exists today.

Also read:
- Any research docs it cites (`research/docs/*.*`)
- The original questions artifact (`research/questions/*.*`) if one exists — it contains the ticket context needed for "Desired End State"
- Relevant specs in `research/specs/` that the research references

Do NOT re-research. Trust the research document. If it's missing something critical, note it in "Open Questions" and flag it to the user rather than fetching it.

### Step 3: Brain Dump (Draft)

Write a first draft that brain-dumps everything learned from research and everything the solution should look like. Don't worry about the line count yet. Cover:

**Current State**
- How does the relevant code work today? (2-5 bullet summary, citing file:line references from research)
- What are the existing conventions, patterns, and constraints?
- What's working well that should NOT change?

**Desired End State**
- What does the feature need to do?
- What does "done" look like from the user's perspective?
- What invariants must hold after the change?

**Design Decisions**

For each significant decision, plan a decision card with contrastive options. The output skill renders each as a decision card. Sketch each one as:

```
Decision: [What is being decided]

- (A) [Option 1] — [pros] — [cons]
- (B) [Option 2] — [pros] — [cons]
- (C) [Option 3] — [pros] — [cons]

Chosen: (B) — [one-line rationale]
Why not (A): [specific reason]
Why not (C): [specific reason]
```

Use a two-sided pros/cons comparison when the choice is what we gain vs what we give up for a single approach, rather than A/B/C.

This contrastive format is critical. Options with concrete tradeoffs force real thinking. Avoid "I chose X because it seems best" — that's not a decision, that's a preference.

**Patterns to Reuse**

List which existing codebase patterns (from research) will be adopted for this feature. Use a table when listing 3+ patterns. Cite `file:line` in inline code. For each pattern, note what file the new code will resemble.

**Open Questions**

Things the agent genuinely does not know and needs the human to decide. Each question uses the same contrastive-clarification shape as a design decision, plus an optional "Recommendation" line (the best guess available):

```
Q1: [Question]

- (A) [Option] — [tradeoff]
- (B) [Option] — [tradeoff]
- (C) [Option] — [tradeoff]

Recommendation: [best guess, if there is one]
```

After the human answers (Step 6), promote the picked option to the chosen state and move the whole card into the Design Decisions section.

**Non-Goals**

Explicit list of things this design does NOT address. Prevents scope creep later. Render as a simple bulleted list.

### Step 4: Cut to ~200 Lines

The draft is probably too long. Cut:
- Redundant explanations ("as mentioned above")
- Implementation code samples and file-by-file change lists (those belong in Structure Outline)
- Speculative future features ("we might also want to...")
- Task breakdowns with dependencies and detailed migration steps (that's Plan)
- Long prose — prefer bullets

Target: 150–250 lines. Hard ceiling: 300 lines. If it doesn't fit, the scope is too large — tell the user to split the feature.

### Step 5: Prepare the Render Brief and Delegate

Hand the structured content to the output skill chosen in Step 1. Do NOT hand-write HTML or Markdown — the output skill owns the template, the component vocabulary, and the slot substitution.

Output path (CRISPY mode):
- Directory: `research/designs/`
- Stem: `YYYY-MM-DD-<topic>` (match the kebab-case topic from the research doc)
- Extension: appended by the output skill (`.html` or `.md`)

#### Slot values

Use these exact slot names — they are the shared CRISPY render-brief vocabulary defined in `skills/output-html/SKILL.md` and `skills/output-markdown/SKILL.md`. Do not invent new slot names.

| Slot | Value |
| --- | --- |
| `PHASE` | `design` |
| `PHASE_LABEL` | `Design Discussion` |
| `STATUS` | `draft` initially; `ready-for-structure` once Step 6 resolves all open questions |
| `STATUS_CLASS` | derived from `STATUS` per the output skill's status table |
| `TOPIC` | kebab-case topic |
| `TITLE` | `Design Discussion: <Topic>` |
| `TICKET` | one-line ticket summary |
| `PROMPT_TEXT` | TL;DR of what's being designed (2-3 sentences) |
| `META_EXTRA` | `crispy:research_doc`, `crispy:questions_doc`, `crispy:author`, `crispy:decisions_resolved` (count) |
| `SUMMARY_EXTRA` | rows for: Research doc (link), Decisions resolved (count, accent), Author |

The `design`-phase metadata fields (`crispy:research_doc`, `crispy:questions_doc`, `crispy:author`, `crispy:decisions_resolved`) are the established schema for this phase in both output skills.

#### Body sections

Emit numbered sections in this order (the output skill numbers them monotonically `01`, `02`, ...):

**Section 01 — Summary**
2-3 sentences: what is being designed and why. This is the TL;DR — already echoed in the header's prompt-box, so keep this short.

**Section 02 — Current state**
A sec-intro ("How the relevant code works today, drawn from research.") then a bulleted list. Each bullet cites a file:line reference. Use a collapsible deep-dive (`<details>`) if the section runs longer than 10 lines.

**Section 03 — Desired end state**
Bulleted list of what the feature needs to do.

**Section 04 — Design decisions**
One decision card per significant decision, in the contrastive format from Step 3.

**Section 05 — Patterns to reuse**
A table with columns: Pattern | Lives in (file:line) | New code mirrors (file).

**Section 06 — Open questions**
One card per open question in the same contrastive shape as design decisions, plus an optional Recommendation line. After Step 6 resolves them, promote each into the Design Decisions section as the chosen option and delete this section.

**Section 07 — Non-goals**
Bulleted list of things this design does NOT address.

### Step 6: Walk the User Through Open Questions

This is the "brain surgery" moment, and it happens by default — no trigger phrase required. For each open question in the document:

1. Read the question and the options aloud to the user
2. Use the `AskUserQuestion` tool to get their answer
3. Have the output skill update the document with the decision, moving the card from "Open Questions" to "Design Decisions" with the chosen option marked
4. Update `crispy:decisions_resolved` AND its matching visible Summary cell so the visible count tracks the resolution progress

Do this for every open question. Do NOT skip any. Do NOT batch them into one giant question. One at a time, with full tradeoff context each time.

### Step 7: Present Final Document

After all questions are resolved:

1. Set the `STATUS` slot to `ready-for-structure` and re-render the Status cell with the matching badge / emoji
2. Show the user a 3-sentence summary of the design
3. Show the file path
4. Offer to commit the artifact via `Skill('gh-commit')` — committed CRISPY artifacts survive worktree teardown and are reviewable in PRs
5. Suggest the next command: `/structure-outline research/designs/YYYY-MM-DD-topic.<ext>`, which feeds `/create-spec` and then `/implement`

## Forking to Explore Competing Designs

This phase sits at the ideal forking checkpoint: all the high-quality research context is loaded, but nothing downstream is committed yet. When two design directions are both genuinely viable and the tradeoff cards can't settle it, suggest the user fork instead of forcing a pick:

- Fork the conversation at this point (`/rewind`, a duplicated session, or a second worktree) and draft the Design Decisions section once per direction
- Compare the resulting design artifacts side by side, keep the winner, and continue the pipeline from that fork
- Catching the wrong architecture here costs one re-rendered design doc; catching it mid-implementation costs the whole downstream chain

Do NOT suggest forking for decisions a tradeoffs table can resolve — forking is for genuinely divergent architectures, not preferences.

## Abort Conditions

Stop and surface to the user rather than proceeding when:
- The research document at `$ARGUMENTS` does not exist or is empty — there is nothing to design against.
- The research document is too thin to ground a design (no file:line references, no current-state map) — ask the user to run `/research-codebase` first.
- The scope is too large to fit in ~300 lines even after cutting — tell the user to split the feature into smaller pieces.
- A required render-brief slot cannot be filled (e.g., no topic derivable) — ask the user rather than emitting a placeholder.
