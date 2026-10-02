# CodeRabbit Interaction Reference

Sources: https://docs.coderabbit.ai/reference/review-commands, https://docs.coderabbit.ai/knowledge-base/learnings, and observed CodeRabbit behavior on live PRs (2026-10).

## Mention Handle

Address CodeRabbit as `@coderabbitai`. It also answers unmentioned replies inside its own review threads, but a PR-level comment without the mention is ignored, so start every reply with it for consistency. Replies are typically answered within about a minute; the answer ends with `_You are interacting with an AI system._`.

## Commands

All commands go in a PR-level comment unless noted.

| Purpose | Syntax | Notes |
|---------|--------|-------|
| Incremental review | `@coderabbitai review` | Reviews commits pushed since the last review |
| Full re-review | `@coderabbitai full review` | Re-reviews the whole PR from scratch |
| Fix one finding | `@coderabbitai autofix` as a reply in that thread | Top-level, it processes every unresolved thread — not what this skill wants |
| Resolve all threads | `@coderabbitai resolve` | Resolves **every** CodeRabbit thread without checking; do not use as a dismissal |
| Pause / resume reviews | `@coderabbitai pause`, `@coderabbitai resume` | |
| Show effective config | `@coderabbitai configuration` | |

## Disputes and Learnings

No fixed phrasing is required. Reply in the finding's own thread and explain *why* the finding does not apply — thread replies scope the resulting learning to the relevant file pattern more tightly than PR-level comments. CodeRabbit then either withdraws the finding (often adding a `✏️ Learnings added` block quoting the learning) or argues back; it marks the thread `✅ Review thread resolved.` when it accepts.

- Learnings created while the PR is open apply only to that PR until it merges, then become repo-wide.
- A one-off exception should not become a learning: say in the reply that the reason is specific to this PR.
- A finding containing `Based on learnings:` was driven by an existing learning. If the dismissal contradicts that learning, tell the user it should be edited or deleted at `app.coderabbit.ai/learnings`.
- Learnings apply only to similar code. Repo-wide rules belong in `.coderabbit.yaml` `reviews.path_instructions`, which take precedence over learnings.

## Auto-resolution

When a push implements a finding, CodeRabbit appends `✅ Addressed in commit <sha>` to the comment and resolves the thread itself. A reply like `Fixed in <sha>: <what changed>` on a still-open thread makes CodeRabbit verify the fix and resolve it.
