# 2026-05-06 Required Init Checklist

**Run ID:** chat-2026-05-07T02-56-11-449Z-46327
**Ontology graph:** `.omk/memory/graph-state.json`

## Required Artifacts
- ✅ `AGENTS.md` — critical; top-level operating contract
- ✅ `.kimi/AGENTS.md` — critical; Kimi-specific operating rules
- ✅ `DESIGN.md` — support; design/brand source of truth
- ✅ `.omk/config.toml` — critical; OMK project runtime settings
- ✅ `.omk/agents/root.yaml` — critical; root coordinator agent
- ✅ `.omk/mcp.json` — critical; project MCP registry
- ✅ `.omk/lsp.json` — support; TypeScript LSP config
- ✅ `.omk/hooks/pre-shell-guard.sh` — critical; destructive shell guard
- ✅ `.omk/hooks/protect-secrets.sh` — critical; secret write guard
- ✅ `.omk/memory/graph-state.json` — critical; local ontology graph database
- ✅ `.kimi/mcp.json` — support; Kimi project MCP bridge
- ✅ `.kimi/skills` — support; Kimi skill directory
- ✅ `.agents/skills` — support; portable skill directory

## Recovery Command
```bash
omk init
omk doctor
```
