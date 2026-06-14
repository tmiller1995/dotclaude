# HTML Component Reference

Every component a CRISPY artifact can use. The CSS for every class below already lives in `template.html` — your job when rendering is to pick the right component for the content, not to invent new CSS.

Treat this like a shared design system. If two artifacts both have "design decisions," they should both look like `.card` + `.options` + `.option.chosen`. Consistency is the point.

## Section structure

### Numbered section header

Use for every top-level body section. Sections are numbered monotonically `01`, `02`, `03`... within the artifact.

```html
<section>
  <div class="sec-head"><span class="num">04</span><h2>Design decisions</h2></div>
  <!-- content -->
</section>
```

### Section intro (subtitle)

Optional. One muted-gray line under the section header that previews what's inside. Skip for short sections.

```html
<p class="sec-intro">High-level documentation of what was found.</p>
```

### Page-level eyebrow

Already emitted by the template's header — do not duplicate inside body sections.

## Header card components

These are already wired through template slots; you do not re-emit them by hand. Listed here for reference so you know what `PROMPT_TEXT`, `SUMMARY_EXTRA`, and the status badge produce.

| Component | Slot | Visual |
| --- | --- | --- |
| `.eyebrow` | derived from `PHASE_LABEL`/`REPO` | Tiny uppercase tracker above the title |
| `<h1>` | `TITLE` | Serif display heading |
| `.prompt-box` | `PROMPT_TEXT` | Clay-accented box containing the originating ticket |
| `.summary` `.cell` | base cells + `SUMMARY_EXTRA` | Grid of key/value chips below the prompt |
| `.badge.status-*` | derived from `STATUS_CLASS` | Pill showing the artifact's lifecycle state |

## Inline elements

### Inline code

```html
<code>path/to/file.cs:123</code>
```

Use for file paths, identifiers, line refs. Embed inside `<a>` when linking: `<a href="…"><code>file.cs:42</code></a>`.

### Highlight span

```html
This explanation calls out <span class="hl">one specific phrase</span> in body text.
```

Clay-background highlight on inline prose. Use sparingly — for the one phrase per paragraph that you want the eye to land on.

### Tags (change kind)

```html
<span class="tag new">NEW</span>
<span class="tag mod">MODIFY</span>
<span class="tag del">DELETE</span>
```

Use in file-inventory tables, slice file lists, and `file-label` rows. The plain `<span class="tag">` (no modifier) is the muted default — fine for category labels in the Questions phase (`<span class="tag">data-model</span>`).

### Status badge

```html
<span class="badge status-ready">ready-for-implementation</span>
```

Already in the template header. If you re-render the badge inline (e.g., in an updated `.cell`), match `STATUS_CLASS` to one of `draft` / `ready` / `complete`.

### Chips (metric pills)

```html
<div class="chips">
  <span class="chip">Size: <strong>~80 LOC</strong></span>
  <span class="chip">Surfaces: <strong>web</strong></span>
  <span class="chip">Behind flag: <strong>enable_reticulation</strong></span>
</div>
```

Inline metric pills, typically inside a `.slice` card. Use `<strong>` for the value so it visually outweighs the label.

## Lists

### Standard lists

```html
<ul>
  <li>Bullet item</li>
</ul>

<ol>
  <li>Numbered step</li>
</ol>
```

### Definition lists (FAQ-style)

```html
<dl>
  <dt>Term</dt>
  <dd>Definition.</dd>
</dl>
```

The template does not style `<dl>` heavily — body text scale. Use semantically for term/definition pairs.

### Blockquote

```html
<blockquote>
  "A skilled engineer writes questions that force the model to touch all relevant
  parts of the codebase." — Alex Lavaee
</blockquote>
```

Clay-accented left bar, muted body. Use for cited principles, not for asides — asides should use `.callout` instead.

## Code blocks

### Plain code block

```html
<div class="file-label">web/src/lib/server/reticulate.ts &nbsp;·&nbsp; <span class="tag new">NEW</span></div>
<pre><span class="kw">export const</span> <span class="fn">reticulateSpline</span> = <span class="fn">createServerFn</span>({ method: <span class="str">'POST'</span> });</pre>
```

The `.file-label` above the `<pre>` is part of the component — emit them together. Inside `<pre>`, hand-emit highlighting spans:

| Class | Use for | Example |
| --- | --- | --- |
| `.kw` | keywords | `<span class="kw">export const</span>` |
| `.fn` | function names / identifiers | `<span class="fn">reticulateSpline</span>` |
| `.str` | string literals | `<span class="str">'POST'</span>` |
| `.cm` | comments | `<span class="cm">// note: ...</span>` |
| `.hl` | visually-emphasized region | `<span class="hl">deprecated</span>` |

The template's palette renders these in Thariq's clay/gold/olive/gray scheme automatically. **Do not** import a syntax-highlighter library — handwriting the spans is the convention.

### When NOT to use a code block

For 1–3 token identifiers inline in prose, use `<code>...</code>`. Reserve `<pre>` for multiline snippets or single-line signatures where a `.file-label` adds value.

## Tables

```html
<table>
  <thead>
    <tr><th>Location</th><th>What's there</th></tr>
  </thead>
  <tbody>
    <tr><td><code>web/Controllers/Api/SpliceController.cs:123</code></td><td>Endpoint registration</td></tr>
  </tbody>
</table>
```

Use for ≥3 rows of structured comparison. For 1–2 rows, prefer a `<ul>` or inline prose — a table for two items looks heavier than it needs to.

## Callouts

### Default callout (clay)

```html
<div class="callout">
  Each slice is behind a feature flag (<code>enable_reticulation</code>). Disabling
  it hides the new UI and disables the server function.
</div>
```

For neutral context: rollback strategy, "for the human, not sub-agents", caveats.

### Warning callout

```html
<div class="callout warn">
  This depends on the database migration in <code>2026-04-10-add-reticulation-log.sql</code>
  being deployed first.
</div>
```

For "be careful" — gold left bar.

### Bad / blocking callout

```html
<div class="callout bad">
  Tests that mock the database have been blocked in this repo since 2025-Q4.
  Use the in-memory store helper instead.
</div>
```

For "this would break something." Rust-red left bar.

## Cards

### Generic card

```html
<div class="card">
  <h3>Pattern: Server-function with Zod validator</h3>
  <p>Lives at <code>web/src/lib/server/createServerFn.ts:15</code>. Every endpoint
     in <code>web/src/lib/server/</code> wraps a Zod schema validator.</p>
</div>
```

A neutral container for a single self-contained idea. Equivalent to "a section that doesn't deserve its own numbered header."

### Decision card with contrastive options

```html
<div class="card">
  <h3>Decision: Where should reticulation results be stored?</h3>
  <div class="options">
    <div class="option">
      <span class="opt-label">A</span> In-memory map — fastest, lost on restart, fine for ephemeral computation
    </div>
    <div class="option chosen">
      <span class="opt-label">B</span> New <code>reticulation_log</code> table — durable, auditable, adds an additive migration
    </div>
    <div class="option">
      <span class="opt-label">C</span> Reuse existing <code>operation_log</code> — no migration, but couples unrelated domains
    </div>
  </div>
  <p><strong>Rationale:</strong> Audit requirement from §3.4 of the design.</p>
  <p><strong>Why not A:</strong> Customers need reticulation history across deployments. &nbsp;·&nbsp;
     <strong>Why not C:</strong> Operation_log row format is too narrow for the result blob.</p>
</div>
```

This is the canonical shape for every architecture decision and every open question. The `.option.chosen` class auto-appends "✓ chosen" with the clay accent, so the chosen one stands out without an extra label.

### Tradeoffs grid (pros vs cons of one approach)

When the comparison is two-sided (not A vs B vs C, but "what we gain vs what we give up"), use the grid:

```html
<div class="tradeoffs">
  <div class="row head"><div class="cell">Pros</div><div class="cell">Cons</div></div>
  <div class="row">
    <div class="cell pro">Reuses existing pattern</div>
    <div class="cell con">Requires migration</div>
  </div>
  <div class="row">
    <div class="cell pro">Auditable in the existing admin UI</div>
    <div class="cell con">Adds JSONB column — query patterns differ</div>
  </div>
</div>
```

The `.cell.pro` and `.cell.con` modifiers auto-prefix `+` (olive) and `−` (rust) bullets.

## Vertical-slice cards

This is the centerpiece of structure-outline and create-spec artifacts.

```html
<div class="slice">
  <h3>Slice 1 — Mock API + Frontend UI</h3>
  <p class="goal">User sees a "Reticulate" button on the splines list and clicking it
     shows a success toast with a fake result.</p>
  <ul>
    <li><span class="tag new">NEW</span> <code>web/src/components/splines/ReticulateButton.tsx</code></li>
    <li><span class="tag new">NEW</span> <code>web/src/lib/server/reticulate.ts</code> — returns hardcoded <code>ReticulationResult</code></li>
    <li><span class="tag mod">MODIFY</span> <code>web/src/routes/(admin)/splines/index.tsx</code> — add button to row</li>
  </ul>
  <p class="checkpoint">✓ Click button in dev → toast displays → no network errors in console.</p>
  <div class="chips">
    <span class="chip">Size: <strong>~80 LOC</strong></span>
    <span class="chip">Surfaces: <strong>web</strong></span>
  </div>
</div>
```

Required children: `<h3>` (slice number + name), `.goal` (one sentence of what success looks like for the user), and `.checkpoint` (the testable acceptance). `<ul>` of files-touched and `.chips` for metrics are optional but conventional. `create-spec` additionally emits "Implementation steps", "Tests", "Automated verification", and "Manual verification" sub-blocks — render each as a labeled `<strong>` line followed by a `<ul>` inside the same `.slice` card.

## Collapsibles

Use `<details>` for "deep dive on component X" — readers can collapse what they don't need. The default state is closed; set `open` on the first / most important one so the artifact is not a wall of `▸` triangles.

```html
<details open>
  <summary>Endpoint registration <span class="where">web/Controllers/Api/</span></summary>
  <p>Every endpoint inherits from <code>BaseApiController</code> and uses attribute routing.</p>
  <ul>
    <li><code>SpliceController.cs:23</code> — example of a tenant-scoped endpoint</li>
  </ul>
</details>

<details>
  <summary>Tenant filtering middleware <span class="where">web/Middleware/</span></summary>
  <p>Tenant ID is resolved in <code>TenantResolutionMiddleware.cs:45</code>...</p>
</details>
```

The `<span class="where">` on the right side of `<summary>` is the conventional path/location annotation.

## Recommendation aside

For "the bottom-line callout" at the end of a section — typically only used in design-discussion artifacts.

```html
<aside class="reco">
  <h2>Recommendation</h2>
  <p>Adopt Option B (new <code>reticulation_log</code> table) so the audit
     requirement is satisfied without coupling to <code>operation_log</code>.</p>
</aside>
```

Renders with a clay border and uppercase heading. Use at most one per section.

## Component-selection cheat sheet

| If the content is… | Use… |
| --- | --- |
| The originating ticket | `.prompt-box` (already in template header) |
| A bulleted list of facts | `<ul>` |
| A numbered procedure | `<ol>` |
| One file's signatures | `.file-label` + `<pre>` |
| One file's bullet-form changes | `.file-label` + `<ul>` |
| ≥3 structured rows | `<table>` |
| A decision with options | `.card` + `.options` + `.option.chosen` |
| Pros vs cons of one approach | `.tradeoffs` grid |
| A short "be careful" | `.callout` (or `.warn` / `.bad`) |
| A vertical slice | `.slice` |
| A self-contained sub-topic with a heading | `.card` |
| A 5+ line deep dive that not everyone needs | `<details>` (first one `open`) |
| The "headline" recommendation for a section | `aside.reco` |
| Metrics / counts inline | `.chips` |
| An inline file path or identifier | `<code>` |
| One phrase to emphasize in prose | `<span class="hl">…</span>` |

## What not to do

- **Don't invent new CSS classes inline.** If a pattern is missing, raise it in the conversation rather than adding ad-hoc styles that downstream skills can't recognize.
- **Don't import a CSS framework or font.** The template is self-contained for a reason.
- **Don't use `<br>` for spacing.** Use the existing margin from `<p>` and section spacing.
- **Don't add inline `style=""` attributes** unless adapting an existing structural property (e.g., grid-template-columns for a one-off table layout). Color, font, padding, border — those belong in the stylesheet.
- **Don't break the section numbering.** `01`, `02`, `03`, ... monotonic, no skips.
