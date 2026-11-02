#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

if [[ $EUID -eq 0 ]]; then echo 'Do NOT run as root.' >&2; exit 1; fi
for bin in git ssh-keygen ssh; do command -v "$bin" >/dev/null || { echo "Missing: $bin (sudo dnf install git openssh-clients)" >&2; exit 1; }; done

read -r -p 'Git display name (for both accounts): ' git_name
read -r -p 'Verified GitHub commit email: ' github_email
read -r -p 'Verified GitLab commit email: ' gitlab_email
for val in "$git_name" "$github_email" "$gitlab_email"; do [[ -n "$val" && "$val" != *$'\n'* ]] || { echo 'Invalid/missing input' >&2; exit 1; }; done
[[ "$github_email" == *@* && "$gitlab_email" == *@* ]] || { echo 'Please enter valid email addresses.' >&2; exit 1; }

mkdir -p "$HOME/.ssh" "$HOME/dev/github" "$HOME/dev/gitlab"
chmod 700 "$HOME/.ssh"

create_key() {
  local key="$1" label="$2"
  if [[ -e "$key" || -e "$key.pub" ]]; then
    if [[ -f "$key" && -f "$key.pub" ]]; then echo "Existing key pair kept: $key"; return; fi
    echo "Incomplete key pair for $key — aborting without overwriting." >&2; exit 1
  fi
  echo "Creating key $key — please enter a strong passphrase."
  ssh-keygen -t ed25519 -a 64 -C "$label" -f "$key"
}
create_key "$HOME/.ssh/id_ed25519_github" 'github-auth-framework16'
create_key "$HOME/.ssh/id_ed25519_github_signing" 'github-sign-framework16'
create_key "$HOME/.ssh/id_ed25519_gitlab" 'gitlab-auth-framework16'
create_key "$HOME/.ssh/id_ed25519_gitlab_signing" 'gitlab-sign-framework16'

backup() { if [[ -f "$1" ]]; then local dst="$1.backup.$(date +%Y%m%d-%H%M%S)"; cp -p "$1" "$dst"; echo "Backup: $dst"; fi; }
# Separate file instead of overwriting existing host blocks.
ssh_hosts="$HOME/.ssh/config.framework-git"
if [[ ! -e "$ssh_hosts" ]]; then
cat > "$ssh_hosts" <<'CONF'
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github
    IdentitiesOnly yes
    AddKeysToAgent yes

Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_ed25519_gitlab
    IdentitiesOnly yes
    AddKeysToAgent yes
CONF
else echo "Existing $ssh_hosts kept — please review."; fi
chmod 600 "$ssh_hosts"
sshconfig="$HOME/.ssh/config"
if [[ -f "$sshconfig" ]]; then
  if ! grep -Fxq 'Include ~/.ssh/config.framework-git' "$sshconfig"; then
    backup "$sshconfig"
    tmp=$(mktemp "$HOME/.ssh/config.XXXXXX")
    { printf 'Include ~/.ssh/config.framework-git\n'; cat "$sshconfig"; } > "$tmp"
    chmod 600 "$tmp"; mv "$tmp" "$sshconfig"
  fi
else printf 'Include ~/.ssh/config.framework-git\n' > "$sshconfig"; fi
chmod 600 "$sshconfig"

# Write via git config instead of hand-rolled INI to handle special characters safely.
write_identity() {
  local file="$1" email="$2" key="$3"
  backup "$file"
  git config --file "$file" user.name "$git_name"
  git config --file "$file" user.email "$email"
  git config --file "$file" user.signingkey "$key"
}
write_identity "$HOME/.gitconfig-github" "$github_email" "$HOME/.ssh/id_ed25519_github_signing.pub"
write_identity "$HOME/.gitconfig-gitlab" "$gitlab_email" "$HOME/.ssh/id_ed25519_gitlab_signing.pub"

backup "$HOME/.gitconfig"
git config --global init.defaultBranch main
git config --global core.autocrlf input
git config --global fetch.prune true
git config --global push.autoSetupRemote true
git config --global gpg.format ssh
git config --global commit.gpgsign true
git config --global tag.gpgsign true
git config --global user.useConfigOnly true
git config --global 'includeIf.gitdir:~/dev/github/.path' "$HOME/.gitconfig-github"
git config --global 'includeIf.gitdir:~/dev/gitlab/.path' "$HOME/.gitconfig-gitlab"

allowed="$HOME/.ssh/allowed_signers"
backup "$allowed"
# Only manage own email principal entries; other existing entries are kept.
tmp=$(mktemp "$HOME/.ssh/allowed_signers.XXXXXX")
if [[ -f "$allowed" ]]; then grep -vF '# framework-git-managed' "$allowed" > "$tmp" || :; fi
# The end-of-line comments serve as the idempotent replacement marker.
printf '%s %s # framework-git-managed\n' "$github_email" "$(cat "$HOME/.ssh/id_ed25519_github_signing.pub")" >> "$tmp"
printf '%s %s # framework-git-managed\n' "$gitlab_email" "$(cat "$HOME/.ssh/id_ed25519_gitlab_signing.pub")" >> "$tmp"
chmod 600 "$tmp"; mv "$tmp" "$allowed"
git config --global gpg.ssh.allowedSignersFile "$allowed"

printf '\nDONE. Register the public keys in your accounts:\n'
for x in github github_signing gitlab gitlab_signing; do echo "  $HOME/.ssh/id_ed25519_${x}.pub"; done
printf '\nThen: bash scripts/verify.sh\n'
printf 'Check for conflicting existing SSH host rules: ssh -G gitlab.com | grep -E "^(hostname|identityfile|identitiesonly) "\n'
