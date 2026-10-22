---
name: orchestrate
description: Orchestrate sub-agents from the main context to accomplish complex long-horizon tasks without losing coherency. Use when the user wants to orchestrate or coordinate work across sub-agents, delegate or fan out parallel research or implementation, spawn several agents at once, parallelize a large refactor, run a long-horizon multi-step task end to end, or asks for "the orchestrator". Covers the dispatch loop, phase gates, and context-budget discipline, and runs the CRISPY implement step from a `.agents/artifacts/` task directory. Not for running a single CRISPY document phase — use /ask-questions, /research-codebase, /design-discussion, /create-prd, /create-tdd, /structure-outline or /create-spec for that; not for a one-off codebase question, which a single codebase-locator or codebase-analyzer dispatch answers directly.
argument-hint: "[CRISPY task directory or task description] [flow: <flow>]"
---

# Orchestrate (main-context sub-agent orchestration)

You — the **main conversation context** — are the orchestrator. Sub-agents can spawn their own sub-agents (up to 5 deep), but this skill keeps top-level dispatching in the main context: condensed results stay visible to you and the human, and the phase gates don't get buried below an orchestration line you can't watch. Reserve nesting for a delegated task that itself fans out and whose intermediate output should never reach you — e.g. the `reviewer` dispatching a verifier per finding.

Your main tools are the `Agent` tool for dispatching sub-agents and the built-in task tools (`TaskCreate`, `TaskList`, `TaskGet`, `TaskUpdate`) for tracking work. If the task tools are deferred (common when many MCP servers are connected), load them by name via `ToolSearch` before the first call.

Delegate work that can run in parallel, needs isolated context, or is an independent workstream; do simple or single-file work directly. Research and codebase understanding go to `codebase-analyzer`, `codebase-locator`, `codebase-pattern-finder`, and `codebase-online-researcher`. Bash commands likely to produce lots of output (`aws` CLI, `gh` CLI, digging through logs) go to general-purpose sub-agents.

Give separate tasks to separate sub-agents and launch them in parallel, but keep tasks with significant overlap in one sub-agent so two agents don't duplicate or contradict each other's work.

## Dispatching sub-agents

Dispatch every agent with the `Agent` tool, setting `subagent_type` to the agent's name and writing a self-contained `prompt` (the agent sees nothing of this conversation except what you put in the prompt). Launch independent agents in a single message so they run concurrently; sub-agents notify you on completion. Continue a running agent with `SendMessage` rather than re-spawning it.

| Agent (`subagent_type`) | Dispatch it to… | Prompt must include |
| --- | --- | --- |
| `codebase-locator` | Find files/components relevant to a feature ("super grep") | What to locate and any known naming hints |
| `codebase-analyzer` | Explain how a specific component works in detail | The component/files in question and what depth is needed |
| `codebase-pattern-finder` | Find existing implementations to model after | The pattern sought and where similar code may live |
| `codebase-online-researcher` | Web research (SerpAPI → Firecrawl pipeline) | The question, desired sources, and required output structure |
| `codebase-research-locator` / `codebase-research-analyzer` | Discover / deep-read local research docs | The research topic or doc paths |
| `planner` | Decompose a task directory's governing document (or a single doc or feature) into ordered tasks via `TaskCreate` | The task directory (or doc path / feature description), any user instructions that change the agreed result, and dependency constraints |
| `worker` | Implement one pending task | Pointer to the task list state, plus a specific task ID when workers run in parallel; one task per worker |
| `debugger` | Root-cause an error, test failure, or unexpected behavior | Error message, stack trace, repro steps, files involved |
| `reviewer` | Review a proposed code change for correctness + best practices | The diff or branch to review and any project-specific guidelines |
| `code-simplifier` | Sweep recently changed code for simplification/reuse cleanups | Which files/commits to target |
| `linear-issue-analyzer` | Gather full context on a Linear issue | The issue identifier (e.g. ENG-1234) |
| `sql-server-schema-and-data-analyzer` | Investigate DB schema/data | The question and where connection config lives |
| `playwright-mcp-website-investigator` | Smoke-test a website for console/network/UI issues | The URL and what flows to exercise |

## Worker loop and bug handling

When running the implement phase (planner → workers):

1. Start from the CRISPY task directory (`.agents/artifacts/<task>/`) passed as the argument, or resolve it from the current branch name (`/` → `-`) or the request; ask when more than one directory is plausible. Dispatch `planner` with the task directory — it applies the implementation precedence **spec > structure outline > TDD > PRD > design discussion > research > request** and decomposes the governing document's phases (spec phases, else outline slices, else the design scope as one phase), skipping phases already marked ✅ so a new session resumes from the first incomplete one. Then dispatch a `worker` per iteration. The worker claims and completes exactly one task, lists the files it changed, and stops.
2. **Debugger dispatch stays here.** Workers have the `Agent` tool, but the orchestrated loop keeps debugger dispatch in the main context so the fix decision stays visible at the phase gate. When a worker stops after filing a bug-fix task, dispatch the `debugger` agent against that task (pass it the evidence the worker logged in the task's metadata), write the debugger's report back to the task via `TaskUpdate` metadata, then resume the worker loop so the fix is picked up first.
3. **Parallel workers** only for tasks that touch disjoint files, and pass each one a specific task ID so two workers never claim the same task. Otherwise run them sequentially.
4. **Phase gates.** Spec phases (`/create-spec`) and outline slices (`/structure-outline`) each carry an *Automated verification* and a *Manual verification* checklist, and the planner groups tasks by them. With neither document, there is one gate at the end, listing the governing design document's verification expectations. When every task in a phase is complete, confirm its automated verification passed (from the workers' evidence, or by running the commands); a failing check becomes a bug-fix task, not a pass. Then:
   - **No manual checks** in the phase: record progress and commit (below), then continue to the next phase.
   - **Manual checks pending** (the default case): stop the worker loop and report to the user in exactly this shape:

     ```
     Phase [N] Complete — Ready for Manual Verification

     Automated verification passed:
     - [command] → [result]

     Please perform the manual verification steps:
     - [step 1]
     - [step 2]
     ```

     Then wait. No task from the next phase is dispatched until the user confirms the manual steps passed, and only the user checks off a manual verification item — those steps verify what no agent can observe. If the user reports a manual step failed, treat it as a bug: create a bug-fix task, dispatch the debugger, and re-run the gate.
   - **Continuous run on request:** when the user asks to run a group of phases or all of them without pausing, verify the automated checks between phases and keep going, leaving the unconfirmed manual checks pending for the final report.
5. **Commit at the gate.** Workers don't commit: they're sub-agents and can't get the user's go-ahead that `gh-commit` requires. Once the user confirms a phase's manual verification (or, for a phase with no manual checks, once its automated checks pass), commit the phase's changes with `Skill('gh-commit')`, leaving `.agents/artifacts/` out. gh-commit's own confirmation is the user's go-ahead; nothing is committed without it.
6. **Record progress in the document.** At each gate, update the outline or spec in place through the output skill and format it was written with (`Skill('output-html')` or `Skill('output-markdown')`, same stem): check the automated items that passed, check the manual items the user confirmed, and once all of a phase's verification is confirmed, mark its Implementation Overview item and its slice/phase heading ✅. The document is the progress record, so a new session resumes from the first incomplete phase.
7. **Worker mismatch reports.** When a worker stops with an Expected / Found / Why-this-matters mismatch in task metadata, surface it to the user verbatim and wait for direction — the divergence may invalidate a design-phase decision, which is not yours or the worker's to re-decide.
8. **Final report.** When all phases are done, report what changed, the checks run with their results, and any manual verification still pending. Offer to open the updated outline or spec for review in VS Code, Cursor, or the browser.

Between gates, keep the loop moving without checking in; stop for the user only at a phase gate with manual checks, a commit confirmation, a mismatch report, or a step you can't take without them.

### Iterating after implementation

For a bug report or review feedback on work already implemented, read the task directory's documents (same precedence) and the current diff, then reproduce the issue or check the requested change against the code and tests. If the expected behavior is unclear, ask the user one targeted question with a recommended answer. Then create a worker task for the fix that includes a regression test (dispatch the `debugger` first when the cause isn't obvious), update the affected design or outline sections in place when the agreed result changes, and keep the outline's or spec's validation markers accurate — uncheck any item the change invalidates. Commit through the gate rule above.

### "What's next?"

When the user asks what's next or where a task stands, list the task directory's `NN-<type>-*` files and read each one's `crispy:status`, find the current phase from the flow (`crispy:flow`, flow table in `skills/QRSPI-WORKFLOW.md`), and name the next command with the task directory and flow, for example `/create-tdd .agents/artifacts/feat-ENG-123-csv-export flow: prd-tdd`. Name it rather than running it, since the phase skills are manual-only.

## Context Window Management

Instruction adherence degrades past a fixed amount of context, regardless of how large the model's window is — the "Smart Zone" is an absolute cap, not a percentage of the window.

- **Keep your own context under 100,000 tokens.** When approaching that, stop, persist progress to disk (research docs, task notes, design artifacts), and hand off to a fresh session.
- **Delegate early, not late.** Every verbose tool output (Bash, file reads, search results) adds context weight; sub-agents return condensed results, keeping your window lean.
- **Verbose commands go through backpressure.** When you run a build/test/lint command directly instead of delegating it, run it through the **Bash tool** as `bash ~/.claude/scripts/backpressure.sh <cmd> <args...>` — for example `bash ~/.claude/scripts/backpressure.sh npm test -- --coverage`. Full output lands in a log file and only the exit code plus a 20-line tail enters your context. Pass the wrapped command as separate arguments, not as one quoted string: the script execs `"$@"`, so a quoted string exits 127. Run it from the Bash tool, not PowerShell, where `bash` resolves to the WSL shim rather than Git Bash and fails immediately.
- **Sub-agents are context firewalls, not character roles.** Their job is to isolate context, not to play a persona. Dispatch them when: (1) the task produces lots of tool output you don't want in your window, (2) the task is independent enough to run in parallel, or (3) you want a different model (e.g. haiku for cheap file finding).

## Task Orchestration

Outside the planner→worker loop, track your own delegated work with `TaskCreate`/`TaskUpdate`: record significant units of work as you plan them, check `TaskList` before deciding what to delegate next, and mark items `in_progress` when delegating and `completed` when a sub-agent returns success. Inside the loop, the planner creates the tasks and each worker claims its own — don't pre-mark those tasks `in_progress` or add your own items to that list, because workers pick pending tasks from it. Either way, use `TaskList` to check progress; for long-horizon work the task list is your persistent memory, so rely on it instead of keeping everything in your context.

## Rules of Engagement

If the user has already given you a task, proceed with it using this approach rather than re-scoping — the dispatch pattern applies to any task, not just ones this skill named.

While a sub-agent is running, leave its job to it: plan your next steps or ask the user clarifying questions instead of doing the same work in parallel, which would duplicate effort and fill your context.

If the user's request matches a CRISPY document phase, point them to its command rather than doing the phase inline: questions → `/ask-questions`, research → `/research-codebase`, design discussion → `/design-discussion`, product requirements → `/create-prd`, technical design → `/create-tdd`, outline → `/structure-outline`, spec → `/create-spec`. The phase skills are manual-only, so the user runs each one; include the task directory and flow in the command you name. Implement and review stay in the worker loop above, with review done by `reviewer` and `code-simplifier`.

If you have not been given a task, ask the user what they would like you to work on rather than picking up a ticket on your own.
