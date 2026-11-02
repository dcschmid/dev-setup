# Framework 16 · Fedora · GitHub/GitLab SSH & Commit Signing

**Documentation package v1.0 · 2026-11-02**

Private GitHub and work GitLab.com with **four separate Ed25519 keys**: one for authentication and one for commit signing per provider. Git picks the right identity based on the repository path. Suitable for Fedora Workstation, Kitty, Zed, Claude Code, and Codex (all of them use plain Git).

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

## Official references

- GitHub: https://docs.github.com/en/authentication/managing-commit-signature-verification/telling-git-about-your-signing-key
- GitHub SSH keys: https://github.com/settings/keys
- GitLab SSH keys: https://docs.gitlab.com/user/ssh/
- GitLab settings: https://gitlab.com/-/user_settings/ssh_keys
- GitLab SSH signatures: https://docs.gitlab.com/user/project/repository/signed_commits/ssh/

Status: 2026-11-02. Platform UIs may change.
