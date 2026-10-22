# Visual guidance

Shared by `output-html` and `output-markdown`, and cited by the CRISPY phase skills. A view earns its place when the reader would otherwise reconstruct the shape from prose. Pick the smallest view that makes the point, keep only the calls, files, props, states, and boundaries that point needs, and place it directly beside the short text it supports. Most sections need one view or none; a few need two.

## Choosing a view

| The point is… | Use | Example |
| --- | --- | --- |
| Logic or an algorithm | pseudocode | `on(save)` → `if unchanged return cached` → `write` |
| Runtime control flow | call tree | `submitForm` › `createSession` › `persistPrompt` |
| UI structure, state, module boundaries | component tree | `<SessionPage>` › `useSessionEvents()` › `<Toolbar>` |
| File responsibility or a broad refactor | shallow file tree with one-line roles | `src/sessions/  # owns session state` |
| Interaction between components, data flow, a sequence | flow or sequence diagram | User → UI → API → stream back |
| An interface, payload, or table shape | contract or schema | a type, DTO, or column list |
| What changes in a shape that already exists | focused `diff` of that shape | `+ <RunSkillButton />` inside the existing tree |
| A copyable target shape, or code that is mostly new | the whole block | the full new function or type |
| A visual UI, layout, or state comparison too dense for a diagram | one focused HTML mockup | `mockup-<desc>.html` beside the document |

Match a diff's shape to the topic: a component diff for a UI change, a file-tree diff for a layout change, a call-tree diff for a new step in a flow, a pseudocode diff for a control-flow change. Show the whole block instead of a diff when most of it is new or when omitted context would hide ownership or order.

```diff
 submitForm
   createSession
     persistPrompt
+    expandSkillMention
     launchAgent
```

## Which views belong in which phase

- **Research** documents the system as it is: current-state call trees, contracts, component and file trees, and flow diagrams. No diffs or target shapes, because research describes, it doesn't propose.
- **Design discussion and TDD** compare before and after: the current shape beside the proposed one, or a focused diff when the point is what changes. Put a view inside each decision it informs so the options are concrete.
- **Structure outline and spec** show target shapes for new code and focused diffs for changed shapes, inside the slice or phase that makes the change.
- **PRD** stays product-level; use a mockup when a visual choice is being decided, and leave code shapes to the TDD.

## How each view renders

| View | HTML (`output-html`) | Markdown (`output-markdown`) |
| --- | --- | --- |
| Pseudocode, call tree, component tree, file tree | `.file-label` + `<pre>` (label optional) | fenced ` ```text ` block (` ```tsx ` for component trees) |
| Contract or schema | `.file-label` + `<pre>` with highlight spans | fenced block with the language hint |
| Focused diff | `<pre>` with `+`/`-` lines; mark added lines with `.hl` spans | fenced ` ```diff ` block |
| Flow or sequence diagram | `figure.diagram` with inline `<svg>` (see `components.md`) | fenced ` ```mermaid ` block in CRISPY mode; ASCII in a ` ```text ` block in Report mode |
| Mockup or dense visual | separate `mockup-<desc>.html` or `diagram-<desc>.html`, linked by relative path | the same separate HTML file, linked by relative path |

HTML artifacts stay self-contained: no Mermaid, no diagram libraries, no external scripts — draw diagrams as inline SVG. A separate mockup or diagram file follows the same rule and uses the product's real colors, type, spacing, labels, and data, so the reader judges the actual result; make it work on desktop and mobile widths. After saving one, offer to open it for the user.

## Checks before writing

- Each view answers the section's question; cut nodes, files, or props that don't.
- Every path or symbol shown exists in the repo (research) or is named in the plan (design onward).
- Diagrams carry a caption that states the point, so the reader knows what to look for.
