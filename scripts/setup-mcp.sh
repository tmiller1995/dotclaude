#!/usr/bin/env bash
# Registers the secret-bearing MCP servers at user scope with ${VAR} references,
# so ~/.claude.json (untracked, per-machine) never holds a literal key.
# Set the four variables below in your user environment first, then run this once per machine.

set -eu
export MSYS_NO_PATHCONV=1

missing=0
for v in GITHUB_MCP_TOKEN SERPAPI_API_KEY CONTEXT7_API_KEY FIRECRAWL_API_KEY; do
  [ -n "${!v:-}" ] || { echo "missing env var: $v" >&2; missing=1; }
done
[ "$missing" -eq 0 ] || exit 1

case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) npx=npx.cmd ;; *) npx=npx ;; esac

add() {
  claude mcp remove "$1" -s user >/dev/null 2>&1 || true
  claude mcp add-json -s user "$1" "$2"
}

add github '{"type":"http","url":"https://api.githubcopilot.com/mcp/","headers":{"Authorization":"Bearer ${GITHUB_MCP_TOKEN}"}}'
add serpapi '{"type":"http","url":"https://mcp.serpapi.com/${SERPAPI_API_KEY}/mcp"}'
add context7 "{\"command\":\"$npx\",\"args\":[\"-y\",\"@upstash/context7-mcp\",\"--api-key\",\"\${CONTEXT7_API_KEY}\"]}"
add firecrawl "{\"command\":\"$npx\",\"args\":[\"-y\",\"firecrawl-mcp\"],\"env\":{\"FIRECRAWL_API_KEY\":\"\${FIRECRAWL_API_KEY}\"}}"

claude mcp list
