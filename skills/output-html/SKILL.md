---
name: output-html
description: Render existing structured content (writeup, report, summary, analysis, postmortem, RFC) as a polished, self-contained single-file HTML document using a shared scaffold and component vocabulary. Use when the user asks for HTML output of content they've already produced or discussed (e.g., "output this in HTML", "give me an HTML report", "make this an HTML artifact"), or when a CRISPY skill (ask-questions, research-codebase, design-discussion, create-prd, create-tdd, structure-outline, create-spec) or linear-roadmap delegates rendering. Produces a no-CDN, no-external-dependency .html file. Not for building a new UI component, page, or web application (use impeccable).
---

# Output: HTML

This skill renders a polished, self-contained `.html` file. The design vocabulary is anchored to Thariq Shihipar's [*The Unreasonable Effectiveness of HTML*](https://thariqs.github.io/html-effectiveness/) — system fonts only, every CSS rule inlined, no CDN, no fonts loaded over the network, inline SVG for diagrams.

Two invocation modes are supported:

- **CRISPY mode** — invoked by `/ask-questions`, `/research-codebase`, `/design-discussion`, `/create-prd`, `/create-tdd`, `/structure-outline`, or `/create-spec`. The caller provides a full render brief with phase, status, ticket, etc., plus the full output stem under the task directory `.agents/artifacts/<task>/`.
- **Report mode** — invoked directly (e.g., the user says "output this in HTML" or "render this as an HTML report"). The caller provides a title and body content; CRISPY-specific slots are skipped. The output lands in `reports/YYYY-MM-DD-<topic>.html` by default unless the caller specifies a path.

The rendering logic is the same for both — only some slots are absent in Report mode, and the SKIP RULES below tell you which structural elements to omit when their slot is empty.

## The job in one sentence

Read `assets/template.html`, fill the slot values, render the body sections using the components in `references/components.md`, apply the SKIP RULES for any empty optional slots, write the file to disk, and report the path.

## Slot schema

The same schema serves both modes. CRISPY mode fills all slots; Report mode fills only the required ones plus whatever optional slots make sense.

| Slot | CRISPY mode | Report mode | Notes |
| --- | --- | --- | --- |
| `{{TITLE}}` | required | required | Display title shown in `<h1>` |
| `{{TOPIC}}` | required | required | kebab-case; used in `<title>` and (default) filename |
| `{{REPO}}` | derived | derived | `basename "$(git rev-parse --show-toplevel)"` — if no git repo, use `""` and apply the SKIP rule |
| `{{BRANCH}}` | derived | derived | `git branch --show-current` — same skip behavior if absent |
| `{{DATE}}` | derived | derived | `date '+%Y-%m-%d %H:%M:%S %Z'` |
| `{{BODY}}` | required | required | Numbered `<section>` blocks rendered via `references/components.md` |
| `{{PHASE}}` | required | optional | One of `request`, `questions`, `research`, `design`, `prd`, `tdd`, `structure`, `spec`. Omit in Report mode. |
| `{{PHASE_LABEL}}` | required | optional | Human label for the eyebrow. CRISPY values, matching `PHASE` in order: `Request`, `Questions`, `Research`, `Design Discussion`, `Product Requirements`, `Technical Design`, `Structure Outline`, `Implementation Spec`. In Report mode, set to a free-form subtitle (e.g., `Status report`, `RFC`, `Postmortem`) OR leave empty to skip the eyebrow entirely. |
| `{{STATUS}}` | required | optional | Lifecycle status (see CRISPY status list). Empty → skip the badge & summary cell. |
| `{{STATUS_CLASS}}` | derived | derived | See the CRISPY status table below. Only used when STATUS is non-empty. |
| `{{TICKET}}` | required | optional | One-line ticket summary or `N/A`. Head-only — emitted as `<meta name="crispy:ticket">`, never rendered visibly. |
| `{{PROMPT_LABEL}}` | derived | optional | Label on the `.prompt-box`. `Ticket` in CRISPY mode; in Report mode set to whatever `PROMPT_TEXT` actually is (`Request`, `Context`, `Summary`). |
| `{{PROMPT_TEXT}}` | required | optional | The originating request / ticket / prose subtitle. Empty → skip the entire `.prompt-box`. |
| `{{META_EXTRA}}` | as needed | as needed | Extra `<meta name="crispy:*">` tags (CRISPY) or `<meta name="report:*">` tags (Report). Always emit empty string if none. |
| `{{SUMMARY_EXTRA}}` | as needed | as needed | Extra `<div class="cell">` entries appended to the summary grid. Empty string if none. |

### SKIP RULES (apply after substitution, before writing)

These rules let one template serve both modes cleanly. After you fill the slots, scan for any structural element whose visible content is empty and remove the surrounding wrapper.

| Slot empty | Remove from the rendered HTML |
| --- | --- |
| `{{PHASE_LABEL}}` AND `{{REPO}}` both empty | the entire `<div class="eyebrow">…</div>` |
| `{{PROMPT_TEXT}}` empty | the entire `<div class="prompt-box">…</div>` block |
| `{{STATUS}}` empty | the Status `<div class="cell">` inside `.summary` |
| `{{BRANCH}}` empty | the Branch `<div class="cell">` inside `.summary` |
| `{{DATE}}` empty | the Date `<div class="cell">` inside `.summary` |
| Report mode (no `{{PHASE}}`) | the whole `crispy:*` `<meta>` block — emit `report:*` tags in its place so CRISPY tooling does not match a report |
| Exactly one of `{{PHASE_LABEL}}` / `{{REPO}}` empty | the ` · ` separator in `.eyebrow` (same for `<title>` when `{{PHASE_LABEL}}` is empty) |

If after applying all SKIP rules the `.summary` grid has zero cells AND `{{SUMMARY_EXTRA}}` is also empty, remove the entire `<div class="summary">…</div>` too.

Never emit a literal `{{SLOT}}` placeholder. If a required slot is missing from the caller's brief, stop and ask the caller.

### CRISPY status workflow

Valid `crispy:status` values, in rough progression order. Each CRISPY phase has its own subset.

| Status string | STATUS_CLASS |
| --- | --- |
| `draft` | `draft` |
| `ready-for-research` | `ready` |
| `ready-for-design` | `ready` |
| `ready-for-tdd` | `ready` |
| `ready-for-structure` | `ready` |
| `ready-for-implementation` | `ready` |
| `complete` | `complete` |

In Report mode, you can use any of these or skip STATUS entirely. Custom status strings work too — just map them to one of the three CSS classes (`draft` / `ready` / `complete`) based on which color you want (gold / clay / olive).

### Phase-specific metadata (CRISPY mode)

Downstream CRISPY skills parse these tags, so the field names are a contract. The set below is the established schema; extend it only by adding new keys deliberately, never by renaming or improvising one-off names.

| Field | Used by |
| --- | --- |
| `crispy:phase`, `crispy:status`, `crispy:date`, `crispy:ticket`, `crispy:topic`, `crispy:repo`, `crispy:branch` | Every phase (already in the template — do not duplicate) |
| `crispy:task_dir`, `crispy:flow`, `crispy:repos` | Every phase, passed by the caller in `META_EXTRA`. `task_dir` is `.agents/artifacts/<task>`; `flow` is `design`, `prd-tdd`, `tdd`, `research-only`, or `none` (standalone research); `repos` is comma-separated `<identifier>@<sha>` entries (identifier = `owner/name`, else the repo directory name; sha = full `git rev-parse HEAD`), or `none` |
| `crispy:request_doc`, `crispy:questions_doc`, `crispy:research_doc`, `crispy:design_doc`, `crispy:prd_doc`, `crispy:tdd_doc`, `crispy:structure_doc` | Any phase that cites that document; the value is its `.agents/artifacts/<task>/NN-<type>-<desc>.<ext>` path. `crispy:questions_doc` is `inline` for standalone research that started from an inline question |
| `crispy:ticket_source` | `request` |
| `crispy:breaking_changes_allowed`, `crispy:compatibility_context` | `request`, `questions`, `research` |
| `crispy:researcher`, `crispy:git_commit`, `crispy:tags` | `research` |
| `crispy:research_doc`, `crispy:questions_doc`, `crispy:author`, `crispy:decisions_resolved` | `design` |
| `crispy:request_doc`, `crispy:research_doc`, `crispy:design_doc` (when a design discussion was read) | `prd` |
| `crispy:request_doc`, `crispy:research_doc`, `crispy:prd_doc` (when a PRD was read), `crispy:design_doc` (when a design discussion was read) | `tdd` |
| `crispy:design_doc`, `crispy:research_doc`, `crispy:slice_count` | `structure` |
| `crispy:structure_doc`, `crispy:design_doc`, `crispy:research_doc`, `crispy:author`, `crispy:phase_count` | `spec` |
| `crispy:last_updated`, `crispy:last_updated_by`, `crispy:last_updated_note` | Any phase, when appending follow-up content |

**Consistency rule:** every value you put in `META_EXTRA` that a human reader should see at a glance must also have a matching `.cell` in `SUMMARY_EXTRA`. Internal references like `crispy:git_commit` can stay in head-only.

### Report-mode metadata (optional)

In Report mode you can stamp the file with `<meta name="report:*">` tags for downstream tooling. These replace the `crispy:*` block rather than joining it. Suggested fields:

| Field | Purpose |
| --- | --- |
| `report:kind` | `status-report`, `rfc`, `postmortem`, `analysis`, `release-notes`, etc. |
| `report:author` | Who produced the report |
| `report:source` | Origin (e.g., a PR URL, a meeting note path, a query) |
| `report:tags` | Comma-separated topic tags |

## Rendering procedure

1. **Read `assets/template.html`** in this skill's folder. Copy from `<!DOCTYPE html>` to the end into a new buffer, verbatim and including the whole `<style>` block, rather than linking or importing it — self-contained means *every CSS rule is inlined*. Leave out the comment above `<!DOCTYPE`; it is authoring documentation for skill maintainers, not part of the artifact.

2. **Gather shell-derived slots** in one parallel call (Bash tool):
   - `git rev-parse --show-toplevel` (for repo basename — empty string is OK if not in a repo)
   - `git branch --show-current` (empty string is OK)
   - `date '+%Y-%m-%d %H:%M:%S %Z'`

3. **Render the body** using the component vocabulary in `references/components.md`. The caller specifies which sections to emit and what content goes in each; you translate that into the correct HTML components. Number sections monotonically with `<div class="sec-head"><span class="num">NN</span><h2>...</h2></div>`. For diagrams, code shapes, and other views beside the prose, follow `references/visual-guidance.md`.

4. **Substitute slot values.** Replace *every* occurrence of each `{{SLOT}}` — six slots appear twice by design: `{{PHASE_LABEL}}` and `{{TOPIC}}` in `<title>`, `{{STATUS}}`, `{{DATE}}`, `{{BRANCH}}`, and `{{REPO}}` in both the `<head>` metadata and the visible header. A second occurrence is expected, not an error.

5. **Apply SKIP RULES.** Walk through the table above; for each empty optional slot, remove the wrapping structural element.

6. **Verify before writing.** Scan the finished buffer, body included, for each of these; every hit is a defect to fix, not a warning to note:
   - `{{` — a slot went unfilled. The caller's brief was incomplete; stop and surface which slot.
   - `<link rel="stylesheet"`, `<script src=`, `@import`, `https://` inside `src=` or `href=` on an asset — the file is no longer self-contained.
   - Section numbers out of order or skipping — renumber monotonically from `01`.

7. **Determine the output path:**
   - **CRISPY mode** — caller provides the full stem `.agents/artifacts/<task>/NN-<type>-<desc>`; you append `.html`. Create the task directory if it doesn't exist.
   - **Report mode** — caller provides a path, OR defaults to `reports/YYYY-MM-DD-<topic>.html`. Create the `reports/` directory if it doesn't exist.

8. **Write the file.** If the path already exists and you are appending (a follow-up section, an updated report), read the file first, splice in the new section, update `crispy:last_updated` / `crispy:last_updated_by` / `crispy:last_updated_note` in `<head>`, sync the matching `.summary` cells, and rewrite.

9. **Report back** to the conversation: the file path, a one-sentence summary, and any slots you had to derive yourself (so the caller can audit).

## Component reference

See `references/components.md` for the full catalog: when to use each component, the HTML snippet to paste, and which CSS classes carry meaning. Components include:

- `.eyebrow`, `.sec-head`, `.sec-intro` — section structure
- `.prompt-box`, `.summary` / `.cell` / `.badge` — header card
- `.callout` (default / `.warn` / `.bad`) — inline callouts
- `.card`, `.options` + `.option.chosen`, `.tradeoffs` — decision cards
- `.slice`, `.checkpoint`, `.chips`, `.tag.new` / `.tag.mod` / `.tag.del` — vertical-slice cards
- `<details>` + `<summary>` — collapsible deep dives
- `.file-label` + `<pre>` with `.kw` / `.fn` / `.str` / `.cm` / `.hl` spans — code blocks with palette-aware highlighting
- `<table>` — palette-styled data tables
- `aside.reco` — recommendation callout
- `figure.diagram` + inline `<svg>` + `<figcaption>` — diagrams

`references/visual-guidance.md` covers which view to draw (pseudocode, call tree, component or file tree, flow diagram, contract, focused diff, mockup) and where it goes in each phase's document.

When a pattern is missing from `references/components.md`, adapt an existing component rather than inventing new CSS, so artifacts stay consistent with each other.

## Self-containment invariants

These keep the file rendering correctly offline, anywhere it is opened or pasted. Every artifact meets all of them:

- No `<link rel="stylesheet">` to anything external
- No `<script src="...">` (inline JS only, and only when a component requires it)
- No `@import` in the inline stylesheet
- No Google Fonts, no Tailwind CDN, no charting libraries, no Mermaid
- No image files referenced by external URL (inline SVG only)
- System font stacks via `ui-serif` / `ui-sans-serif` / `ui-monospace` keywords
- All CSS in one `<style>` block in `<head>`
- All JS (if any) inline at the bottom of `<body>`
- All diagrams as inline `<svg>`

## What success looks like

The reader opens the file in a browser (or pastes it into a chat that renders HTML, or drops it in a PR description). It renders correctly the first time, on any machine, offline, in light or dark mode, and prints cleanly. The component vocabulary is consistent with every other artifact rendered through this skill, so the structure is recognizable within a glance.

## What failure looks like

- Slots left as literal `{{PLACEHOLDER}}` text
- A SKIP rule not applied — the page renders an orphan eyebrow / prompt-box / status cell with no content
- A required `<meta>` tag is missing — downstream tooling crashes
- An external resource (font, script, CSS) is referenced — the file is no longer self-contained
