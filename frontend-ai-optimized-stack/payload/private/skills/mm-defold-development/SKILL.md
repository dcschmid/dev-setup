---
name: mm-defold-development
description: Defold engineering workflow using current project structure, official documentation, and model-neutral automation interfaces.
---
# Defold development

Inspect the existing Defold project before changing architecture. Preserve established collection, game-object, component, message, input, factory/proxy, render, material, GUI, and resource-lifetime conventions unless the task requires a deliberate migration.

Use the current Defold project and current official documentation as the authority. For editor automation, prefer the open editor's HTTP API and treat its generated `/openapi.json` as the source of truth because the editor HTTP API is experimental and may change between Defold versions. Use Bob for command-line builds, reports, archives, and bundles where appropriate.

Do not invent engine APIs from memory when version-sensitive behavior matters. Keep controller/gamepad behavior, platform differences, performance, and resource ownership in mind for gameplay changes.
