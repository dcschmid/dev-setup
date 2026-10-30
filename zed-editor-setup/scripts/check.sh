#!/usr/bin/env bash
set -uo pipefail
printf '%s\n' '=== Zed Framework Devkit · Diagnostics ==='
if [[ -f /etc/fedora-release ]]; then head -1 /etc/fedora-release; else echo 'Non-Fedora OS'; fi
printf 'Desktop: %s / session: %s\n' "${XDG_CURRENT_DESKTOP:-unknown}" "${XDG_SESSION_TYPE:-unknown}"
for cmd in zed zsh node npm pnpm yarn bun git python3 java vulkaninfo; do
  if command -v "$cmd" >/dev/null 2>&1; then
    printf '[OK] %-12s %s\n' "$cmd" "$(command -v "$cmd")"
  else
    printf '[--] %-12s not on PATH\n' "$cmd"
  fi
done
if command -v zsh >/dev/null 2>&1; then
  printf '\nExisting launchers in interactive zsh:\n'
  for cmd in claude codex yolo-working yolo-private; do
    if zsh -ic "whence -w '$cmd'" </dev/null 2>/dev/null | grep -q .; then
      printf '[OK] %s\n' "$cmd"
    else
      printf '[--] %s (check existing agent stack / zshrc)\n' "$cmd"
    fi
  done
fi
printf '\nZed extensions (if installed):\n'
for name in catppuccin catppuccin-icons astro defold lua; do
  if [[ -d "${XDG_DATA_HOME:-$HOME/.local/share}/zed/extensions/installed/$name" ]]; then
    echo "[OK] $name"
  else
    echo "[--] $name (will be fetched by Zed on startup)"
  fi
done
printf '\nConfig files:\n'
for path in "${XDG_CONFIG_HOME:-$HOME/.config}/zed/settings.json" "${XDG_CONFIG_HOME:-$HOME/.config}/zed/tasks.json"; do
  [[ -f "$path" ]] && echo "[OK] $path" || echo "[--] $path"
done
if command -v fc-match >/dev/null 2>&1; then
  echo "Font fallback: $(fc-match -f '%{family}\n' 'JetBrains Mono' | head -1)"
fi
if command -v java >/dev/null 2>&1; then
  echo "Java: $(java -version 2>&1 | head -1)"
fi
if [[ -n ${BOB_JAR:-} ]]; then echo "BOB_JAR: $BOB_JAR"; fi
printf '\nOptional Delta integration:\n'
if [[ -d "$HOME/.local/delta.app" ]]; then
  echo '[OK] Delta desktop app installed'
else
  echo '[--] Delta not installed (optional; see docs/DELTA.md)'
fi
if command -v delta >/dev/null 2>&1; then
  echo "Delta CLI PATH: $(command -v delta) (verify this is Delta by Zed, not git-delta)"
fi
echo 'Zed requires Vulkan 1.3 and working desktop portals: see docs/TROUBLESHOOTING.md'
