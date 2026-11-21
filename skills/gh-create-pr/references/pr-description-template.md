# PR Description Template

This is the bundled PR body for repositories without their own template. It is HumanLayer's `describe-pr` template plus a Merge danger line taken from Matt Pocock's `pr` skill. gh-create-pr and `/describe-pr` both use it.

~~~~markdown
## Why the change

{Exactly one sentence: the problem this PR solves and what becomes possible after it ships.}

## Merge danger

{One line. **Two-way door** (easy to revert, no lasting effects) or **one-way door** (a data migration, a public contract or API change, deleted data, or anything a revert won't undo), then the blast radius: who or what breaks if this is wrong.}

## Special things to note

- {1–3 bullets a reviewer needs: warnings, migrations, compatibility constraints or breaking changes and how to migrate, deliberate omissions, surprising decisions. Write `- None.` when there are none.}

## Change outline

{The smallest set of views below that explains the change, in the order that makes it easiest to follow. Give each view a short lead-in sentence.}

{lead-in}

```diff
{changed SQL tables and key columns, or endpoint request/response contracts}
```

{lead-in}

```csharp
{a new data structure central to the change}
```

{lead-in}

```diff
{concise pseudocode for the changed behavior}
```

{lead-in}

```diff
{a shallow file tree with each file's changed responsibility}
```

{lead-in}

```diff
{a changed React component tree: key hooks, state, package boundaries}
```

{lead-in}

```diff
{a changed call tree, control flow, or data flow}
```

Closes ENG-123
~~~~

## Rules

- **Why the change** is exactly one sentence.
- **Merge danger** is one line. A one-way door tells the reviewer to read the whole diff; a two-way door can get a lighter review.
- **Special things to note** has 1–3 bullets, or `- None.`.
- **Change outline** is a structural view, not prose and not a file-by-file changelog. Every view is optional: use only the ones that help, and name and order them to suit the change. Prefer `diff` blocks for focused changes to existing shapes. Show the complete target shape in a language block (or `text`) when it is new, high-level, or clearer without diff notation. Keep each view to the calls, files, fields, components, and boundaries a reviewer needs, and leave out categories that didn't change. `skills/output-html/references/visual-guidance.md` describes each view.
- End with the Linear reference: `Closes ENG-123` when the PR completes the issue, `Refs ENG-123` when the issue stays open after merge. Leave it out when there is no issue.
- Leave out verification checklists, changelog text, exhaustive implementation narratives, and plan-deviation sections. Deviations from a CRISPY plan go in `/describe-pr`'s report to the user, not in the PR body.
- Write as one person talking to another, in plain, concise language with no AI attribution.
