---
name: research-codebase
description: Document codebase as-is by spawning parallel sub-agents and synthesizing findings. Use this as the SECOND phase of CRISPY (Questions → RESEARCH → Design → Structure → Plan → Implement → Review). Accepts either a questions artifact from /ask-questions OR a raw research query. CRITICAL rule — feature ticket content must NOT be passed to sub-agents, only the questions themselves. Accepts `--format=html|md` to select output format (default `html`).
argument-hint: "<path to questions file OR research question> [--format=html|md]"
---

# Research Codebase (CRISPY R Phase)

You are tasked with conducting comprehensive research across the codebase by spawning parallel sub-agents and synthesizing their findings.

The user's input is: **$ARGUMENTS**

This is the **Research (R)** phase of CRISPY. Your output becomes the factual foundation for the Design Discussion phase. **Facts only — no opinions, no recommendations, no implementation suggestions.**

## CRITICAL: The Ticket Isolation Rule

The single most important rule in this phase — and what distinguishes CRISPY from RPI:

> **The feature ticket / user intent must NEVER be passed to sub-agents.**

Sub-agents (`codebase-locator`, `codebase-analyzer`, `codebase-pattern-finder`, etc.) should only receive **the research questions themselves**, not the ticket that motivated them. This prevents the "plan-reading illusion" — where sub-agents form premature opinions about what the code "should" look like based on what's being built.

### How to enforce this

- **If `$ARGUMENTS` is a path to a questions file** (from `/ask-questions`): Read the file yourself in the main context. The file has a `## Context` section describing the ticket — this section is for YOU (the main agent synthesizing results). Do NOT pass the Context section to sub-agents. Only pass specific questions from the `## Questions` section.
- **If `$ARGUMENTS` is an inline research query**: Rephrase it as pure questions about the codebase before spawning sub-agents. Strip any phrasing like "I'm trying to build X" or "for a new feature that does Y."
- **When you write sub-agent prompts**, include the question and the relevant scope (file paths, component names to explore) — NEVER include the ticket, feature description, or user intent.
- **In the research document you write**, the Context section can mention the ticket (for humans reading it later). But the research findings themselves must be pure facts about the code as-is.

If you catch yourself about to tell a sub-agent "we're building X, so go find Y" — STOP. Rewrite it as "find Y" without the "we're building X" prefix.

## Steps to follow after receiving the research query:

<EXTREMELY_IMPORTANT>

- OPTIMIZE each research question before dispatching it to a sub-agent: make it self-contained (no pronouns, no references back to the ticket), scope it concretely (name components/directories when known), phrase it as a question about what EXISTS (not what should be built), and give each sub-agent ONE focused question rather than a bundle. Strip any ticket context that leaked in.
- After research is complete and the research artifact(s) are generated, provide an executive summary of the research and path to the research document(s) to the user, and ask if they have any follow-up questions or need clarification.

</EXTREMELY_IMPORTANT>

### Step 0: Parse arguments and pick the output format

Extract `--format=html|md` from `$ARGUMENTS`. Default to `html` when the flag is absent. The remainder of `$ARGUMENTS` (with the flag stripped out) is either a path to a questions file or an inline research query — treat it exactly as before. The chosen format decides which output skill you delegate to in Step 5 and the file extension `<ext>` (`.html` or `.md`) used throughout.

1. **Read any directly mentioned files first:**
    - If the user mentions specific files (tickets, docs, or other notes), read them FULLY first
    - **IMPORTANT**: Use the `readFile` tool WITHOUT limit/offset parameters to read entire files
    - **CRITICAL**: Read these files yourself in the main context before spawning any sub-tasks
    - This ensures you have full context before decomposing the research

2. **Determine the compatibility posture:**
    - **Inherit first:** if the questions artifact carries `crispy:breaking_changes_allowed` (set by `/ask-questions`), adopt it and its `crispy:compatibility_context` verbatim — do NOT re-ask the user. Only fall back to the inference/ask steps below when the field is absent (e.g., inline research queries).
    - Before decomposing the research request, identify whether this project must preserve backward compatibility for real downstream users.
    - If the user explicitly allows breaking changes, public API changes, cleanup, or says there are no real users/downstream dependencies → `breaking_changes_allowed: true`
    - If the user mentions production users, published APIs, downstream consumers, migration safety, or compatibility requirements → `breaking_changes_allowed: false`
    - If the posture is not inferable from the request or the questions artifact, ask the user ONCE via the `AskUserQuestion` tool before continuing.
    - Carry the posture into the research plan, every sub-agent prompt, the `crispy:breaking_changes_allowed` / `crispy:compatibility_context` metadata fields, and the "Compatibility context" body section.
    - When `true`: document legacy behavior, compatibility shims, optional flags, and public APIs as **current state** — NOT as constraints future specs must preserve (unless the user explicitly asks for preservation).
    - When `false`: document public APIs, compatibility-sensitive surfaces, downstream callers, migration constraints, and behavior future work must preserve.

3. **Analyze and decompose the research question:**
    - Break the research question down into composable research areas
    - Take time to ultrathink about the underlying patterns, connections, and architectural implications the user might be seeking
    - Identify specific components, patterns, or concepts to investigate
    - Create a research plan using TodoWrite to track all subtasks
    - Include the compatibility posture in the plan so later synthesis and downstream phases inherit the same constraint
    - Consider which directories, files, or architectural patterns are relevant

4. **Spawn parallel sub-agent tasks:**
    - Create multiple Task agents to research different aspects concurrently
    - We now have specialized agents that know how to do specific research tasks:

    **For codebase research:**
    - Use the **codebase-locator** agent to find WHERE files and components live
    - Use the **codebase-analyzer** agent to understand HOW specific code works (without critiquing it)
    - Use the **codebase-pattern-finder** agent to find examples of existing patterns (without evaluating them)
    - Output directory: `research/docs/`
    - Examples:
        - The database logic is found and can be documented in `research/docs/2024-01-10-database-implementation.<ext>`
        - The authentication flow is found and can be documented in `research/docs/2024-01-11-authentication-flow.<ext>`

    **IMPORTANT**: All agents are documentarians, not critics. They will describe what exists without suggesting improvements or identifying issues.

    **For research directory:**
    - Use the **codebase-research-locator** agent to discover what documents exist about the topic
    - Use the **codebase-research-analyzer** agent to extract key insights from specific documents (only the most relevant ones)

    **For online search:**
    - VERY IMPORTANT: In case you discover external libraries as dependencies, use the **codebase-online-researcher** agent for external documentation and resources
        - The online researcher uses the search pipeline: SerpAPI for discovery (#1) → Firecrawl for extraction (#2), with Context7 (#3) and MSLearn (#4) as direct routes for library-API / Microsoft docs lookups
        - Instruct the agent to return references to code snippets or documentation, PLEASE INCLUDE those references (e.g. source file names, line numbers, etc.)
        - Instruct the agent to return LINKS with their findings and INCLUDE those links in the research document
        - Instruct the agent to check `research/web/` for a fresh cached copy BEFORE fetching, and to persist newly fetched sources there with provenance frontmatter — pass it today's date (`YYYY-MM-DD`) for the cache filenames and the freshness check. Reusing a cached source saves SerpAPI/Firecrawl credits and tokens on repeat research.

    The key is to use these agents intelligently:
    - Start with locator agents to find what exists
    - Then use analyzer agents on the most promising findings to document how they work
    - Run multiple agents in parallel when they're searching for different things
    - Each agent knows its job - just tell it what you're looking for
    - Don't write detailed prompts about HOW to search - the agents already know
    - Remind agents they are documenting, not evaluating or improving
    - Include `breaking_changes_allowed: true` or `breaking_changes_allowed: false` in each sub-agent prompt so compatibility-sensitive findings are documented with the right posture. (This is a documentation posture, not ticket context — it does not violate the Ticket Isolation Rule.)
    - **TICKET ISOLATION**: When writing sub-agent prompts, give them questions and scope, NEVER the feature ticket or user intent. A bad prompt is "we're adding a new endpoint to reticulate splines, find the existing endpoint registration code". A good prompt is "locate the files where HTTP endpoints are registered and routed in this codebase". The first contaminates the sub-agent's context with opinions about what should exist; the second produces pure facts about what does exist.

5. **Wait for all sub-agents to complete and synthesize:**
    - IMPORTANT: Wait for ALL sub-agent tasks to complete before proceeding
    - Compile all sub-agent results (both codebase and research findings)
    - Prioritize live codebase findings as primary source of truth
    - Use research findings as supplementary historical context
    - Connect findings across different components
    - Include specific file paths and line numbers for reference
    - Highlight patterns, connections, and architectural decisions
    - Answer the user's research question with concrete evidence
    - **If findings reveal the original question was misframed** (e.g., the system works differently than assumed, or the components don't exist where expected), flag this to the user before finalizing the document. This is valuable signal — don't bury it.

6. **Prepare the render brief and delegate to the output skill:**

    Follow the directory structure for research documents:

    ```
    research/
    ├── tickets/
    │   ├── YYYY-MM-DD-XXXX-description.<ext>
    ├── docs/
    │   ├── YYYY-MM-DD-topic.<ext>
    ├── notes/
    │   ├── YYYY-MM-DD-meeting.<ext>
    ├── web/
    │   ├── YYYY-MM-DD-topic.md          # cached external sources (provenance frontmatter), written by codebase-online-researcher
    ```

    Naming conventions:
    - `YYYY-MM-DD` is today's date
    - `topic` is a brief kebab-case description of the research topic
    - `meeting` is a brief kebab-case description of the meeting topic
    - `XXXX` is the ticket number (omit if no ticket)
    - `description` is a brief kebab-case description of the research topic
    - Examples:
        - With ticket: `2025-01-08-1478-parent-child-tracking`
        - Without ticket: `2025-01-08-authentication-flow`

    Then invoke the matching output skill via the Skill tool, passing the directory stem (without extension) so the output skill appends the right extension and writes inside `research/`:
    - `--format=html` → `Skill('output-html')`
    - `--format=md` → `Skill('output-markdown')`

    The output skill reads its `template` + `components.md` reference and produces the file. You stay in the conversation — answer any clarifying questions it raises, then let it write. The slot names and slice-card contract below are exactly the ones both output skills declare; do not introduce new slot names.

    #### Slot values

    Fill the output skill's slots with these CRISPY-research values (the slot vocabulary is shared by `output-html` and `output-markdown`):

    | Slot | Value |
    | --- | --- |
    | `PHASE` | `research` |
    | `PHASE_LABEL` | `Research` |
    | `STATUS` | `complete` |
    | `STATUS_CLASS` | `complete` (HTML) / the matching `STATUS_EMOJI` 🟢 is derived by the MD skill) |
    | `TOPIC` | kebab-case topic |
    | `TITLE` | the user's research question, lightly cleaned for a heading |
    | `TICKET` | one-line ticket summary, or `N/A` if no ticket |
    | `PROMPT_TEXT` | the original research query, verbatim |
    | `META_EXTRA` | `crispy:researcher`, `crispy:git_commit`, `crispy:tags` (comma-separated list relevant to the topic + components studied), `crispy:breaking_changes_allowed` (`true`/`false`), `crispy:compatibility_context` (one-line posture explanation) |
    | `SUMMARY_EXTRA` | rows for: Researcher, Commit (short SHA in `<code>`/backticks), Tags, Breaking changes (`allowed` / `not allowed`) |

    `TOPIC`, `TITLE`, `REPO`, `BRANCH`, and `DATE` follow the shared slot schema; the output skill derives `REPO` / `BRANCH` / `DATE` from the shell itself.

    #### Body sections

    Emit numbered sections in this order. Use a collapsible deep-dive component (`<details>` in HTML, `<details>` inline in MD) for any "deep dive on component X" sections so readers can collapse what they don't need.

    **Section 01 — Research question**
    A single paragraph: the original user query, verbatim, in prose.

    **Section 02 — Compatibility context**
    One short paragraph stating whether breaking changes are allowed (mirrors `crispy:breaking_changes_allowed`). If `true`, note that compatibility shims, optional flags, and legacy/public APIs are documented as current state rather than preservation constraints. If `false`, summarize the compatibility-sensitive surfaces, downstream users/callers, migration constraints, and behavior future work must preserve.

    **Section 03 — Summary**
    A sec-intro line ("High-level documentation of what was found.") then 2-4 paragraphs answering the question by describing what exists.

    **Section 04 — Detailed findings**
    One collapsible deep-dive per component / area. Each contains:
    - One short prose paragraph describing what exists
    - A list of code references — each item is a linked inline code reference (`<a href="..."><code>path/to/file.ext:LINE</code></a>` in HTML; `` [`path/to/file.ext:LINE`](url) `` in MD) followed by a one-line description
    - One more paragraph on how this component connects to others
    - Set the first deep-dive to `open` so the artifact isn't a wall of `▸` triangles

    **Section 05 — Code references**
    A 2-column table: Location | What's there. Use inline code for the location.

    **Section 06 — Architecture & conventions**
    Prose describing current patterns and design implementations. Use a table when listing 3+ related patterns.

    **Section 07 — Historical context**
    A sec-intro line ("Relevant insights from the `research/` directory."), then a list of links to prior research docs / notes with a one-line description of each.

    **Section 08 — Related research**
    A flat list of related links.

    **Section 09 — Open questions** *(optional — omit if everything was resolved)*
    Prose listing areas that need further investigation.

    For code snippets shown inline: pick the right language hint (MD) or hand-emit highlighting spans `.kw`/`.fn`/`.str`/`.cm`/`.hl` (HTML) — see the chosen output skill's `components.md` for details.

7. **Add GitHub permalinks (if applicable):**
    - Check if on the main branch or if the commit is pushed: `git branch --show-current` and `git status`
    - If on main or pushed, generate GitHub permalinks:
        - Get repo info: `gh repo view --json owner,name`
        - Create permalinks: `https://github.com/{owner}/{repo}/blob/{commit}/{file}#L{line}`
    - Replace local file references with permalinks in the document

8. **Present findings:**
    - Present a concise summary of findings to the user
    - Include key file references for easy navigation
    - Offer to commit the new artifact via `Skill('gh-commit')` — committed CRISPY artifacts survive worktree teardown and are reviewable in PRs
    - Ask if they have follow-up questions or need clarification

9. **Handle follow-up questions:**

    If the user has follow-up questions, append to the same research document by re-invoking the same output skill in append mode:
    - Update `crispy:last_updated`, `crispy:last_updated_by`, `crispy:last_updated_note` (frontmatter in MD or `<meta>` in HTML, depending on format)
    - Sync the visible Summary row so the visible card matches the machine-readable fields
    - Append a new numbered section: "Follow-up research — [timestamp]" with the new findings
    - Spawn new sub-agents as needed for additional investigation
    - Continue updating the document and syncing

## Important notes:

- Please DO NOT implement anything in this stage, just create the comprehensive research document
- Always use parallel Task agents to maximize efficiency and minimize context usage
- Always run fresh codebase research - never rely solely on existing research documents
- The `research/` directory provides historical context to supplement live findings
- Focus on finding concrete file paths and line numbers for developer reference
- Research documents should be self-contained with all necessary context
- Each sub-agent prompt should be specific and focused on read-only documentation operations
- Document cross-component connections and how systems interact
- Include temporal context (when the research was conducted)
- Link to GitHub when possible for permanent references
- Keep the main agent focused on synthesis, not deep file reading
- Have sub-agents document examples and usage patterns as they exist
- Explore all of research/ directory, not just the research subdirectory
- **CRITICAL**: You and all sub-agents are documentarians, not evaluators
- **REMEMBER**: Document what IS, not what SHOULD BE
- **NO RECOMMENDATIONS**: Only describe the current state of the codebase
- **File reading**: Always read mentioned files FULLY (no limit/offset) before spawning sub-tasks
- **Compatibility posture**: Always determine `breaking_changes_allowed` before decomposing the question. This is a single research-wide posture, not a request to add compatibility flags — it decides whether legacy APIs and shims are documented as preservation constraints or merely as current state.
- **Critical ordering**: Follow the numbered steps exactly
    - ALWAYS parse arguments and pick the format first (step 0)
    - ALWAYS read mentioned files first before spawning sub-tasks (step 1)
    - ALWAYS determine the compatibility posture before decomposing the question (step 2)
    - ALWAYS wait for all sub-agents to complete before synthesizing (step 5)
    - ALWAYS gather metadata before delegating to the output skill (step 6)
    - NEVER let the output skill write with placeholder values — it will halt if any `{{SLOT}}` is unfilled

- **Metadata consistency** (the machine-readable `crispy:*` fields + the visible Summary cells):
    - Always emit the full set of `crispy:*` fields — downstream skills parse them
    - Keep the same field names across all research documents (do not invent new ones ad hoc)
    - Update both the machine-readable fields AND the matching visible cells when adding follow-up research; the visible card and the machine-readable head must stay in sync
    - Use snake_case for multi-word field names (e.g., `crispy:last_updated`, `crispy:git_commit`)
    - The `crispy:tags` value is a comma-separated list relevant to the research topic and components studied

## Final Output

- A collection of research files with comprehensive research findings, properly formatted and linked, ready for consumption to create detailed specifications or design documents.
- IMPORTANT: DO NOT generate any other artifacts or files OUTSIDE of the `research/` directory.
