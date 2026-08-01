---
name: atomic upstream skills source
description: flora131/atomic is the upstream source of user's skills and agents — cloned locally for diff/sync
type: reference
originSessionId: 3a7a217a-db3d-4612-951d-d1edeb23c816
modified: 2026-08-01T04:20:58.725Z
---
`flora131/atomic` (GitHub) is the upstream source of the user's `.claude/skills/` and `.claude/agents/`. Referenced in Alex Lavaee's "From RPI to QRSPI" blog post (https://alexlavaee.me/blog/from-rpi-to-qrspi/).

- **Local clone**: `C:\GitHub\atomic`
- **Skills dir**: `C:\GitHub\atomic\.agents\skills\` (last sync 2026-04-24 against Atomic v0.5.34, commit `0a40566f`)
- **Agents dir**: `C:\GitHub\atomic\.claude\agents\` (12 agents)
- **Design context file**: `C:\GitHub\atomic\.impeccable.md` (copied to `C:\Users\skinn\.claude\.impeccable.md`)

When upgrading skills from upstream, pull the clone fresh (`git pull` in `C:\GitHub\atomic`) then diff before copying.

## Skills user has customized — DO NOT overwrite from atomic

- **`create-spec`** — customized for CRISPY P (Plan) phase with explicit "spot-check not deep review" framing citing Alex Lavaee
- **`research-codebase`** — customized for CRISPY R (Research) phase with critical "ticket isolation rule" (feature ticket must NOT be passed to sub-agents)
- **`liteparse`** — user has extensions beyond atomic's version (formatting-only drift confirmed 2026-04-24)

## Skills user has that atomic lacks (custom CRISPY/workflow scaffolding)

- `ask-questions`, `design-discussion`, `structure-outline` — Q/D/S phases of CRISPY not in atomic upstream
- `review-codeant` — CodeAnt PR triage workflow
- `testing-anti-patterns` — user swapped this in where atomic uses `test-driven-development` (see debugger/reviewer/worker agents)

## Skills removed from atomic (PR #653, v2.1.1) — keep removed locally

`arrange`, `extract`, `frontend-design`, `normalize`, `onboard`, `teach-impeccable` were consolidated into `layout`/`polish`/`harden`/`impeccable`. Deleted from user's `.claude/skills/` on 2026-04-24. If they reappear, run `node .claude/skills/impeccable/scripts/cleanup-deprecated.mjs`.

## Agent divergence — DO NOT overwrite

- **`orchestrator.md`** — REMOVED 2026-06-12: transformed into the `skills/orchestrate/SKILL.md` skill (orchestration kept in the main context by deliberate choice — see [[subagent-nesting-claude-code]]). All customizations (HumanLayer Mar 2026 context-window management + CRISPY preference) preserved in the skill. Do NOT re-add an orchestrator AGENT from atomic upstream (backups deleted 2026-06-12 at user request — the skill is now the only copy of the customizations)
- **`worker.md` / `debugger.md` / `reviewer.md` / `planner.md`** — `Agent` tool GRANTED in frontmatter 2026-06-29 (nesting works since v2.1.172 — see [[subagent-nesting-claude-code]]) so these agents can spawn helper sub-agents. On upstream sync, KEEP these `Agent` grants and the corrected nesting wording — do NOT strip them. worker's Bug Handling still logs evidence + stops so the MAIN context dispatches `debugger` (a deliberate phase-gate choice, not a capability limit)
- **`codebase-locator.md`** — user swapped JS/TS/Python/Go stack hints for C#/.NET + React/TypeScript to match their profile
- **`debugger.md`** — user added MCP tool allowlist (firecrawl/serpapi/context7/mslearn). reviewer's web-tool allowlist was REMOVED 2026-07-31 (context hygiene — reviewer routes web checks through spawned `codebase-online-researcher`); do not re-add it on sync.

## Preserve-on-sync divergences (2026-05-30 work->personal migration)

A migration brought skills/agents from a WORK config (`C:/temp/.claude`) into this PERSONAL config and stripped ALL Azure DevOps coupling. A future `flora131/atomic` upstream sync MUST NOT silently re-introduce ADO coupling (wit_*/repo_*/pipelines_* MCP tools, WIQL, dev.azure.com / visualstudio.com / vstfs:// parsing, `AB#` and `[Done|Fix|In Progress] #id` commit/PR conventions, org hardcodes like Buya/UsedGuns/Bravo Store/MaxPawn/HubSpot/ConnectionString.Local.config) or clobber these de-ADO'd adaptations. Issues => Linear (`mcp__linear__*`); repos/PRs => GitHub (`gh` CLI or `mcp__github__*`). Branching is TRUNK-BASED (base = `main`, short-lived `feat/`/`fix/`; no develop/release/hotfix Git Flow). Commits carry NO AI attribution (`includeCoAuthoredBy:false`).

Skill-level adaptations to preserve:
- **`output-html`, `output-markdown`** — newly added rendering skills; de-ADO'd. Keep.
- **`gh-commit`** — ported `ado-commit`'s process discipline but DROPPED AI attribution. Replaces `ado-commit` (do not re-add `ado-commit`).
- **`gh-create-pr`** — ported `ado-create-pr` logic re-targeted to `gh` CLI + GitHub MCP + Linear attachments. Replaces `ado-create-pr`.
- **`linear-roadmap`** — adapted from `ado-roadmap` (Linear issues, not WIQL). Replaces `ado-roadmap`.
- **`qa-summary`** — adapted to attach summaries to Linear issues / GitHub PRs (no `wit_*`).
- **`git-branch-namer`** — adapted to Linear ids + trunk-based `main` base.
- **`create-worktree`** — adapted to Linear issues (branch off `main`, runs `codegraph init -i`).
- **`review-codeant`** — gained `references/codeant-interactions.md` + a dispute-learning format. Keep the references file on sync.
- **`QRSPI-WORKFLOW.md`** — workflow doc added at skills root. Keep.
- **SKIPPED:** `frontend-design` and `teach-impeccable` — intentionally NOT migrated (redundant with `impeccable`). Do NOT re-introduce.
- **`impeccable`** — KEPT as-is (no de-ADO needed).

Agent-level adaptations to preserve:
- **`linear-issue-analyzer.md`** — adapted from `azure-devops-analyzer.md`. The ADO analyzer is NOT present in this config; do not re-add it.
- **`codebase-online-researcher.md`** — SerpAPI-first discovery restored 2026-07-31 (SerpAPI discovers → Firecrawl extracts, matching the search-priority memory); absolute cache path `C:/Users/skinn/.claude/research/web/`; `permissionMode: acceptEdits`.
- **codegraph-wired agents** (`codebase-*`, `worker`, `debugger`, `code-simplifier`, `reviewer`, `planner`) — carry ONLY `mcp__codegraph__codegraph_explore` (see below).

## codegraph MCP server surface is explore-ONLY (updated 2026-07-31)

The `codegraph` MCP server is wired in `C:/Users/skinn/.claude.json` (`command: codegraph`, `args: [serve, --mcp]`) — home-root `.claude.json`, not inside `.claude/`. The server's tool surface was consolidated: `DEFAULT_MCP_TOOLS = ['explore']`, so **only `mcp__codegraph__codegraph_explore` exists**. The old names (`codegraph_search`, `codegraph_callers`, `codegraph_callees`, `codegraph_impact`, `codegraph_node`, `codegraph_files`, `codegraph_status`) ARE dangling — all 77 occurrences were purged from the agent fleet on 2026-07-31 (commit `53630b7`). Do NOT re-add them from atomic upstream or old examples; re-enabling extra tools would require `CODEGRAPH_MCP_TOOLS` env config, which is not set.

## 2026-07-31 fleet-wide best-practices overhaul — preserve on sync

Commit `53630b7` rewrote all 14 agents against Anthropic + HumanLayer subagent best practices (net −767 lines). Preserve on any upstream sync: trigger-shaped `description` fields with sibling boundaries, `maxTurns` on every agent, structured output contracts (worker/planner/debugger/code-simplifier), failure-handling blocks, model tiers (locator+research-locator=haiku, debugger/planner/reviewer=opus, rest=sonnet), and the removal of upstream boilerplate (SOLID essays, T-SQL template library, MCP usage examples, fabricated transcripts).

## 2026-07-31 skills best-practices overhaul — preserve on sync

All 15 custom skills (CRISPY five, gh-commit/gh-create-pr/git-branch-namer/create-worktree,
linear-roadmap, orchestrate, output-html/output-markdown, review-codeant, improve-claude-md)
were rewritten against the 2026-07 rubric (`.claude/research/skill-reviews/RUBRIC.md`; plan
docs alongside). Net −188 lines + fixes. Preserve on sync: trigger-shaped descriptions with
sibling boundaries (≤1024 chars, no XML tags), `references/`+`assets/` layout in the output
skills, `gh-commit/references/conventional-commits.md`, `create-worktree/scripts/create-worktree.sh`,
`git-branch-namer/references/trunk-based-branching.md` (renamed from git-flow-standards),
new/expanded `evals/`, and `disable-model-invocation: true` on the five CRISPY skills
(user's choice: phase gates are human-invoked slash commands; skills-not-commands is
deliberate — commands merged into skills per current Claude Code docs).

## `testing-anti-patterns` dangling reference — RESOLVED 2026-07-31

All references were removed (frontmatter `skills:` blocks deleted from debugger/reviewer/worker; create-spec SKILL.md reworded). The intended discipline now lives INLINE: worker.md has a "Test discipline" section (public entry points, specific assertions, mock only process boundaries, never weaken tests). If a `testing-anti-patterns` skill is ever authored, re-wire deliberately — do not assume the old refs should return.
