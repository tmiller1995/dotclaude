---
name: ask-questions
description: Turn a feature ticket, user story, or change request into the first two CRISPY documents in the task directory under `.agents/artifacts/` — a request document (desired result, constraints, source pointers, chosen flow, compatibility posture) and a research-questions document of 2–7 current-state questions with starting pointers. The Questions phase of CRISPY; asks which flow follows research (design discussion, PRD then TDD, TDD, or research only) and hands off to /research-codebase. Invoked manually. Does not answer the questions or read source code (use /research-codebase). Accepts `--format=html|md` (default `html`).
argument-hint: "<ticket text or file path> [--format=html|md] [flow: <flow>]"
disable-model-invocation: true
---

# Ask Questions (CRISPY Q Phase)

Turn the feature ticket, user story, or implementation request in **$ARGUMENTS** into two documents: a **request** document that records what the user wants, and a **research-questions** document that tells the research phase what to look at. This phase produces those two documents only — not research findings and not an implementation plan.

## Why this phase splits the request from the questions

An agent handed the whole ticket forms opinions about the solution before it understands the code. So the desired change lives in the request document, which later design and implementation sessions read, and the questions document describes only the current system. `/research-codebase` reads the questions document alone, so research stays a neutral map of what exists. Good questions produce good research; vague questions produce vague research.

## What good questions look like

Good questions are specific, describe the current state, and point at where to start: they make the research phase open specific files and follow specific call chains. Attach a starting pointer to each question — a path, package, or component named in the ticket, or found by the locator pass in Step 4.

<example>
Illustrative only. Ticket: "Add a new endpoint to reticulate splines across tenants"

Good questions:
- How do existing endpoints get registered and routed? (start: `src/Api/Endpoints/`)
- Where is the spline data model defined and how is it persisted? (start: `src/Domain/Splines/`)
- How does the current tenant isolation pattern work — middleware, query filters, or something else? (start: `src/Api/Middleware/TenantResolver.cs`)
- How are cross-tenant operations currently authorized, if at all?
- What test patterns exist for endpoints that touch tenant-scoped data? (start: `tests/Api.Tests/`)

Bad questions:
- "What's the best way to add this endpoint?" (asks for opinion, not facts)
- "How should tenant isolation work?" (asks for design, not current state)
- "What files need to change?" (that's planning, not research)
- "How does the endpoint for reticulating splines across tenants handle auth?" (smuggles the desired change into the question)
</example>

## Workflow

### Step 1: Parse arguments

Extract `--format=html|md` (default `html`) and an optional `flow: <flow>` (`design`, `prd-tdd`, `tdd`, or `research-only`) from `$ARGUMENTS`. The rest is the ticket input — inline text or a file path. A task directory or artifact path in the input means the user is iterating on existing documents (see Step 2).

### Step 2: Resolve the task directory

All documents for one task live in `.agents/artifacts/<task>/` at the repo root.

- An explicit task directory or artifact path in the arguments wins.
- Otherwise, reuse an existing directory under `.agents/artifacts/` whose name or filenames obviously match the request or the current branch, without asking. If one looks close but could belong to another task, or several are plausible, ask which to use before writing.
- Otherwise create one: `<task>` is the current branch name with `/` replaced by `-` when the branch identifies the task (`feat/ENG-123-csv-export` → `feat-ENG-123-csv-export`); on `main`/`master`, or when the branch doesn't identify the task, use a short kebab-case slug from the request.

State the chosen path. Remember whether the directory is new — Step 6 needs it.

**Create vs update.** If the directory already holds a `request` or `research-questions` document and the user is iterating or resuming, update that document in place, keeping its path and number; when several of a type match, use the highest-numbered and name it. Create new documents only when none exists or the user asks for new ones.

### Step 3: Read the ticket

Read the ticket file and any files it names in full; for inline text, parse it directly. Pull out:
- The feature or change being requested and the desired result
- Constraints, non-goals, and acceptance criteria
- Exact paths, package names, repository names, URLs, and linked tickets or docs — preserve these verbatim as source pointers

### Step 4: Find starting pointers (optional, one small pass)

When the ticket doesn't name enough concrete places to start, dispatch **one** `codebase-locator` sub-agent with the topic area only — for example "order export and download code; column visibility settings" — not the desired change, and use the paths it returns as pointers. Keep it to that single pass and don't open source files yourself: this phase scopes the research, and code read here pulls implementation opinions into the questions. A pointer says where to start looking, never which files to change.

### Step 5: Draft and prune the questions

Work out what you would need to know about the current system to implement this correctly, across these categories:

1. **Existing patterns** — what the codebase already does in this area and its conventions
2. **Data model** — structures, schemas, or entities involved
3. **Entry points** — how the relevant code is invoked (routes, events, CLI, jobs)
4. **Call graph** — other code paths that touch this area
5. **Cross-cutting concerns** — auth, validation, logging, error handling, telemetry
6. **Test patterns** — how similar things are tested
7. **External dependencies** — libraries, services, or APIs involved
8. **Historical context** — prior task directories or research docs on this topic
9. **Design system** *(frontend work)* — existing components, colors and hex codes, typography, spacing, borders, shadows, theming; include one question on this for any frontend task so later mockups match the project

Keep 2–7 questions; go beyond 7 only when the task genuinely spans more areas, because each extra question dilutes the research phase's attention. Rewrite or cut any question that fails these checks:

- It asks about the codebase as it exists today, not how to build the feature.
- Answering it produces facts (paths, signatures, data flows), not opinions.
- It is specific enough that a research agent knows where to open files.
- It contains nothing that reveals the desired change — that content belongs in the request document.

### Step 6: Choose the flow and compatibility posture

Both answers shape every downstream phase, so settle them here, in one `AskUserQuestion` call where possible. When updating existing documents, keep the flow and posture they already record unless the user changes them.

**Flow.** Skip this if `flow:` was given on the command line. Otherwise show this chart in your message, recommend one flow in a sentence or two based on the request, and include the note below:

```text
┌────────────────────┐      ┌──────────┐
│ Research questions │─────▶│ Research │
└────────────────────┘      └────┬─────┘
       ┌─────────────────────────┘
       │    ┌──────────────────────┐
       ├───▶│ 1. Design discussion │───┐
       │    └──────────────────────┘   │
       │    ┌────────┐    ┌─────┐      │
       ├───▶│ 2. PRD │───▶│ TDD │──────┤
       │    └────┬───┘    └─────┘      │
       │         └─────────────────────┤
       │    ┌────────┐                 │
       ├───▶│ 3. TDD │─────────────────┤
       │    └────────┘                 │    ┌────────────┐
       │                               ├───▶│  Outline   │
       │                               │    │ (optional) │
       │                               │    └─────┬──────┘
       │                               └──────────┤
       │      4. Research only                    ▼
       └─────────────────────────────────▶ Spec (optional) → Implement
```

> Implementation can start from any step — if a phase's document specifies the task well enough, say so and we'll skip the rest.

| Option | `crispy:flow` | Fits |
| --- | --- | --- |
| Design discussion | `design` | a change with a few clear options; product and technical choices together |
| PRD then TDD | `prd-tdd` | a larger feature with open product questions |
| TDD | `tdd` | fixes, cleanup, refactors where the desired behavior is clear |
| Research only | `research-only` | answer questions about the current system, then implement |

Put the recommended option first, labeled "(Recommended)".

**Compatibility posture.** Infer it from the ticket when you can: explicit permission for breaking changes, cleanup, or "no real users yet" → `breaking_changes_allowed: true`; production users, published APIs, downstream consumers, or migration safety → `false`. Ask only when the ticket doesn't settle it. `/research-codebase` and later phases inherit this posture instead of re-asking.

**Local exclude.** If the task directory is new and `git check-ignore -q .agents/artifacts` fails, mention once that these documents are working files that aren't committed, and offer to add `.agents/` to `.git/info/exclude` (local-only, not committed). Include this as a question in the same `AskUserQuestion` call when you are asking anything else; otherwise offer it in the handoff. Act only if the user agrees:

```bash
echo ".agents/" >> "$(git rev-parse --git-path info/exclude)"
```

### Step 7: Gather metadata and render both documents

Gather `crispy:repos`: one `<identifier>@<sha>` entry per repository the task covers (usually just the current one), comma-separated — identifier from `gh repo view --json nameWithOwner -q .nameWithOwner`, else the repo directory name; sha from `git rev-parse HEAD`; `none` when no repository applies.

Pick numbers: `NN` is the next available two-digit prefix in the task directory, counting every existing `NN-` file of any type (first file is `01`). New documents get the request first, then the questions (e.g. `01-request-csv-export`, `02-research-questions-export-downloads`). The request's `<desc>` names the feature; the questions document's `<desc>` names the area under study, for the same reason as its slots below. Documents being updated keep their paths.

Render each document by invoking the matching output skill once per document — `Skill('output-html')` for `html`, `Skill('output-markdown')` for `md` — passing the full stem without extension; the output skill appends the extension and creates the directory. Both output skills share one slot schema, so the brief renders unchanged in either format. Stay in the conversation as the caller: answer any clarification the output skill asks for, then let it write.

These slot and `crispy:*` names are the output skills' schema; use only these.

#### Request document — `.agents/artifacts/<task>/NN-request-<desc>`

| Slot | Value |
| --- | --- |
| `PHASE` | `request` |
| `PHASE_LABEL` | `Request` |
| `STATUS` | `complete` |
| `STATUS_CLASS` | `complete` |
| `TOPIC` | kebab-case topic |
| `TITLE` | `Request: <Topic>` |
| `TICKET` | one-line ticket summary (with its identifier, if any) |
| `PROMPT_TEXT` | the originating ticket body, in prose (1–2 sentences) |
| `META_EXTRA` | `crispy:ticket_source` (file path the ticket came from, or `inline`), `crispy:breaking_changes_allowed` (`true`/`false`), `crispy:compatibility_context` (one-line posture explanation), `crispy:task_dir`, `crispy:flow`, `crispy:repos`, `crispy:questions_doc` (path of the questions document) |
| `SUMMARY_EXTRA` | rows: **Source** = path or `inline`, **Flow** = chosen flow, **Breaking changes** = `allowed` / `not allowed` |

Body sections, numbered monotonically:

1. **Original request** — the ticket or request as given, verbatim apart from light cleanup.
2. **Desired result** — what should be true when the work is done, in a short paragraph.
3. **Constraints and acceptance criteria** — constraints, non-goals, and acceptance criteria from the ticket. Omit if there are none.
4. **Source pointers** — exact paths, package names, repository names, URLs, and linked tickets or docs from the request and the locator pass.
5. **Flow and compatibility** — the chosen flow with a one-line reason, and the compatibility posture with its reason.

#### Research-questions document — `.agents/artifacts/<task>/NN-research-questions-<desc>`

This is everything `/research-codebase` reads, so keep the desired change out of every slot and section — including `TICKET` and `PROMPT_TEXT`. `TOPIC`, `TITLE`, and the filename `<desc>` name the area under study, like `PROMPT_TEXT`, not the feature being built; the request document keeps the feature name.

| Slot | Value |
| --- | --- |
| `PHASE` | `questions` |
| `PHASE_LABEL` | `Questions` |
| `STATUS` | `ready-for-research` |
| `STATUS_CLASS` | `ready` |
| `TOPIC` | kebab-case area under study (e.g. `order-export-downloads`) |
| `TITLE` | `Research Questions: <Area>` (e.g. "Research Questions: Order Export and Downloads") |
| `TICKET` | the ticket identifier only (e.g. `ENG-412`), or `N/A` |
| `PROMPT_TEXT` | one neutral sentence naming the area under study, e.g. "Current-state questions about order export, downloads, and column visibility settings." |
| `META_EXTRA` | `crispy:breaking_changes_allowed`, `crispy:compatibility_context`, `crispy:task_dir`, `crispy:flow`, `crispy:repos` |
| `SUMMARY_EXTRA` | rows: **Questions** = count (accent the count), **Flow** = chosen flow, **Breaking changes** = `allowed` / `not allowed` |

Body sections, numbered monotonically:

1. **Context pointers** — the exact paths, package names, repository names, and URLs research should start from, each with a few neutral words on what lives there. Omit if there are none.
2. **Questions** — a sec-intro line ("Current-state questions for the research phase, each answerable with file:line references.") and an ordered list of the 2–7 questions. Each item starts with a plain category tag such as `data-model`, `call-graph`, or `validation`, then the question, then its starting pointer as inline code. The tags are non-modifying labels, so the output skill's default muted tag applies; its `components.md` owns the markup.
3. **Notes** *(optional — omit if empty)* — known-unknowns or areas the user flagged, phrased as facts to check about the current system.

### Step 8: Hand off

After both documents are written:

1. Show the saved paths and the list of questions.
2. Ask whether any question is missing, wrong, or could use a better starting pointer. Apply revisions to the questions document in place.
3. Offer to open the documents for review in VS Code, Cursor, or the browser.
4. Make the local-exclude offer from Step 6 if it hasn't been made.
5. Name the next command and say it can run here, after compaction, or in a new session — the questions document carries everything research needs:

   ```text
   /research-codebase .agents/artifacts/<task> flow: <flow>
   ```

Then wait. Research starts only when the user runs it.

## Scope of user questions

Turning the ticket into questions is the job, so don't interrogate the user. The Step 6 call (flow, compatibility posture, local exclude) is the standing exception; ask for more feature context only when the ticket is genuinely ambiguous about what is being requested.
