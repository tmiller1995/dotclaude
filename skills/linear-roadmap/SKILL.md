---
name: linear-roadmap
description: Generate executive-ready release notes, roadmaps, and delivery-flow diagnostics from Linear issues. Use this skill whenever the user mentions release notes, roadmaps, cycle or sprint summaries, issues being stuck or blocked, cycle time, bounce counts, bottlenecks, Sankey or flow diagrams of state transitions, or wants to classify items as customer-facing vs internal — even if they don't explicitly say "roadmap" or "release notes" (e.g., "what shipped this cycle", "why is the team slowing down", "where's ENG-572 stuck"). Triggers on phrases like "release notes for cycle X", "roadmap for sprint Y", "where are issues stuck", "why is this issue stalled", "flow diagnostic", "show the bottleneck", "deep dive on issue N". Also handles "HTML release report" / "markdown release report" requests — the format keyword routes here (not output-html/output-markdown) because the user wants Linear data, and this skill delegates rendering to the matching output skill internally. Accepts `--format=html|md` (default `md` — most outputs go to PR/issue-comment contexts where Mermaid renders natively; use `html` for polished customer-share docs).
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

- Default is `--format=md`. Markdown is the right format for GitHub PR descriptions, Linear comments, GitHub, GitLab — and Mermaid diagrams render natively in all of those.
- `--format=html` produces a polished single-file HTML document (useful for emailing to a non-engineering audience or pasting into Confluence). **Caveat:** Mermaid diagrams in HTML mode are emitted as plain fenced blocks — they render in Mermaid-aware viewers (GitHub Pages with mermaid.js, GitLab) but appear as source text in vanilla browsers. If the consumer needs static rendered diagrams in HTML, post-process the file with `mermaid-cli` (`mmdc -i in.html -o out.html`) to convert the blocks to inline SVG.

## How to run

1. Read `references/workflow.md` first — it covers capability detection (MCP vs pasted-data), data fetching, customer-facing-vs-internal classification, rendering, and the confirm/refine loop. The same script runs for every mode.
2. Then load only what the chosen mode needs:

| Mode | Also load |
|---|---|
| `release_notes` | `references/modes.md` § release_notes, `references/linear-queries.md` |
| `flow_diagnostic` | `references/modes.md` § flow_diagnostic, `references/flow-metrics.md`, `references/mermaid-templates.md`, `references/linear-queries.md` |
| `roadmap` | union of the above two |
| `deep_dive` | `references/modes.md` § deep_dive, `references/flow-metrics.md`, `references/mermaid-templates.md` |

Don't pre-load reference files you won't use — that's the point of progressive disclosure.

## Non-negotiable guardrails

- **Never invent issues.** If an MCP call fails or returns empty, say so and stop — don't fabricate IDs or fields to fill the template.
- **No AI attribution.** The artifact is authored by the engineer/PM, not by the assistant; don't sign it or footnote it.
- **Don't write back to Linear or GitHub** (comments, issue edits, field changes) without explicit user approval. Producing the artifact is a read operation; pushing it anywhere is a separate write that needs a green light.
