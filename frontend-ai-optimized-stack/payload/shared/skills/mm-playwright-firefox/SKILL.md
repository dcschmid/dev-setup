---
name: mm-playwright-firefox
description: Browser validation policy for Playwright MCP using Firefox.
---
# Playwright Firefox workflow

Prefer Playwright with Firefox for browser validation when that integration is available; do not assume the Playwright MCP has been installed. OMP also has a built-in browser tool, commonly backed by Chromium. That is useful for exploratory checks but is not a substitute for a Firefox-specific regression test.

Prefer structured interaction and accessibility snapshots. Validate the smallest relevant path first, then expand when a defect suggests broader regression risk. For destructive or stateful flows, explain the action before executing it. Never treat a screenshot alone as proof that behavior is correct; verify interaction, console-visible symptoms, navigation, and relevant UI state.

Use existing repository Playwright tests when they cover the requested behavior. For exploratory terminal automation, the stack's `mm-playwright` launcher selects Firefox unless the repository or user explicitly chooses another browser. Check `mm-playwright --help` before relying on it; installing a skill does not prove a working browser runtime. Keep sessions and captured state scoped to the project/profile, and do not reuse personal browser logins in Working.
