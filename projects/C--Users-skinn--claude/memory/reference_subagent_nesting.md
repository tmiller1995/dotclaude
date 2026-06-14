---
name: subagent-nesting-claude-code
description: "Claude Code sub-agents cannot reliably spawn sub-agents — orchestration must live in the main context (skills, not agents); v2.1.172 nominally added nesting but docs/reliability lag"
metadata: 
  node_type: memory
  type: reference
  originSessionId: cdf80dac-7392-46fd-b1b2-e42e1c067f1f
---

Through Claude Code v2.1.171, sub-agents could NOT spawn sub-agents: the `Agent` (formerly `Task`) tool was silently stripped from sub-agent contexts even when listed in frontmatter `tools:`. Failure modes: "tool not available" errors, OOM crashes, or silent self-execution instead of delegation (github.com/anthropics/claude-code issues #4182, #19077, #60763).

v2.1.172 (~2026-06-12) changelog claims nested spawning up to 5 levels, but official docs (https://code.claude.com/docs/en/sub-agents) still state "Subagents cannot spawn other subagents" and recommend: orchestrate from the main conversation via Skills, or chain sub-agents from main.

**Decision (2026-06-12):** user's config standardizes on main-context orchestration — `orchestrator` agent transformed into `skills/orchestrate/SKILL.md`; `Agent` grants stripped from worker/debugger/reviewer; worker files bug-fix tasks and stops so main context dispatches `debugger`. See [[atomic upstream skills source]] for sync-preservation rules. Revisit if nested spawning proves stable and docs confirm it.
