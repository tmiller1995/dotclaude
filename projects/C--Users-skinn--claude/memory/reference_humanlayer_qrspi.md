---
name: humanlayer-qrspi-status
description: "HumanLayer status as of 2026-11-02: product open-sourced 2026-10-22 (humanlayer/humanlayer, Apache-2.0); portable `rpi` skill is 1.1.0 with a new prose-review step (adopted in user's output skills); phases otherwise unchanged since 2026-10-08"
metadata:
  node_type: memory
  type: reference
  originSessionId: ea1e6bff-266f-4a73-9908-9c95ed4d2576
  modified: 2026-11-03T01:10:27.391Z
---

As of 2026-11-02 (re-checked; prior checks 2026-10-21, 2026-07-31):

- **Open-sourced 2026-10-22:** `github.com/humanlayer/humanlayer` now holds the whole product (desktop app, daemon, CLI, web UI, API, plugins) under Apache-2.0; the old SDK moved to the `legacy` branch / `legacy-final` tag. It contains `apps/riptide-rpi-claude-plugin` (RPI v0.50.0, Linear/Jira-oriented, per-phase skills, older `.humanlayer/tasks/` layout) — **older and divergent from `humanlayer/skills`; nothing to adopt from it**: 26 skills, no agents/hooks/commands, no review phase or model tiers; its extras (orchestrator re-runs build/test/lint and reports automated vs manual separately, CI watch after PR, worktree setup, `ci-commit` hygiene) are already covered by the user's `orchestrate`, `gh-create-pr`, `create-worktree`, `gh-commit`. Outside PRs are gated by a "Vouch" list; self-hosting guides in progress.
- **`humanlayer/skills` `plugins/rpi` is 1.1.0** (bump 2026-11-01). SKILL.md lives at `plugins/rpi/skills/rpi/SKILL.md`. Only real change since 2026-10-08: PR #14 (2026-10-31) added `references/prose.md` (plain-language response style + Orwell's six rules) and a "Review the Document" step — after writing/updating any workflow doc, review against `prose.md` + `show-me.md` to make it shorter and more visual. Agents (locator/analyzer/pattern-finder/web-search-researcher/outline-implementer-agent), per-phase `process.md`, flow menu, `.agents/artifacts/<branch>/NN-` layout, `repos:` frontmatter, and not-committing-artifacts are all unchanged since 2026-10-07/08.
- **Applied 2026-11-02 to user's [[crispy-workflow-adoption]] skills:** shared `skills/output-html/references/prose.md` + a review-before-writing paragraph in `output-html` and `output-markdown` (the single render path every phase uses, so no phase skill needed editing); `QRSPI-WORKFLOW.md` points at rpi 1.1.0. `show-me.md` content was already covered by `visual-guidance.md` (2026-10-21).
- No methodology-changing HumanLayer blog/docs/release note between 2026-10-08 and 2026-11-02. Repo skill set: `rpi`, `show-me`, `visual-pr`, `improve-claude-md`, `narrow-react-prop-types`, `build-iterated-agentic-loop`, `design-control-loop`.
- Earlier context still valid: "Skill Issue: Harness Engineering" (2026-03-12): sub-agents are context firewalls not personas, cheaper models for them, hooks for control flow, CLAUDE.md < 60 lines.
- Cached: `C:/Users/skinn/.claude/research/web/2026-11-02-humanlayer-rpi-*.md` (SKILL.md, prose, show-me, workflow, workflow-choice, implement-outline, iterate-implementation, create-research-questions, create-design-discussion).
