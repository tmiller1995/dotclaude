---
name: structure-outline
description: Produce a C-header-file-style structure outline — signatures, new types, file inventory, and a vertical-slice breakdown where each slice (mock API → front-end → database) carries a testable checkpoint plus Automated and Manual verification. The optional outline step of CRISPY, run after research and whichever design documents the flow produced (design discussion, PRD, TDD); reads them from the task directory under `.agents/artifacts/`. Manual-only. Does not decide what to build or why (use /design-discussion, /create-prd or /create-tdd) and does not produce per-phase implementation steps (use /create-spec) or task lists (planner agent). Accepts `--format=html|md` (default `html`).
argument-hint: "<task directory or prior artifact path> [--format=html|md] [flow: <flow>]"
disable-model-invocation: true
---

# Structure Outline (CRISPY outline step)

You are tasked with producing a structure outline for the task in: **$ARGUMENTS**

This is the optional **Structure Outline** step of CRISPY. It comes after research and the flow's design documents, and before implementation (or the optional `/create-spec`). Dex Horthy's analogy:

> "If design is the architecture review, structure outline is the sprint planning meeting. It's like a C header file — signatures, new types, high-level phases. Not implementation."

## The Core Principle

The Structure Outline phase exists to **enforce vertical slices** over horizontal layers. This is one of the hardest things to get models to do reliably, which is why it needs its own phase.

**Horizontal plan (what models default to):**
1. Set up all database migrations
2. Build all backend endpoints
3. Build all frontend components
4. Wire everything together
5. Integration test at the end

**Vertical slice plan (what this phase enforces):**
1. Mock API returning static data → frontend renders it → checkpoint: "data appears on page"
2. Real API hitting in-memory store → checkpoint: "create + read works"
3. Database schema + migration → checkpoint: "data persists across restarts"
4. Validation + error handling → checkpoint: "bad input rejected gracefully"
5. Auth/tenancy → checkpoint: "cross-tenant access prevented"

Each vertical slice produces a working end-to-end path that can be tested and reviewed. Horizontal layers defer integration to the end, where the agent is deep in a context window full of accumulated work and least equipped to handle integration complexity.

## What the Artifact Contains

1. **Implementation Overview** — one unchecked item per slice, so progress can be tracked against it
2. **Header-style signatures** — function/class signatures and new types, like a `.h` file. No implementation bodies.
3. **New types / data models** — full type definitions with field names and types
4. **File inventory** — list of files being created, modified, or deleted (paths only, no diffs)
5. **Vertical slice breakdown** — the feature carved into slices, each with a change outline, its tests, a testable checkpoint, and separate Automated and Manual verification
6. **Integration points** — where new code connects to existing code (by file:line from research)
7. **Rollback strategy** — how to revert if a slice fails
8. **Open Questions** — unresolved scope or slice-order questions (omitted when there are none)

Implementation code bodies, per-phase implementation steps (the spec's job), design decisions and their rationale (settled in the design documents), and research findings (settled in research) stay out of the outline. A slice's change outline is the exception to "no code": focused `diff` blocks for changed shapes and full target shapes for new code show what the slice changes, which is the outline's job. `skills/output-html/references/visual-guidance.md` covers choosing these views and rendering them in each format.

## Workflow

### Step 1: Parse Arguments and Resolve the Task Directory

Extract `--format=html|md` (default `html`) and an optional `flow: <flow>` from `$ARGUMENTS`. Hold the format for Step 8 — it selects which output skill renders the artifact. The remainder is a task directory, a document path inside one (use its directory), or empty.

When it is empty, look in `.agents/artifacts/` for the task directory: the current branch name with `/` replaced by `-` when the branch identifies the task, otherwise a directory whose name and documents match the request. Reuse an obvious match without asking. When a directory looks close but could belong to another task, or several are plausible, ask the user which to use. State the chosen path.

The flow is the `flow:` argument, else the request document's `crispy:flow` metadata. Carry it into the metadata and the handoff command.

Workflow documents are named `NN-<type>-<description>.<ext>`. If the directory already has a `structure-outline` document, update it in place (same path and number) — the user is iterating or resuming. Create a new one only when none exists or the user asks for a new one; it takes the next available two-digit `NN` (count every existing `NN-` file, whatever its type or extension). When several outlines exist, use the highest-numbered and name it.

### Step 2: Read the Workflow Documents

Read these in full in the main context (no limit/offset):
- The `request` document
- The `research` document
- Every design document present: `tdd`, `prd`, `design-discussion`
- Mockups or diagrams they link, when they help with the slices

The **governing document** is the highest-precedence design document present: TDD > PRD > design discussion. In the `research-only` flow there is none, and the research and request govern. When documents conflict, the higher-precedence one wins and the lower ones supply context.

The design is settled by the time you are here, and reopening it here would split the decision record across two documents. Check only the governing document for unresolved open questions (or a `draft` status) — the lower-precedence documents are superseded by it, so their leftovers don't block. If it has any, stop and send the user back to the phase that owns it — see When to Stop. When the user explicitly asks to proceed anyway, write the outline and carry those items into its Open Questions section (status `draft`) instead of stopping.

### Step 3: Read Relevant Code and Verification Commands

Read the source files the documents cite where you need exact signatures or integration points. Find the repository's actual build, test, typecheck, and lint commands (for example `package.json` scripts, `dotnet test` against the solution, a Makefile, or the CI workflow) — the Automated verification blocks name these commands, not generic placeholders.

For a remaining factual gap, dispatch a `codebase-locator` or `codebase-analyzer` and wait for its result before writing. A gap that needs a design decision belongs to the design phase instead.

### Step 4: Enumerate the Changes as Signatures

For each new function, class, method, type, or module the feature introduces, write its signature. **No bodies.** Plan each signature as a file-label + code block. The output skill owns syntax highlighting — pass a language hint with each block and let it render.

Write signatures in the target repository's language and idiom; the examples below are illustrative.

**Example — Backend (TypeScript):**

```typescript
export const reticulateSchema = z.object({
  splineId: z.string().uuid(),
  tenantId: z.string().uuid(),
  factor: z.number().positive(),
});

export const reticulateSpline = createServerFn({ method: 'POST' })
  .validator(zodValidator(reticulateSchema))
  .handler(async ({ data }): Promise<ReticulationResult> => { /* ... */ });

export type ReticulationResult = {
  splineId: string;
  newCurvature: number;
  processedAt: Date;
};
```

**Example — Frontend (TSX):**

```typescript
interface ReticulateButtonProps {
  splineId: string;
  onSuccess?: (result: ReticulationResult) => void;
}
export function ReticulateButton(props: ReticulateButtonProps): JSX.Element;
```

**Example — Database (SQL):**

```sql
-- additive: no schema changes to existing tables
CREATE TABLE reticulation_log (
  id            UUID PRIMARY KEY,
  spline_id     UUID NOT NULL REFERENCES splines(id),
  tenant_id     UUID NOT NULL,
  reticulated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  factor        NUMERIC NOT NULL,
  result        JSONB NOT NULL
);
CREATE INDEX idx_reticulation_log_tenant ON reticulation_log(tenant_id, reticulated_at DESC);
```

For **existing files being modified**, describe the change at a signature level:
- File label: the existing path tagged `MODIFY`
- Bullets: each significant change at a sentence level (e.g., "Add `ReticulateButton` to the splines list row action menu")
- When the point is how an existing shape changes (a signature, type, props, schema), a focused `diff` block of just that shape in the slice's change outline

When the governing document is a TDD, its Program Design already carries signatures and file trees — carry them over rather than redesigning them.

### Step 5: Carve the Vertical Slices

Break the feature into vertical slices — usually 3–6; a small change can be a single slice. Each slice:
- Produces a working end-to-end path (even if parts are mocked)
- Has a **testable checkpoint** — a concrete thing a human can verify before moving on
- Is independently deployable (optional but preferred)
- Touches more than one layer by default. A safe preparatory slice (an additive migration, or a refactor with no behavior change) may stay in one layer when later slices build on it.

Plan each slice as a slice-card matching the output skills' slice-card contract (the same contract create-spec and the planner consume):
- A `### Slice N — Name` heading
- A `goal` line: one sentence of what success looks like for the user
- A files-touched list with `NEW` / `MODIFY` / `DELETE` tags (see `skills/output-html/references/components.md`, Vertical-slice cards, for the shape both output skills expect)
- A **Change outline** sub-block: the slice's target shapes for new code and focused `diff` blocks for changed shapes, drawn from Step 4, each with a short explanation beside it
- A **Tests (following the repo's existing patterns)** sub-block: the tests the slice adds or changes, by type (unit, integration, e2e) and location, modeled on the repository's existing test files and fixtures
- A `checkpoint` line: the testable thing the user can verify (prefix with `✓`), stated as an observable result
- An **Automated verification** sub-block: a checklist of the repository's actual commands that prove the slice works unattended (build, tests, typecheck, lint — e.g. `dotnet test`, `npm run typecheck`), each with what it verifies
- A **Manual verification** sub-block: a checklist of steps only a human can confirm (UI behavior, visual checks, end-to-end flows in a real environment), each written as an instruction to the human. Implementation pauses at these, and only the user checks them off. Write "None — fully covered by automated checks" only when that is literally true.
- An optional `chips` row with metrics: `Size: ~80 LOC`, `Surfaces: web`, `Behind flag: enable_reticulation`

Render the Change outline, Tests, and both verification sub-blocks as labeled lines followed by their lists or code blocks inside the same slice card, as the output skills' slice-card contract describes.

By default the last slice is the hardening slice: auth, validation, error handling, telemetry, migration. When each slice already carries its own error paths and tests, or the change is a single slice, a separate hardening slice isn't needed.

### Step 6: Identify Integration Points

From the research document, list the exact `file:line` locations where new code touches existing code. Plan as a 2-column table: Location | What changes.

### Step 7: Write the Rollback Strategy

One short paragraph in a callout: if any slice fails in production, what's the revert?

Example:
> Each slice is behind a feature flag (`enable_reticulation`). Disabling the flag hides the `ReticulateButton` and disables the server function. The DB migration is additive (new table, no changes to existing tables), so no rollback migration is needed. To fully remove: disable flag → drop `reticulation_log` in a follow-up migration.

### Step 8: Prepare the Render Brief and Delegate

Output path: pass the full stem `.agents/artifacts/<task>/NN-structure-outline-<description>` (no extension), where `<description>` is a short kebab-case description matching the task's other documents. When updating, pass the existing document's stem. The output skill appends the extension and creates the directory if needed.

#### Slot values

Both output skills share one slot schema, so this brief is consumed unchanged by either. Use these exact slot names — the output skills recognize no others.

| Slot | Value |
| --- | --- |
| `PHASE` | `structure` |
| `PHASE_LABEL` | `Structure Outline` |
| `STATUS` | `ready-for-implementation`; `draft` while the Open Questions section has unresolved items |
| `STATUS_CLASS` | `ready` (`draft` while questions remain) |
| `TOPIC` | kebab-case topic |
| `TITLE` | `Structure Outline: <Topic>` |
| `TICKET` | one-line request summary from the request document |
| `PROMPT_TEXT` | 2-3 sentences: what's being built and how it's being sliced |
| `META_EXTRA` | `crispy:task_dir`, `crispy:flow`, `crispy:repos`, `crispy:request_doc`, `crispy:research_doc`, the doc-link key for each design document present (`crispy:design_doc`, `crispy:prd_doc`, `crispy:tdd_doc`), `crispy:slice_count` |
| `SUMMARY_EXTRA` | rows for: Slice count (accent), Governing doc (link — the research doc in the `research-only` flow), New files (count), Modified files (count) |

`crispy:repos` lists each repository the outline covers as `<identifier>@<sha>`, comma-separated: the identifier from `gh repo view --json nameWithOwner -q .nameWithOwner` (the repository directory name if that fails), the sha from `git rev-parse HEAD`. Use `none` when no repository applies. Doc-link values are `.agents/artifacts/...` paths.

`REPO`, `BRANCH`, and `DATE` are derived by the output skill from the shell — leave them to it.

#### Body sections

Emit numbered sections in this order. The output skill numbers them monotonically (`01`, `02`, ...).

**Section 01 — Summary**
2-3 sentences echoing the prompt-box, plus the slice count and the desired end state.

**Section 02 — Implementation Overview**
A checklist with one unchecked item per slice: `- [ ] Slice N — Name`. It gives the reviewer the slice order at a glance and a list to track progress against during implementation, so keep it in sync with Section 05.

**Section 03 — File inventory**
A 3-column table: Change tag | Path | Purpose. One row per file affected, using the `NEW` / `MODIFY` / `DELETE` tag vocabulary.

**Section 04 — New types & signatures**
One file-label + code block per new file, per Step 4.

**Section 05 — Vertical slices**
One slice-card per slice, per Step 5. This is the centerpiece of the artifact.

**Section 06 — Integration points**
The 2-column file:line table from Step 6.

**Section 07 — Rollback strategy**
The callout from Step 7.

**Section 08 — Open Questions**
Unresolved scope or slice-order questions, one per item. Omit the section when there are none.

#### Step 8a — Check before rendering

Run the brief past these questions. On a miss, fix the brief and recheck before delegating.

- Does every slice touch more than one layer? If a slice is only database or only UI and isn't a safe preparatory slice, recut it.
- Does every slice have a change outline, a Tests block following the repository's existing patterns, a concrete checkpoint, an Automated verification list naming the repository's real commands, and a Manual verification list?
- Is the last slice the hardening slice (auth, validation, error handling, telemetry, migration), or do the slices carry their own error paths and tests?
- Does the Implementation Overview have exactly one item per slice, in slice order?
- Does any signature or target-shape block contain a function body? Shapes only; `diff` blocks show just the changed shape.
- Do the slot names match the Step 8 table exactly, with none renamed or invented?
- Does the Section 03 file inventory account for every file named in a slice card?
- Does every integration point carry a `file:line` reference from the research doc?

#### Delegate

Invoke the matching output skill, passing the stem so it appends the extension:
- `--format=html` → `Skill('output-html')`
- `--format=md` → `Skill('output-markdown')`

### Step 9: Apply Outline Feedback

When the user corrects facts, scope, slice order, or verification, verify factual corrections against the code, then revise the outline in place (same path). Fold settled answers into the relevant sections, remove them from Open Questions, keep the Implementation Overview in sync with the slices, and set the status to `ready-for-implementation` once no open questions remain.

### Step 10: Hand Off

Show:
1. The slice count and names, and any Open Questions that still need the user
2. The saved file path, and an offer to open it for review in VS Code, Cursor, or the browser
3. The next command with the task directory and flow, for example `/orchestrate .agents/artifacts/feat-ENG-123-csv-export flow: design` — the planner decomposes the outline's slices into tasks, and the worker loop pauses at each slice's Manual verification. For a small change, the user can instead implement directly from the outline in this session.
4. The optional alternative, `/create-spec .agents/artifacts/feat-ENG-123-csv-export flow: design`, when the user wants a task-ready plan with implementation steps per phase before implementing
5. That the command can run here, after compaction, or in a new session — the outline and the documents it cites carry everything implementation needs

Then wait for the user. The human reviews the slice breakdown before implementation turns it into tasks, so this skill does not start the next phase itself.

## When to Stop

Stop, and send the user back, when any of these hold:

1. There is no research document in the task directory → run `/research-codebase` first
2. The governing design document has unresolved open questions or is still `draft` → return to the phase that owns it (`/design-discussion`, `/create-prd`, or `/create-tdd`), unless the user explicitly asks to proceed (Step 2 carries the items into Open Questions)
3. The research the design cites is stale against the current code in a way that changes the slices → run `/research-codebase` again

Leave the gaps to the earlier phase rather than filling them here: each phase's document is a separate human review gate, and work done here would skip it.

## What Happens Next

Implementation reads the task directory and applies the precedence spec > structure outline > TDD > PRD > design discussion > research > request. Without a spec, the planner decomposes this outline's slices into tasks for workers to pick up one at a time, with a phase gate at each slice's Manual verification. With `/create-spec`, each slice becomes a spec phase with implementation steps and tests. Each phase reads only the documents in the task directory, not the conversation history, which is why it can run in a fresh session.
