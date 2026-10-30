---
name: mm-game-project-engineering
description: Engine-agnostic private game-project engineering for gameplay systems, input, state, UI, content, performance, multiplayer readiness, testing, and release work across future games.
---
# Game project engineering

Use this skill for feature work that affects a game as a product rather than a single engine API or asset. Start by discovering the repository's real architecture, engine/version, scene or collection structure, runtime entry points, build commands, input model, save/config format, asset pipeline, test hooks, and platform targets. Existing project conventions and workspace skills override generic package guidance.

Protect the playable loop. Before changing architecture, identify what the player can currently do, the states that drive that loop, and which systems own transitions. Prefer small explicit boundaries between gameplay rules, presentation, input, persistence, platform integration, tooling, and content. Reuse established patterns before adding managers, service layers, event buses, ECS abstractions, or new frameworks.

Treat keyboard, mouse, controller and local-multiplayer input as first-class when the project supports them. Keep device-specific input at the edge and game actions in gameplay code. Preserve remapping, focus/navigation, pause/disconnect/reconnect behavior, dead-zone handling, and deterministic ownership of each player's controls.

For persistent state, distinguish save data, user settings, progression, run/session state, and transient scene state. Migrations must preserve old data when compatibility matters. Never silently reset player data to make a new schema easier.

For UI and UX, follow the project's established visual source of truth and interaction language. Verify legibility, controller navigation, feedback, error/empty states, aspect ratios and accessibility-relevant behavior in the running game. Do not redesign unrelated screens while implementing a feature.

For assets and content, respect naming, scale, axes, pivots, import settings, material/texture budgets, animation contracts and source-of-truth files. Validate the runtime result after import; editor appearance alone is not proof.

Treat performance as a measured constraint. Profile before large optimizations and re-measure afterward. Watch frame time, allocations/GC, draw calls, physics cost, script/update frequency, loading, memory and asset size according to the engine and target hardware. Do not trade maintainability for speculative micro-optimizations.

For multiplayer or co-op, make player ownership, authority, synchronization boundaries, join/leave flow and failure behavior explicit. Do not bolt multiplayer assumptions onto single-player state implicitly; prefer systems that can state which data is local, shared, authoritative or replicated.

Validate substantial changes with the strongest evidence the project supports: build, automated tests, runtime logs, screenshots/video, deterministic repro steps, input/controller checks, save/load, performance captures and platform packaging. Fix regressions at the owning layer instead of masking them elsewhere.

When implementation evidence contradicts the current plan, update the plan and record the reason. Do not impose artificial thinking, retry, action or time limits on legitimate game-development work.
## Ponytail interaction

Ponytail may reduce accidental complexity in implementation, but required game architecture is not waste. Do not remove or flatten boundaries that exist for measured runtime performance, deterministic state ownership, save compatibility/migrations, multiplayer authority or replication, platform support, controller/input abstraction, asset lifetime, loading, physics, rendering, or validated project requirements merely to reduce lines of code. Prefer the simplest implementation that still preserves those contracts. For large architectural work, Ponytail `lite` is usually safer than `ultra`.

