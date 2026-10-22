---
name: research-codebase
description: Document the codebase as it exists by dispatching parallel sub-agents and synthesizing their findings into a research document in the task directory under `.agents/artifacts/`. The Research phase of CRISPY, run after /ask-questions; reads only the research-questions document (or a single inline question for standalone research), never the request or ticket, and sub-agents receive only individual questions. Facts only — choosing what to change belongs to /design-discussion, /create-prd, or /create-tdd. Invoked manually. Accepts `--format=html|md` (default `html`).
argument-hint: "<task directory | research-questions path | research question> [--format=html|md] [flow: <flow>]"
disable-model-invocation: true
---

# Research Codebase (CRISPY R Phase)

Research the codebase by dispatching parallel sub-agents and synthesizing their findings.

The user's input is: **$ARGUMENTS**

This is the **Research (R)** phase of CRISPY. Its document is the factual foundation for the design phases, so it describes what exists — no opinions, recommendations, or implementation suggestions. The design phases depend on it being a neutral map.

## The Ticket Isolation Rule

> **Research reads only the research-questions document. Sub-agents receive individual questions and their scope — never the request, the ticket, or the desired change.**

This rule is what separates CRISPY research from plan-driven research. An agent that knows what is being built starts reporting what the code "should" look like instead of what it does — the "plan-reading illusion" — and those opinions land in the research document as if they were facts.

<example>
Illustrative only.

Bad prompt: "We're adding a new endpoint to reticulate splines — find the existing endpoint registration code."
Good prompt: "Locate the files where HTTP endpoints are registered and routed in this codebase."

The first contaminates the sub-agent's context with opinions about what should exist; the second produces facts about what does exist.
</example>

How the rule applies:

- **Task directory.** The request document and any design documents sit beside the questions document. Leave them unopened — they belong to the design and implementation sessions. When locating files in the directory, go by filename and type.
- **Research-questions document.** Read it in full in the main context; it is your whole task context. Pass sub-agents only individual questions and their pointers.
- **Inline question.** Rephrase it as pure questions about the codebase before spawning anything, dropping phrasing like "I'm trying to build X" or "for a new feature that does Y."
- **Ticket or request passed directly.** Don't read it. Say why in one line, and ask for the research-questions document or suggest `/ask-questions` to create one.

## Steps

1. **Parse arguments.**

    Extract `--format=html|md` (default `html`) and an optional `flow: <flow>` from `$ARGUMENTS`. The remainder is a task directory, an artifact path, or an inline research question. The format picks the output skill in step 8 and the extension `<ext>` (`.html` or `.md`).

2. **Resolve the research scope and task directory.**

    - **Task directory** — use its highest-numbered `NN-research-questions-*` document and name it. If it has none, ask for a research question or suggest `/ask-questions`.
    - **Research-questions path** — use it; its directory is the task directory.
    - **Path to another artifact in a task directory** — resolve the research-questions document from that directory as above, without reading the given file.
    - **Inline question** — this is standalone research. Resolve the task directory: reuse an existing `.agents/artifacts/` directory whose name obviously matches the question or current branch; ask when one looks close but could belong to another task, or several are plausible; otherwise use the current branch name with `/` replaced by `-` when it identifies the task, or a short kebab-case slug from the question on `main`/`master`. State the chosen path.

    **Flow.** Take it from `flow:` in the arguments, else from the questions document's `crispy:flow`. Standalone research has no flow (`none`).

    **Create vs update.** If the task directory already holds a `research` document and the user is iterating or resuming, update it in place (step 11), keeping its path and number; when several match, use the highest-numbered and name it. Otherwise create a new one.

3. **Read the research scope.**

    Read the research-questions document in full in the main context so the decomposition reflects the whole document. Its context pointers and per-question pointers are starting points to hand to sub-agents. You may also read the source files those pointers name, in a targeted way, to frame the decomposition and check findings; leave broad exploration to the sub-agents.

4. **Determine the compatibility posture.**
    - **Inherit first:** if the questions document carries `crispy:breaking_changes_allowed`, adopt it and its `crispy:compatibility_context` verbatim without re-asking. Use the steps below only when the field is absent (standalone research).
    - The user allows breaking changes, public API changes, or cleanup, or says there are no real users or downstream dependencies → `breaking_changes_allowed: true`.
    - The user mentions production users, published APIs, downstream consumers, migration safety, or compatibility requirements → `breaking_changes_allowed: false`.
    - If neither the user's input nor the questions document settles it, ask once via `AskUserQuestion` before decomposing.
    - Carry the posture into the research plan, every sub-agent prompt, the metadata fields, and the "Compatibility context" section.
    - When `true`: document legacy behavior, compatibility shims, optional flags, and public APIs as **current state**, not as constraints future work must preserve (unless the user asks for preservation).
    - When `false`: document public APIs, compatibility-sensitive surfaces, downstream callers, migration constraints, and behavior future work must preserve.

5. **Decompose the questions.**
    - Group the questions into focused research areas: the components, patterns, directories, and connections to investigate. Usually that is 2–6 sub-agents, one per research area; adapt the count to the scope.
    - Track the areas with `TaskCreate`/`TaskUpdate` so every question gets an answer.
    - Record the compatibility posture in the plan so synthesis inherits it.

6. **Spawn parallel sub-agents.**

    Dispatch sub-agents via the `Agent` tool, sending independent dispatches in one message so they run concurrently. Fan out when areas are independent or would flood your context; a question one direct file read answers can be read directly.

    **Codebase:**
    - **codebase-locator** — find WHERE files and components live
    - **codebase-analyzer** — explain HOW specific code works (without critiquing it)
    - **codebase-pattern-finder** — find examples of existing patterns (without evaluating them)

    **Prior artifacts:**
    - **codebase-research-locator** — find documents about the topic in prior task directories under `.agents/artifacts/` and in the legacy `research/` directory. Tell it to exclude the current task directory, because that directory holds the request document.
    - **codebase-research-analyzer** — extract key decisions and constraints from the most relevant of those documents. Pass it only paths the locator returned, and repeat the instruction to exclude the current task directory.

    **External docs:**
    - When the research touches external libraries or services, dispatch **codebase-online-researcher**. Pass today's date as `YYYY-MM-DD` (it uses it for cache filenames and freshness checks) and require links plus source file/line references in its findings so they carry into the document.

    Writing the prompts:
    - Start with locators to find what exists, then run analyzers on the most promising findings.
    - Give each sub-agent one focused, self-contained question scoped to named components or directories — no pronouns and nothing from the request (the Ticket Isolation Rule).
    - Tell each agent what to find, not how to search; each one knows its tools.
    - Remind agents they are documenting, not evaluating or improving.
    - Ask locators and analyzers to report the tests for each component they cover (locations, test types, fixtures, mocks, utilities), or that they found none.
    - Include `breaking_changes_allowed: true` or `false` in each prompt so compatibility-sensitive findings are documented with the right posture. This is a documentation posture, not ticket context, so it is consistent with the Ticket Isolation Rule.

7. **Wait for all sub-agents, then synthesize.**
    - Wait for every sub-agent before synthesizing, so the document reflects the full picture rather than whichever results arrived first.
    - Treat live codebase findings as the source of truth and prior artifacts as supplementary historical context.
    - Connect findings across components with specific file paths and line numbers, and answer each question with concrete evidence.
    - **Open questions.** If a question is still unanswered, do one targeted follow-up investigation and weave its results into the affected sections. Keep any remaining uncertainty explicit in Open questions.
    - **If findings show a question was misframed** (the system works differently than assumed, or the components don't exist where expected), flag it to the user before finalizing, and record it in the Summary and, if unresolved, in Open questions. Report it as a fact about current state, not as a defect to fix.

8. **Prepare the render brief and delegate.**

    Write to `.agents/artifacts/<task>/NN-research-<desc>`, where `NN` is the next available two-digit prefix in the task directory (count every existing `NN-` file of any type; the first file is `01`) and `<desc>` is a short kebab-case description. Pass this full stem without extension to the matching output skill, which appends the extension and creates the directory:
    - `--format=html` → `Skill('output-html')`
    - `--format=md` → `Skill('output-markdown')`

    The output skill reads its template and `components.md` and produces the file. Stay in the conversation — answer any clarification it asks for, then let it write.

    Gather `crispy:repos` first: one `<identifier>@<sha>` entry per repository researched, comma-separated — identifier from `gh repo view --json nameWithOwner -q .nameWithOwner`, else the repo directory name; sha from `git rev-parse HEAD`; `none` when no repository applies.

    #### Slot values

    These slot and `crispy:*` names are the output skills' shared schema; use only these.

    | Slot | Value |
    | --- | --- |
    | `PHASE` | `research` |
    | `PHASE_LABEL` | `Research` |
    | `STATUS` | `complete` |
    | `STATUS_CLASS` | `complete` (HTML); the MD skill derives the matching `STATUS_EMOJI` 🟢 |
    | `TOPIC` | kebab-case topic |
    | `TITLE` | the research topic or inline question, lightly cleaned for a heading |
    | `TICKET` | the questions document's `crispy:ticket` value, or `N/A` |
    | `PROMPT_TEXT` | the questions document's `PROMPT_TEXT`, or the inline question verbatim |
    | `META_EXTRA` | `crispy:researcher`, `crispy:git_commit`, `crispy:tags` (comma-separated topic and component tags), `crispy:breaking_changes_allowed` (`true`/`false`), `crispy:compatibility_context` (one-line posture explanation), `crispy:task_dir`, `crispy:flow` (`none` for standalone), `crispy:repos`, `crispy:questions_doc` (path, or `inline`) |
    | `SUMMARY_EXTRA` | rows: Researcher, Commit (short SHA in `<code>`/backticks), Tags, Flow, Breaking changes (`allowed` / `not allowed`) |

    `REPO`, `BRANCH`, and `DATE` follow the shared slot schema; the output skill derives them from the shell.

    #### Body sections

    Emit numbered sections in this order. Use the collapsible deep-dive component (`<details>` in both formats) for per-component deep dives so readers can collapse what they don't need.

    Current-state views — call trees, contracts, component or file trees, sequence flows — may sit beside the prose they support when they make the structure clearer: Mermaid in Markdown, inline SVG in HTML. Follow `skills/output-html/references/visual-guidance.md` for choosing and placing them.

    **Section 01 — Research questions**
    The questions from the research-questions document as a numbered list, or the inline question verbatim.

    **Section 02 — Compatibility context**
    One short paragraph stating whether breaking changes are allowed (mirrors `crispy:breaking_changes_allowed`). If `true`, note that compatibility shims, optional flags, and legacy/public APIs are documented as current state rather than preservation constraints. If `false`, summarize the compatibility-sensitive surfaces, downstream users and callers, migration constraints, and behavior future work must preserve.

    **Section 03 — Summary**
    A sec-intro line ("High-level documentation of what was found.") then 2–4 paragraphs answering the questions by describing what exists.

    **Section 04 — Detailed findings**
    One collapsible deep dive per component or area. Each deep-dive title states the finding ("Workers restore pending jobs before accepting new work", not "Worker startup"), so the headers alone summarize the research. Each has:
    - One short paragraph describing what exists
    - A list of code references — each a linked inline code reference (`<a href="..."><code>path/to/file.ext:LINE</code></a>` in HTML; `` [`path/to/file.ext:LINE`](url) `` in MD) followed by a one-line description
    - One paragraph on how this component connects to others
    - A tests block: test locations; unit, integration, or end-to-end coverage; fixtures, mocks, and utilities — or "no tests found". Keep tests read separate from checks run: a check claimed as passing cites its command and observed result.
    - The first deep dive set to `open`, so the document isn't a wall of collapsed triangles

    **Section 05 — Code references**
    A 2-column table: Location | What's there. Inline code for the location.

    **Section 06 — Architecture & conventions**
    Prose describing current patterns and design implementations; a table when listing 3+ related patterns.

    **Section 07 — Historical context**
    A sec-intro line ("Relevant insights from prior task directories in `.agents/artifacts/` and the legacy `research/` directory."), then links to the prior documents, grouped by task directory, each with a one-line description.

    **Section 08 — Related research**
    A flat list of related links.

    **Section 09 — Open questions** *(optional — omit if everything was resolved)*
    Prose listing areas that need further investigation.

    For inline code snippets, use the right language hint (MD) or hand-emit the highlighting spans `.kw`/`.fn`/`.str`/`.cm`/`.hl` (HTML) — see the chosen output skill's `components.md`.

9. **Add GitHub permalinks (if applicable).**
    - Check whether you are on the main branch or the commit is pushed: `git branch --show-current` and `git status`
    - If on main or pushed, generate permalinks:
        - Get repo info: `gh repo view --json owner,name`
        - Build links: `https://github.com/{owner}/{repo}/blob/{commit}/{file}#L{line}`
    - Replace local file references with permalinks in the document

10. **Hand off.**
    - Give a concise summary of the findings with key file references, and the saved path.
    - Offer to open the document for review in VS Code, Cursor, or the browser.
    - Mention any open questions; the user can ask you to investigate them, answer them, or rule them out of scope.
    - **Standalone research** stops here and invites follow-up questions.
    - **With a flow**, name the next command, including the task directory and flow, and say it can run here, after compaction, or in a new session:

        | `crispy:flow` | Next |
        | --- | --- |
        | `design` | `/design-discussion .agents/artifacts/<task> flow: design` |
        | `prd-tdd` | `/create-prd .agents/artifacts/<task> flow: prd-tdd` |
        | `tdd` | `/create-tdd .agents/artifacts/<task> flow: tdd` |
        | `research-only` | implement from the research: `/orchestrate .agents/artifacts/<task>`, or directly in this session for a small change |

      Note that the user can also add `/structure-outline .agents/artifacts/<task> flow: <flow>` or go straight to implementation if the research already specifies the task well enough.

    Then wait; the next phase starts only when the user runs it.

11. **Handle follow-up research.**

    Follow-up questions update the same research document in place:
    - Spawn new sub-agents as needed, under the same Ticket Isolation Rule.
    - Weave verified findings into the affected sections, keeping the Summary, Code references, and Open questions in step; add a "Follow-up research — [timestamp]" section only for findings that don't fit an existing one.
    - Update `crispy:last_updated`, `crispy:last_updated_by`, and `crispy:last_updated_note` (frontmatter in MD, `<meta>` in HTML) and sync the visible Summary cells to match.
    - Re-render through the same output skill at the same path.

## Notes

- This phase writes the research document and nothing else, and only inside the task directory, because downstream phases look for artifacts there. Implementation belongs to later phases.
- Research documents are self-contained: include when the research was conducted and link to GitHub for permanent references where possible.

**Metadata consistency** (the machine-readable `crispy:*` fields and the visible Summary cells):
- Emit the full set of `crispy:*` fields every time, because downstream skills parse them, and keep the same field names across all research documents.
- When updating a document, change the machine-readable fields and the matching visible cells together.
- Use snake_case for multi-word field names (e.g., `crispy:last_updated`, `crispy:git_commit`).
