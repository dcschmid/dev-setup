---
name: mm-omp-code-workflow
description: OMP-only guide for YOLO-Auto coding: native LSP, tasks, worktrees, safe extensions and shared TinyContext project memory.
---
# Efficient OMP coding workflow (Working / Private)

This skill belongs to the OMP profile only. It must not be linked into Claude Code or Codex, and it does not change the YOLO-Auto model or billing plan.

1. Discover existing repository instructions, project architecture and tests before changing files. Use built-in `lsp` for symbols, references, diagnostics and rename/code actions where a matching language server is available; otherwise use repository tools without inventing LSP results.
2. For a substantial task, write a short, checkable implementation plan and maintain a todo list. If the official `yolo-todo-discipline.ts` extension has been reviewed and explicitly enabled, follow its plan-first gate. Do not install that extension automatically.
3. Use built-in `task` subagents only for independent bounded subproblems where parallelization saves work. Use separate Git worktrees for concurrent file edits, verify output, and never automatically delete or discard uncommitted user work.
4. For UI validation, use an actually available browser tool and validate interactions, errors and accessibility. OMP's browser is not proof of Firefox compatibility. Use the project's Playwright Firefox tests where configured.
5. For project continuity, use `mm-tinycontext` to retrieve concise existing decisions and save durable checkpoints for Claude/Codex/OMP handoff. The same Git repository and profile share a database; Working and Private must remain isolated. Do not enable another memory backend to duplicate TinyContext by default.
6. Use `learn` and `manage_skill` sparingly and only for reusable, verified techniques; review new or changed skills before keeping them. Do not install marketplace plugins, download executables or change repo settings just because the model suggests doing so.
7. Respect profile MCP boundaries: TinySearch/TinyContext in both profiles; Blender MCP only in Private. Repository-owned `.omp` sources may still contribute tools; inspect unexpected project capabilities before executing code. Do not stream or share sessions containing employer code without explicit approval.
8. Finish substantial changes with relevant tests or runtime evidence and a concise handoff (changed files, validation, remaining issues). Never report unrun tests as passed.

## Fedora v3.13.2 OMP feature policy

- `lsp` is enabled on-demand; language servers and edit validation still have to be checked.
- For parallel tasks request `isolated: true` only for independent bounded work. Isolated
  changes do not auto-apply. Validate and merge only after explicit review.
- Browser is enabled in both profiles, but does not validate Firefox behavior.
- Native host `computer` remains off until expressly enabled and approval is granted.
- `autolearn.enabled` exposes `manage_skill`; **`learn` is unavailable** while
  `memory.backend: off`. Store durable learnings via profile-scoped TinyContext
  before requesting any managed-skill creation or update.
- The official YOLO Todo Discipline extension must be SHA256-reviewed and enabled;
  its strict gate applies only to `yolo-auto/yolo`, not the default Qwen model.
