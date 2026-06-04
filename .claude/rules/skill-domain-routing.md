# Skill Domain Routing

When a user's task involves a specific domain, use these decision trees to pick the RIGHT skill based on user intent.

## Frontend / UI

```
User wants to...
├── Replicate a mockup, screenshot, or video    → frontend-design
├── Build React/TS components with best practices → frontend-development
├── Style with Tailwind CSS + shadcn/ui          → ui-styling
├── Choose colors, fonts, layout, design system  → ui-ux-pro-max
├── Audit existing UI for accessibility/UX       → web-design-guidelines
├── Apply React performance patterns             → react-best-practices
├── Build with Stitch (AI design generation)     → stitch
├── Create 3D / WebGL / Three.js experience      → threejs
├── Write GLSL shaders / procedural graphics     → shader
└── Build programmatic video with Remotion       → remotion
```

## Codebase Understanding

```
User wants to...
├── Quick file search, locate specific code     → scout
├── Onboard a new repo / dump codebase for LLM  → repomix
├── Semantic go-to-definition, find-usages      → gkg
└── Build a queryable knowledge graph from code → graphify
```

## Backend / API

```
User wants to...
├── Build REST/GraphQL API (NestJS, FastAPI, Django) → backend-development
├── Add authentication (OAuth, JWT, passkeys)        → better-auth
└── Integrate payments (Stripe, Polar, SePay)        → payment-integration
```

## Database

```
User wants to...
├── Design schemas, write SQL/NoSQL queries     → databases
├── Optimize indexes, migrations, replication   → databases
└── Add auth with database-backed sessions      → better-auth
```

## Infrastructure / Deployment

```
User wants to...
├── Deploy to Vercel, Netlify, Railway, Fly.io   → deploy
└── Docker, Kubernetes, CI/CD pipelines, GitOps   → devops
```

## Security

```
User wants to...
├── STRIDE/OWASP security audit with auto-fix    → security
├── Scan for secrets, vulnerabilities, OWASP patterns → security-scan
└── OSINT / CTI / threat-intel investigation     → cti-expert
```

## AI / LLM

```
User wants to...
├── Optimize context, agent architecture, memory → context-engineering
├── Generate llms.txt, LLM-friendly docs         → llms
├── Build AI agents with Google ADK              → google-adk-python
├── Generate/analyze images, audio, video with AI → ai-multimodal
└── Learn the autoresearch pattern / find the right family member → autoresearch
```

## MCP (Model Context Protocol)

```
User wants to...
├── Build a new MCP server                       → mcp-builder
├── Convert existing code into CLI/MCP server    → agentize
├── Discover and execute MCP tools               → use-mcp
└── Target a real Chrome profile through browser MCP → chrome-profile
```

## Testing / Browser

```
User wants to...
├── Run test suites, coverage reports, TDD          → test
├── Test strategy + Playwright/Vitest/k6 runner     → web-testing
├── Drive the user's real Chrome profile/cookies    → chrome-profile
└── Browser automation/testing without real user cookies → agent-browser
```

## Media

```
User wants to...
├── Process video/audio (FFmpeg), images (ImageMagick) → media-processing
└── Generate AI images (Imagen, Nano Banana)           → ai-artist
```

## Documentation

```
User wants to...
├── Update project docs (codebase-summary, PDR)   → docs
├── Search library/framework docs (context7)      → docs-seeker
├── Discover skills by capability / "is there a skill" → find-skills
├── Build docs site with Mintlify                 → mintlify
├── Inline doc diagrams (Mermaid v11)             → mermaidjs-v11
├── Publish-grade SVG/PNG diagrams (architecture) → tech-graph
├── Read long-form docs / RFCs / specs in browser → markdown-novel-viewer
├── Generate session hand-off / EOD summary       → watzup
└── Sprint retrospective from git history         → retro
```

## Documents / Office Files

```
User wants to...
├── Create / edit / extract from .docx (Word)         → docx
├── Create / edit / extract from .pdf (forms, tables) → pdf
├── Create / edit / extract from .pptx (PowerPoint)   → pptx
└── Create / edit / extract from .xlsx (spreadsheets) → xlsx
```

## Content / Copy

```
User wants to...
├── Write landing page, email, headline copy     → copywriting
├── Brand identity, logos, banners               → design
└── Create Excalidraw diagrams                   → excalidraw
```

## Frameworks

```
User wants to...
├── Next.js App Router, RSC, Turborepo           → web-frameworks
├── TanStack Start/Form/AI                       → tanstack
├── React Native, Flutter, SwiftUI               → mobile-development
└── Shopify apps, Polaris, Liquid templates       → shopify
```

## Usage Notes

- Pick ONE skill per distinct user intent
- If a task spans two domains (e.g. "build + deploy"), suggest the primary skill and mention the secondary
- Domain skills combine with core workflow: `plan` → domain skill → `cook`
- Skills not listed here are either core workflow skills (see `skill-workflow-routing.md`) or utility skills activated on demand (e.g. `ask`, `preview`, `sequential-thinking`)
