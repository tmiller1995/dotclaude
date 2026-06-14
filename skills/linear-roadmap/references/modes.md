# Modes — full output templates

This file documents the four modes the `linear-roadmap` skill supports. Each mode has a strict output shape; follow it unless the user explicitly asks for variation.

---

## Mode: `release_notes`

Two sections, in this order.

### Public Release Notes (customer-facing)

Include only items that are EITHER:

- **Features** that have user-visible value (judge from title/description), OR
- **Bugs carrying the customer label** (customer-reported)

Group by:

```
## New Features
- <one-line benefit-focused description>

## Improvements
- <one-line benefit-focused description>

## Bug Fixes
- <one-line benefit-focused description>
```

Rules:

- Plain language. No internal jargon.
- **No issue identifiers** in the public version.
- One line per item. If you need two, you're being too detailed.
- Lead with the user benefit, not the technical change.
  - Bad: `Refactored the offer state machine.`
  - Good: `Offers no longer get stuck in "pending" after declining a counter.`

### Internal Release Notes (full)

Every done-state item, grouped the same way:

```
## New Features
- [Feature] ENG-572 — Add saved-cart reminders — (customer-facing) — @alice
  Adds a daily email to users with stale carts. customer label set.

## Improvements
- [Feature] ENG-580 — Speed up checkout API — (internal) — @bob
  Reduces p95 from 1.4s to 380ms. No user-visible change in copy.

## Bug Fixes
- [Bug] ENG-611 — Fix offer countdown rollover — (customer-facing) — @carol
  Reported by user; carries the customer label.
- [Bug] ENG-622 — Fix admin-only typo in audit log — (internal) — @dave
  OMITTED FROM PUBLIC: internal admin tool, no end-user impact.
```

Rules:

- Include **every** done-state item.
- Tag each as `(customer-facing)` or `(internal)`.
- For items omitted from the public version, add a line `OMITTED FROM PUBLIC: <one-sentence reason>` so the reviewer can spot-check the call.
- The `[Feature]` / `[Bug]` prefix comes from the issue's type label (Linear has no built-in work-item type — teams encode this as a label). If a team uses different label names, use theirs.

---

## Mode: `flow_diagnostic`

Goal: show *where* work is stuck and *why*.

Produce these four sections, in order:

### 1. Executive summary (≤ 6 bullets)

Plain-language. The audience is a director who has 30 seconds.

Examples of the kind of bullets to write:

- `8 admin-redesign issues have bounced from In Review → Backlog over the past 14 days because QA capacity is absorbed by Urgent customer bugs.`
- `Cycle time on Bugs has grown from 4d (last cycle) to 9d (this cycle).`
- `The top stuck item (ENG-572, 18 days in In Review) is waiting on a single reviewer who is on PTO until 2026-04-29.`

### 2. Stuck-items table

Sorted by `days_in_current_state` desc. Cap at 20 rows; if there are more, note the count and offer to expand.

```
| ID      | Title                              | State        | Days Stuck | Bounces | Last Toucher | Why Stuck                                  |
|---------|------------------------------------|--------------|------------|---------|--------------|--------------------------------------------|
| ENG-572 | Admin redesign: category picker    | Backlog      | 18         | 2       | @alice       | QA capacity absorbed by Urgent bugs        |
| ENG-611 | Offer countdown rollover           | In Review    | 11         | 0       | @bob         | Awaiting reviewer (on PTO until 04-29)     |
```

`Why Stuck` is the `blocker_reason` from Step 5. If unclear, write `unclear — no comment near transition` rather than guessing.

### 3. Sankey diagram of state flow

Mermaid `sankey-beta`. Each node is a workflow state; each link weight is the number of transitions between those states across the cycle. **Include backward transitions as distinct links** — that's how regressions become visible.

See `mermaid-templates.md` for the skeleton.

### 4. Per-item timelines (only for items in the stuck-items table)

Mermaid `gantt`. One section per item, showing each state with its date range and actor. See `mermaid-templates.md`.

---

## Mode: `roadmap`

Combines `release_notes` + `flow_diagnostic` and adds a forward-looking section.

Order of output:

1. **Shipping this cycle** — from `release_notes` (public framing, but include IDs since this is internal).
2. **At risk** — items with `days_in_current_state > 7` OR `state_bounce_count >= 2`. Use the same table format as `flow_diagnostic` Step 2.
3. **Next up** — items in the cycle still in `Todo` or `In Progress`, ordered by priority (Linear priority: `1` Urgent first, then `2` High, `3` Medium, `4` Low, `0` No priority last) then by identifier asc. One line each: `[Type] ID — Title — @assignee — Priority N`.
4. **Bottleneck snapshot** — the Sankey diagram from `flow_diagnostic`.
5. **Executive summary** — 4–6 bullets covering ship-readiness, risks, and bottleneck pattern.

Place the executive summary **last** in roadmap mode (counter-intuitive, but execs scroll to the top diagram, then read the prose under it).

---

## Mode: `deep_dive`

Single issue. Full forensic breakdown.

Produce:

### 1. Header

```
## ENG-572 — Admin redesign: category picker — Bug — @alice — Backlog (18 days)

- Cycle: Cycle 12
- Project: Admin redesign
- Priority: 2 (High)
- Labels: customer, admin
- Parent: ENG-500 — Admin redesign: site customization
```

### 2. Timeline (Mermaid gantt)

Every state transition, with actor visible in the section title. See `mermaid-templates.md`.

### 3. Comment summary

Bullet list of comments in chronological order, each prefixed with date + author. Summarize, don't paste verbatim.

### 4. Linked artifacts

- PRs (with merge status, target branch, reviewer state)
- Commits (sha, subject, author)
- Related Linear issues (sub-issues, blocks/blocked-by relations)
- Document / spec links

### 5. Recommendation

One paragraph. Format:

> **What is blocking this:** <one sentence>.
> **What would unblock it:** <one or two specific actions, with owners if possible>.

Don't recommend "more communication" or "follow up" — be specific (e.g., `Reassign code review from @bob (PTO until 04-29) to @carol or @dave who own this area`).
