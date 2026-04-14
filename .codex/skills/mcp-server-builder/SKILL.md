---
name: mcp-server-builder
description: >
  Use to design/build MCP servers from API contracts with stable tool schemas,
  validation gates, and versioning discipline.
---

# MCP Server Builder

## Use Cases

- Expose REST/OpenAPI capabilities to agent tools
- Replace brittle browser automation with typed tools

## Workflow

1. Contract first
- Start from OpenAPI or explicit endpoint contract.

2. Tool design
- One clear intent per tool; verb-first names.
- Explicit input schema and structured error output.

3. Scaffold runtime
- Python or TypeScript implementation.

4. Validate
- Check duplicates, missing descriptions, weak schemas.

5. Secure by design
- No secrets in schema, host allowlist, timeout/rate limits.

6. Version safely
- Additive changes only for backward compatibility.
- New tool IDs for breaking behavior.

## Output

- Tool manifest
- Server scaffold
- Validation report
- Versioning notes
