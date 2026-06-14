# Trunk-Based Branching Standards

The team uses a trunk-based branching model. This document covers the base branch, branch types, and when to use each one.

**Source references:**
- Trunk-based development: https://trunkbaseddevelopment.com/
- Branching patterns (Martin Fowler): https://martinfowler.com/articles/branching-patterns.html

## Base branch

### main
`main` is the single long-lived branch and the **base branch** — the default branch checked out on a fresh clone and the default target for pull requests. All work branches are cut from `main` and merge back into `main`.

There are no `develop`, `master`, `release/*`, or `hotfix/*` branches. Releases are cut directly from `main` (e.g. tags), so there is no Git Flow stabilization or hotfix line to maintain.

## Work branches

These are the short-lived branches developers create from Linear issues. The naming pattern is:

```
prefix/ENG-1234-short-kebab-case-description
```

Where `ENG-1234` is the Linear issue identifier (preserved exactly, including its casing), and the description is the issue title converted to kebab-case.

Branches are **short-lived**: cut from `main`, kept small, and merged back via pull request as quickly as possible. After merge the branch is deleted to keep history clean — commit history remains accessible through the linked pull request.

### feat/ENG-1234-short-feature-description
For new features and enhancements. Maps to the `feat` conventional-commit type.

### fix/ENG-1234-short-fix-description
For bug fixes and patches. Maps to the `fix` conventional-commit type.

### chore/ENG-1234-short-chore-description
For maintenance work that is neither a new feature nor a bug fix — dependency bumps, tooling, config, and refactors. Maps to the `chore` conventional-commit type.

## Choosing the right branch type

| Situation | Branch type | Why |
|---|---|---|
| Adding a new feature or enhancement | feat/ | New behavior — PR into main when done |
| Fixing a bug or regression | fix/ | Corrects existing behavior — PR into main when done |
| Maintenance, deps, tooling, or refactor | chore/ | Neither feature nor fix |

When in doubt, decide whether the change adds behavior (feat/) or corrects it (fix/); use chore/ for everything else.

## Branch lifecycle

1. Developer creates a short-lived work branch (feat/, fix/, or chore/) from `main`
2. Work is done with commits referencing the Linear issue (e.g. `ENG-1234` in the branch name and PR description)
3. A pull request is created targeting `main`
4. Code review happens
5. After approval and merge, the source branch is deleted
6. Commit history remains accessible through the pull request details

## Linking to Linear

Reference the Linear issue identifier (e.g. `ENG-1234`) in the branch name and PR description so the work is traceable. Linear can auto-link the pull request to the issue when the identifier appears in the branch name or PR title/body; you can also attach the PR URL to the issue with `mcp__linear__create_attachment`.
