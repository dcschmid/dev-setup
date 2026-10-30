# OMP Advanced Features — Fedora v3.13.2

Reference (read upstream when upgrading):
- https://github.com/can1357/oh-my-pi/blob/main/docs/settings.md
- https://github.com/can1357/oh-my-pi/blob/main/docs/tools/task.md
- https://github.com/can1357/oh-my-pi/blob/main/docs/tools/browser.md
- https://github.com/can1357/oh-my-pi/blob/main/docs/tools/computer.md
- https://github.com/yolo-auto-org/yolo-auto-omp

## Profile matrix

Both `yolo-working` and `yolo-private` get the same capabilities but different
agent state, skills and MCP configuration. `blender` remains **private only**.
Claude/Codex MCPs, skills, and TinyContext paths are unchanged.

| Feature | Default | Change / limitation |
|---|---|---|
| OMP language server | ON | Need language server installed for the language |
| OMP `task` and async workers | ON | Do not delegate secret-bearing prompts to unrelated services |
| isolated task workspaces | ON, only with per-task `isolated: true` | `task.isolation.apply=false` avoids silently merging results; review patches |
| Git guard | ON | Prevents many destructive git changes in OMP embedded shell; no OS sandbox |
| `manage_skill` | ON | Agent can author OMP-managed skills, with approval; review each |
| `learn` | not exposed | Upstream needs an OMP memory backend; TinyContext remains the ONLY memory store |
| OMP Browser | ON | Uses Chromium/CDP; separate from Firefox Playwright tests |
| OMP Computer | OFF | Explicit opt-in needed; real host desktop input with per-tool approval |
| OMP Hindsight / Mnemopi / local memory | OFF | Keep project memory centralized in TinyContext |
| YOLO Todo Discipline | STAGED, optional | Official extension matches **only** `yolo-auto/yolo`, not `yolo-auto/qwen3.8-27b` |
| OMP completions | helper | `./setup-omp-completions.sh --install` |

### Configured protection

The managed YAML is under `~/.omp/profiles/{working,private}/agent/config.yml`
and is enclosed by `BEGIN/END FRONTEND-AI-STACK OMP WORKFLOW` comments.
It modifies neither model authentication nor external coding-client profiles.
It does not overwrite user-owned conflicting YAML keys, and it preserves the
browser/computer switch choices across ordinary upgrades.

Toggle desktop/browser for both or one profile:

```bash
./setup-omp-features.sh --profile private --computer on
./setup-omp-features.sh --profile working --browser off
./setup-omp-features.sh --check
```

`computer` uses `backgroundFallback: refuse` and `tools.approval.computer:
prompt` plus a separate foreground-control prompt, even if YOLO uses broad
automatic approval. Take care with desktop screenshots, logins and work files.
Computer tooling and native permissions may not work fully with Wayland.
Launch fresh OMP session after changing configuration.

### Official Todo Discipline

The official extension is third-party executable TypeScript from a mutable
GitHub URL. **Do not fetch and execute it implicitly.** To opt in:

```bash
./setup-yolo-todo.sh --stage
# Inspect ~/.cache/frontend-ai-stack/yolo-todo-discipline.ts
sha256sum ~/.cache/frontend-ai-stack/yolo-todo-discipline.ts
./setup-yolo-todo.sh --enable <sha256-from-above>
./setup-yolo-todo.sh --check
```

Disable safely (only if file has not changed from managed hash):

```bash
./setup-yolo-todo.sh --disable
```

The upstream extension enforces plan-first only with model `yolo-auto/yolo`.
Switch to this model using `/model` when plan-first hard gating is desired.
On `yolo-auto/qwen3.8-27b` our `mm-omp-code-workflow` skill gives advisory
planning, not a hard technical gate. New sessions are required to load
extensions. Review upstream source changes before upgrading the extension.

### LSP, subagents and isolated workspaces

Use `lsp` when language servers are available. `task` can split large work; an
isolated task needs `isolated: true` and user review of its changes. OMP may
use `overlayfs`, `rcopy`, or another isolation backend; isolated workspace is
**not necessarily a Git worktree**. Git worktrees can be used manually for
feature branches, but no cleanup or destructive merge is automated here.

For a substantial change, ask OMP to plan, split reviewable subtasks, produce
patches or commits, run tests, and finally save durable project decisions with
TinyContext. `manage_skill` may create/update repeatable procedures **only
with review and consent**. `learn` deliberately stays unavailable because its
native storage would duplicate TinyContext. Save reusable facts through the
TinyContext MCP rather than adding another memory backend.

### Native browser/computer & test coverage

OMP Browser automates Chromium/CDP interactions and is not equivalent to
Playwright Firefox. Keep Firefox tests in the existing testing skill.
Computer uses native host desktop access and may require desktop permissions.
Never give a background worker unattended access to credentials, production
admin systems or your employer's account without authorization.

### Kitty / Zsh

```bash
./setup-omp-completions.sh --install
exec zsh
```

This adds one idempotent, guarded `source` block to `.zshrc` and writes a
reusable Zsh snippet to `~/.config/frontend-ai-stack/omp-completions.zsh`.
It does not install a framework, modify Kitty config or provide completions if
`omp` itself is missing.
