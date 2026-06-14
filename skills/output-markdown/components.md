# Markdown Component Reference

Every component a CRISPY artifact can use in Markdown form. Each one maps 1:1 against a component in `skills/output-html/components.md`; the *semantics* are the same, only the rendering differs. A CRISPY skill produces one render brief and either format can consume it.

Dialect: **GitHub-flavored Markdown (GFM)**. Inline HTML (notably `<details>`/`<summary>`) is allowed where it adds value — most GFM renderers (GitHub, Linear, Notion, VS Code preview) handle it.

## Section structure

### Numbered section header

Sections are numbered monotonically `01`, `02`, `03`... within the artifact.

```markdown
## 04. Design decisions
```

### Section intro (subtitle)

One muted-tone italic line under the section header that previews what's inside.

```markdown
## 02. Summary

_High-level documentation of what was found._
```

### Page-level header

Already emitted by the template — do not duplicate inside body sections.

## Inline elements

### Inline code

```markdown
`path/to/file.cs:123`
```

Embed inside a link when referencing a remote source: `[\`file.cs:42\`](https://github.com/...)`.

### Highlight / emphasis

GFM has no direct equivalent of the HTML `.hl` span. Options, in order of preference:

```markdown
**one specific phrase**             ← use this by default
~~with strikethrough for "we used to do X"~~
<mark>literal highlight</mark>      ← GFM accepts <mark> but many renderers ignore it
```

Default to bold for "the eye should land here." Reserve `<mark>` for places you really need a visual highlight.

### Tags (change kind)

| Change | Markdown | When |
| --- | --- | --- |
| New file | `**NEW**` | adding |
| Modified file | `**MODIFY**` | editing |
| Deleted file | `**DELETE**` | removing |
| Generic category | `` `category-name` `` | non-modifying labels (e.g., Questions phase) |

Example: `**NEW** \`web/src/components/splines/ReticulateButton.tsx\``

### Status badge

Status is rendered in the template header with an emoji + backticked status string:

```markdown
✅ `ready-for-implementation`
```

Emoji choice: 📝 for draft, ✅ for any `ready-*`, 🟢 for `complete`.

### Chips (metric pills)

A space-separated list of backticked `Label: Value` pairs:

```markdown
`Size: ~80 LOC` · `Surfaces: web` · `Behind flag: enable_reticulation`
```

Use `·` as the separator. Inline pairs are easier to scan than a definition list for the chip use case.

## Lists

### Standard lists

```markdown
- Bullet item
- Another item

1. Numbered step
2. Next step
```

### Task checklists (when steps are completable)

```markdown
- [ ] Pending step
- [x] Completed step
```

Use for the "Tests" sub-block in a slice card, or any genuinely actionable checklist.

### Definition lists

GFM has no native definition list. Use a 2-column table:

```markdown
| Term | Definition |
| --- | --- |
| Ring | The hash function's output range... |
| Node | A server bound to a position on the ring |
```

### Blockquote

```markdown
> "A skilled engineer writes questions that force the model to touch all
> relevant parts of the codebase." — Alex Lavaee
```

Use for cited principles. Not for asides — asides should use the callout convention below.

## Code blocks

### Plain code block with file label

The file-label-plus-`<pre>` pattern from HTML maps to a labeled fenced code block:

````markdown
**`web/src/lib/server/reticulate.ts`** · **NEW**

```typescript
export const reticulateSpline = createServerFn({ method: 'POST' })
  .validator(zodValidator(reticulateSchema))
  .handler(async ({ data }) => /* ... */);
```
````

Language hint after the opening fence (`` ```typescript ``) gives GFM's syntax highlighter the cues it needs — no manual span-wrapping required. Use the right hint for the file: `typescript`, `tsx`, `csharp`, `sql`, `python`, `bash`, `yaml`, `json`, `html`, `css`. Use `text` for plain text and `diff` for diffs.

### Diff blocks

```markdown
```diff
- old line
+ new line
  unchanged context
```
```

The `diff` language hint gives `+`/`-` lines the appropriate coloring on GitHub and most other GFM renderers.

### When NOT to use a code block

For 1–3 token identifiers inline in prose, use single backticks. Reserve fenced blocks for multi-line content or single-line signatures where the file label adds value.

## Tables

```markdown
| Location | What's there |
| --- | --- |
| `web/Controllers/Api/SpliceController.cs:123` | Endpoint registration |
| `web/Services/SpliceService.cs:45` | Business logic |
```

Use for ≥3 rows of structured comparison. For 1–2 rows, prefer a list.

## Callouts

GFM does not have a styled callout primitive. Three options:

### GitHub-style alert (preferred when target is GitHub or supports GFM alerts)

```markdown
> [!NOTE]
> Each slice is behind a feature flag (`enable_reticulation`).

> [!WARNING]
> This depends on the database migration in `2026-04-10-add-reticulation-log.sql`
> being deployed first.

> [!CAUTION]
> Tests that mock the database have been blocked in this repo since 2025-Q4.
```

| HTML component | GFM alert |
| --- | --- |
| `.callout` (clay, default) | `> [!NOTE]` |
| `.callout.warn` | `> [!WARNING]` |
| `.callout.bad` | `> [!CAUTION]` |

### Emoji-prefix blockquote (universal fallback)

If the target renderer doesn't support GFM alerts:

```markdown
> ℹ️ Each slice is behind a feature flag (`enable_reticulation`).
> ⚠️ This depends on the database migration being deployed first.
> 🚨 Tests that mock the database have been blocked since 2025-Q4.
```

Default to GFM alerts. Drop to emoji blockquotes only if you know the target won't render alerts.

## Cards

Markdown has no native `.card` container. Use a labeled section under a heading, with horizontal rules to set off the boundary when it would otherwise blur.

### Generic card

```markdown
### Pattern: Server-function with Zod validator

Lives at `web/src/lib/server/createServerFn.ts:15`. Every endpoint in
`web/src/lib/server/` wraps a Zod schema validator.
```

Use `###` for cards inside a numbered section.

### Decision card with contrastive options

```markdown
### Decision: Where should reticulation results be stored?

- [ ] **A.** In-memory map — fastest, lost on restart, fine for ephemeral computation
- [x] **B.** New `reticulation_log` table — durable, auditable, adds an additive migration ✓ **chosen**
- [ ] **C.** Reuse existing `operation_log` — no migration, but couples unrelated domains

**Rationale:** Audit requirement from §3.4 of the design.

**Why not A:** Customers need reticulation history across deployments. · **Why not C:** Operation_log row format is too narrow for the result blob.
```

Notes:
- The chosen option uses a checked checkbox `- [x]` and is suffixed with `✓ **chosen**` so it survives renderers that don't render checkbox state visually.
- Always emit "Rationale" and "Why not" lines for context — same as the HTML version.

### Tradeoffs grid (pros vs cons of one approach)

```markdown
| Pros | Cons |
| --- | --- |
| ✅ Reuses existing pattern | ❌ Requires migration |
| ✅ Auditable in admin UI | ❌ Adds JSONB column — query patterns differ |
```

Use ✅ / ❌ as the pro/con markers so the table works in renderers that don't color cells.

## Vertical-slice cards

The centerpiece of structure-outline and create-spec artifacts. Use `###` heading + sub-sections:

```markdown
### Slice 1 — Mock API + Frontend UI

**Goal:** User sees a "Reticulate" button on the splines list and clicking it shows a success toast with a fake result.

**Files touched:**

- **NEW** `web/src/components/splines/ReticulateButton.tsx`
- **NEW** `web/src/lib/server/reticulate.ts` — returns hardcoded `ReticulationResult`
- **MODIFY** `web/src/routes/(admin)/splines/index.tsx` — add button to row

**Checkpoint:** ✓ Click button in dev → toast displays → no network errors in console.

`Size: ~80 LOC` · `Surfaces: web`
```

Required parts: `### Slice N — Name`, `**Goal:**`, `**Files touched:**` list, `**Checkpoint:** ✓ ...`. Chips and any "Implementation steps" / "Tests" / "Automated verification" / "Manual verification" sub-blocks are optional but conventional (in `create-spec`); the verification sub-blocks render as `- [ ]` checklists.

## Collapsibles

Use inline HTML `<details>` — GFM supports it natively.

```markdown
<details open>
<summary><strong>Endpoint registration</strong> · <code>web/Controllers/Api/</code></summary>

Every endpoint inherits from `BaseApiController` and uses attribute routing.

- `SpliceController.cs:23` — example of a tenant-scoped endpoint

</details>

<details>
<summary><strong>Tenant filtering middleware</strong> · <code>web/Middleware/</code></summary>

Tenant ID is resolved in `TenantResolutionMiddleware.cs:45`...

</details>
```

The blank lines around the inner Markdown matter — without them GFM may not parse the body as Markdown. Set `open` on the first / most important deep dive.

## Recommendation aside

```markdown
> ### 💡 Recommendation
>
> Adopt Option B (new `reticulation_log` table) so the audit requirement is
> satisfied without coupling to `operation_log`.
```

A heading-inside-blockquote pattern. Use at most one per section. Light bulb emoji is the convention.

## Component-selection cheat sheet

| If the content is… | Use… |
| --- | --- |
| The originating ticket | Template's `> **Ticket:**` blockquote (already in header) |
| A bulleted list of facts | `-` list |
| A numbered procedure | `1.` list |
| Actionable items to complete | `- [ ]` checkboxes |
| One file's signatures | `**filepath**` label + fenced code block |
| ≥3 structured rows | pipe table |
| A decision with options | `### Decision: …` + `- [ ]` / `- [x]` options |
| Pros vs cons of one approach | 2-col table with ✅ / ❌ |
| A short "be careful" | `> [!NOTE]` / `> [!WARNING]` / `> [!CAUTION]` |
| A vertical slice | `### Slice N — Name` + Goal/Files/Checkpoint sub-blocks |
| A self-contained sub-topic with a heading | `### …` |
| A 5+ line deep dive that not everyone needs | `<details>` (first one `open`) |
| The "headline" recommendation for a section | `> ### 💡 Recommendation` blockquote |
| Metrics / counts inline | space-separated backticked pairs with `·` |
| An inline file path or identifier | single backticks |
| One phrase to emphasize in prose | `**bold**` |

## What not to do

- **Don't reach for HTML when Markdown would do.** The point of this format is grep-ability and renderer portability. Save HTML for `<details>` and a few other cases where there's no alternative.
- **Don't over-emphasize.** Bolding every phrase teaches the reader nothing stands out. One emphasized phrase per paragraph at most.
- **Don't break the section numbering.** `01`, `02`, `03`, ... monotonic, no skips.
- **Don't mix decision-card formats.** Pick the checkbox-options style (`- [x] B. ...`) and stay consistent — readers learn to recognize the chosen option visually.
- **Don't omit language hints on code blocks.** Even ` ```text ` is better than no hint; renderers can use it to disable highlighting cleanly.
- **Don't emit `{{PLACEHOLDER}}` text.** If a slot is missing, surface it back to the upstream skill rather than writing the literal.
