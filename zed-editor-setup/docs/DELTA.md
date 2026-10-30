# Delta by Zed Industries · Integration into the Framework Devkit

Status: 2026-10-30. Delta is a **separate** beta application alongside the Zed editor. The Git CLI `git-delta` (pager) is **not** the same thing and may already occupy the `delta` command.

## Usage recommendation

- **Zed**: daily editor for Astro/Next.js/TypeScript/Defold, Claude/Codex ACP or CLI, OMP via terminal.
- **Delta**: agent threads, multi-step changes, reviews with traceable history between commits, occasional collaboration.
- GitHub and GitLab remain the source of truth. Delta uses the existing Git repositories and requires a Git remote connection for projects.

## Prerequisites

Linux x86_64 with glibc, a Zed account, plus online sign-in to Delta and acceptance of the Delta early-access agreement. Delta runs on Fedora (system libraries must be compatible). The free Personal tier supports your own API keys/external agents; the paid Pro tier supports hosted models. Details: https://delta.dev/pricing.

## Safe installation (optional)

```bash
./scripts/install-delta.sh --dry-run
./scripts/install-delta.sh --install
./scripts/install-delta.sh --status
```

The wrapper downloads the **official** script `https://delta.dev/install.sh` over HTTPS into a temporary file and executes it. Inspect the source yourself before running it, if needed. It installs into `~/.local/delta.app` and links `~/.local/bin/delta`; the wrapper does not overwrite a foreign CLI of the same name. No `sudo`. After installation, restart Kitty/Zed if needed so the PATH is updated.

Alternatively, obtain the app from https://delta.dev/download as a Linux x86_64 archive and use the official installation guide: https://delta.dev/docs/installation.

Start: `delta` or the Zed task **Delta · Open collaboration app (optional)**. Sign in on the Delta welcome screen. Plan separate workspaces in Zed and Delta, since Delta does **not** simply run as an ACP panel inside Zed.

## Agents · What is actually supported

**Claude Code**: official Delta plugin for syncing existing Claude CLI sessions (Claude Code 2.1.303+ and Delta 0.22.0+). The Devkit does **not** install it automatically:

```bash
claude plugin marketplace add zed-industries/delta-claude
claude plugin install delta@zed-industries
```

Start a new Claude session, check `/delta`, and use `/delta share` once if needed. Do **not** set `/delta setup` to automatic team synchronization before private/professional data boundaries are clarified. Before use, check plugin compatibility with the existing `cswap` rotation in a test session. Do not confuse the plugin/Claude installation with the Devkit installer.

**Codex CLI**: an equivalent official Delta session synchronization is not documented. The Delta app itself can use OpenAI models via a ChatGPT Plus/Pro login (separate from the Codex CLI agent). This does not mean that existing Codex sessions are imported automatically. Leave Codex in Zed via ACP/CLI unchanged.

**YOLO-Auto / OMP**: the integration for Pi is still in progress according to the Delta roadmap/CLI; no equivalent finished official integration is documented for OMP. Therefore, continue using YOLO-Auto separately in Zed terminal threads.

**Local models**: Delta can also connect compatible OpenAI/Anthropic endpoints on the desktop; that is a separate model provider and no direct connection to TinySearch/TinyContext/MCP. MCP support is still in progress according to the roadmap. Do not set up local endpoints automatically.

## Data protection · especially important for professional GitLab repositories

Delta is not a purely local Git diff viewer. Sharing/sync can synchronize **uncommitted**, **unstaged**, and **untracked** files, messages, tool inputs/outputs, and images to DeltaDB. Git-ignored files are excluded according to the plugin documentation; that does not replace a security check, however. Team sharing can make data accessible to all organization members. Once shared sessions cannot easily be switched back to private according to the documentation. Safest: start with a demo/test repo, manual `/delta share`, visibility set to *Just me*, no `.env`/credentials in the history; comply with company policy before use.

The Devkit installer **sets up neither the Delta plugin nor sync**. The optional Delta app requires an internet connection and an account for workspaces. If you stay offline for security reasons, continue using Zed + local CLI agents.

## Updates and troubleshooting

```bash
./scripts/install-delta.sh --update  # update the Delta app via the official CLI
# alternatively:
delta update --check
delta update
```

If `delta` instead runs `git-delta`: check `type -a delta`, `readlink -f ~/.local/bin/delta`. Do not overwrite an existing Git diff pager binary without asking. Further details and an alternative installation: https://delta.dev/docs/installation.

Sources: https://delta.dev/docs/installation · https://delta.dev/docs/cli/claude-code · https://delta.dev/docs/agents/models-and-providers · https://delta.dev/pricing · https://delta.dev/roadmap.
