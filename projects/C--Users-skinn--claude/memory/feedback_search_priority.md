---
name: search-tool-priority
description: Web research follows a SerpAPI-discovery → Firecrawl-extraction pipeline; Context7/MSLearn are niche/fallback only
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 233b7672-54be-4d2b-8329-4e6bf56edd5e
---

Web research tool hierarchy (updated 2026-06-03, supersedes the earlier "Firecrawl first" ordering):

**Discovery (find candidate URLs):**
1. SerpAPI (`mcp__serpapi__search`) — always first.
2. `firecrawl_search` (`mcp__firecrawl__firecrawl_search`) — fallback when SerpAPI is unavailable/empty.
3. WebSearch — last resort.

**Extraction (pull content from the discovered URLs):**
1. Firecrawl (`mcp__firecrawl__firecrawl_scrape` / `firecrawl_crawl` / `firecrawl_map`) — default.
2. WebFetch — fallback.
3. playwright-cli — only for JS/login/interaction.

**Context7 / MSLearn — narrow exception + fallback:**
- Context7 (`mcp__context7__*`) for a direct library/framework API lookup.
- MSLearn (`mcp__mslearn__*`) for canonical Microsoft/.NET/Azure docs.
- Otherwise, only as fallback when the SerpAPI + Firecrawl pipeline is unavailable. Do NOT use them as a substitute for the pipeline on general research.

**Why:** User clarified the workflow is a two-stage pipeline — SerpAPI discovers URLs in bulk, Firecrawl extracts their content — not a flat "firecrawl-first" search. See [[atomic-upstream]] for the agent these settings drive.

**How to apply:** Agents/skills that do web research should follow this hierarchy. CRITICAL — the Firecrawl MCP **server key is `firecrawl`**, so tools are `mcp__firecrawl__firecrawl_*`. The earlier `mcp__firecrawl-mcp__*` prefix was WRONG (that's the npm package name, not the server key) and caused every Firecrawl call to fail. A second managed server `mcp__claude_ai_Firecrawl__*` exists but is disabled in some projects — prefer `mcp__firecrawl__`.
