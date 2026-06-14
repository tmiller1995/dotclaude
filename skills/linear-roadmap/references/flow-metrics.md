# Flow metrics

For each issue in scope, compute these from the state-change history. Used by `flow_diagnostic`, `roadmap`, and `deep_dive`. `release_notes` doesn't need them.

## Per-item metrics

- `current_state` and `days_in_current_state`
- `total_cycle_time` = (first move out of the initial backlog/started state → now)
- `state_bounce_count` = number of **backward** transitions (e.g., `In Review → Backlog`, `In Progress → Todo`). See "Defining backward" below.
- `last_toucher`, `last_action`, `last_action_date`
- `blocker_reason` — extract from the most recent comment within ±48 hours of the latest backward transition, OR from a label like `blocked` / `on hold`. If none found, write `"unclear — no comment near transition"` rather than guessing. Honesty about uncertainty makes the diagnostic more trustworthy than a confident-sounding fabrication.

## Defining "backward"

Prefer the team's own ordering when you can see it. The real workflow states and their order come from `list_issue_statuses` — use those, not assumed names. If the data shows a dominant left-to-right path (most transitions move in one direction across the cycle), use that as the forward flow and treat the minority direction as backward.

If the data is too sparse to infer and `list_issue_statuses` is unavailable, fall back to this generic Linear default flow:

```
Backlog → Todo → In Progress → In Review → Done
```

Always surface the inferred order in the executive summary so the reader can correct it if it's wrong:

> "Backward transitions defined as moves earlier in: Backlog → Todo → In Progress → In Review → Done."

This matters because what counts as a "regression" is team-dependent — an `In Review → In Progress` move might be normal rework on one team and a red flag on another. The diagnostic is only credible if its definition is visible.
