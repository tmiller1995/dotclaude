---
name: git-branch-namer
description: "Generates kebab-case Git branch names from Linear issues using the team's trunk-based convention: a feat/, fix/, or chore/ prefix, the issue identifier with its casing preserved, and a slugified title (for example fix/ENG-1234-cookie-policy-broken-here-link). Use when the user asks for a branch name, asks what to call a branch, supplies a Linear issue ID, identifier line, or Linear URL and wants a branch for it, asks which prefix (feat, fix, or chore) a change belongs under, or asks about the base branch or the trunk-based branching model. Produces the name only: create-worktree creates the branch and worktree, gh-create-pr commits and opens the pull request."
argument-hint: "ENG-1234 - Issue Title | ENG-1234 | Linear issue URL"
---

# Git Branch Namer

Generate kebab-case git branch names from Linear issues, following a trunk-based branching model.

## Reference files

This skill has supporting documentation in the `references/` directory. Load it when needed:

- **references/trunk-based-branching.md** — Read this when the user asks about the branching model, which branch type to use, what the base branch is, or anything about the trunk-based branching conventions.

For straightforward "give me a branch name" requests, the instructions below are self-contained — no need to load references.

## Input format

The user provides a Linear issue as:

```
ENG-1234 - Issue Title
```

For example: `ENG-1234 - Cookie Policy – Broken 'here' link`

The leading segment is the Linear issue identifier (team key + number, e.g. `ENG-1234`, `WEB-42`). Preserve it exactly — see the casing rule below.

### Optional sourcing step

When the user supplies **only** an issue ID or a Linear issue URL with no title, fetch the title before generating the name:

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

If the user seems uncertain about which type to choose, read `references/trunk-based-branching.md` to give them informed guidance.

## Conversion rules

1. **Start with the prefix**: `feat/`, `fix/`, or `chore/`
2. **Append the Linear issue identifier** (e.g. `ENG-1234`), followed by a hyphen
   - **Preserve the identifier's casing** — the issue-id segment is exempt from kebab-lowercasing, so `ENG-1234` stays `ENG-1234`, not `eng-1234`.
3. **Convert the title to kebab-case**:
   - Lowercase everything in the title portion
   - Replace spaces, underscores, and any non-alphanumeric characters (except hyphens) with hyphens
   - Collapse consecutive hyphens into a single hyphen
   - Strip leading and trailing hyphens from the title portion
4. **Keep the slug readable**: if the kebab-cased title pushes the full branch name past ~60
   characters, drop trailing words until it fits. Trim at word boundaries only, and never shorten
   the prefix or the issue identifier — those are what Linear and `gh-create-pr` parse.
5. **Result**: `prefix/ENG-1234-kebab-case-title`

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
