# 04 · Security & Operations

## Key principles

- **Never** upload private SSH keys (`id_ed25519_*` without `.pub`) to Git, chat, cloud notes, screenshots, or tickets.
- Use separate **auth and signing keys** for the private and work identities; protect them with strong passphrases.
- `~/.ssh` on mode 700, private keys and config on 600. `ssh-keygen` sets safe key permissions.
- **Do not** trust unknown SSH host fingerprints. Compare official provider host keys independently.
- The local `allowed_signers` list contains **only your own keys**. It is not a company-wide trust policy.
- The script sets `user.useConfigOnly=true`; commits outside the configured paths without an explicit identity fail — deliberately.
- The global signing mandate (`commit.gpgsign=true`, `tag.gpgsign=true`) can affect existing repositories and tools. With incompatible company requirements, **coordinate beforehand**.
- Check your backups: they may contain email addresses and earlier configuration material; store them appropriately.

## Key loss / laptop change

Revoke/remove old auth and signing keys at the provider if they were compromised. Generate new key pairs, re-register the public keys, and update the local signing configuration. Already-signed commits may verify differently platform-dependent after key removal. Do not copy private keys unencrypted to the NAS.

## Secure backup

Store private keys only in a trusted **encrypted** backup (if your policies allow it). Alternatively, use new keys per device. For work accounts, mind the security policy.

## If a YubiKey is desired

This version deliberately uses **plain Ed25519 file keys**, not hardware-based `ed25519-sk` keys. A YubiKey-FIDO2 variant would be a separate setup and must consider OpenSSH support, access/signing compatibility, and recovery.
