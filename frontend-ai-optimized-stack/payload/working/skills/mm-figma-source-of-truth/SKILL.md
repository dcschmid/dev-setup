---
name: mm-figma-source-of-truth
description: Working-project UI policy: Figma and Code Connect are the source of truth; implementation must not invent a competing design system.
---
# Figma is the source of truth

For working UI tasks, Figma is the visual and interaction source of truth. Use Code Connect and existing production components when available. Do not invent colors, spacing scales, typography, variants, component APIs, or interaction patterns when the design system already defines them.

General frontend guidance may improve implementation quality, performance, accessibility, and code structure, but it must not override an explicit Figma or Code Connect decision. If implementation and design disagree, surface the mismatch instead of silently redesigning the interface.
