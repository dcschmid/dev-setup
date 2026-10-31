# Changelog

## v3.15.0 — Skill maintenance, CI metadata gate, accessibility suite (2026-10-31)

- Add `mm-stack-maintenance`, a shared skill documenting how to verify, update, repair and roll back the installed stack using its own tooling (`verify-profiles.sh`, `mm-skill-audit`, `mm-project-memory-doctor`, `mm-stack-update`, `rollback-profiles.sh`).
- Remove the redundant `mm-playwright-firefox` skill; its policy is already covered by the vendored `playwright` skill and `mm-omp-code-workflow`. The vendored `playwright` skill is unchanged.
- Make `mm-skill-audit` usable offline: `--no-drift` skips installed-store drift checks, and package roots fall back to the source `payload/` when no store is installed.
- Add a CI step that validates all bundled skill metadata (frontmatter, name/description, size, conflicts) offline via `mm-skill-audit --no-drift --strict`.
- Import the `masuP9/a11y-specialist-skills` suite (WCAG 2.2 + WAI-ARIA APG) as six shared skills for Private and Working: `a11y-knowledge`, `reviewing-a11y`, `auditing-wcag`, `planning-wcag-audit`, `planning-a11y-improvement`, `implementing-a11y`. English only; Playwright MCP tool references adapted to the stack's `mm-playwright` launcher; per-skill MIT provenance recorded.
- Add `mm-screenreader-a11y`, a shared skill for screen reader and keyboard accessibility testing: automated ARIA-snapshot and keyboard passes via `mm-playwright`, plus a manual NVDA/Orca/VoiceOver checklist.

## v3.14.0 — Profile policy and maintenance repair (2026-10-30)

- Recognize OMP's serialized YAML semantically; keep browser/computer toggles and unrelated settings, reject conflicting policies, and record managed policy metadata.
- Deliver profile rules to Codex/Claude/OMP. Materialize an independent Working Codex config, limit inherited Working Claude MCPs, and remove only recognized missing Asset Forge commands.
- Extend skill audits to real YAML, symlinks, OMP, installed drift and optional plugin-cache inspection; verify memory registrations for all three clients.
- Consolidate upstream skill refresh with validation, staged publishing, recorded commits and recoverable previous versions. Preserve optional upstream skills through stack upgrades.
- Add focused CI/review skills, adapt the official Playwright skill for pinned Firefox automation and consolidate general game-development guidance.
- Provide optional verified gh/glab/ShellCheck installers and a pinned Playwright CLI; detect the Zed Delta/Git Delta name collision in shell diagnostics.
- Add offline regression coverage and a read-only CI workflow; refresh package checksum manifests.

## v3.13.4 — OMP launcher aliases / Zed Delta removal (2026-10-30)

- Bring back `omp-working` and `omp-private` as managed entrypoints; keep `yolo-*` aliases.
- Fix `LEGACY` logic that was removing the requested `omp-*` launchers.
- On upgrade, remove only identified Zed Delta installation, CLI, Claude plugin and MCP registrations in Claude, Codex and OMP, using recoverable backup copies. Never touch the ordinary Zed editor or unrelated `mcpdelta` product.
- Add a read-only scan / health check and a targeted standalone removal command.
- Preserve all existing Claude/Codex logins, profile skills, TinyContext and Private Blender MCP.


## v3.13.3 — OMP CLI Auto-Install Hotfix (2026-10-30)

- Fix the missing OMP CLI after successful stack/profile installation.
  `install-profiles.sh` now invokes `setup-omp-cli.sh --install` after safety
  preflights but before any managed stack configuration is changed.
- Use the official upstream Linux installer with forced `--binary`, avoiding
  unwanted Bun bootstrap; vendor binary SHA-256 is verified upstream.
- Skip already healthy OMP installations and refuse to overwrite a broken
  executable rather than destroying a user's prior install.
- Independent `setup-yolo-omp.sh` normal invocation also installs OMP when needed;
  `--preflight` / `--check` remain side-effect-free.
- Add OMP executable checks to `verify-profiles.sh`, idempotent Kitty/Zsh PATH
  setup if `~/.local/bin` is missing, and offline mock installer tests.
- No changes to Codex/Claude auth, YOLO credentials, TinyContext, Blender scopes,
  extensions, existing account handling, or profile isolation.

## v3.13.2 — OMP Advanced Workflows

- Scoped OMP LSP, batched subagents, opt-in isolated workspaces (no auto-apply),
  Git Guard and guarded `manage_skill` in Working/Private.
- Keep OMP native memory **off**; shared project memory remains TinyContext.
  OMP `learn` requires a separate backend and is therefore not turned on.
- Browser ON in both OMP profiles, Computer OFF until per-profile opt-in with
  explicit approval and `backgroundFallback: refuse`.
- Add a safe stage/review/SHA256-gated installer for official YOLO Todo
  Discipline, only effective for `yolo-auto/yolo` model.
- Add idempotent Zsh completion setup for Kitty; no change to Claude/Codex.

## v3.13.2 — OMP skills & safe upstream review (2026-10-29)

- Introduce one OMP-only workflow skill for LSP, tasks/worktrees, project handoffs and optional Yolo plan-first discipline; never exposed to Claude/Codex.
- Refresh project-memory wording to include OMP as a third client sharing the same TinyContext project database within each profile.
- Clarify the shared Firefox browser QA skill: OMP's Chromium browser is not automatically a Firefox Playwright test.
- Stop `mm-stack-update` from silently pulling the old GitHub MCP v1.14.0 image when v2.0.3 is already published; instead print a major-upgrade review note.
- Add a reviewed recommendation sheet for OMP, optional official Yolo Todo Discipline and upstream Working skills. No new extensions are automatically installed; no credentials, MCPs or rotation policies changed.

## v3.13.2 — Codex manual + YOLO-Auto OMP profiles (2026-10-29)

- Remove `codex-switch` and `cxswap` invocations from `codex-private` and `codex-working`; Codex now uses native authentication and **no automatic rotation**.
- Disable only the stack-managed `codex-swap-auto.service`; preserve previous account stores and existing Codex logins.
- Add `yolo-working`, `yolo-private` wrappers using OMP native named profiles with the registered YOLO-Auto provider (no custom model bridge).
- Per-profile OMP MCP configuration: TinySearch/TinyContext in both; Blender MCP 2.2.0 **private only**, and explicit Working denylist. Disable imported Claude/Codex/Gemini/OpenCode discovery for profile isolation.
- Shared TinyContext SQLite project memory remains available to Claude, Codex and OMP inside each profile; Working/Private remain separate.
- Remove bundled `mm-blender-asset-pipeline` and `mm-blender-defold-handoff` skills and previous managed links, without touching project-owned skills or Blender MCP.
- Recommend optional official Yolo Todo Discipline extension, but never fetch or execute unreviewed third-party code during installation.
- Reduce backup scope to stack-owned skills/MCP/launcher files; do **not** snapshot Codex working auth/token files; other MCP configuration backups are protected by umask 077 and must be treated as sensitive. Include non-destructive rollback, migration preflight and mock integration tests.

## v3.12.5 — Codex managed runtime switch migration (2026-10-25)

- Replace v3.12.4 cxswap launch checks with `seven332/codex-switch run` managed interactive/resume/fork sessions.
- Add explicit `setup-codex-switch.sh` with pinned Cargo install, disabling only the stack-owned old cxswap user service, no credential migration/deletion.
- Keep Claude `cswap` untouched, preserve all TinySearch/TinyContext/Blender scopes and shared project memory.
- Both Working and Private Codex managed TUIs use the same two-account pool automatically; Working preserves a separate CODEX_HOME, skills and TinyContext DB, with no Blender MCP and Work-specific skill links in its own CODEX_HOME.
- Doctor and verification report legacy competing switch service; non-interactive Codex subcommands bypass managed proxy.
- No claim of seamless replay of an in-flight request; existing cxswap tokens preserved and new codex-switch account onboarding is explicit.


## v3.12.4 — Fix broken Codex auto-switch service arguments

- **Critical fix:** cxswap `auto` does not accept `--strategy`; the previous systemd unit and pre-launch checks passed this unsupported flag. The unit therefore failed and the launchers silently suppressed the error.
- Use supported `cxswap auto --threshold 90` and `cxswap auto --once --threshold 90` syntax, report unexpected pre-launch errors, and diagnose legacy units still passing `--strategy`.
- Upgrade requires re-running `./setup-codex-swap.sh --no-install` after installing profiles to regenerate the existing stack-managed user unit; then inspect `systemctl --user status codex-swap-auto.service`.
- **Scope limitation:** cxswap only switches the account for *new* Codex processes; it cannot hot-switch an active Codex TUI. For seamless next-turn rotation consider `seven332/codex-switch` managed proxy after a separate, credential-safe migration.
- No credentials, TinyContext databases, skills, or MCP registrations intentionally altered by this hotfix beyond the normal v3.12.3 installer actions.

## v3.12.3 — Global Blender isolation repair / safe TinyContext reinstall

- Unblock fresh/migrated Fedora installations when Claude and/or Codex still have a recognized user-global `blender` MCP for `mcp-for-blender@2.2.0`.
- Preflight existing MCP definitions; back up original files; remove only the recognized global Blender entry, then configure Blender in the Private-only launcher overlay. Unknown/custom definitions are left untouched and require manual review.
- Avoid the early installer abort that previously caused missing `mm-tinycontext-path`, `mm-project-memory-doctor`, TinySearch registration and shared-memory checks.
- New migration regression tests cover original config backups, safety with unknown entries, profile isolation and account credential preservation.
- Improved verification repair hint; neither Claude/Codex account credentials nor TinyContext memories are deleted.

## v3.12.2 — Shared cross-agent project memory

- Claude Code and Codex use the same TinyContext SQLite DB for a given repository and profile.
- Git linked worktrees resolve to one canonical project identity without changing standard repo DB keys.
- Four CLI launchers bind the project path before MCP startup.
- Fixed `tinycontext-doctor` using a Private DB even when inspecting Working.
- New read-only `mm-project-memory-doctor` checks both CLI registrations and resolved memory paths.
- Documentation and regression tests cover worktrees, upgrades and Working/Private separation.
- Existing credentials, MCP scopes, account-swapping services and stored databases untouched.


## v3.12.1 — Fedora scoped MCP profiles

- TinySearch + existing TinyContext for Working and Private on both Claude Code and Codex.
- Blender MCP pinned to `mcp-for-blender@2.2.0`, injected only by `claude-private` and `codex-private` launchers.
- Global Blender registration is rejected before installation to prevent unwanted Working exposure.
- TinyContext Working and Private databases segregated; legacy Private DB locations preserved.
- No modifications to account credentials, cswap/cxswap rotations, project skills, or GPU drivers.

Previous release: v3.12.0 (Fedora Dual Swap).
