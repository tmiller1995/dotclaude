---
name: explain-code
description: Explain what a piece of code does and how it works — a high-level overview, its structure, a line-range walkthrough of the non-obvious parts, and notes on errors, performance, security, and possible improvements. Use when the user asks to explain, walk through, or help them understand a file, function, snippet, or library usage. For tracing how a component works across the codebase as input to CRISPY research, dispatch the codebase-analyzer agent instead.
---

# Analyze and Explain Code Functionality

Explain: **$ARGUMENTS**

## Looking up external documentation

Use the **playwright-cli** skill for third-party library, framework, and API docs, in preference to WebFetch/WebSearch. Load it with the Skill tool before first use. It is installed; if the bare `playwright-cli` command fails, use `npx playwright-cli`.

Fetch in this order and stop as soon as you have what you need, because each step costs more tokens than the last:

1. **`/llms.txt`** — many docs sites publish an AI-friendly index ([llmstxt.org](https://llmstxt.org/llms.txt)). Try `curl https://<site>/llms.txt` first; it often links straight to the relevant pages in plain text.
2. **`Accept: text/markdown`** — for an HTML page, try `curl <url> -H "Accept: text/markdown"`. Sites behind Cloudflare's [Markdown for Agents](https://developers.cloudflare.com/fundamentals/reference/markdown-for-agents/) return pre-converted Markdown (look for `content-type: text/markdown` and an `x-markdown-tokens` header).
3. **HTML** — otherwise, navigate with `playwright-cli` to extract the rendered DOM, or `curl` the raw HTML and parse it locally.

Check `research/web/` before fetching. When a fetched document is worth keeping (API references, SDK guides, troubleshooting docs), save it to `research/web/<YYYY-MM-DD>-<kebab-case-topic>.md` with a short header noting the source URL and fetch date.

`playwright-cli` is also the tool for live browser inspection — reproducing frontend behavior when static reading isn't enough.

## What to cover

Read the code and its surroundings first: language and framework, the file's role in the project, its imports, configuration, and callers. Then explain from high level to detail, covering the areas below that apply to this code and skipping the ones that don't:

1. **Overview** — what the code does, the problem it solves, and how it fits into the larger system.
2. **Structure** — its logical sections, key classes/functions/types, design patterns, and the data and control flow between them.
3. **Walkthrough of the non-obvious parts** — the algorithm or approach, complex conditions and loops, recursion or async behavior, data transformations and input/output shapes, and framework- or language-specific idioms a reader might not know (e.g., C# LINQ and `async`/`Task`, TypeScript closures and Promise chains, React/TanStack conventions). Explain the lines that need it, not every line.
4. **Cross-cutting concerns** — error handling and edge cases, performance and complexity, security (authn/authz, input validation, likely vulnerabilities), external integrations (databases, APIs, services), and how to test or debug it (logging, failure points, test helpers).
5. **Potential improvements** — refactoring opportunities, maintainability concerns, and risks worth fixing.
6. **Related code** — the functions, classes, and components it interacts with, its calling context, and relevant docs.

Match the depth and vocabulary to the audience, use analogies for hard concepts, and add a diagram or flowchart when the flow is easier to see than to read.

## Explanation format

Walk through the code as numbered steps tied to line ranges, then close with short labeled notes for whichever cross-cutting concerns matter. Illustrative examples:

**An algorithm:**

```
This function implements a depth-first search algorithm:

1. Line 1-3: Initialize a stack with the starting node and a visited set
2. Line 4-8: Main loop - continue until stack is empty
3. Line 9-11: Pop a node and check if it's the target
4. Line 12-15: Add unvisited neighbors to the stack
5. Line 16: Return null if target not found

Time Complexity: O(V + E) where V is vertices and E is edges
Space Complexity: O(V) for the visited set and stack
```

**API integration code:**

```
This code handles user authentication with a third-party service:

1. Extract credentials from request headers
2. Validate credential format and required fields
3. Make API call to authentication service
4. Handle response and extract user data
5. Create session token and set cookies
6. Return user profile or error response

Error Handling: Catches network errors, invalid credentials, and service unavailability
Security: Uses HTTPS, validates inputs, and sanitizes responses
```

**A database operation:**

```
This function performs a complex database query with joins:

1. Build base query with primary table
2. Add LEFT JOIN for related user data
3. Apply WHERE conditions for filtering
4. Add ORDER BY for consistent sorting
5. Implement pagination with LIMIT/OFFSET
6. Execute query and handle potential errors
7. Transform raw results into domain objects

Performance Notes: Uses indexes on filtered columns, implements connection pooling
```
