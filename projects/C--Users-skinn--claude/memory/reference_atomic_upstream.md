---
name: atomic upstream skills source
description: flora131/atomic is the upstream source of user's skills and agents — cloned locally for diff/sync
type: reference
originSessionId: 3a7a217a-db3d-4612-951d-d1edeb23c816
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

- **`orchestrator.md`** — REMOVED 2026-06-12: transformed into the `skills/orchestrate/SKILL.md` skill (sub-agents can't spawn sub-agents — see [[subagent-nesting-claude-code]]). All customizations (HumanLayer Mar 2026 context-window management + CRISPY preference) preserved in the skill. Do NOT re-add an orchestrator AGENT from atomic upstream (backups deleted 2026-06-12 at user request — the skill is now the only copy of the customizations)
- **`worker.md` / `debugger.md` / `reviewer.md`** — `Agent` tool stripped from frontmatter 2026-06-12 (silently unavailable in sub-agents anyway); worker's Bug Handling now logs evidence + stops so the MAIN context dispatches `debugger`. Do not restore `Agent` grants on upstream sync
- **`codebase-locator.md`** — user swapped JS/TS/Python/Go stack hints for C#/.NET + React/TypeScript to match their profile
- **`debugger.md` / `reviewer.md` / `worker.md`** — user added MCP tool allowlist (firecrawl/serpapi/context7/mslearn) and references `testing-anti-patterns` instead of `test-driven-development`

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
- **`codebase-online-researcher.md`** — kept Firecrawl-first (matches search-priority memory).
- **`reviewer.md`** — changed SharePoint -> Linear and stayed LEAN (deliberately NO codegraph wiring, unlike the other codebase agents). Do not add codegraph to reviewer.
- **`codebase-*` agents** (`codebase-analyzer`, `codebase-locator`, `codebase-pattern-finder`, `codebase-research-analyzer`, `codebase-research-locator`) + `worker`/`debugger` — adopted the CodeGraph layer (`mcp__codegraph__*`).

## codegraph MCP server is wired (valid across sessions)

The `codegraph` MCP server is wired in `C:/Users/skinn/.claude.json` (`command: codegraph`, `args: [serve, --mcp]`) — note this is the home-root `.claude.json`, not a file inside `.claude/`. This makes the codegraph-dependent agents above valid in every session; do not treat `mcp__codegraph__*` references as dangling.

## Known dangling reference: `testing-anti-patterns` skill

The `testing-anti-patterns` skill is referenced by `debugger.md`, `reviewer.md`, and `worker.md` frontmatter (and in `debugger.md`/`worker.md` body prose) but is ABSENT from both `C:/Users/skinn/.claude/skills/` and the source `C:/temp/.claude/skills/`. Confirmed it does NOT ship as a plugin skill: not present in `C:/Users/skinn/.claude/plugins/` (marketplaces `claude-code-warp`, `claude-plugins-official`, `gitkraken`; installed plugins csharp-lsp/typescript-lsp/warp/gitkraken-hooks) nor anywhere under `plugins/cache`. This is a documented KNOWN DANGLING reference — the frontmatter refs were intentionally LEFT IN PLACE (not removed) so the agents self-document the intended discipline; the agents fall back to inline guidance when the skill is missing. Resolve by authoring/porting a `testing-anti-patterns` skill (atomic upstream uses `test-driven-development` instead — see "Agent divergence" above), NOT by deleting the refs.
