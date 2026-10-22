---
name: humanlayer-qrspi-status
description: "HumanLayer QRSPI status as of 2026-10-21: phases unchanged; portable `rpi` skill shipped in humanlayer/skills (2026-10-08) with flow menu, optional outline, PRD/TDD; user's CRISPY skills adopted the low-risk refinements only"
metadata:
  node_type: memory
  type: reference
  originSessionId: ea1e6bff-266f-4a73-9908-9c95ed4d2576
  modified: 2026-10-21T17:27:45.659Z
---

As of 2026-10-21 (re-checked; prior check 2026-07-31):

- QRSPI phases unchanged. HumanLayer IDE (paid) ships it; `github.com/humanlayer/humanlayer` deprecated.
- **New 2026-10-08:** `github.com/humanlayer/skills` PR #13 added a portable `rpi` skill (`plugins/rpi/`) — one skill + 5 agents (locator/analyzer/pattern-finder on sonnet, web-search-researcher, outline-implementer) + per-phase `references/<step>/process.md`. Flow menu after research: design discussion | PRD→TDD | TDD | research-only; structure outline optional; artifacts in `.agents/artifacts/<branch>/NN-<type>-<desc>.md` with `repos:[{identifier,sha}]` frontmatter; authors recommend NOT committing artifacts. Repo now 7 skills incl. `show-me`, `visual-pr`, `improve-claude-md` (cosmetic changes only vs user's fork).
- **Applied to user's [[crispy-workflow-adoption]] skills (2026-10-21):** one-decision-at-a-time design interview with recorded rationale, design-system question for frontend work, early-handoff option, in-session/fresh-session handoff note. **Deliberately not adopted (user's call, pending):** flow menu / PRD+TDD, `.agents/artifacts/` layout + NN numbering, not committing artifacts, 2–7 questions (user's evals require 5–10).
- HumanLayer focus since Aug 2026 is "software factories" (videos 2026-08/09). "Skill Issue: Harness Engineering" (2026-03-12): sub-agents are context firewalls not personas, run them on cheaper models, hooks for control flow, CLAUDE.md < 60 lines.
- Cached: `C:/Users/skinn/.claude/research/web/2026-10-21-humanlayer-rpi-workflow-md.md` (and older 2026-07-31-humanlayer-*.md).
