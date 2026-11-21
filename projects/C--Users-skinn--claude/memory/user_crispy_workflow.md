---
name: crispy-workflow-adoption
description: "User's CRISPY workflow: skill names match HumanLayer's /rpi:* one-to-one since 2026-11-21 (create-*/iterate-* pairs, implement-outline/plan, describe-pr, ci-commit); .agents/artifacts task dirs, manual-only phase skills, artifacts not committed"
metadata:
  node_type: memory
  type: user
  modified: 2026-11-21T21:02:08.264Z
  originSessionId: 47e52f26-1304-49a8-a16f-d3a101c3c249
---

User runs **CRISPY** (their name for HumanLayer's QRSPI/RPI) for non-trivial changes. They adopted HumanLayer's `rpi` guidance in full on 2026-10-21. On 2026-11-21 they chose **literal one-to-one skill names** with HumanLayer's open-sourced `/rpi:*` plugin, which reversed the earlier merged create-and-iterate skills. See [[humanlayer-qrspi-status]].

**Flow:**
1. `/create-research-questions`, which writes `NN-request-*` and `NN-research-questions-*`, then `/create-research`.
2. Then one flow:
   - `design` → `/create-design-discussion`
   - `prd-tdd` → `/create-prd`, then `/create-tdd`
   - `tdd` → `/create-tdd`
   - `research-only`
3. Optionally `/create-structure-outline`, then optionally `/create-plan`.
4. `/implement-outline` or `/implement-plan` (the latter covers Oneshot from the request), then review (`reviewer` + `code-simplifier`), then `/describe-pr`.

Each document phase has an `/iterate-*` pair. Post-implementation fixes go through `/iterate-implementation`. `/ci-commit` commits without asking and is used when the user says "commit as you go". `/setup-worktree` copies the task dir, `.env*`, and `CLAUDE.local.md`. Implementation precedence: plan > outline > TDD > PRD > design discussion > research > request.

**Renamed 2026-11-21:**
- ask-questions → create-research-questions
- research-codebase → create-research
- design-discussion → create-design-discussion
- structure-outline → create-structure-outline
- create-spec → create-plan; doc type `spec` → `plan` (legacy `NN-spec-*` is still read as a plan)
- create-worktree → setup-worktree

`orchestrate` is now the worker-loop engine the implement skills call.

**Conventions:**
- Artifacts live in `.agents/artifacts/<branch-or-slug>/NN-<type>-<desc>.<html|md>` with `repos` metadata.
- A `/create-*` skill writes a new document. When the document already exists, it names the `/iterate-*` command instead.
- Artifacts are NOT committed.
- `--format=html|md` renders through output-html or output-markdown.
- PR body template: `skills/gh-create-pr/references/pr-description-template.md` (HumanLayer describe-pr + Matt's Merge danger line).

**User preferences (explicit):** all phase skills are **manual-only** (`disable-model-invocation: true`). The user invokes each phase; Claude names the next command but never starts it. `/create-plan` stays optional. The worker writes tests for what it implements.

**How to apply:** for a non-trivial implementation request, suggest starting the flow at the right phase and name the command. Don't run phases inline or skip alignment phases unprompted. Related: [[mattpocock-skills-import]].
