# OMP / Skills update review — 2026-10-29

This file documents *verified candidates*, not an assertion about the exact versions on your laptop. Nothing below installs itself when you install the stack.

## OMP

- OMP upstream moved quickly in October 2026; use `omp --version` then review <https://github.com/can1357/oh-my-pi/releases> and <https://www.npmjs.com/package/@oh-my-pi/pi-coding-agent> before upgrading. Avoid asserting a latest release from a stale build artifact.
- Native LSP, `task`/subagents, Git worktree isolation, todo, `learn`/`manage_skill`, shell completions and optional model roles already exist. Prefer these native features to extra extensions and MCPs.
- Yolo-Auto is a registered provider; login separately per named OMP profile using `/login yolo-auto`. Do not hard-code keys.
- The official Yolo Todo Discipline extension is appropriate for the `yolo-auto/yolo` router. It is NOT needed for every model; source: <https://github.com/yolo-auto-org/yolo-auto-omp>. Review TypeScript source before putting it in any `extensions/` directory. For named profiles, use `~/.omp/profiles/{working,private}/agent/extensions/`, not the default profile's path.
- OMP's optional Hindsight memory backend duplicates the current TinyContext function. Keep OMP memory off unless a separate deliberate memory migration is planned.
- Native `.omp` project config (including extensions, hooks and MCPs) can change effective behavior; verify unexpected repo-local config, especially under Working. Profile-specific user MCP denylist `disabledServers: ["blender"]` guards the server named blender, but aliases require review.

## Skills inventory

- 13 local package skills in v3.13.0: 3 shared, 3 Working, 7 Private. Blender skills remain intentionally absent.
- v3.13.1 adds **one OMP-only** skill, `mm-omp-code-workflow`, installed only into OMP Working/Private, not Claude/Codex.
- Update `project-memory` to name all three agents and clarify that this is curated shared memory, not automatic chat sync.
- Clarify that the shared Playwright/Firefox skill requires an actually available Playwright integration; OMP's default browser does not by itself validate Firefox.
- Update Working upstream skills (Vercel React and Figma) only from the project-maintained updater; review git commit recorded under `~/.local/share/frontend-ai-stack/upstream/` after the update. Never replace project-owned skills. Verify presence and capability before relying on any skill requiring a connected MCP.

## GitHub MCP

Our updater in v3.13.0 still pinned `ghcr.io/github/github-mcp-server:v1.14.0`. GitHub MCP Server v2.0.3 is published as of Oct 21, 2026. This is a **major version** with MCP-protocol and schema changes; do not auto-replace a working v1 installation. Evaluate v2 with a separate compatibility test for the real clients and permissions before changing the production pin. See <https://github.com/github/github-mcp-server/releases>.

## Upgrade and diagnosis on Fedora

```bash
# read-only
omp --version
omp models yolo-auto
mm-skill-audit
mm-yolo-doctor
mm-stack-audit

# optional OMP shell completion for the current zsh session
# (put in ~/.zshrc only after confirming omp works)
eval "$(omp completions zsh)"

# optional: refresh only approved Working upstream skills after reviewing source
./install-working-upstream-skills.sh
```

## Optional Todo Discipline — manual installation

Inspect: <https://github.com/yolo-auto-org/yolo-auto-omp/blob/main/yolo-todo-discipline.ts>

Download to a local staging file and review it. Then copy the reviewed file separately into the *named profiles* where desired:

```bash
curl -fsSL https://raw.githubusercontent.com/yolo-auto-org/yolo-auto-omp/main/yolo-todo-discipline.ts -o /tmp/yolo-todo-discipline.ts
less /tmp/yolo-todo-discipline.ts
sha256sum /tmp/yolo-todo-discipline.ts
mkdir -p ~/.omp/profiles/private/agent/extensions
cp -i /tmp/yolo-todo-discipline.ts ~/.omp/profiles/private/agent/extensions/
# optionally do the same for working, only if company policy allows the extra code
```

A future upstream revision may change behavior: re-review the source rather than using an unpinned silent auto-updater. Restart OMP after adding extensions.
