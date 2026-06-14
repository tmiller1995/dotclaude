<!--
  CRISPY shared markdown template — parallel artifact to skills/output-html/template.html.

  Every CRISPY skill (ask-questions, research-codebase, design-discussion,
  structure-outline, create-spec) can emit either HTML or Markdown depending
  on the `--format` flag. This is the Markdown scaffold.

  The frontmatter holds machine-readable `crispy:*` keys — downstream skills
  parse them. The visible header (title, ticket blockquote, summary table) is
  the human-readable rendering of those same fields.

  Slots to fill (search-and-replace when writing the artifact):
    {{PHASE}}            questions | research | design | structure | spec
    {{PHASE_LABEL}}      Questions | Research | Design Discussion | Structure Outline | Implementation Spec
    {{STATUS}}           draft | ready-for-research | ready-for-design | ready-for-structure | ready-for-plan | ready-for-implementation | complete
    {{STATUS_EMOJI}}     📝 (draft) | ✅ (ready-*) | 🟢 (complete)
    {{TOPIC}}            kebab-case topic
    {{TITLE}}            human title shown in <h1>
    {{REPO}}             output of: basename "$(git rev-parse --show-toplevel)"
    {{BRANCH}}           output of: git branch --show-current
    {{DATE}}             output of: date '+%Y-%m-%d %H:%M:%S %Z'
    {{TICKET}}           one-line ticket summary (or "N/A")
    {{PROMPT_TEXT}}      the originating ticket body or research query, in prose
    {{META_EXTRA}}       0+ extra YAML keys under `crispy:` — phase-specific
                         (each on its own line, indented two spaces)
    {{SUMMARY_EXTRA}}    0+ extra rows in the summary table — each is `| **Key** | Value |`
    {{BODY}}             phase-specific content — numbered ## sections using components.md
-->
---
crispy:
  phase: {{PHASE}}
  status: {{STATUS}}
  date: {{DATE}}
  ticket: {{TICKET}}
  topic: {{TOPIC}}
  repo: {{REPO}}
  branch: {{BRANCH}}
{{META_EXTRA}}
---

# {{TITLE}}

> **{{PHASE_LABEL}}** · `{{REPO}}` · {{STATUS_EMOJI}} `{{STATUS}}`
>
> **Ticket:** {{PROMPT_TEXT}}

| Field | Value |
| --- | --- |
| **Status** | {{STATUS_EMOJI}} `{{STATUS}}` |
| **Date** | {{DATE}} |
| **Branch** | `{{BRANCH}}` |
{{SUMMARY_EXTRA}}

{{BODY}}
