#!/usr/bin/env bash
set -u
printf '\n=== Tools ===\n'; git --version; ssh -V
printf '\n=== SSH host identities (effective) ===\n'
for host in github.com gitlab.com; do
  echo "--- $host"; ssh -G "$host" | grep -E '^(hostname|identityfile|identitiesonly) ' || :
done
printf '\n=== Account registration (SSH connection; needs network + uploaded keys) ===\n'
for host in github.com gitlab.com; do
  echo "--- $host"; ssh -o BatchMode=yes -o ConnectTimeout=10 -T "git@$host" 2>&1 || echo 'Note: ssh -T can return exit code 1 even when authentication succeeded.'
done
printf '\n=== Git identities via temporary repositories ===\n'
for provider in github gitlab; do
  dir="$HOME/dev/$provider/.git-signing-check-$$"
  mkdir -p "$dir"
  git -C "$dir" init -q
  echo "--- $provider"
  for key in user.name user.email user.signingkey gpg.format commit.gpgsign gpg.ssh.allowedSignersFile; do
    printf '%-30s %s\n' "$key" "$(git -C "$dir" config --get "$key" || echo '[not set]')"
  done
  echo 'Attempting locally signed test commit …'
  if git -C "$dir" -c core.hooksPath=/dev/null commit -q --allow-empty -m 'test: local ssh signing'; then
    git -C "$dir" log -1 --show-signature --format='%h %s'
  else echo 'Signature test failed; check agent/passphrase and key.'; fi
  rm -rf -- "$dir"
done
printf '\nNo test commit was created or pushed in a real repository.\n'
