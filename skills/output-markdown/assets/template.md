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
