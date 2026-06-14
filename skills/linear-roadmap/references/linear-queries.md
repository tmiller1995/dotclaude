# Linear queries

Reference Linear MCP calls for the `linear-roadmap` skill. Substitute placeholders (`<...>`) with actual values before running. All calls are read-only.

## Available tools

| Tool | Purpose |
|---|---|
| `mcp__linear__list_issues` | The workhorse. Filter by `cycle`, `project`, `team`, `state`, `label`, `assignee`, `updatedAt`, `priority`, `parent`. Returns issues with their current state, assignee, labels, priority, timestamps. |
| `mcp__linear__list_cycles` | Resolve a cycle name/number to its id and date window. Use when the user names a cycle/sprint. |
| `mcp__linear__list_projects` | Resolve a project the user names (e.g., "the billing project"). |
| `mcp__linear__list_milestones` | Resolve a project milestone if the user scopes by milestone rather than cycle. |
| `mcp__linear__get_project` | Pull a single project's details (description, lead, target date, status). |
| `mcp__linear__get_issue` | Single issue with full detail — history/state changes, relations, sub-issues, attachments, timestamps. Backbone of `deep_dive`. |
| `mcp__linear__list_comments` | Comments on an issue, used to extract blocker reasons near backward transitions. |
| `mcp__linear__list_issue_statuses` | The team's real workflow states (Backlog / Todo / In Progress / In Review / Done / Canceled, or whatever the team configured). Use to learn the canonical forward order instead of guessing. |
| `mcp__linear__list_issue_labels` | The team's labels, used to resolve the configurable customer-facing label (default `customer`). |

Resolve scope first (cycle/project/milestone id), then list issues filtered to it. Always read `list_issue_statuses` early so state-name comparisons use the team's real states, not assumed ones.

---

## Resolve the scope

The user gives a cycle name/number, a project name, or a milestone. Resolve it to an id before listing issues.

```
mcp__linear__list_cycles      { team: "<team_key_or_id>" }          # match the named/numbered cycle, capture id + start/end
mcp__linear__list_projects    { team: "<team_key_or_id>" }          # OR match the named project
mcp__linear__list_milestones  { project: "<project_id>" }          # OR a milestone within a project
```

If the team's workflow states are unknown, fetch them so downstream comparisons (done-state, forward order) use real names:

```
mcp__linear__list_issue_statuses { team: "<team_key_or_id>" }
```

The "done" / "ready to ship" state varies per team — common names: `Done`, `Released`, `Shipped`, `Deployed`. Use `done_state_name` if the user supplied one; otherwise infer from `list_issue_statuses` (the completed-type state).

---

## All done-state items in a cycle

For `release_notes` mode — only completed issues.

```
mcp__linear__list_issues {
  cycle:   "<cycle_id>",          # or project: "<project_id>" / project + milestone
  state:   "<done_state_name>",   # the completed workflow state (e.g., "Done")
  orderBy: "priority"             # then break ties by identifier
}
```

If scoping by project/milestone instead of cycle, swap `cycle` for `project` (and filter by `milestone` if the tool supports it; otherwise post-filter the returned issues by their milestone field).

---

## All items in a cycle (any state) — for flow_diagnostic / roadmap

```
mcp__linear__list_issues {
  cycle:   "<cycle_id>",          # or project: "<project_id>"
  orderBy: "updatedAt"            # any state — no state filter
}
```

Pull every issue regardless of state so the Sankey and stuck-items analysis sees the full flow, including backward transitions.

---

## Items still in progress — for "Next up" section of roadmap

```
mcp__linear__list_issues {
  cycle:   "<cycle_id>",
  state:   ["Todo", "In Progress"],   # or the team's not-yet-done active states
  orderBy: "priority"                 # priority 0 = No priority, 1 = Urgent ... see modes.md
}
```

Linear priority is numeric (`0` No priority, `1` Urgent, `2` High, `3` Medium, `4` Low). Order by the team's intended urgency, then by identifier. See `modes.md` for the exact ordering rule.

---

## Items at risk — long days-in-state OR bounced

Linear's filters don't natively expose `days_in_current_state` or bounce count, so this narrows the candidate set by staleness; compute the actual at-risk filter from each issue's history in Step 5 of the workflow.

```
mcp__linear__list_issues {
  cycle:     "<cycle_id>",
  state:     ["Todo", "In Progress", "In Review"],   # exclude Done / Canceled
  updatedAt: "-P7D"                                   # not updated in the last 7 days (ISO-8601 duration)
}
```

`-P7D` means "older than 7 days ago". Adjust the threshold if the team's cycle length differs from 2 weeks. (If the tool uses a different staleness filter syntax, post-filter the full cycle list by `updatedAt`.)

---

## Sub-issues of a parent (for customer-label rollup classification)

Linear models parent/child as sub-issues. Fetch the parent with `get_issue` (which includes its children/relations), or list children directly:

```
mcp__linear__get_issue   { id: "<parent_issue_id>" }     # includes sub-issues + relations
# or
mcp__linear__list_issues { parent: "<parent_issue_id>" }  # direct child query if supported
```

Walk the children so a parent inherits the customer-facing classification from any descendant (a parent may not carry the `customer` label directly even though a child bug does).

---

## Customer-labeled items in a cycle

Customer-facing detection is a configurable **label** (default `customer`), not an external URL. Resolve the label, then filter:

```
mcp__linear__list_issue_labels { team: "<team_key_or_id>" }     # confirm the label exists; capture exact name/id
mcp__linear__list_issues {
  cycle: "<cycle_id>",
  label: "<customer_label>"                                     # default "customer"; override per team
}
```

If the team uses a different label name (e.g., `customer-reported`, `external`, `csat`), set `customer_label` accordingly. If no such label exists and the team is known to track customer reports another way, ask before classifying everything as internal rather than guessing.

---

## Single issue (deep_dive)

```
mcp__linear__get_issue    { id: "<issue_id>" }      # state, assignee, priority, labels, parent, sub-issues, relations, history, attachments
mcp__linear__list_comments { issueId: "<issue_id>" } # comment thread for the timeline + blocker extraction
```

`get_issue` returns the issue history (state changes with timestamps and actors) where available; if transition-level granularity is limited, fall back to the created / updated / completed timestamps. Linked GitHub PRs and commits come from attachments — cross-reference them with `mcp__github__pull_request_read` / `mcp__github__list_commits` (see `workflow.md` Step 2).
