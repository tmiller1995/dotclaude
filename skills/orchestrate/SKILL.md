---
name: orchestrate
description: Orchestrate sub-agents from the MAIN context to accomplish complex long-horizon tasks without losing coherency. Use when the user wants to orchestrate or coordinate work across sub-agents, delegate or fan out parallel research or implementation, spawn several agents at once, parallelize a large refactor, run a long-horizon multi-step task end to end, or asks for "the orchestrator". Covers the dispatch loop, phase gates, and context-budget discipline. Not for running a single CRISPY phase — use /research-codebase, /design-discussion, /structure-outline or /create-spec for that; not for a one-off codebase question, which a single codebase-locator or codebase-analyzer dispatch answers directly.
---

# Orchestrate (main-context sub-agent orchestration)

You — the **main conversation context** — are the orchestrator. Since Claude Code v2.1.172 sub-agents *can* spawn their own sub-agents (up to 5 deep), but this skill deliberately keeps dispatching in the main context: condensed results stay visible to you and the human, and the phase gates don't get buried below an orchestration line you can't watch. Reach for nesting only when a delegated task itself fans out and its intermediate output should never reach you — e.g. the `reviewer` dispatching a verifier per finding. All top-level dispatching happens here.

Your most important tools are the `Agent` tool for dispatching sub-agents and the built-in task tools (`TaskCreate`, `TaskList`, `TaskGet`, `TaskUpdate`) for tracking work — load the task tools by name via `ToolSearch` before the first call, as they are deferred when many MCP servers are connected.

All non-trivial operations should be delegated to sub-agents. Delegate research and codebase understanding to `codebase-analyzer`, `codebase-locator`, `codebase-pattern-finder`, and `codebase-online-researcher`. Delegate bash commands likely to produce lots of output (`aws` CLI, `gh` CLI, digging through logs) to general-purpose sub-agents.

Use separate sub-agents for separate tasks, and launch them in parallel — but do not delegate multiple tasks that are likely to have significant overlap to separate sub-agents.

## Dispatching sub-agents

Dispatch every agent with the `Agent` tool, setting `subagent_type` to the agent's name and writing a self-contained `prompt` (the agent sees nothing of this conversation except what you put in the prompt). Launch independent agents in a single message so they run concurrently; sub-agents run in the background by default and notify you on completion, so pass `run_in_background: false` only when you need a result before you can continue; continue a running agent with `SendMessage` rather than re-spawning it.

| Agent (`subagent_type`) | Dispatch it to… | Prompt must include |
| --- | --- | --- |
| `codebase-locator` | Find files/components relevant to a feature ("super grep") | What to locate and any known naming hints |
| `codebase-analyzer` | Explain how a specific component works in detail | The component/files in question and what depth is needed |
| `codebase-pattern-finder` | Find existing implementations to model after | The pattern sought and where similar code may live |
| `codebase-online-researcher` | Web research (SerpAPI → Firecrawl pipeline) | The question, desired sources, and required output structure |
| `codebase-research-locator` / `codebase-research-analyzer` | Discover / deep-read local research docs | The research topic or doc paths |
| `planner` | Decompose a spec/feature into ordered tasks via `TaskCreate` | The spec or feature description and any dependency constraints |
| `worker` | Implement the SINGLE highest-priority pending task | Pointer to the task list state; never assign multiple tasks |
| `debugger` | Root-cause an error, test failure, or unexpected behavior | Error message, stack trace, repro steps, files involved |
| `reviewer` | Review a proposed code change for correctness + best practices | The diff or branch to review and any project-specific guidelines |
| `code-simplifier` | Sweep recently changed code for simplification/reuse cleanups | Which files/commits to target |
| `linear-issue-analyzer` | Gather full context on a Linear issue | The issue identifier (e.g. ENG-1234) |
| `sql-server-schema-and-data-analyzer` | Investigate DB schema/data | The question and where connection config lives |
| `playwright-mcp-website-investigator` | Smoke-test a website for console/network/UI issues | The URL and what flows to exercise |

## Worker loop and bug handling

When running the implement phase (planner → workers):

1. Have `planner` decompose the spec into tasks, then dispatch a `worker` per iteration. The worker claims and completes exactly one task, then stops.
2. **Workers deliberately don't self-dispatch the debugger.** Workers have the `Agent` tool, but the orchestrated loop keeps debugger dispatch here so the fix decision stays visible at the phase gate. When a worker stops after filing a bug-fix task, dispatch the `debugger` agent against that task (pass it the evidence the worker logged in the task's metadata), write the debugger's report back to the task via `TaskUpdate` metadata, then resume the worker loop so the fix is picked up first.
3. Parallel workers are fine when tasks touch disjoint files; otherwise run them sequentially.
4. **Phase gates — manual verification (CRITICAL).** Specs from `/create-spec` group tasks into numbered phases, each with an *Automated verification* and a *Manual verification* checklist. When every task in a phase is complete, STOP the worker loop and report to the user in exactly this shape:

   ```
   Phase [N] Complete — Ready for Manual Verification

   Automated verification passed:
   - [command] → [result]

   Please perform the manual verification steps:
   - [step 1]
   - [step 2]
   ```

   Then WAIT. Do not dispatch any task from the next phase until the user explicitly confirms the manual steps passed. NEVER check off a manual verification item yourself — only the user's confirmation advances the gate. If the user reports a manual step failed, treat it as a bug: create a bug-fix task, dispatch the debugger, and re-run the gate.
5. **Worker mismatch reports.** When a worker stops with an Expected / Found / Why-this-matters mismatch in task metadata, surface it to the user verbatim and wait for direction — the divergence may invalidate a design-phase decision, which is not yours or the worker's to re-decide.

## Context Window Management (CRITICAL)

You may be running on a long-context model. **Instruction budget does not scale with context window size** — a 1M-token model still has the same instruction adherence ceiling as a 200K-token model. The "Smart Zone" is not a percentage of the window; it is a hard absolute cap.

**Rules:**
- **Keep your own context under 100,000 tokens.** Past this point, instruction adherence degrades regardless of how much window is left. This is HumanLayer's revised guidance from March 2026 ("Long-Context Isn't the Answer") — replacing the older "40% of window" heuristic.
- **When approaching 100K tokens:** stop, persist progress to disk (research docs, task notes, design artifacts), and hand off to a fresh session.
- **Delegate early, not late.** Every verbose tool output (Bash, file reads, search results) adds context weight. Sub-agents return condensed results, keeping your window lean.
- **Verbose commands go through backpressure.** When you must run a build/test/lint command directly instead of delegating it, run it through the **Bash tool** as `bash ~/.claude/scripts/backpressure.sh <cmd> <args...>` — for example `bash ~/.claude/scripts/backpressure.sh npm test -- --coverage`. Full output lands in a log file and only the exit code plus a 20-line tail enters your context. Pass the wrapped command as separate arguments, not as one quoted string: the script execs `"$@"`, so a quoted string exits 127. Do not run this from PowerShell, where `bash` resolves to the WSL shim rather than Git Bash and fails immediately.
- **Sub-agents are context firewalls, not character roles.** Their job is to isolate context, not to play a persona. Dispatch them when: (1) the task produces lots of tool output you don't want in your window, (2) the task is independent enough to run in parallel, or (3) you want a different model (e.g. haiku for cheap file finding).

## Task Orchestration

- Use `TaskCreate` to record significant units of work as you plan them
- Use `TaskList` to check progress before deciding what to delegate next
- Use `TaskUpdate` to mark tasks `in_progress` when delegating and `completed` when a sub-agent returns success
- For long-horizon work, the task list IS your persistent memory — use it instead of keeping everything in your context

## Rules of Engagement

If the user has already given you a task, proceed with it using this approach rather than re-scoping — the dispatch pattern below applies to any task, not just ones this skill named.

Sometimes sub-agents will take a long time. DO NOT attempt to do the job yourself while waiting for the sub-agent to respond. Instead, use the time to plan out your next steps, or ask the user follow-up questions to clarify the task requirements.

If the user's request matches a CRISPY phase, prefer invoking the corresponding skill rather than doing the phase inline: questions → `/ask-questions`, research → `/research-codebase`, design → `/design-discussion`, structure → `/structure-outline`, plan → `/create-spec`. Implement and review stay in the worker loop above. Skills are lazy-loaded, so each phase gets fresh instruction budget.

If you have not already been explicitly given a task, ask the user what task they would like you to work on — do not assume or begin working on a ticket automatically.
