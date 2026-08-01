---
name: structure-outline
description: Produce a C-header-file-style structure outline — signatures, new types, file inventory, and a vertical-slice phase breakdown where each slice (mock API → front-end → database) carries a testable checkpoint. Use this as the STRUCTURE phase of CRISPY (Questions → Research → Design → STRUCTURE → Plan → Implement → Review), normally after /design-discussion has produced a design document. Trigger when the user asks to "create a structure outline", "define the implementation structure", "break this into vertical slices", "slice this feature into phases with checkpoints", "what files will this touch", or "give me the header-file view" — including when they describe that work without naming the skill. Not for deciding what to build or why (that is design-discussion) and not for tactical task lists with ids and dependencies (that is create-spec). Accepts `--format=html|md` to select output format (default `html`).
argument-hint: "<path to design file> [--format=html|md]"
disable-model-invocation: true
---

# Structure Outline (CRISPY S Phase)

You are tasked with producing a structure outline for the feature described by the design document at: **$ARGUMENTS**

This is the **Structure (S)** phase of CRISPY. Dex Horthy's analogy:

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

1. **Header-style signatures** — function/class signatures and new types, like a `.h` file. No implementation bodies.
2. **New types / data models** — full type definitions with field names and types
3. **File inventory** — list of files being created, modified, or deleted (paths only, no diffs)
4. **Vertical slice breakdown** — the feature carved into phases, each with a testable checkpoint
5. **Integration points** — where new code connects to existing code (by file:line from research)
6. **Rollback strategy** — how to revert if a slice fails

## What It Does NOT Contain

- Implementation code bodies (that's Implement)
- Tactical task lists with ids and dependencies (that's Plan)
- Design decisions and rationale (that's Design Discussion — already done)
- Research findings (that's Research — already done)

## Workflow

### Step 1: Parse Arguments and Pick the Output Format

Extract `--format=html|md` from `$ARGUMENTS`. Default to `html` when no flag is present. The remainder of `$ARGUMENTS` is the path to the design document. If nothing remains after stripping the flag, list `research/designs/` newest-first and confirm the intended document with the user before reading. Hold the chosen format for Step 7 — it selects which output skill renders the artifact.

### Step 2: Read the Design Document

Read the design document fully (no limit/offset). Also read:
- The research document it cites
- The questions artifact if one exists (for ticket context)

The design is frozen at this point — reopening it here splits the decision record across two artifacts. If the design looks wrong or incomplete, stop and send the user back to `/design-discussion`.

### Step 3: Enumerate the Changes as Signatures

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

For **existing files being modified**, describe the change at a signature level — no code, just bullets:
- File label: the existing path tagged `MODIFY`
- Bullets: each significant change at a sentence level (e.g., "Add `ReticulateButton` to the splines list row action menu")

### Step 4: Carve the Vertical Slices

Break the feature into 3-6 vertical slices. Each slice must:
- Produce a working end-to-end path (even if parts are mocked)
- Have a **testable checkpoint** — a concrete thing a human can verify before moving on
- Be independently deployable (optional but preferred)

Plan each slice as a slice-card matching the output skills' slice-card contract (same contract create-spec consumes):
- A `### Slice N — Name` heading
- A `goal` line: one sentence of what success looks like for the user
- A files-touched list with `NEW` / `MODIFY` / `DELETE` tags (see `skills/output-html/references/components.md`, Vertical-slice cards, for the shape both output skills expect)
- A `checkpoint` line: the testable thing the user can verify (prefix with `✓`)
- An optional `chips` row with metrics: `Size: ~80 LOC`, `Surfaces: web`, `Behind flag: enable_reticulation`

The LAST slice is always the hardening slice: auth, validation, error handling, telemetry, migration.

### Step 5: Identify Integration Points

From the research document, list the exact `file:line` locations where new code touches existing code. Plan as a 2-column table: Location | What changes.

### Step 6: Write the Rollback Strategy

One short paragraph in a callout: if any slice fails in production, what's the revert?

Example:
> Each slice is behind a feature flag (`enable_reticulation`). Disabling the flag hides the `ReticulateButton` and disables the server function. The DB migration is additive (new table, no changes to existing tables), so no rollback migration is needed. To fully remove: disable flag → drop `reticulation_log` in a follow-up migration.

### Step 7: Prepare the Render Brief and Delegate

Output path:
- Directory: `research/structures/`
- Stem: `YYYY-MM-DD-<topic>` (match the kebab-case topic from the design doc)
- Extension: chosen by the output skill

#### Slot values

Both output skills share one slot schema, so this brief is consumed unchanged by either. Use these exact slot names — do not invent new ones.

| Slot | Value |
| --- | --- |
| `PHASE` | `structure` |
| `PHASE_LABEL` | `Structure Outline` |
| `STATUS` | `ready-for-plan` |
| `STATUS_CLASS` | `ready` |
| `TOPIC` | kebab-case topic |
| `TITLE` | `Structure Outline: <Topic>` |
| `TICKET` | one-line ticket summary |
| `PROMPT_TEXT` | 2-3 sentences: what's being built and how it's being sliced |
| `META_EXTRA` | `crispy:design_doc`, `crispy:research_doc`, `crispy:slice_count` |
| `SUMMARY_EXTRA` | rows for: Slice count (accent), Design doc (link), New files (count), Modified files (count) |

`REPO`, `BRANCH`, and `DATE` are derived by the output skill from the shell — leave them to it.

#### Body sections

Emit numbered sections in this order. The output skill numbers them monotonically (`01`, `02`, ...).

**Section 01 — Summary**
2-3 sentences echoing the prompt-box, plus the slice count.

**Section 02 — File inventory**
A 3-column table: Change tag | Path | Purpose. One row per file affected, using the `NEW` / `MODIFY` / `DELETE` tag vocabulary.

**Section 03 — New types & signatures**
One file-label + code block per new file, per Step 3.

**Section 04 — Vertical slices**
One slice-card per slice, per Step 4. This is the centerpiece of the artifact.

**Section 05 — Integration points**
The 2-column file:line table from Step 5.

**Section 06 — Rollback strategy**
The callout from Step 6.

#### Step 7a — Check before rendering

Run the brief past these questions. On a miss, fix the brief and recheck before delegating.

- Does every slice touch more than one layer? If a slice is only database or only UI, recut it.
- Does every slice have a concrete checkpoint a human can run?
- Is the last slice the hardening slice (auth, validation, error handling, telemetry, migration)?
- Does any code block contain a function body? Signatures only.
- Do the slot names match the Step 7 table exactly, with none renamed or invented?
- Does the Section 02 file inventory account for every file named in a slice card?
- Does every integration point carry a `file:line` reference from the research doc?

#### Delegate

Invoke the matching output skill, passing the stem so it appends the extension:
- `--format=html` → `Skill('output-html')`
- `--format=md` → `Skill('output-markdown')`

### Step 8: Present to User

Show:
1. The slice count and names
2. The file path
3. Offer to commit the artifact via `Skill('gh-commit')` — committed CRISPY artifacts survive worktree teardown and are reviewable in PRs
4. Suggest next command: `/create-spec research/structures/YYYY-MM-DD-topic.<ext>`

Do not proceed to planning automatically — the human should review the slice breakdown before the Plan phase turns it into tasks.

## When to Abort This Phase

Stop and send the user back if any of these hold:

1. The design document doesn't exist, or what was passed is a research doc / raw ticket instead → run `/design-discussion` first
2. The design doc has unresolved open questions → return to `/design-discussion`
3. The research doc the design cites doesn't exist or is stale → run `/research-codebase` first

Each phase runs in its own context for a reason, so do not fill the gaps by performing the earlier phases here.

## What Happens Next

The structure outline feeds `/create-spec`, which converts each slice into concrete tasks with dependencies for the worker agent to pick up one at a time. Each phase runs in a fresh context and reads only the prior artifact, not the whole history.
