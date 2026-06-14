# Workflow — shared runtime for all modes

Once the mode is known, this is the script that runs for every mode. Per-mode output templates live in `modes.md`; metric formulas in `flow-metrics.md`; visualization skeletons in `mermaid-templates.md`; Linear MCP calls in `linear-queries.md`.

## Step 1 — Confirm host capabilities

Check what's available before pulling data. The skill is intentionally portable across hosts (Claude Code, Claude Desktop, ChatGPT, Cursor, Copilot Chat) and the capability check is what makes that work.

1. **If a Linear MCP is loaded** (tool names starting with `mcp__linear__`), use it. Operations needed:
   - `mcp__linear__list_cycles` / `list_projects` / `list_milestones` — resolve the named cycle/project/milestone to an id
   - `mcp__linear__list_issue_statuses` — the team's real workflow states (forward order, done-state name)
   - `mcp__linear__list_issues` — items in the cycle, filterable by state / label / priority / updatedAt
   - `mcp__linear__get_issue` — single issue with history, sub-issues, relations, attachments
   - `mcp__linear__list_comments` — comments around blockers
   - `mcp__linear__list_issue_labels` — resolve the configurable customer-facing label
   - For linked code: `mcp__github__pull_request_read` / `mcp__github__list_commits` (or the `gh` CLI) to enrich PRs/commits referenced in issue attachments

2. **If no Linear MCP is available** (e.g., Copilot Chat without connectors), stop and ask the user to either:
   - Paste a CSV/JSON export of the cycle, or
   - Paste the issue details directly.

   Then continue from Step 3 with whatever they provide. Don't try to invent the missing data.

### Host quirks

- **Claude Code / Claude Desktop** — Linear MCP loads natively. Spawn parallel sub-agents per issue only when item count > ~30, otherwise the orchestration overhead outweighs the parallelism.
- **ChatGPT** — requires the Linear connector to be enabled. If it isn't, fall back to pasted CSV/JSON.
- **Cursor** — same as Claude Code if the Linear MCP is configured in `~/.cursor/mcp.json`.
- **GitHub Copilot Chat** — at present, no arbitrary MCP support; operate in pasted-data mode.

## Step 2 — Pull the data

First resolve the **scope**: the user names a cycle, a project, or a milestone — resolve it to an id with `list_cycles` / `list_projects` / `list_milestones`. Also pull `list_issue_statuses` once so state-name comparisons (done-state, forward order) use the team's real states.

For the cycle in scope, fetch:

1. **Issues in scope.**
   - `release_notes` — done-state issues only. See the first query in `linear-queries.md`.
   - `flow_diagnostic` / `roadmap` — broaden to **all** issues in the cycle (any state). See the all-items query.
   - `deep_dive` — skip the cycle query; just fetch the single issue with `get_issue`, plus its comments and relations.

2. **Per issue, capture:**
   - Title, labels (including issue-type labels), workflow state, assignee, priority (0–4), project, cycle/milestone
   - **State-change history** (`from → to`, timestamp, actor) from `get_issue`. **If transition-level granularity is limited** (the issue history doesn't expose every state hop with an actor), fall back to the `created` / `updated` / `completed` timestamps and note the reduced fidelity in the output rather than fabricating transitions.
   - **Comments**, especially around backward transitions (`list_comments`)
   - **Linked artifacts:**
     - GitHub PRs and commits — Linear surfaces these as issue **attachments**. Cross-reference each with `mcp__github__pull_request_read` (merge status, target branch, reviewer state) and `mcp__github__list_commits` (sha, subject, author), or the `gh` CLI.
   - **Parent issue** for a sub-issue (one level up) and **sub-issues** for a parent (one level down)

3. **Roll up children.** A parent inherits the customer-facing classification from any descendant. This is why we walk the hierarchy — a parent may not carry the `customer` label directly even though its child bug does.

## Step 3 — Classify customer-facing vs internal

Customer-facing detection is a configurable **label** (default `customer`), resolved via `list_issue_labels` and applied as a `label` filter on `list_issues`. Apply per issue, then roll up to the parent:

| Signal | Classification |
|---|---|
| Carries the customer label (self or descendant) | **Customer-facing** — reported by / affecting an actual user |
| No customer label | **Internal** — internal discovery / dev-side cleanup |

`customer_label` is configurable per team (common alternatives: `customer-reported`, `external`, `csat`). If the team uses a different label, set `customer_label` accordingly; if no such label exists and the team tracks customer reports another way, ask before classifying everything as internal.

For `release_notes`, treat customer-facing as the default-public set. Features (issues without the customer label) should also be public *if* they have user-visible value — apply judgment based on the title and description, and surface uncertain calls to the user rather than guessing silently.

## Step 4 — Apply the mode

Open `modes.md` and follow the per-mode template.

For `flow_diagnostic`, `roadmap`, and `deep_dive`, also compute the flow metrics from `flow-metrics.md` — they populate the stuck-items table, the at-risk section, and the bottleneck identification. `release_notes` doesn't need these; skip them.

## Step 5 — Render outputs

This skill **gathers and structures** the data; it does NOT directly write the final scaffolded artifact. After producing the body content per `modes.md`, hand off to the matching output skill:

- `--format=md` (default) → `Skill('output-markdown')`
- `--format=html` → `Skill('output-html')`

The output skill wraps the body in the standard CRISPY-style scaffold (header card with status / cycle / mode chips, summary grid, polished section frames) and writes a self-contained file. The body content you produce — Mermaid blocks, stuck-items tables, executive summary bullets — flows through unchanged.

### Slot values for the render brief

| Slot | Value |
|---|---|
| `PHASE` | (omit — this is Report mode, not CRISPY mode) |
| `PHASE_LABEL` | `Release Notes` / `Flow Diagnostic` / `Roadmap` / `Deep Dive` (matching the chosen mode) |
| `STATUS` | (omit) |
| `TITLE` | `<Mode>: <cycle>` (e.g., `Roadmap: Cycle 2026-05`) or `<Mode>: <issue_id>` for deep_dive |
| `TOPIC` | kebab-case derived from cycle name/number or issue id |
| `TICKET` | (omit) |
| `PROMPT_TEXT` | one-sentence subtitle describing what's in the artifact (e.g., "Release notes for Cycle 2026-05 — 14 done issues, 3 customer-facing.") |
| `META_EXTRA` | `report:kind: <mode>`, `report:cycle: <cycle>`, `report:item_count: <N>` |
| `SUMMARY_EXTRA` | rows for: Mode, Cycle, Item count (accent), Customer-facing count |
| `BODY` | the rendered body content per `modes.md` |

### Output path

Default: `reports/YYYY-MM-DD-<mode>-<cycle-or-id>.<ext>`. Override if the user specified a path.

### Content-rendering rules (carried through to either output skill)

- **Diagrams** — always Mermaid. Sankey uses `sankey-beta`; timelines use `gantt`. Skeletons in `mermaid-templates.md`. **Both output skills preserve Mermaid as fenced code blocks** — they render natively in GitHub / GitLab / Confluence (with plugin). In vanilla HTML browsers Mermaid won't render automatically; see the "Format selection" callout in `SKILL.md` for the post-processing recipe.
- **Tables** — GitHub-flavored markdown (works in both output formats; `output-markdown` keeps them as pipe tables, `output-html` converts to palette-styled `<table>`). Sort the stuck-items table by `days_in_current_state` desc.
- **IDs** — include in *internal* sections; omit from *public* sections.
- **Dates** — convert all relative dates to absolute `YYYY-MM-DD`.
- **Executive summaries** — ≤ 8 bullets. Detail belongs in tables and diagrams, not prose.
- **Public release notes** — plain language, benefit-focused, no internal jargon, no issue identifiers.

## Step 6 — Confirm and refine

After producing the artifact, ask the user:

```
Output ready. Want me to:
1. Adjust which items go in public vs internal release notes
2. Drill into a specific stuck item (deep_dive)
3. Re-run with a different cycle / project / filter
4. Post the result as a Linear comment or a GitHub issue/PR comment
```

Option 4 is a **write back** — the SKILL.md guardrail still applies. Confirm before pushing anything. When approved:
- Post to a Linear issue → `mcp__linear__save_comment` (the issue/PR can also be linked via `mcp__linear__create_attachment`).
- Post to a GitHub issue or PR → `mcp__github__add_issue_comment` (or the `gh` CLI).
