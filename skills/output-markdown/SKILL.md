---
name: output-markdown
description: Render existing structured content (writeup, report, summary, analysis, postmortem, RFC, commit summary) as a GitHub-flavored Markdown file with YAML frontmatter and the shared component vocabulary. Use when the user asks for Markdown output of content they've already produced or discussed (e.g., "output this in markdown", "give me a markdown report", "md doc I can attach to the PR"), or when a CRISPY skill (ask-questions, research-codebase, design-discussion, create-prd, create-tdd, structure-outline, create-spec) delegates rendering with `--format=md`. Produces a portable .md file. Not for writing code that processes, parses, or transforms Markdown, or for building a Markdown-based application. For HTML output use output-html; for release notes or roadmaps sourced from Linear use linear-roadmap, which delegates here.
---

# Output: Markdown

This skill renders a polished `.md` file in GitHub-flavored Markdown (GFM). The component vocabulary parallels `output-html` — every component there has a markdown equivalent here, and a caller's render brief can target either format unchanged.

Two invocation modes:

- **CRISPY mode** — invoked by `/ask-questions`, `/research-codebase`, `/design-discussion`, `/create-prd`, `/create-tdd`, `/structure-outline`, or `/create-spec` with `--format=md`. The caller provides a full render brief with phase, status, ticket, etc., plus the full output stem under the task directory `.agents/artifacts/<task>/`.
- **Report mode** — invoked directly (e.g., the user says "output this in markdown" or "render this as a markdown report"). The caller provides a title and body content; CRISPY-specific slots are skipped. The output lands in `reports/YYYY-MM-DD-<topic>.md` by default unless the caller specifies a path.

The rendering logic is the same for both — only some slots are absent in Report mode, and the SKIP RULES below name the structural elements to omit when their slot is empty.

## The job in one sentence

Read `assets/template.md`, fill the slot values, render the body sections using the conventions in `references/components.md`, apply the SKIP RULES for any empty optional slots, write the file to disk, and report the path.

## Slot schema

The slot schema is **identical to output-html** — only the rendering differs. This is intentional: one render brief can be consumed by either output skill. The one Markdown-only slot, `{{REPOS_LIST}}`, is derived here from `crispy:repos`, so callers never supply it.

| Slot | CRISPY mode | Report mode | Notes |
| --- | --- | --- | --- |
| `{{TITLE}}` | required | required | Shown as `# <title>` |
| `{{TOPIC}}` | required | required | kebab-case; default filename component |
| `{{REPO}}` | derived | derived | `basename "$(git rev-parse --show-toplevel)"` — empty OK |
| `{{BRANCH}}` | derived | derived | `git branch --show-current` — empty OK |
| `{{DATE}}` | derived | derived | `date '+%Y-%m-%d %H:%M:%S %Z'` |
| `{{BODY}}` | required | required | Numbered `## NN. Title` sections rendered via `references/components.md` |
| `{{PHASE}}` | required | optional | One of `request`, `questions`, `research`, `design`, `prd`, `tdd`, `structure`, `spec`. Omit in Report mode. |
| `{{PHASE_LABEL}}` | required | optional | CRISPY values, matching `PHASE` in order: `Request`, `Questions`, `Research`, `Design Discussion`, `Product Requirements`, `Technical Design`, `Structure Outline`, `Implementation Spec`. Report mode: free-form kind label (e.g., `Status report`, `RFC`). Empty → omit this segment. |
| `{{STATUS}}` | required | optional | Lifecycle status. Empty → skip the status emoji + summary row. |
| `{{STATUS_EMOJI}}` | derived | derived | 📝 (draft) / ✅ (ready-*) / 🟢 (complete). Only used when STATUS is non-empty. |
| `{{TICKET}}` | required | optional | One-line ticket summary or `N/A`. |
| `{{PROMPT_TEXT}}` | required | optional | Originating request / prose subtitle. Empty → skip the `> **Ticket:**` line. |
| `{{META_EXTRA}}` | as needed | as needed | Extra `crispy:` or `report:` YAML keys (indented two spaces, one per line) |
| `{{SUMMARY_EXTRA}}` | as needed | as needed | Extra `| **Key** | Value |` rows for the summary table |
| `{{REPOS_LIST}}` | derived | omitted | Top-level `repos:` YAML list built from `crispy:repos` (see the frontmatter schema below); `repos: []` when it is `none` |

### SKIP RULES (apply after substitution, before writing)

These rules let one template serve both modes cleanly. After filling the slots, scan for any structural element whose visible content is empty and remove it.

| Empty slot | Effect on the rendered Markdown |
| --- | --- |
| any `crispy:` / `report:` key | remove that key's line from the frontmatter |
| `{{META_EXTRA}}` | remove the placeholder line entirely — no blank line left behind |
| `{{PHASE_LABEL}}` | drop the `**…**` segment of the header blockquote |
| `{{REPO}}` | drop the `` `…` `` segment of the header blockquote |
| `{{STATUS}}` | drop the emoji + status segment of the blockquote AND the `Status` row |
| `{{PROMPT_TEXT}}` | remove the entire `> **Ticket:** …` line |
| `{{BRANCH}}` | remove the `Branch` row of the summary table |
| `{{DATE}}` | remove the `Date` row of the summary table |
| `{{SUMMARY_EXTRA}}` | remove the placeholder line entirely |
| `{{REPOS_LIST}}` (Report mode) | remove the placeholder line entirely; a report carries a `repos:` list only when the caller explicitly supplies repos for it |

Assemble the header blockquote from whichever of its three segments survive, joined
by ` · `. If none survive, drop the line. If both blockquote lines are gone, drop the
blockquote. If the summary table has no rows left and `{{SUMMARY_EXTRA}}` is empty,
drop the table.

Never emit a literal `{{SLOT}}` placeholder. If a required slot is missing from the caller's brief, stop and ask the caller.

### CRISPY status workflow

Same status strings as the HTML output skill. The template renders status as `{{STATUS_EMOJI}} \`{{STATUS}}\``:

Valid CRISPY statuses: `draft`, `ready-for-research`, `ready-for-design`,
`ready-for-tdd`, `ready-for-structure`, `ready-for-implementation`, `complete`.

| Status prefix | Emoji |
| --- | --- |
| `draft` | 📝 |
| `ready` | ✅ |
| `complete` | 🟢 |

The prefix is the stem of the status string, not the status itself — every `ready-for-*` value matches the `ready` row.

Custom statuses are fine — pick the emoji that matches the "weight" of the state (in-progress, ready, done).

### Frontmatter metadata schema (CRISPY mode)

YAML frontmatter is the markdown equivalent of `<meta name="crispy:*">` tags. Downstream skills parse this — the field names mirror the HTML schema exactly (same names, nested under `crispy:`).

```yaml
---
crispy:
  phase: research
  status: complete
  date: 2026-05-14 09:32:11 EDT
  ticket: ENG-1234 - reticulate splines
  topic: cross-tenant-spline-reticulation
  repo: my-app
  branch: feat/ENG-1234-reticulate-splines
  # common and phase-specific extras (META_EXTRA):
  task_dir: .agents/artifacts/feat-ENG-1234-reticulate-splines
  flow: tdd
  repos: acme/my-app@a685261004c1f0e2b3d4a5b6c7d8e9f0a1b2c3d4
  questions_doc: .agents/artifacts/feat-ENG-1234-reticulate-splines/02-research-questions-spline-reticulation.md
  researcher: tylerm
  git_commit: a685261004c1f0e2b3d4a5b6c7d8e9f0a1b2c3d4
  tags: research,codebase,tenancy
repos:
  - identifier: acme/my-app
    sha: a685261004c1f0e2b3d4a5b6c7d8e9f0a1b2c3d4
---
```

Common keys every CRISPY phase passes in `META_EXTRA`:

- `task_dir` — `.agents/artifacts/<task>`.
- `flow` — `design`, `prd-tdd`, `tdd`, `research-only`, or `none` (standalone research).
- `repos` — comma-separated `<identifier>@<sha>` entries (identifier = `owner/name`, else the repo directory name; sha = full `git rev-parse HEAD`), or `none`.

Doc-link keys — `request_doc`, `questions_doc`, `research_doc`, `design_doc`, `prd_doc`, `tdd_doc`, `structure_doc` — appear on any phase that cites that document and hold its `.agents/artifacts/<task>/NN-<type>-<desc>.<ext>` path; `questions_doc` is `inline` for standalone research that started from an inline question. Phase-specific keys (`ticket_source` on request; `breaking_changes_allowed` and `compatibility_context` on request, questions, and research; the prd and tdd doc links) match the HTML schema table in `output-html/SKILL.md`.

The top-level `repos:` list (`{{REPOS_LIST}}`) sits beside the `crispy:` block, not inside it, in the shape other `rpi`-style tools read. Build it by splitting `crispy.repos` on commas and each entry on its last `@`; when `crispy.repos` is `none`, emit `repos: []`.

**Consistency rule:** every key under `crispy:` that a human reader should see at a glance must also have a row in the summary table at the top of the body. Internal references (`crispy:git_commit`) can stay in frontmatter-only.

### Report-mode frontmatter

Report mode **replaces the whole `crispy:` block** in the template with the block below — it does not edit the CRISPY keys in place, so no empty `phase:` / `status:` / `ticket:` keys can survive:

```yaml
---
report:
  title: {{TITLE}}
  kind: {{PHASE_LABEL}}
  date: {{DATE}}
  topic: {{TOPIC}}
{{META_EXTRA}}
---
```

Anything else the report needs (`author`, `source`, `tags`, …) goes through `{{META_EXTRA}}` as additional `report:` keys, indented two spaces, one per line. The top-level `repos:` list is left out of reports unless the caller explicitly supplies repos for one.

## Rendering procedure

1. **Read `assets/template.md`** in this skill's folder.

2. **Gather shell-derived slots** in one parallel call (Bash tool):
   - `basename "$(git rev-parse --show-toplevel)"` (empty OK)
   - `git branch --show-current` (empty OK)
   - `date '+%Y-%m-%d %H:%M:%S %Z'`

3. **Render the body** using the component conventions in `references/components.md`. Number sections monotonically (`## 01. Title`, `## 02. Title`, ...). For diagrams, code shapes, and other views beside the prose, follow `skills/output-html/references/visual-guidance.md` (shared with output-html).

4. **Substitute slot values.** Replace every occurrence of each `{{SLOT}}` — `{{STATUS}}`, `{{STATUS_EMOJI}}`, `{{REPO}}`, `{{DATE}}`, and `{{BRANCH}}` each appear more than once in the template (across the frontmatter, header blockquote, and summary table) by design.

5. **Apply SKIP RULES.** Walk the table above; for each empty optional slot, remove the surrounding structural element.

6. **Verify no placeholders remain.** Search the finished buffer, body included, for `{{` — if anything remains, the caller's brief was incomplete; stop and surface the missing slot.

7. **Determine the output path:**
   - **CRISPY mode** — caller provides the full stem `.agents/artifacts/<task>/NN-<type>-<desc>`; append `.md`. Create the task directory if it doesn't exist.
   - **Report mode** — caller provides a path, OR defaults to `reports/YYYY-MM-DD-<topic>.md`. Create the `reports/` directory if it doesn't exist.

8. **Write the file.** If the path already exists and the render is an append, read the file first, splice in the new section, update `crispy.last_updated*` / `report.last_updated*` keys in frontmatter, sync the summary table, and rewrite.

9. **Report back** to the conversation: the file path, a one-sentence summary, and any slots derived here rather than supplied by the caller.

## What about GitHub-flavored extensions?

Target dialect: **GitHub-flavored Markdown (GFM)** — the most portable variant across the places these artifacts get pasted: GitHub (PR descriptions, issues), Linear, VS Code preview.

Safe to rely on:

- Pipe-syntax tables
- Fenced code blocks with language hints (`` ```ts ``)
- Task list checkboxes (`- [x] done`)
- Inline HTML — `<details>`, `<summary>`, `<kbd>`, `<sub>`, `<sup>`, basic `<div>`/`<span>` for layout
- Strikethrough (`~~`)
- Footnotes (`[^1]`)
- GFM alerts (`> [!NOTE]`, `> [!WARNING]`, `> [!CAUTION]`)
- Emoji shortcodes (`:warning:`) — but prefer raw emoji characters (✅ ❌ ⚠️) since not every renderer expands shortcodes

Avoid, because support is inconsistent across those targets:

- Heavy CSS-in-Markdown — that's what `output-html` is for
- Mermaid in Report mode, which may be pasted where it doesn't render — prefer ASCII diagrams in fenced blocks there. CRISPY-mode documents may use fenced `mermaid` blocks, because they are read on GitHub and in VS Code, which render them
- Math (`$...$`) — not consistently supported

## Component reference

See `references/components.md` for the catalog: when to use each pattern, the Markdown snippet to paste, and how it maps to the HTML component vocabulary.

## What success looks like

The reader views the file on GitHub, in Linear, or in VS Code preview. It renders correctly with no broken syntax. The frontmatter is valid YAML so downstream tooling can parse `crispy:*` / `report:*` fields. The section numbering and component vocabulary feel familiar.

A second test: the user can grep the file, parse the frontmatter with a YAML library, and extract content with standard text tools. Markdown's plain-text advantage is real — preserve it.

## Before writing, verify

- [ ] Frontmatter starts at line 1 and parses as YAML
- [ ] No `{{` remains anywhere in the file
- [ ] No orphan blockquote line or summary row with an empty value
- [ ] Section numbers run 01, 02, 03… with no gaps
- [ ] Every human-facing frontmatter key has a summary-table row
