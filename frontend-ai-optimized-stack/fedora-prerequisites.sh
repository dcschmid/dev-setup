#!/usr/bin/env bash
set -euo pipefail
if ! command -v dnf >/dev/null 2>&1; then echo 'ERROR: This helper is only for Fedora.' >&2; exit 1; fi
cat <<'DOC'
Fedora Workstation 44 prerequisites (runs only after your confirmation):
  sudo dnf install git python3 python3-pip python3-pyyaml uv nodejs npm zsh kitty flatpak pipx
No NVIDIA driver, external repositories, OMP, YOLO-Auto, or credentials are touched.
DOC
if [[ "${1:-}" == --apply ]]; then
  sudo dnf install git python3 python3-pip python3-pyyaml uv nodejs npm zsh kitty flatpak pipx
elif [[ "${1:-}" != '' ]]; then echo 'Usage: ./fedora-prerequisites.sh [--apply]' >&2; exit 2; fi
