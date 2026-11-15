# dev-setup

My development setup for a Framework Laptop 16 running Fedora 44 with KDE Plasma or GNOME on Wayland. This repository brings together four packages: a terminal workspace, a Zed configuration, Git authentication and signing, and separate Working and Private profiles for three coding agents.

Install the parts you need. Each package has its own entry point and can be maintained separately.

## Choose a package

| Package | Use it for | Start here |
|---|---|---|
| Frontend AI Optimized Stack | Claude Code, Codex CLI and YOLO-Auto through Oh My Pi; profile rules, skills, search and project memory | [Agent stack README](frontend-ai-optimized-stack/README.md) |
| Kitty Workspace Pack | Kitty and Zsh, saved tab layouts, shell tools, Node setup and worktree helpers | [Terminal README](kitty-terminal-setup/README.md) |
| Zed Framework Devkit | Editor settings, language support, project tasks and access to existing coding agents | [Editor README](zed-editor-setup/README.md) |
| SSH and commit signing | Separate GitHub and GitLab identities, authentication keys and signing keys | [SSH README](ssh-setup/README.md) |

## Start from a checkout

The commands in this documentation assume this repository is at `~/dev/github/dev-setup`. Adjust that path if your checkout lives elsewhere. You do not need a release ZIP.

```bash
cd ~/dev/github/dev-setup
git status --short
```

Read each package's installation notes before running its installer. A practical order for a new machine is:

1. Set up SSH and Git identities so private and work repositories use the intended account.
2. Install the Kitty configuration and the shell tools you want.
3. Install the agent stack, then sign in to each client/profile you intend to use.
4. Configure Zed and open a repository.

This is an onboarding order, not a dependency chain. Zed and SSH do not require the agent stack; Kitty does not install it.

## Use the skills in daily work

Start a profile from the repository you want to work on:

```bash
cd ~/dev/github/dev-setup
codex-private
# Alternatives: claude-private or omp-private
```

Then write a normal request in the agent conversation:

```text
Use documentation-technical-writing and human-writing to improve this
repository's READMEs in English. Check every command against the scripts,
include realistic examples, and report anything you could not verify.
```

That example requires those two skills to be installed and visible in the selected client. The stack's bundled skills and your separately installed skill collection are different inventories. A skill installed in one client is not automatically available in another.

For a bundled workflow, try:

```text
Use project-memory to recall the decisions relevant to this repository.
Then explain the constraints that affect the task I am about to give you.
```

For work repositories, start `codex-working`, `claude-working` or `omp-working` from the work checkout. Keep Working and Private sessions separate. OMP carries out its own tasks through YOLO-Auto; it does not delegate to Claude or Codex.

The [skill usage guide](frontend-ai-optimized-stack/docs/SKILL_USAGE.md) explains all three clients, terminal and Zed workflows, bundled skills, examples for the additional collection, precedence, updates and troubleshooting.

## How the packages fit together

```text
dev-setup/
├── frontend-ai-optimized-stack/  # agent launchers, profile rules, skills and MCP setup
├── kitty-terminal-setup/        # terminal configuration and shell helpers
├── zed-editor-setup/            # editor configuration and project tasks
└── ssh-setup/                   # Git identities, SSH and commit signing
```

Kitty provides a terminal in which you can launch an agent. Zed can open a terminal in the same repository. The agent stack determines the profile, available managed skills and MCP configuration. Git uses its own identity and signing configuration, which is selected separately by repository path.

Skills describe how an agent should approach a task. MCP servers provide tools such as search, project memory or Blender access. Installing a skill does not install the application, grant access to an account or start the corresponding service.

## Installation and data boundaries

Run installers as your normal user. Some dependency helpers invoke `sudo dnf` for system packages; configuration installation and system package installation are separate operations. For example, Kitty's `--config-only` option avoids dependency downloads and upgrades.

The packages have different backup and recovery mechanisms. Read the package-specific instructions before changing an existing setup. Re-running an installer is supported, but backup behavior is not identical across packages. Zed merges JSONC configuration and writes JSON, so comments and formatting are retained only in the original backup.

Credentials belong to the tools that use them. Never commit private keys, tokens, local secret files or configuration backups. MCP configuration files can contain secrets even when the agent stack leaves login stores untouched.

Terminal session persistence restores layout and directories. It does not resume running agents or development servers. Shared TinyContext memory stores selected project facts within a profile; it does not synchronize full conversations.

## Check and maintain the setup

Run checks from the relevant package directory:

| Package | Check | Recovery reference |
|---|---|---|
| Agent stack | `./verify-profiles.sh` | [Maintenance and rollback](frontend-ai-optimized-stack/README.md#maintenance-and-rollback) |
| Kitty | `./shell-doctor.sh` and `./state-status.py` | [Session recovery](kitty-terminal-setup/PERSISTENT-STATE.md) |
| Zed | `./scripts/check.sh` | [Rollback](zed-editor-setup/README.md#maintenance-updates-and-rollback) |
| SSH | `bash scripts/verify.sh` | [Troubleshooting](ssh-setup/docs/03-TROUBLESHOOTING.md) |

The target environment is Fedora 44 on the Framework Laptop 16. Other systems need their own validation. Historical reviews and changelogs record the state at the time they were written; they are not live upstream version catalogs.
