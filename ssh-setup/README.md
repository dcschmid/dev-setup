# Framework 16 · Fedora · GitHub/GitLab SSH & Commit Signing

**Documentation package v1.0 · 2026-11-02**

Private GitHub and work GitLab.com with **four separate Ed25519 keys**: one for authentication and one for commit signing per provider. Git picks the right identity based on the repository path. Suitable for Fedora Workstation, Kitty, Zed, Claude Code, and Codex (all of them use plain Git).

## Start from this repository

```bash
cd ~/dev/github/dev-setup/ssh-setup
```

Read [the installation guide](docs/01-INSTALLATION.md) before running the setup,
especially if SSH host blocks or Git identities already exist. Run the scripts
as your normal user. Installing missing Fedora packages may require `sudo`.

## Quick start

1. Unpack the package and open a terminal in the package folder.
2. Prerequisites: `sudo dnf install -y git openssh-clients`.
3. **Before running anything**, read `docs/01-INSTALLATION.md` — especially the notes on existing configurations and company security policies.
4. Start the setup: `bash scripts/setup.sh` — enter your display name and the verified GitHub/GitLab email addresses. Keys are created interactively, each with its own passphrase.
5. Register the four `.pub` files in GitHub/GitLab with the matching key types — instructions in `docs/01-INSTALLATION.md`.
6. Verify: `bash scripts/verify.sh`.
7. Clone or migrate repositories according to `docs/02-REPOSITORIES.md`.

**Note:** The package never acts on its own. It uploads no private keys and pushes no test commits.

## Contents

| File | Purpose |
|---|---|
| `scripts/setup.sh` | Interactive, re-runnable setup; existing key pairs are left untouched |
| `scripts/verify.sh` | SSH and Git checks, local signature tests in temporary repositories |
| `docs/01-INSTALLATION.md` | Installation steps, account registration, key handling |
| `docs/02-REPOSITORIES.md` | Cloning, existing repositories, the nested work GitLab group |
| `docs/03-TROUBLESHOOTING.md` | SSH agent, Verified status, configuration conflicts, recovery |
| `docs/04-SECURITY.md` | Security model, backups, rotation, company policies |
| `examples/` | Readable configuration examples — **not** usable as-is with real identities |

## Folder concept

```text
~/dev/
├── github/                         # private
│   └── riff-racers/
└── gitlab/                         # work
    └── unified-frontend/
```

For **Unified Frontend**: `git@gitlab.com:ndrde/code/unified-sophora/frontend/unified-frontend.git`.

**Important:** The provider is selected by the local location, not by the remote URL. A correct clone destination and a controlled Git identity before the first commit therefore matter.

## Verify the identity inside a real checkout

The directory rules select the Git identity. The agent profile selects skills,
MCPs and agent settings. Check both when starting a project; neither replaces
the other.

```bash
cd ~/dev/github/dev-setup
git config --show-origin --get user.name
git config --show-origin --get user.email
git config --show-origin --get user.signingkey
git config --get commit.gpgsign
git remote -v
```

Use the equivalent checks from `~/dev/gitlab/unified-frontend` for work. Local
repository settings, environment overrides and isolated tool environments can
change the effective identity, so check from the actual checkout and workflow.
After creating a signed commit, inspect it with:

```bash
git log -1 --show-signature
```

Local signature verification and a provider's Verified badge are separate checks.
Register the public signing key with the appropriate account as described in the
installation guide. Never upload the matching private key.

## Use this setup with coding agents and skills

SSH and signing work through Git; they do not require a coding skill. After
installing the separate [agent stack](../frontend-ai-optimized-stack/README.md),
launch the intended client from a correctly located repository:

```bash
cd ~/dev/github/dev-setup
codex-private
# Alternatives: claude-private or omp-private
```

In the agent conversation:

```text
Use mm-github-workflow to inspect this repository's remote context if needed.
Check local Git status and the effective author and signing configuration.
Keep this inspection read-only; do not create commits or push changes.
```

For work, use a Working launcher in the GitLab checkout and ask for
`mm-gitlab-workflow`. Git SSH authentication does not automatically authenticate
`gh`, `glab` or a GitHub/GitLab MCP. Those integrations need their own authorized
account setup.

If installed in the selected client, the writing skills can help maintain these
guides too:

```text
Use documentation-technical-writing and human-writing to explain this SSH setup
in plain English. Verify paths against the scripts, use placeholders for personal
information, and never include private keys or tokens.
```

The [skill usage guide](../frontend-ai-optimized-stack/docs/SKILL_USAGE.md) explains
which skills are bundled and which belong to the additional collection.

## Recovery and key rotation

Existing complete key pairs are kept. An incomplete pair causes the setup to
stop rather than overwrite it. Review the reported path and follow
[troubleshooting](docs/03-TROUBLESHOOTING.md) before trying again.

Read [the security guide](docs/04-SECURITY.md) for backups, passphrases and key
rotation. Removing local configuration does not revoke keys registered with a
provider. If a private key is exposed, revoke the corresponding registered key
and replace it through the documented rotation process.

## Official references

- GitHub: https://docs.github.com/en/authentication/managing-commit-signature-verification/telling-git-about-your-signing-key
- GitHub SSH keys: https://github.com/settings/keys
- GitLab SSH keys: https://docs.gitlab.com/user/ssh/
- GitLab settings: https://gitlab.com/-/user_settings/ssh_keys
- GitLab SSH signatures: https://docs.gitlab.com/user/project/repository/signed_commits/ssh/

Status: 2026-11-02. Platform UIs may change.
