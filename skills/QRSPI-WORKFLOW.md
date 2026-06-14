# QRSPI Workflow (CRISPY)

A structured alignment-first workflow for building features with AI coding agents. Based on Dex Horthy's (HumanLayer) methodology — front-load alignment before any code is written.

## The Flow

```
/ask-questions  →  /research-codebase  →  /design-discussion  →  /structure-outline  →  /create-spec  →  implement  →  review
```

### 1. Questions (`/ask-questions <feature>`)

**You drive this phase.** The agent helps you articulate what you don't know — converting a vague ticket into targeted technical questions. You'll answer what you already know (so research doesn't waste time re-discovering it) and prioritize what matters most.

**Output:** `research/questions/YYYY-MM-DD-topic.html` — a research brief scoped to your unknowns.

### 2. Research (`/research-codebase`)

The agent investigates your unknowns by spawning parallel sub-agents across the codebase, database, and external docs. It gathers **objective facts only** — no implementation opinions. The feature ticket context is intentionally deferred so the agent maps what exists without forming premature conclusions.

**Output:** `research/docs/YYYY-MM-DD-topic.html` — a factual codebase map.

### 3. Design Discussion (`/design-discussion`)

The agent presents a ~200-line "brain dump" covering what exists, where we're going, and the design crossroads. Every decision uses **contrastive clarification** — 2-3 concrete options with tradeoffs, plus the agent's lean with reasoning. You perform **"brain surgery"**: correcting wrong assumptions, redirecting toward team patterns, adding constraints the code doesn't reveal.

This is the highest-leverage phase. Every wrong assumption caught here is one that won't be embedded in the plan.

**Output:** `research/designs/YYYY-MM-DD-topic.html` — validated decisions with your rationale.

### 4. Structure Outline (`/structure-outline`)

Defines the implementation skeleton: type signatures (like a C header file) and **vertical slices** — end-to-end paths that can each be tested independently. No horizontal layers ("do all DB work, then all API work, then all UI"). Each slice touches all relevant layers and has a concrete checkpoint.

**Output:** `research/structures/YYYY-MM-DD-topic.html` — slices, checkpoints, and file change map.

### 5. Spec (`/create-spec`)

The tactical implementation plan. Because alignment happened upstream, this is a lighter review — spot-check rather than deep audit. The spec automatically discovers and consumes outputs from all prior phases. Remaining open questions use contrastive clarification.

**Output:** `research/specs/YYYY-MM-DD-topic.html` — the implementation plan organized by vertical slices.

All five artifacts can be emitted as either **self-contained HTML** (default) or **GitHub-flavored Markdown** — pass `--format=html` or `--format=md` to any phase command. Each CRISPY skill delegates rendering to one of two output skills: `skills/output-html/` (template + component library) or `skills/output-markdown/` (parallel template + component library). The component vocabulary maps 1:1 between formats — the `.options` + `.option.chosen` decision card in HTML is rendered as `- [x] **B.** … ✓ chosen` checkbox-options in Markdown, and so on. Machine-readable fields (`<meta name="crispy:*">` in HTML, `crispy:` keys under YAML frontmatter in Markdown) carry the same schema for downstream skills to parse.

### 6. Implement

The planner decomposes the spec into parallel tasks following the vertical slice ordering. Workers execute one task at a time. **At each phase boundary the orchestrator stops: automated verification results are reported and the phase's manual verification steps are handed to you — the next phase does not start until you explicitly confirm them.** The reviewer checks the code. QA summary is generated and attached to the related Linear issue. PR is created via the gh-create-pr skill (gh CLI) / GitHub MCP create_pull_request.

### 7. Review

A final quality pass before the PR merges. The **reviewer** agent audits the diff for correctness bugs, and the **code-simplifier** sweeps for reuse, simplification, and efficiency cleanups. Findings can be posted as inline comments on the GitHub PR or applied directly to the working tree. This closes the loop on the CRISPY flow — Questions → Research → Design → Structure → Plan → Implement → Review.

## When to Skip Phases

Not every task needs the full flow:

- **Bug fix with clear repro:** Skip to `/research-codebase` → fix it
- **Small, well-understood change:** `/design-discussion` → `/create-spec` → implement
- **Large feature, unfamiliar area:** Run the full flow — that's what it's built for
- **Performance investigation:** Start with `/ask-questions` to separate what you know from what you need to measure

## Why This Order Matters

Each phase produces an artifact that constrains the next phase, reducing the instruction load per step and preventing the three failure modes that killed simpler workflows:

1. **Instruction budget overflow** — distributed across phases instead of one mega-prompt
2. **Magic words dependency** — each phase triggers correct behavior by default
3. **Plan-reading illusion** — assumptions are surfaced and validated before they're embedded in a plan
