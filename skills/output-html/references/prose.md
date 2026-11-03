# Prose guidance

Shared by `output-html` and `output-markdown`, and applied to every CRISPY document and report before it is written. Adapted from HumanLayer's `rpi` skill (`references/prose.md`, 2026-10-31) and George Orwell's "Politics and the English Language" (1946). A document is read by a person who did not watch the work; it earns its length.

## Style

- Plain language, like one person talking to another. Lead with the point; background, caveats, and long lists come only when they change what the reader does.
- Short sentences in the active voice. Cut every word that can be cut.
- Call things by their real name: the code identifier, the user's own words, or a short description. Never a label coined during the session ("the switch-back note").
- No "it", "this", or "that" unless the referent is obvious; name the thing again instead.
- No stock figures of speech, no jargon where an everyday word exists, no long word where a short one will do.
- Break any rule above sooner than write something awkward.

## Review before writing

Run this pass over the rendered body, keeping the caller's slot values, section order, components, and `crispy:*` fields intact:

1. Cut sentences and sections that do not earn their place; a settled decision needs its outcome and rationale, not its history.
2. Replace dense prose with the smallest view that makes the point (see `visual-guidance.md`), and keep each view beside the short text it supports.
3. Check that headings state the point, so the headings alone summarize the document.
