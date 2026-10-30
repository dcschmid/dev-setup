#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Configures only local files; never executes remote code, stores keys or signs in.
# An independent normal invocation should install the CLI as well. Read-only
# --check and --preflight must never download or mutate anything.
if [[ "${1:-}" != '--check' && "${1:-}" != '--preflight' ]]; then
  "$ROOT/setup-omp-cli.sh" --install
fi
python3 "$ROOT/scripts/configure_yolo_omp.py" "$@"
python3 "$ROOT/scripts/configure_omp_features.py" "$@"
if [[ "${1:-}" != '--check' && "${1:-}" != '--preflight' ]]; then
  echo 'INFO  OMP CLI installed/verified by setup-omp-cli.sh.'
  echo 'INFO  First login: omp-working (or yolo-working), then /login yolo-auto; repeat in omp-private.'
  echo 'INFO  Provider model: yolo-auto/qwen3.8-27b (use /model if your plan differs).'
fi
