# 03 · Troubleshooting

| Problem | Check and fix |
|---|---|
| `Permission denied (publickey)` | Is the public **auth** key registered in the right provider account? `ssh -vT git@gitlab.com`; `ssh -G gitlab.com \| grep identityfile` |
| Wrong SSH key | Check existing host blocks / other `Include` files. `ssh -G github.com` and `ssh -G gitlab.com` show the effective identities. |
| `Author identity unknown` | Is the repository under `~/dev/github/` or `~/dev/gitlab/`? `git config --show-origin --get user.email` |
| Commit not signed | `git config --show-origin --get commit.gpgsign`, `git config user.signingkey`, key files, and passphrase/agent. |
| `No principal matched` | `~/.ssh/allowed_signers` must match the commit email and the public signing key. Check `git config gpg.ssh.allowedSignersFile`. |
| Valid locally, `Unverified` online | Register the public key as **Signing**, and check commit email/account attribution and platform policies. |
| Host key warning | Abort the connection; verify the host fingerprint via an independent official source. Do not simply delete from `known_hosts`. |
| `ssh-add` reports agent errors | `echo "$SSH_AUTH_SOCK"`; check GNOME SSH agent/session integration; do not carelessly start a second competing agent. |
| Signing prompt on every commit | Check the signing private key's passphrase, the agent, and the desktop keyring. Do not use empty passphrases as a supposed default fix. |

## List configuration and precedence

```bash
git config --global --list --show-origin
ssh -G gitlab.com | grep -E '^(hostname|identityfile|identitiesonly) '
```

## Recovery

The setup creates backups as `~/.gitconfig.backup.YYYYMMDD-HHMMSS`, `~/.gitconfig-github.backup.*`, `~/.gitconfig-gitlab.backup.*`, `~/.ssh/config.backup.*`, and `~/.ssh/allowed_signers.backup.*` if previous files existed. Changes to `~/.ssh/config.framework-git` are **not** overwritten. Restore old configurations only deliberately, after reviewing them; do not blindly remove existing keys of other projects.

## Separate configuration for deviating working directories

If a repository should live outside `~/dev/...`, either add an additional `includeIf` or set `git config user.email ...` and `git config user.signingkey /absolute/path/key.pub` locally in that repository. For worktrees, check whether the actual Git directory matches the rule (`git rev-parse --absolute-git-dir`).
