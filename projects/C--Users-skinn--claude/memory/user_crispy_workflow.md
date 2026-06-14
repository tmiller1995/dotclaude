---
name: CRISPY workflow adoption
description: User adopted CRISPY (Questions → Research → Design → Structure → Plan → Implement → Review) as replacement for RPI
type: user
originSessionId: 3a7a217a-db3d-4612-951d-d1edeb23c816
---
User has adopted **CRISPY** (also known as QRSPI per Alex Lavaee) as their structured workflow for complex code changes, replacing the older Research-Plan-Implement (RPI) methodology from HumanLayer/Dex Horthy.

**Phases (7):**
1. **Q**uestions — `/ask-questions` skill
2. **R**esearch — `/research-codebase` skill (with ticket-isolation rule)
3. **D**esign Discussion — `/design-discussion` skill (~200-line brain dump)
4. **S**tructure Outline — `/structure-outline` skill (C-header style, vertical slices)
5. **P**lan — `/create-spec` skill (spot-check, not deep review)
6. **I**mplement — typically via `worker` agent or manual
7. **R**eview — via `reviewer` + `code-simplifier` agents

**How to apply:** When the user asks for a non-trivial implementation, prefer suggesting the CRISPY pipeline starting from whichever phase is appropriate. Don't skip alignment phases (Q/R/D/S) — skipping is what caused RPI to fail per the QRSPI analysis.

**Key principle from Alex Lavaee:** "Plans are persuasive artifacts by nature — LLMs are very good at producing text that reads as authoritative." Alignment must happen in Design + Structure, not Plan.

**Provenance (verified 2026-06-12):** CRISPY/QRSPI was announced by Dex Horthy in the talk "Everything We Got Wrong About Research-Plan-Implement" (MLOps.community, 2026-03-24, youtube.com/watch?v=YwZR6tc7qYg). HumanLayer's own implementation lives in `.claude/commands/` of github.com/humanlayer/humanlayer (research_codebase.md, create_plan.md, implement_plan.md) plus a public skills registry at github.com/humanlayer/skills; commercial product is CodeLayer. RPI failure modes that motivated it: instruction budget (~150-200 followable instructions; keep each prompt <40), magic-words control flow (move conditionals into hooks/harness), and the plan-reading illusion (fixed by the Design Discussion phase). Still current as of June 2026; refined by "Long-Context Isn't the Answer" (100k-token absolute context warning), conditional `<important if>` CLAUDE.md blocks, and context forking. HumanLayer's phase letters differ slightly from ours: they include a "sYnthesize" work-tree setup phase; we instead have a formal Review phase.
