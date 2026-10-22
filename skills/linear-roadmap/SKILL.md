---
name: linear-roadmap
description: Generate executive-ready release notes, roadmaps, and delivery-flow diagnostics from Linear issues. Use when the user wants shipped or planned work summarized (release notes, roadmaps, cycle or sprint summaries), delivery flow diagnosed (stuck or blocked issues, cycle time, bounce counts, bottlenecks, Sankey or flow diagrams of state transitions, a single-issue deep dive), or work classified as customer-facing vs internal — even when they don't say "roadmap" or "release notes" (e.g., "what shipped this cycle", "why is the team slowing down", "where's ENG-572 stuck"). Also handles "HTML release report" / "markdown release report" — a format keyword routes here rather than to output-html or output-markdown, which this skill calls internally to render. Accepts `--format=html|md` (default `md`).
argument-hint: "[mode] [cycle | issue_id] [--format=html|md]"
---

# Linear Roadmap & Flow Insights

Turn raw Linear issue data into executive-ready artifacts.

## Modes

| Mode | Output | Required input |
|---|---|---|
| `release_notes` | Public (customer-facing) + internal release notes for a cycle | `cycle` |
| `flow_diagnostic` | Stuck-items table + Sankey of state transitions + per-stuck-item timelines | `cycle` |
| `roadmap` | `release_notes` + `flow_diagnostic` + forward-looking ship/at-risk/next-up | `cycle` |
| `deep_dive` | Full forensic timeline + linked artifacts + recommendation for one issue | `issue_id` |

If `mode` is missing, ask: **"Which mode? `release_notes`, `roadmap`, `flow_diagnostic`, or `deep_dive`?"**

Optional inputs: `team` / `project`, `customer_label` (defaults to `customer`), `done_state_name` (defaults to the team's completed workflow state, commonly `Done`).

A "cycle" can be a Linear cycle, a project, or a milestone — resolve whichever the user names. See `references/linear-queries.md`.

## Format selection

This skill is the entry point for Linear release/flow data, regardless of whether the user wants HTML or Markdown output. It gathers and structures the data; the output skills (`output-html` / `output-markdown`) handle the scaffolding.

- Default is `--format=md`, because most outputs land in GitHub PR descriptions, Linear comments, or GitLab, where Mermaid diagrams render natively.
- `--format=html` produces a polished single-file HTML document for a non-engineering audience (email, Confluence, customer-share docs). `output-html` is self-contained and does not render Mermaid, so pre-render each diagram to SVG before handing off and inline the result:

  ```
  npm install -g @mermaid-js/mermaid-cli
  mmdc -i diagram.mmd -o diagram.svg      # one file per diagram
  ```

  Inline each `<svg>` element into the body. If `mmdc` is unavailable, keep the tables and the executive summary, omit the diagram, and tell the user that `--format=md` preserves it.

## How to run

1. Read `references/workflow.md` first — it covers capability detection (MCP vs pasted-data), data fetching, customer-facing-vs-internal classification, rendering, and the confirm/refine loop. The same script runs for every mode.
2. Then load only what the chosen mode needs:

| Mode | Also load |
|---|---|
| `release_notes` | `references/modes.md` § release_notes, `references/linear-queries.md` |
| `flow_diagnostic` | `references/modes.md` § flow_diagnostic, `references/flow-metrics.md`, `references/mermaid-templates.md`, `references/linear-queries.md` |
| `roadmap` | union of the above two |
| `deep_dive` | `references/modes.md` § deep_dive, `references/flow-metrics.md`, `references/mermaid-templates.md` |

## Guardrails

- **Don't invent issues.** If an MCP call fails or returns empty, say so and stop — fabricated IDs or fields would make the whole artifact untrustworthy.
- **No AI attribution.** The artifact is authored by the engineer/PM, not by the assistant; don't sign it or footnote it.
- **Don't write back to Linear or GitHub** (comments, issue edits, field changes) without explicit user approval. Producing the artifact is a read operation; pushing it anywhere is a separate write that needs a green light.
