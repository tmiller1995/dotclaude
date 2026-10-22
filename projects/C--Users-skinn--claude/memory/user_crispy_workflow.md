---
name: crispy-workflow-adoption
description: "User's CRISPY workflow (HumanLayer QRSPI/RPI-aligned since 2026-10-21) — flow menu after research, .agents/artifacts task dirs, manual-only phase skills, artifacts not committed"
metadata:
  node_type: memory
  type: user
  originSessionId: ea1e6bff-266f-4a73-9908-9c95ed4d2576
  modified: 2026-10-21T18:54:35.991Z
---

User runs **CRISPY** (their name for HumanLayer's QRSPI/RPI) for non-trivial changes. On 2026-10-21 the user chose to adopt HumanLayer's 2026-10 `rpi` guidance in full; see [[humanlayer-qrspi-status]].

**Flow:** `/ask-questions` (writes `NN-request-*` + `NN-research-questions-*`, 2–7 questions, asks which flow) → `/research-codebase` (reads only the questions doc) → one of: `design` (`/design-discussion`) | `prd-tdd` (`/create-prd` → `/create-tdd`) | `tdd` (`/create-tdd`) | `research-only` → optional `/structure-outline` → optional `/create-spec` → implement via `/orchestrate <task-dir>` (planner + worker loop with phase gates) or directly → review (`reviewer` + `code-simplifier`). Implementation precedence: spec > outline > TDD > PRD > design discussion > research > request.

**Conventions:** artifacts in `.agents/artifacts/<branch-or-slug>/NN-<type>-<desc>.<html|md>` with `repos` metadata; phases update docs in place; artifacts are NOT committed (gh-commit/worker skip `.agents/artifacts/`); `--format=html|md` via output-html/output-markdown.

**User preferences (explicit):** phase skills stay **manual-only** (`disable-model-invocation: true`) — the user invokes each phase; Claude names the next command but never starts it. `/create-spec` kept as an optional step. Worker writes tests for what it implements.

**How to apply:** for a non-trivial implementation request, suggest starting the flow at the right phase and name the command; don't run phases inline or skip alignment phases unprompted.
