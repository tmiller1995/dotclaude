---
name: ask-questions
description: Generate targeted research questions from a feature ticket, user story, or feature request, so the research phase is forced to touch every relevant region of the codebase. The Questions phase of the CRISPY workflow (Questions → Research → Design → Structure → Plan → Implement → Review); its output feeds /research-codebase. Does not answer the questions or open codebase files — that is research-codebase. Accepts `--format=html|md` to select output format (default `html`).
argument-hint: "<ticket text or file path> [--format=html|md]"
disable-model-invocation: true
---

# Ask Questions (CRISPY Q Phase)

Generate a focused list of research questions from the feature ticket, user story, or implementation request in **$ARGUMENTS**.

This is the **Questions (q)** phase of the CRISPY workflow. The output of this phase directly drives the Research phase. Good questions produce good research; vague questions produce vague research.

## The Core Principle

This phase produces **targeted questions** only — not an implementation plan, and not research findings. The questions become the input to `/research-codebase`.

## Why This Phase Exists

An agent handed the whole ticket forms opinions about the solution before it understands the code. Extracting **just the questions** into their own artifact does four things:

1. Keep the research phase focused on facts, not opinions
2. Prevent the feature ticket from contaminating the research context (the ticket stays hidden from sub-agents during Research)
3. Force the human to think about what the agent needs to know before it starts looking
4. Create a durable artifact that can be reviewed and refined

## What Good Questions Look Like

**Good questions are specific and trace-oriented.** They force the research phase to open specific files and follow specific call chains.

Example — Ticket: "Add a new endpoint to reticulate splines across tenants"

Good questions:
- How do existing endpoints get registered and routed in this codebase?
- Where is the spline data model defined and how is it persisted?
- What existing code paths touch spline reticulation (trace all call sites)?
- How does the current tenant isolation pattern work — middleware, query filters, or something else?
- Are there existing background workers or queue handlers that process splines?
- What validation patterns are used for endpoint inputs (Zod, FluentValidation, manual)?
- How are cross-tenant operations currently authorized (if at all)?
- What test patterns exist for endpoints that touch tenant-scoped data?

**Bad questions** are vague or premature:
- "What's the best way to add this endpoint?" (asks for opinion, not facts)
- "How should tenant isolation work?" (asks for design, not current state)
- "What files need to change?" (that's the Plan phase, not Research)
- "Is there a library for spline math?" (too narrow, doesn't explore the codebase)

## Workflow

### Step 1: Parse arguments and pick the output format

Extract `--format=html|md` from `$ARGUMENTS`. Default to `html` if not specified. The rest of `$ARGUMENTS` is the ticket input (inline text or a file path). Remember the chosen format — Step 6 hands off to the matching output skill.

### Step 2: Read the Ticket Carefully

If the user provided a ticket file path, read it fully. If they provided inline text, parse it for:
- The **feature/change** being requested
- Any **constraints or non-goals** mentioned
- Any **acceptance criteria**
- Any **linked documents, tickets, or prior discussions**

Stop at the ticket — no file reads beyond it, no grep, no glob. Opening codebase files or forming an implementation opinion at this point is the contamination this phase exists to prevent.

### Step 3: Identify the Unknowns

Think deeply about what you would need to know to implement this feature correctly. Break it down into categories:

1. **Existing patterns** — What does the codebase already do in this area? What conventions exist?
2. **Data model** — What data structures, schemas, or entities are involved?
3. **Entry points** — How does the relevant code get invoked (routes, events, CLI, etc.)?
4. **Call graph** — What other code paths will be touched or affected?
5. **Cross-cutting concerns** — Auth, validation, logging, error handling, telemetry
6. **Test patterns** — How are similar things tested?
7. **External dependencies** — What libraries, services, or APIs are involved?
8. **Historical context** — Any prior research docs, specs, or tickets on this topic?

For each category, write 1-3 questions that would force the research phase to explore it.

### Step 4: Prune Ruthlessly

**Aim for 5-10 questions total, not 20+.** Too many questions blow the instruction budget in the research phase. Check each question against four tests:

- Is this question about **the codebase as it exists today**, not about how to build the feature?
- Will answering it produce **facts** (file paths, function signatures, data flows), not **opinions**?
- Is it **specific enough** that a research agent can open files and find the answer?
- Does it **force exploration** of a region that's likely to be relevant?

If a question doesn't pass all four checks, cut it or rewrite it.

### Step 5: Determine the Compatibility Posture

Research and every downstream phase need to know whether this work may break existing behavior.

- Infer from the ticket: explicit permission for breaking changes, cleanup, or "no real users yet" → `breaking_changes_allowed: true`. Mentions of production users, published APIs, downstream consumers, or migration safety → `false`.
- If the ticket doesn't settle it, ask the user exactly one question via `AskUserQuestion` — this is the sole exception to not interrogating the user, because the posture changes how research documents everything it finds.
- Record the result in the render brief as `crispy:breaking_changes_allowed` and `crispy:compatibility_context` (Step 6). `/research-codebase` inherits the posture from these fields instead of re-asking.

### Step 6: Prepare the Render Brief and Delegate

Assemble a **render brief** with the values and section content listed below, then invoke the matching output skill via the Skill tool:

- `--format=html` → `Skill('output-html')`
- `--format=md` → `Skill('output-markdown')`

Both output skills share one slot schema and component vocabulary, so this brief renders unchanged in either format. The output skill reads its template + `components.md` and produces the file. This skill stays in the conversation as the upstream caller — answer any clarification the output skill asks for, and otherwise let it write the file.

#### Output path

- Directory: `research/questions/`
- Stem: `YYYY-MM-DD-<topic>` (topic in kebab-case)
- Extension: chosen by the output skill (`.html` or `.md`)

#### Slot values

These slot names match the output skills' slot schema exactly — do not invent new ones.

| Slot | Value |
| --- | --- |
| `PHASE` | `questions` |
| `PHASE_LABEL` | `Questions` |
| `STATUS` | `ready-for-research` |
| `STATUS_CLASS` | `ready` |
| `TOPIC` | kebab-case topic |
| `TITLE` | `Research Questions: <Topic>` |
| `TICKET` | one-line ticket summary |
| `PROMPT_TEXT` | the originating ticket body, in prose (1-2 sentences) |
| `META_EXTRA` | `crispy:ticket_source` (the file path the ticket came from, or `inline`), `crispy:breaking_changes_allowed` (`true`/`false` from Step 5), `crispy:compatibility_context` (one-line posture explanation) |
| `SUMMARY_EXTRA` | three rows: **Source** = `<path or 'inline'>`, **Questions** = `<count>` (accent the count), **Breaking changes** = `allowed` / `not allowed` |

`crispy:ticket_source` is the questions-phase metadata field owned by this phase in the output skills' schema — keep that exact key. The two compatibility fields are read by `/research-codebase`, which inherits the posture rather than re-asking.

#### Body sections

Emit three numbered sections in this order. Number them monotonically (`01`, `02`, `03`).

**Section 01 — Context** *(human-only, stripped when this artifact is passed to `/research-codebase`)*
- A neutral `.callout` (HTML) or `> [!NOTE]` (MD) containing exactly: "**For the human, not sub-agents.** When these questions are passed to `/research-codebase`, this section is STRIPPED. It exists only for the human reviewing this document."
- A 2-3 sentence prose description of what the feature request is.

**Section 02 — Questions**
- A sec-intro line: "5-10 targeted questions that force the research phase to touch the relevant parts of the codebase. Each question is about *current state*, answerable with file:line references."
- An ordered list of 5-10 questions. Each item begins with a **plain category tag** such as `data-model`, `call-graph`, or `validation`. These are non-modifying category labels, so the output skill's default muted tag applies rather than the change tags; `components.md` in the chosen output skill owns the exact markup for both formats, including inline file paths and identifiers.

**Section 03 — Notes** *(optional — omit entirely if there are no notes)*
- Free prose for known-unknowns, gotchas the human spotted, or areas the user explicitly flagged for investigation.

### Step 7: Present to the User

After the output skill writes the file:

1. Show the user the list of questions
2. Ask if any are missing, wrong, or should be refined
3. Do NOT proceed to research automatically — wait for the user to explicitly start the next phase
4. Offer to commit the new artifact via `Skill('gh-commit')` — committed CRISPY artifacts survive worktree teardown and are reviewable in PRs (the `thoughts sync` equivalent)
5. Suggest the next command: `/research-codebase research/questions/YYYY-MM-DD-topic.<ext>`

## Important Rules

- **Do not interrogate the user.** Turning the ticket into questions is the job; ask for more feature context only when the ticket is genuinely ambiguous about what is being requested. (Step 5's compatibility question is the one standing exception.)

The questions are the leverage point — `/research-codebase` answers them, and must never see the ticket.
