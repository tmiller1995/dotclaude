---
name: subagent-nesting-claude-code
description: "Claude Code sub-agents CAN spawn sub-agents (5 deep) since v2.1.172 — docs now confirm it; this config GRANTS Agent to worker/debugger/reviewer/planner, but the orchestrate skill keeps main-context dispatch by choice"
metadata:
  node_type: memory
  type: reference
  originSessionId: cdf80dac-7392-46fd-b1b2-e42e1c067f1f
---

Claude Code **v2.1.172 (2026-06-10)** added nested sub-agent spawning: a sub-agent can spawn its own sub-agents up to **5 levels deep**, and the `Agent` tool is available to sub-agents by default at every depth except 5 (auto-removed there). The official docs (https://code.claude.com/docs/en/sub-agents) now confirm this verbatim — the earlier hedge that "docs still say cannot spawn" is obsolete. Requires **v2.1.172+**; on older builds the `Agent` tool is silently stripped from sub-agents and grants degrade with no error. Forks count toward the depth cap.

**Decision (2026-06-29):** the config now GRANTS the `Agent` tool to `worker`, `debugger`, `reviewer`, and `planner` so they can spawn helper sub-agents. Wording across `skills/orchestrate/SKILL.md`, `agents/worker.md`, and the memory files was corrected from "cannot spawn" to reflect the real capability. The clearest nesting win is the `reviewer` dispatching a verifier per finding so intermediate output never reaches the caller. See [[atomic upstream skills source]] for sync-preservation rules (Agent grants must be KEPT on sync, not stripped).

**Still a deliberate choice (not a limitation):** the `orchestrate` skill keeps top-level dispatching in the MAIN context for context hygiene and phase-gate visibility, and the `worker` files a bug-fix task and STOPS rather than self-dispatching the `debugger` — so the fix decision stays visible at the phase gate. The capability exists; main-context orchestration is preferred wherever intermediate output should stay visible to you and the human.
