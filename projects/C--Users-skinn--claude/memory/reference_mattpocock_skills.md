---
name: mattpocock-skills-import
description: "Which mattpocock/skills (MIT, v1.3.2) were imported on 2026-11-21 as editable copies, the edits made, and which were deliberately skipped and why"
metadata:
  node_type: memory
  type: reference
  modified: 2026-11-21T21:02:15.224Z
  originSessionId: 47e52f26-1304-49a8-a16f-d3a101c3c249
---

**Imported 2026-11-21** with `npx skills@latest add mattpocock/skills -g -a claude-code --copy -s <names>`, as copies in `~/.claude/skills/`. The lock lives at `~/.agents/.skill-lock.json`. `npx skills update` would overwrite local edits, so treat the copies as forks.

**Imported:**
- grilling, grill-me, grill-with-docs
- domain-modeling: writes `GLOSSARY.md` and `docs/adr/NNNN-*.md` into repos, and these ARE committed
- codebase-design
- improve-codebase-architecture
- handoff
- diagnosing-bugs

**Wiring edits:**
- `agents/debugger.md` loads diagnosing-bugs for hard bugs. It skips the user-checkpoint and HITL steps because it runs as a sub-agent.
- `create-research` and `create-design-discussion` read `GLOSSARY.md` and ADRs when present.

**Folded in, not imported:** the `pr` skill's Merge danger line is part of the gh-create-pr template ([[crispy-workflow-adoption]]).

**Skipped on purpose (don't re-import without asking):**
- to-spec, to-tickets, triage, wayfinder, implement-spec, setup-matt-pocock-skills: they need a GitHub or GitLab issue tracker, and Linear is out of scope upstream.
- implement, ask-matt: they duplicate the implement skills, orchestrate, and CRISPY routing.
- code-review: collides with the built-in `/code-review`.
- research: writes into the repo, which breaks "artifacts not committed".
- tdd: duplicates worker.md test discipline.
- retro: the user didn't pick it.
- prototype: name clash with a hidden built-in.

Avoid the plugin route (`mattpocock-skills@claude-plugins-official`). It installs all 27 skills read-only, and several would auto-fire against the local reviewer, gh-create-pr, the research agents, and worker.
