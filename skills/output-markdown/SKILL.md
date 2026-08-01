---
name: output-markdown
description: Render existing structured content (writeup, report, summary, analysis, postmortem, RFC, commit summary) as a GitHub-flavored Markdown file with YAML frontmatter and the shared component vocabulary. Trigger when the user asks for Markdown output of content they've already produced or discussed — phrases like "output this in markdown", "render as markdown", "give me a markdown report", "write this up as md", "make this an md artifact", "md doc I can attach to the PR", "summarize as a markdown writeup" — or when a CRISPY skill (ask-questions, research-codebase, design-discussion, structure-outline, create-spec) delegates rendering with `--format=md`. Produces a portable .md file. Do not use this skill to write code that processes Markdown, to parse or transform an existing Markdown file, or to build a Markdown-based application; for HTML output use output-html, and for release notes or roadmaps sourced from Linear use linear-roadmap, which delegates here.
---

# Output: Markdown

This skill renders a polished `.md` file in GitHub-flavored Markdown (GFM). The component vocabulary parallels `output-html` — every component there has a markdown equivalent here, and a caller's render brief can target either format unchanged.

Two invocation modes:

- **CRISPY mode** — invoked by `/ask-questions`, `/research-codebase`, `/design-discussion`, `/structure-outline`, or `/create-spec` with `--format=md`. The caller provides a full render brief with phase, status, ticket, etc. The output lands in the standard `research/{questions,docs,designs,structures,specs}/` directory.
- **Report mode** — invoked directly (e.g., the user says "output this in markdown" or "render this as a markdown report"). The caller provides a title and body content; CRISPY-specific slots are skipped. The output lands in `reports/YYYY-MM-DD-<topic>.md` by default unless the caller specifies a path.

The rendering logic is the same for both — only some slots are absent in Report mode, and the SKIP RULES below name the structural elements to omit when their slot is empty.

## The job in one sentence

Read `assets/template.md`, fill the slot values, render the body sections using the conventions in `references/components.md`, apply the SKIP RULES for any empty optional slots, write the file to disk, and report the path.

## Slot schema

The slot schema is **identical to output-html** — only the rendering differs. This is intentional: one render brief can be consumed by either output skill.

| Slot | CRISPY mode | Report mode | Notes |
| --- | --- | --- | --- |
| `{{TITLE}}` | required | required | Shown as `# <title>` |
| `{{TOPIC}}` | required | required | kebab-case; default filename component |
| `{{REPO}}` | derived | derived | `basename "$(git rev-parse --show-toplevel)"` — empty OK |
| `{{BRANCH}}` | derived | derived | `git branch --show-current` — empty OK |
| `{{DATE}}` | derived | derived | `date '+%Y-%m-%d %H:%M:%S %Z'` |
| `{{BODY}}` | required | required | Numbered `## NN. Title` sections rendered via `references/components.md` |
| `{{PHASE}}` | required | optional | One of `questions`, `research`, `design`, `structure`, `spec`. Omit in Report mode. |
| `{{PHASE_LABEL}}` | required | optional | CRISPY values: `Questions`, `Research`, `Design Discussion`, `Structure Outline`, `Implementation Spec`. Report mode: free-form kind label (e.g., `Status report`, `RFC`). Empty → omit this segment. |
| `{{STATUS}}` | required | optional | Lifecycle status. Empty → skip the status emoji + summary row. |
| `{{STATUS_EMOJI}}` | derived | derived | 📝 (draft) / ✅ (ready-*) / 🟢 (complete). Only used when STATUS is non-empty. |
| `{{TICKET}}` | required | optional | One-line ticket summary or `N/A`. |
| `{{PROMPT_TEXT}}` | required | optional | Originating request / prose subtitle. Empty → skip the `> **Ticket:**` line. |
| `{{META_EXTRA}}` | as needed | as needed | Extra `crispy:` or `report:` YAML keys (indented two spaces, one per line) |
| `{{SUMMARY_EXTRA}}` | as needed | as needed | Extra `| **Key** | Value |` rows for the summary table |

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

Assemble the header blockquote from whichever of its three segments survive, joined
by ` · `. If none survive, drop the line. If both blockquote lines are gone, drop the
blockquote. If the summary table has no rows left and `{{SUMMARY_EXTRA}}` is empty,
drop the table.

Never emit a literal `{{SLOT}}` placeholder. If a required slot is missing from the caller's brief, stop and ask the caller.

### CRISPY status workflow

Same status strings as the HTML output skill. The template renders status as `{{STATUS_EMOJI}} \`{{STATUS}}\``:

Valid CRISPY statuses: `draft`, `ready-for-research`, `ready-for-design`,
`ready-for-structure`, `ready-for-plan`, `ready-for-implementation`, `complete`.

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
  branch: ticket/...
  # phase-specific extras (META_EXTRA):
  research_doc: research/docs/2026-05-13-tenant-isolation.md
  researcher: tylerm
  git_commit: a68526100
  tags: research,codebase,tenancy
---
```

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

Anything else the report needs (`author`, `source`, `tags`, …) goes through `{{META_EXTRA}}` as additional `report:` keys, indented two spaces, one per line.

## Rendering procedure

1. **Read `assets/template.md`** in this skill's folder.

2. **Gather shell-derived slots** in one parallel call (Bash tool):
   - `basename "$(git rev-parse --show-toplevel)"` (empty OK)
   - `git branch --show-current` (empty OK)
   - `date '+%Y-%m-%d %H:%M:%S %Z'`

3. **Substitute slot values.** Replace each `{{SLOT}}` exactly once.

4. **Apply SKIP RULES.** Walk the table above; for each empty optional slot, remove the surrounding structural element.

5. **Verify no placeholders remain.** Search for `{{` — if anything remains, the caller's brief was incomplete; stop and surface the missing slot.

6. **Render the body** using the component conventions in `references/components.md`. Number sections monotonically (`## 01. Title`, `## 02. Title`, ...).

7. **Determine the output path:**
   - **CRISPY mode** — caller provides `research/<phase-dir>/YYYY-MM-DD-<topic>` as the stem; append `.md`.
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

Do **not** rely on:

- Heavy CSS-in-Markdown — that's what `output-html` is for
- Mermaid in places that don't support it — prefer ASCII diagrams in fenced blocks
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
