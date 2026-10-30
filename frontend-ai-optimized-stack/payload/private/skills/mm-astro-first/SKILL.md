---
name: mm-astro-first
description: "Private-project frontend policy: Astro-first, static-first, minimal client JavaScript, current Astro docs."
---
# Private Astro-first policy

Private frontend work is Astro-first. Prefer `.astro`, server-rendered/static markup, Astro Content Collections, and islands only where interaction actually requires client JavaScript. Do not introduce React, Next.js, or another UI runtime merely out of habit.

Use the Astro Docs MCP for version-sensitive framework questions when available; otherwise consult the current official documentation at https://docs.astro.build/. Prefer platform HTML/CSS and Astro-native features before adding dependencies. Preserve accessibility, progressive enhancement, small bundles, and straightforward deployment.
