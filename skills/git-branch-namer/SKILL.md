---
name: git-branch-namer
description: "Use this skill for Git branching: generate kebab-case branch names from Linear issues, choose the right branch prefix (feat/, fix/, chore/), or get guidance on the team's trunk-based branching conventions."
---

# Git Branch Namer

Generate kebab-case git branch names from Linear issues, following a trunk-based branching model. The resulting `prefix/ENG-1234-slug` name is ready to hand straight to the `gh-create-pr` skill.

## Reference files

This skill has supporting documentation in the `references/` directory. Load it when needed:

- **references/git-flow-standards.md** — Read this when the user asks about the branching model, which branch type to use, what the base branch is, or anything about the trunk-based branching conventions.

For straightforward "give me a branch name" requests, the instructions below are self-contained — no need to load references.

## Input format

The user provides a Linear issue as:

```
ENG-1234 - Issue Title
```

For example: `ENG-1234 - Cookie Policy – Broken 'here' link`

The leading segment is the Linear issue identifier (team key + number, e.g. `ENG-1234`, `WEB-42`). Preserve it exactly — see the casing rule below.

### Optional sourcing step

If the user gives you **only** an issue ID or a Linear issue URL (no title), fetch the title before generating the name:

1. Call `mcp__linear__get_issue` with the identifier (e.g. `ENG-1234`) or the URL.
2. Use the returned `identifier` and `title` to build the input `ENG-1234 - Issue Title`.

If the user already supplied a title, skip this step.

## Determining the branch type

The primary branch prefixes are `feat/` and `fix/`. `chore/` is available for maintenance work that is neither a feature nor a bug fix.

**Auto-detect from the user's wording first.** If keywords clearly indicate the type, use it without asking:

| User keywords | Branch prefix |
|---|---|
| "feature", "enhancement", "add", "new", "implement", "support" | feat/ |
| "bug", "fix", "broken", "issue", "patch", "defect", "regression" | fix/ |
| "chore", "cleanup", "refactor", "deps", "bump", "tooling", "maintenance", "config" | chore/ |

If the type cannot be confidently inferred, ask a single clarifying question: **"Is this a feat, fix, or chore branch?"** — then proceed.

If the user seems uncertain about which type to choose, read `references/git-flow-standards.md` to give them informed guidance.

## Conversion rules

1. **Start with the prefix**: `feat/`, `fix/`, or `chore/`
2. **Append the Linear issue identifier** (e.g. `ENG-1234`), followed by a hyphen
   - **Preserve the identifier's casing** — the issue-id segment is exempt from kebab-lowercasing, so `ENG-1234` stays `ENG-1234`, not `eng-1234`.
3. **Convert the title to kebab-case**:
   - Lowercase everything in the title portion
   - Replace spaces, underscores, and any non-alphanumeric characters (except hyphens) with hyphens
   - Collapse consecutive hyphens into a single hyphen
   - Strip leading and trailing hyphens from the title portion
4. **Result**: `prefix/ENG-1234-kebab-case-title`

## Examples

**Example 1 — fix detected from keywords:**
User: "Create a fix branch for ENG-1234 - Cookie Policy – Broken 'here' link"
```
fix/ENG-1234-cookie-policy-broken-here-link
```

**Example 2 — feat detected from keywords:**
User: "Create a feature branch for ENG-4089 - Add SSO support for enterprise customers"
```
feat/ENG-4089-add-sso-support-for-enterprise-customers
```

**Example 3 — chore detected from keywords:**
User: "Chore branch for OPS-310 - Bump TypeScript and clean up tooling config"
```
chore/OPS-310-bump-typescript-and-clean-up-tooling-config
```

**Example 4 — ambiguous, ask the user:**
User: "Branch name for WEB-1045 - Homepage hero banner image not loading on mobile"
→ Ask: "Is this a feat, fix, or chore branch?"
User: "Fix"
```
fix/WEB-1045-homepage-hero-banner-image-not-loading-on-mobile
```

**Example 5 — special characters cleaned up, identifier casing preserved:**
User: "Fix branch for ENG-5501 - Update & Fix: Login/Logout (v2.1)"
```
fix/ENG-5501-update-fix-login-logout-v2-1
```

**Example 6 — only an ID supplied, fetch the title first:**
User: "Branch name for ENG-7788"
→ Call `mcp__linear__get_issue` for `ENG-7788`, then proceed with the returned title.

## Response format

Present the branch name in a code block so the user can easily copy it. Keep the response short — just the branch name. No extra explanation unless the user asks.

This `prefix/ENG-1234-slug` form feeds the `gh-create-pr` skill directly: it parses the issue segment for the PR description and the prefix maps to the conventional-commit type.
