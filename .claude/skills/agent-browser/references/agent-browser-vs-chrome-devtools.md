# Browser Automation Routing

Use `agent-browser` for normal browser automation and testing when a fresh or tool-managed browser is acceptable. Use `chrome-profile` only when the task needs the user's actual Chrome profile state.

## Decision Tree

```
Need browser automation?
|
+-- Needs the user's real Chrome profile, cookies, tenant, or Google account?
|   +-- YES --> chrome-profile
|   +-- NO --> Continue
|
+-- Browser/app testing, screenshots, forms, scraping, exploratory QA?
|   +-- YES --> agent-browser
|   +-- NO --> Continue
|
+-- Repeatable CI/e2e test suite?
|   +-- YES --> web-testing or project-native Playwright/Vitest/Cypress
|   +-- NO --> Continue
|
+-- Low-level Chrome DevTools Protocol inspection?
|   +-- YES --> chrome-devtools-mcp through use-mcp
|   +-- NO --> Continue
|
+-- Browserbase/cloud browser or Electron workflow?
|   +-- YES --> agent-browser
+-- Otherwise --> web-testing
```

## agent-browser Pattern

```bash
agent-browser --session test1 open https://example.com
agent-browser snapshot -i
agent-browser click @e1
agent-browser close
```

## Chrome Profile Pattern

```bash
chrome-profile doctor
chrome-profile setup
chrome-profile work "https://example.com/dashboard"
```

Then select the page whose URL contains `cdp-profile=work` through the active MCP bridge.
