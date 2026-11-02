# 01 · Installation on Fedora Workstation

## Prerequisites and checks

Fedora Workstation 44, Git, OpenSSH client, access to **both** accounts, and the verified commit email addresses belonging to them. No GPG installation required. Before running anything, check your company policies (especially any mandated signing method).

```bash
sudo dnf install -y git openssh-clients
git --version
ssh -V
```

Git needs version >= 2.34 for SSH commit signatures; OpenSSH should be reasonably current.

## Start the setup

```bash
bash scripts/setup.sh
```

The script interactively asks for your name and both email addresses. It creates four keys (if they do not exist yet) and asks for a passphrase for **each new key**. It creates or updates:

- `~/.ssh/id_ed25519_github` + `.pub` (GitHub auth)
- `~/.ssh/id_ed25519_github_signing` + `.pub` (GitHub signing)
- `~/.ssh/id_ed25519_gitlab` + `.pub` (GitLab auth)
- `~/.ssh/id_ed25519_gitlab_signing` + `.pub` (GitLab signing)
- `~/.ssh/config.framework-git` and an Include at the **top** of `~/.ssh/config`
- `~/.gitconfig-github` and `~/.gitconfig-gitlab`
- the global `~/.gitconfig`: includes, SSH signing, mandatory identity, practical Git defaults
- `~/.ssh/allowed_signers` for local verification of your own signatures

Existing private key files are never overwritten. Timestamped backups are created before any change to Git configuration files and the allowed signers. An existing `config.framework-git` is not overwritten: **review it manually when making changes**.

## Register the public keys in your accounts

**Never** share, upload, or copy the files without `.pub` into tickets or chats.

```bash
cat ~/.ssh/id_ed25519_github.pub
cat ~/.ssh/id_ed25519_github_signing.pub
cat ~/.ssh/id_ed25519_gitlab.pub
cat ~/.ssh/id_ed25519_gitlab_signing.pub
```

**GitHub**: https://github.com/settings/keys

1. Add `id_ed25519_github.pub` as an **Authentication Key**.
2. Add `id_ed25519_github_signing.pub` as a **Signing Key**.
3. The commit email must match your GitHub account (a verified address or the matching GitHub noreply address).

**GitLab.com**: https://gitlab.com/-/user_settings/ssh_keys

1. Add `id_ed25519_gitlab.pub` as **Authentication**.
2. Add `id_ed25519_gitlab_signing.pub` as **Signing**.
3. GitLab supports the usage types Authentication, Signing, or both; here they are deliberately kept separate.
4. The commit email must match your account for signature attribution.

## Test SSH authentication

```bash
ssh -T git@github.com
ssh -T git@gitlab.com
```

On first contact, compare the host fingerprint with the provider's official host keys **before accepting**. The plain SSH test on GitHub or GitLab can return **exit code 1 even when authentication succeeded**, because no shell is provided. The greeting/success message is what matters.

After registration:

```bash
bash scripts/verify.sh
```

This test creates temporary test repositories under `~/dev/github` and `~/dev/gitlab`, performs one locally signed commit in each where possible, and removes the temporary directories. Nothing is pushed. On the command line it only prints configured emails and public key paths.

## Agent under Fedora / GNOME

```bash
echo "$SSH_AUTH_SOCK"
ssh-add -l
```

If a working agent is present, you can load the keys for the session:

```bash
ssh-add ~/.ssh/id_ed25519_github ~/.ssh/id_ed25519_gitlab
ssh-add ~/.ssh/id_ed25519_github_signing ~/.ssh/id_ed25519_gitlab_signing
```

Do not blindly start a second agent instance; GNOME/Keyring/Wayland/terminal integration differs. Passphrase prompts are normal until your active agent/keyring configuration has unlocked the keys.
