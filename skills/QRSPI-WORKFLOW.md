# QRSPI Workflow (CRISPY)

A structured, alignment-first workflow for building features with AI coding agents. It is based on Dex Horthy's (HumanLayer) methodology — front-load alignment before any code is written — and follows HumanLayer's `rpi` skill guidance (`humanlayer/skills`, `plugins/rpi`, 2026-10): a choice of flows after research, a per-task artifact directory, and artifacts that stay out of commits. HumanLayer brands the flow **QRSPI**; these skills are the Claude Code equivalent, named CRISPY. Optionally start with `/create-worktree <issue>` to run the whole flow in an isolated checkout.

## The Flows

Every task starts with questions and research. The flow decides what comes after research. `/ask-questions` asks for it once (unless it is given on the command line), and every handoff command and document carries it as `crispy:flow`:

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

| `crispy:flow` | After research | Then |
| --- | --- | --- |
| `design` | `/design-discussion` | optional `/structure-outline`, then implement |
| `prd-tdd` | `/create-prd` | `/create-tdd` (a settled PRD may skip to outline or implement), optional `/structure-outline`, implement |
| `tdd` | `/create-tdd` | optional `/structure-outline`, implement |
| `research-only` | — | implement from the research (add a design step or outline if useful) |

- **Design discussion** settles product and technical choices together. It fits a change with a few clear options.
- **PRD then TDD** separates the user-facing result from the technical approach. It fits a larger feature with open product questions.
- **TDD** goes straight to technical choices. It fits fixes, cleanup, and refactors where the desired behavior is already clear.
- **Research only** answers questions about the current system, then moves to implementation.

`/create-spec` is optional wherever there is an outline or a design document to build it from: use it when you want a task-ready plan with implementation steps per phase; otherwise the planner decomposes the outline or design document directly. In the `research-only` flow without an outline there is nothing for a spec to transcribe, so implement from the research or add `/structure-outline` first.

**Early handoff.** Implementation can start from any step. If a phase's document specifies the task well enough, say so and skip the rest of the flow. When you explicitly ask to move on while the governing document still has open questions, the next phase proceeds and carries those items into its own Open Questions instead of stopping.

## Manual-Only Phases

The document phase skills — `/ask-questions`, `/research-codebase`, `/design-discussion`, `/create-prd`, `/create-tdd`, `/structure-outline`, `/create-spec` — are **manual-only** (`disable-model-invocation: true`). Claude never starts a phase on its own: each `/command` is a deliberate human gate, matching the document reviews the flow is built around. Each phase ends with a handoff that names the saved document, offers to open it for review, and gives the next command with the task directory and flow, for example:

```text
/research-codebase .agents/artifacts/feat-ENG-123-csv-export flow: prd-tdd
```

Because each phase reads only the documents in the task directory, the next command can run here, after compaction, or in a new session.

## Task Directory and File Naming

All workflow documents for one task live in **`.agents/artifacts/<task>/`** at the repository root.

- `<task>` is the current branch name with `/` replaced by `-` when the branch identifies the task (`feat/ENG-123-csv-export` → `feat-ENG-123-csv-export`). On `main`/`master`, or when the branch doesn't identify the task, it is a short kebab-case slug from the request.
- A phase reuses an existing task directory that obviously matches the request or branch, and asks when one looks close but could belong to another task or several are plausible. A phase given an explicit task directory or document path uses that.
- Each document is **`NN-<type>-<description>.<ext>`**: `NN` is the next available two-digit number in the directory (counting every `NN-` file, whatever its type or extension; the first is `01`), `<description>` is short kebab-case, and `<ext>` is `html` (default) or `md`.
- Types: `request`, `research-questions`, `research`, `design-discussion`, `prd`, `tdd`, `structure-outline`, `spec`.
- A phase updates the existing document of its type in place (same path and number) when you are iterating or resuming, and creates a new numbered document only when none exists or you ask for one.
- Supporting files — mockups (`mockup-<desc>.html`) and diagrams (`diagram-<desc>.html`) — sit beside the documents and are linked as ordinary relative links.

A typical `prd-tdd` task directory:

```text
.agents/artifacts/feat-ENG-123-csv-export/
├── 01-request-csv-export.html
├── 02-research-questions-csv-export.html
├── 03-research-csv-export.html
├── 04-prd-csv-export.html
├── 05-tdd-csv-export.html
└── 06-structure-outline-csv-export.html
```

Older repositories may still hold `research/{questions,docs,designs,structures,specs,tickets,notes}/`. The research agents search those as historical context, but new documents are always written to the task directory.

## Artifacts Are Not Committed

Workflow documents are working files, so they stay out of commits (HumanLayer's guidance). Phases offer to open a document for review instead of committing it, and `gh-commit` leaves `.agents/artifacts/` out of commits unless you explicitly ask to commit an artifact. When `/ask-questions` creates a task directory and `.agents/` isn't git-ignored, it offers once to add `.agents/` to `.git/info/exclude` (local-only, not committed).

**Worktrees:** the documents live in the checkout, so a worktree's task directory goes away when the worktree is removed. Copy it out first if you want to keep it.

## The Phases

### 1. Questions (`/ask-questions <ticket or request>`)

**You drive this phase.** The agent turns the ticket into two documents: a **request** document (the original request, desired result, constraints and acceptance criteria, exact source pointers, the chosen flow, and the compatibility posture) and a **research-questions** document (2–7 descriptive questions about the current system, each with concrete starting pointers and no ticket content). It may run one small `codebase-locator` pass to find starting pointers, and it asks which flow to use.

### 2. Research (`/research-codebase <task-dir>`)

The agent answers the research questions by spawning parallel sub-agents across the codebase, database, and external docs. It gathers **objective facts only**. Research reads only the research-questions document — never the request or ticket — and sub-agents receive only their individual questions, so the agent maps what exists without forming premature conclusions about the desired change.

**Output:** `NN-research-<desc>` — a factual map of the current system.

### 3a. Design Discussion (`/design-discussion`, flow `design`)

The agent lays out what exists, where we're going, and the design crossroads. Decisions are taken **one at a time**: 2–3 concrete options with tradeoffs and a codebase-grounded recommendation, then your answer, recorded in the document with the rationale and why the alternatives were set aside. You correct wrong assumptions, redirect toward team patterns, and add constraints the code doesn't reveal. Visual choices get a focused HTML mockup or diagram beside the document.

This is the highest-leverage phase: every wrong assumption caught here is one that won't be embedded in the code.

**Output:** `NN-design-discussion-<desc>` — validated decisions with your rationale.

### 3b. PRD (`/create-prd`, flow `prd-tdd`)

Product requirements: the problem to solve, an agreed success measure, and the user-facing solution, settled one product decision at a time. Technical questions are recorded under "Deferred to TDD". You approve the solution details as a whole.

**Output:** `NN-prd-<desc>`.

### 3c. TDD (`/create-tdd`, flows `prd-tdd` and `tdd`)

Technical design in two approved halves: **System Design** (component interactions, contracts, schemas, current vs proposed) and then **Program Design** (call trees, file trees, signatures, pseudocode), plus patterns to follow. If a technical choice changes product scope, the PRD is updated too.

**Output:** `NN-tdd-<desc>`.

### 4. Structure Outline (`/structure-outline`, optional)

The implementation skeleton: type signatures (like a C header file) and **vertical slices** — end-to-end paths that can each be tested independently, never horizontal layers ("all DB work, then all API work, then all UI"). An Implementation Overview lists the slices; each slice carries a change outline (focused diffs for changed shapes, full target shapes for new code), tests following the repository's existing patterns, a checkpoint, and separate **Automated verification** (the repository's real commands) and **Manual verification** steps. It reads the request, research, and every design document present, and stops if the governing design document still has unresolved questions (unless you ask to proceed — see Early handoff).

**Output:** `NN-structure-outline-<desc>`.

### 5. Spec (`/create-spec`, optional)

A tactical plan built from the highest-precedence document available (outline, else TDD, else PRD, else design discussion): numbered phases, each with implementation steps, tests, and Automated and Manual verification. Because alignment happened upstream, this is a spot-check rather than a deep review.

**Output:** `NN-spec-<desc>`.

All documents can be emitted as **self-contained HTML** (default) or **GitHub-flavored Markdown** — pass `--format=html` or `--format=md` to any phase command. Each phase delegates rendering to `skills/output-html/` or `skills/output-markdown/` (each bundling an `assets/` template and a `references/components.md` component library). The component vocabulary maps 1:1 between formats — the `.options` + `.option.chosen` decision card in HTML renders as `- [x] **B.** … ✓ chosen` checkbox options in Markdown, and so on. Machine-readable fields (`<meta name="crispy:*">` in HTML, `crispy:` keys under YAML frontmatter in Markdown) carry the same schema for downstream skills, including `crispy:task_dir`, `crispy:flow`, and `crispy:repos`. `skills/output-html/references/visual-guidance.md` covers which views each phase uses (current-state views in research, before/after in design and TDD, target shapes and diffs in outlines) and how they render in each format.

### 6. Implement (`/orchestrate <task-dir>`, or directly)

Implementation reads the task directory and applies this **precedence**:

> **spec > structure outline > TDD > PRD > design discussion > research > request**

Your latest instructions override when they change the agreed result. Higher-precedence documents win on conflicts; lower ones supply context.

- **`/orchestrate <task-dir>`** — the planner decomposes the highest-precedence document into a dependency-wired task list (spec phases, else outline slices, else the design scope as one phase), and workers execute one task at a time. Phase gates come from the spec's or outline's Automated and Manual verification; with neither, there is one gate at the end listing the design document's verification expectations. At each phase boundary the orchestrator confirms the automated checks passed, then:
  - continues to the next phase when the phase has no manual checks;
  - otherwise **stops, reports the automated results, and hands you the manual verification steps — the next phase doesn't start until you confirm them**;
  - when you ask to run a group of phases or all of them continuously, verifies between phases and leaves unconfirmed manual checks for the final report.
- **Directly in the session** — for a small change, implement from the governing document here, still stopping for its manual verification.

**Commits happen at the gates, not per task.** Workers are sub-agents and can't get your go-ahead, so they don't commit. The orchestrator commits each phase's code through the gh-commit skill (Conventional Commits, task documents left out) once you confirm the manual verification — or once automated checks pass for a phase with no manual checks — and only with your go-ahead through gh-commit's own confirmation. The PR is created with the gh-create-pr skill, draft by default with the related Linear issue linked.

**Progress lives in the document.** At each gate the orchestrator updates the outline or spec in place: passed automated items and confirmed manual items are checked, and a phase whose verification is all confirmed gets ✅ on its Implementation Overview item and heading. A new session resumes from the first incomplete phase. When every phase is done, the final report lists what changed, the checks run, and any manual verification still pending.

**Iterating.** Bugs or review feedback after implementing go back through `/orchestrate <task-dir>`: the issue is reproduced, fixed through a worker task with a regression test, affected design or outline sections are updated in place, and validation markers are kept accurate. When the expected behavior is unclear, you get one targeted question.

**What's next?** Ask `/orchestrate` what's next for a task directory: it reads the `NN-<type>` files and their statuses, finds the current phase in the flow, and names the next command with the task directory and flow.

### 7. Review

A final quality pass before the PR merges. The **reviewer** agent audits the diff for correctness bugs, and the **code-simplifier** sweeps for reuse, simplification, and efficiency cleanups. Findings can be posted as inline comments on the GitHub PR or applied directly to the working tree.

## When to Skip Phases

Not every task needs every step:

- **Bug fix with a clear repro:** `/ask-questions` with the `tdd` or `research-only` flow, then fix it from the research or a short TDD
- **Small, well-understood change:** take the early handoff — implement directly from the design discussion or TDD, skipping the outline and spec
- **Cleanup or refactor where behavior stays the same:** the `tdd` flow
- **Large feature with open product questions, or an unfamiliar area:** the `prd-tdd` flow with an outline — that's what the full flow is built for
- **Performance investigation:** start with `/ask-questions` to separate what you know from what you need to measure, and use `research-only` until the numbers point at a change

## Why This Order Matters

Each phase produces a document that constrains the next, reducing the instruction load per step and preventing the three failure modes that hurt simpler workflows:

1. **Instruction budget overflow** — the work is spread across phases instead of one mega-prompt
2. **Magic words dependency** — each phase triggers the right behavior by default
3. **Plan-reading illusion** — assumptions are surfaced and validated before they're embedded in a plan
