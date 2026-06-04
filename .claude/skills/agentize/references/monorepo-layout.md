# Monorepo Layout

Canonical tree for `--both` mode (Node/TypeScript). Adapt paths for other ecosystems.

## Tree

```
.
├── packages/
│   ├── core/
│   │   ├── src/
│   │   │   ├── capabilities/       # one file per capability
│   │   │   ├── config/             # config schema + loader
│   │   │   ├── errors.ts           # typed error classes
│   │   │   └── index.ts            # public exports
│   │   ├── test/
│   │   ├── package.json            # private: true (not published)
│   │   └── tsconfig.json
│   ├── cli/
│   │   ├── src/
│   │   │   ├── commands/           # one file per command
│   │   │   ├── credentials.ts      # resolution chain
│   │   │   ├── formatter.ts        # json + text renderers
│   │   │   └── bin.ts              # #!/usr/bin/env node entry
│   │   ├── test/
│   │   ├── package.json            # bin, files, engines, publishConfig
│   │   └── tsconfig.json
│   └── mcp/
│       ├── src/
│       │   ├── tools/              # one file per tool
│       │   ├── transports/
│       │   │   ├── stdio.ts
│       │   │   ├── sse.ts
│       │   │   └── streamable-http.ts
│       │   ├── auth.ts
│       │   └── server.ts           # transport-agnostic server factory
│       ├── test/
│       ├── package.json
│       ├── wrangler.toml           # Cloudflare Workers
│       ├── Dockerfile
│       └── tsconfig.json
├── .claude/skills/<tool-name>/     # companion skill (staged for marketplace)
├── docs/
│   ├── cli.md
│   ├── mcp.md
│   ├── architecture.md
│   └── contributing.md
├── scripts/
├── .github/workflows/
│   ├── ci.yml
│   └── release.yml
├── .changeset/                     # changesets for release
├── package.json                    # workspaces
├── pnpm-workspace.yaml             # or workspaces field
├── tsconfig.base.json
├── .gitignore
├── LICENSE
└── README.md
```

## Root `package.json`

```json
{
  "name": "<tool-name>-monorepo",
  "private": true,
  "workspaces": ["packages/*"],
  "scripts": {
    "build": "pnpm -r build",
    "test": "pnpm -r test",
    "lint": "pnpm -r lint",
    "typecheck": "pnpm -r typecheck",
    "release": "changeset publish"
  },
  "packageManager": "pnpm@9"
}
```

## `packages/core/package.json`

```json
{
  "name": "@<scope>/<tool-name>-core",
  "private": true,
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "scripts": {
    "build": "tsc -p .",
    "test": "vitest run",
    "typecheck": "tsc --noEmit"
  }
}
```

## `packages/cli/package.json`

```json
{
  "name": "<tool-name>",
  "version": "0.1.0",
  "description": "CLI for <tool-name>",
  "bin": { "<tool-name>": "dist/bin.js" },
  "files": ["dist", "README.md", "LICENSE"],
  "engines": { "node": ">=20" },
  "publishConfig": { "access": "public", "provenance": true },
  "dependencies": {
    "@<scope>/<tool-name>-core": "workspace:*",
    "commander": "^12",
    "dotenv": "^16",
    "keytar": "^7"
  },
  "scripts": {
    "build": "tsc -p . && chmod +x dist/bin.js",
    "prepublishOnly": "pnpm build && pnpm test"
  }
}
```

## `packages/mcp/package.json`

```json
{
  "name": "<tool-name>-mcp",
  "version": "0.1.0",
  "bin": { "<tool-name>-mcp": "dist/bin.js" },
  "files": ["dist", "README.md", "LICENSE"],
  "engines": { "node": ">=20" },
  "publishConfig": { "access": "public", "provenance": true },
  "dependencies": {
    "@<scope>/<tool-name>-core": "workspace:*",
    "@modelcontextprotocol/sdk": "^1",
    "hono": "^4"
  }
}
```

## Core/adapter boundary

`core/` rules:
- No `process.argv`, no `console.log` as control flow, no HTTP server code.
- Accepts config via explicit parameters; returns plain data or throws typed errors.
- Pure functions where feasible; side-effects isolated into injected clients.

`cli/` and `mcp/` rules:
- Import only from `core/` (and formatting/transport deps).
- Translate argv / MCP arguments → core params.
- Translate core results/errors → CLI output / MCP response.
- No business logic.

If you find yourself adding business logic to an adapter, it belongs in `core/`.

## Single-package fallback (`--cli` or `--mcp` alone)

```
.
├── src/
│   ├── core/           # same boundary, just not a separate package yet
│   ├── cli/  (or mcp/)
│   └── index.ts
├── package.json
└── tsconfig.json
```

Keep the `src/core/` folder even when there's only one adapter — it makes adding the other surface later a file move, not a rewrite.
