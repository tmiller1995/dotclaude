---
name: review-codeant
description: Review and triage CodeAnt AI comments on a GitHub PR. Use when the user says "review codeant", "triage codeant comments", "handle codeant", "codeant review", "address codeant feedback", or wants to process automated code review comments from CodeAnt on a pull request.
allowed-tools: Bash(gh *)
---

# Review CodeAnt Comments

Fetch, triage, and respond to CodeAnt AI review comments on a GitHub pull request.

> **CodeAnt requires `@codeant-ai` in EVERY reply.** Without that mention, CodeAnt never sees the reply and the learning loop never fires. See [references/codeant-interactions.md](references/codeant-interactions.md) for the full command formats, dispute/learning behavior, and why the tagged reply (not any thread status) is the only feedback channel.

## When to Use

- User wants to review CodeAnt comments on a PR
- User says "review codeant", "triage codeant", "handle codeant comments"
- User wants to address automated code review feedback from CodeAnt
- User shares a PR URL or number and mentions CodeAnt

## When NOT to Use

- User wants a general code review (not CodeAnt-specific)
- User wants to run linting or static analysis locally
- User wants to deploy or manage infrastructure — use appropriate Railway skills

## Workflow

```
User provides PR (URL or number)
        │
  Step 1: Fetch PR metadata
  (gh pr view)
        │
  Step 2: Fetch ALL CodeAnt comments
  (review comments + issue comments)
        │
  Step 3: For each comment, analyze
  the referenced code using agents
        │
   ┌────┴────┐
 Valid     Not valid / Nitpick
   │           │
   │      Reply with reasoning
   │      (why not implementing)
   │           │
   └─────┬─────┘
         │
  Step 4: Present remediation plan
  for valid comments
```

## Step 1: Identify the PR

If the user provides a PR URL, extract the owner/repo and PR number. If only a number is given, use the current repo context.

```bash
# View PR details
gh pr view <PR_NUMBER> --json number,title,headRefName,baseRefName,url
```

## Step 2: Fetch CodeAnt Comments

Fetch both review comments (inline on code) and issue comments (PR-level). CodeAnt's bot username is `codeant-ai[bot]`.

### Review Comments (inline code comments)

```bash
# Fetch all review comments and filter for CodeAnt
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments \
  --paginate \
  --jq '[.[] | select(.user.login == "codeant-ai[bot]") | {id, path, line, side, body, in_reply_to_id, diff_hunk, created_at, html_url}]'
```

### Issue Comments (PR-level comments)

```bash
# Fetch all issue comments and filter for CodeAnt
gh api repos/{owner}/{repo}/issues/{pr_number}/comments \
  --paginate \
  --jq '[.[] | select(.user.login == "codeant-ai[bot]") | {id, body, created_at, html_url}]'
```

### Important Notes on Comment Filtering

- If `codeant-ai[bot]` returns no results, try alternate usernames: `codeant-ai`, `codeantai[bot]`, `codeantai`
- If still no results, list ALL comment authors to identify the correct username:

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments \
  --paginate \
  --jq '[.[].user.login] | unique'
gh api repos/{owner}/{repo}/issues/{pr_number}/comments \
  --paginate \
  --jq '[.[].user.login] | unique'
```

## Step 3: Analyze Each Comment

For each CodeAnt comment, determine the file and code region referenced, then assess validity.

### 3a: Understand the Code

Use agents to understand the code that CodeAnt commented on:

- **`codebase-analyzer`** — Trace how the referenced code works. Invoke with: "Analyze the implementation at `{file_path}` around lines `{start_line}-{end_line}`. Explain what this code does, its data flow, and any error handling."
- **`codebase-pattern-finder`** — Check if the code follows existing project patterns. Invoke with: "Find existing patterns in the codebase similar to the code at `{file_path}:{line}`. Does this code conform to established conventions?"

### 3b: Classify Each Comment

Classify each CodeAnt comment into one of these categories:

| Category | Action |
|----------|--------|
| **Valid — Bug/Correctness** | Include in remediation plan |
| **Valid — Security** | Include in remediation plan (high priority) |
| **Valid — Performance** | Include in remediation plan if impact is meaningful |
| **Valid — Convention** | Include in remediation plan if project patterns confirm |
| **Nitpick — Style** | Dismiss with reasoning |
| **Nitpick — Subjective** | Dismiss with reasoning |
| **False Positive** | Dismiss with reasoning |
| **Already Addressed** | Dismiss noting where it's handled |

### 3c: Decision Criteria

A comment is **valid** when:
- It identifies a real bug, race condition, or correctness issue
- It identifies a security vulnerability (injection, auth bypass, data leak)
- It identifies a meaningful performance issue (not micro-optimization)
- The suggested change aligns with existing project patterns (confirmed by `codebase-pattern-finder`)

A comment should be **dismissed** when:
- It's a style preference not matching project conventions
- The "issue" is already handled elsewhere (e.g., upstream validation, middleware)
- It's a micro-optimization with no measurable impact
- It suggests patterns that contradict established project conventions
- The concern is addressed by framework guarantees or type system

## Step 4: Respond and Plan

### Reply to Dismissed Comments

For **review comments** (inline), reply directly to the comment thread:

```bash
# Reply to a review comment thread
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments/{comment_id}/replies \
  -f body="@codeant-ai <REASONING>"
```

For **issue comments** (PR-level), add a new comment tagging CodeAnt:

```bash
# Reply to a PR-level comment
gh api repos/{owner}/{repo}/issues/{pr_number}/comments \
  -f body="@codeant-ai Re: <BRIEF_QUOTE_OF_ORIGINAL>

<REASONING>"
```

### Dismissal Response Format

Keep responses concise and technical. **Prefer the dispute format** — it triggers CodeAnt's learning loop so it stops flagging similar code in future reviews:

```
@codeant-ai: This is not an issue because <1-2 sentence technical reasoning>
```

Examples:
- "@codeant-ai: This is not an issue because this validation is already handled by the `[Validator]` middleware registered in `Program.cs:42`. The endpoint never receives unvalidated input."
- "@codeant-ai: This is not an issue because the project uses `snake_case` naming convention per PostgreSQL standards. This matches the pattern established across all DbContexts."
- "@codeant-ai: This is not an issue because the collection is bounded to max 10 items by the query's `Take(10)` — the allocation difference is negligible."

CodeAnt records each dispute as a "learning" (manageable at `app.codeant.ai/settings/learnings`) and avoids similar flags going forward.

### Present Remediation Plan

After triaging all comments, present the valid ones as a remediation plan to the user:

```markdown
## CodeAnt Remediation Plan — PR #<NUMBER>

### Summary
- **Total comments**: X
- **Valid (to fix)**: Y
- **Dismissed**: Z

### Fixes Required

#### 1. [Category] — file.cs:line
**CodeAnt said**: <brief summary>
**Fix**: <what to change>
**Priority**: High/Medium/Low

#### 2. ...

### Dismissed Comments
| # | File | Comment Summary | Reason |
|---|------|----------------|--------|
| 1 | file.cs:42 | ... | Already handled by ... |
| 2 | ... | ... | ... |
```

Wait for user approval before implementing any fixes.

### After Implementing Valid Fixes

Once a valid comment's fix has been implemented (and ideally committed/pushed), post an acknowledgement reply so CodeAnt knows the finding was actioned. Every reply must include `@codeant-ai`.

For **review comments** (inline), reply to the comment thread:

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments/{comment_id}/replies \
  -f body="@codeant-ai Good catch — this has been fixed."
```

For **issue comments** (PR-level), add a new comment:

```bash
gh api repos/{owner}/{repo}/issues/{pr_number}/comments \
  -f body="@codeant-ai Good catch — this has been fixed."
```

## Composability

- **Implement fixes**: After user approves the remediation plan, implement the changes directly
- **Run tests**: After implementing fixes, run the project's test suite to verify
- **Create commit**: Use `/commit` skill to commit the fixes

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| `gh: command not found` | GitHub CLI not installed | Install with `winget install GitHub.cli` or `brew install gh` |
| `HTTP 404` on PR | Wrong repo or PR number | Verify with `gh pr list` in the correct repo |
| No CodeAnt comments found | Bot hasn't run or different username | Check all comment authors (see Step 2 notes) |
| `HTTP 403` on reply | Insufficient permissions | Ensure `gh auth status` shows write access |
| Reply fails with 422 | Comment may have been deleted | Skip and note in output |
