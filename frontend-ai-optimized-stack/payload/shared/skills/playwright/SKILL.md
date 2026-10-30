---
name: playwright
description: Automate a real browser from the terminal for UI exploration, navigation, snapshots and interaction debugging.
---
# Browser automation with Playwright

Use the installed `mm-playwright` launcher for exploratory browser work. It runs the stack's pinned official Playwright CLI, defaults to Firefox, and separates sessions by agent profile and working directory. Repository browser settings and explicit user choices take precedence.

Check `command -v mm-playwright` and `mm-playwright --help`. If unavailable, use an existing repository Playwright workflow or explain the missing runtime. Do not install a second global CLI merely because this skill is present. The optional stack installer is `setup-workflow-tools.py --install`.

Prefer existing repository regression tests when they cover the requested behavior. Use terminal automation to inspect a UI or reproduce interactions; it does not replace the project's test suite. Add test files when they materially verify a requested behavior change.

```bash
mm-playwright open http://localhost:4321
mm-playwright snapshot
# Use a real element reference from the returned snapshot:
mm-playwright click e15
mm-playwright snapshot
```

Read fresh snapshots before using element references, and refresh after navigation, dialogs or significant DOM changes. Verify interaction state and browser errors as well as screenshots. Use traces for a difficult reproduction and retain artifacts in the repository's existing output location, or `output/playwright/`.

Do not reuse personal browser logins in Working. Preserve the launcher's project/profile session separation; avoid overriding session names across unrelated profiles. Stateful submissions and external account actions must stay within the user's authorized scope. Never report an unrun browser check as passed.

For detailed CLI syntax, read [the command reference](references/cli.md). For navigation, snapshots, forms, dialogs and traces, read [workflow examples](references/workflows.md) only as needed. Confirm flags against the installed CLI when references and runtime differ.
