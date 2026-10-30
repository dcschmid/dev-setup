#!/usr/bin/env bash
# Offline tests: neither remote download nor real user configuration is touched.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
mkdir -p "$T/home" "$T/mockbin"
export HOME="$T/home" PATH="$T/mockbin:/usr/bin:/bin"
cat > "$T/installer.sh" <<'INSTALLER'
#!/bin/sh
set -eu
[ "$1" = '--binary' ] || { echo 'Expected binary install' >&2; exit 3; }
mkdir -p "$PI_INSTALL_DIR"
cat > "$PI_INSTALL_DIR/omp" <<'APP'
#!/bin/sh
if [ "$1" = '--version' ]; then echo 'omp mock-18'; exit 0; fi
exit 0
APP
chmod +x "$PI_INSTALL_DIR/omp"
echo invocation >> "$HOME/install-count"
INSTALLER
cat > "$T/mockbin/curl" <<'MOCK_CURL'
#!/usr/bin/env bash
set -euo pipefail
args=("$@")
out=''
for ((i=0;i<${#args[@]};i++)); do
  [[ "${args[i]}" == '-o' ]] && out="${args[i+1]}"
done
[[ -n "$out" ]] && [[ " $* " == *' https://omp.sh/install '* ]]
cp -- "$MOCK_INSTALLER_SOURCE" "$out"
MOCK_CURL
chmod +x "$T/mockbin/curl"
export MOCK_INSTALLER_SOURCE="$T/installer.sh"
# Read-only checks must not install.
if "$ROOT/setup-omp-cli.sh" --check > /dev/null 2>&1; then echo 'unexpected pre-install pass'; exit 1; fi
[[ ! -e "$HOME/install-count" ]]
"$ROOT/setup-omp-cli.sh" --install > /dev/null
[[ "$($HOME/.local/bin/omp --version)" == 'omp mock-18' ]]
[[ "$(wc -l < "$HOME/install-count")" -eq 1 ]]
# On the next run, existing binary should be reused without downloading or rerunning.
"$ROOT/setup-omp-cli.sh" --install > /dev/null
[[ "$(wc -l < "$HOME/install-count")" -eq 1 ]]
"$ROOT/setup-omp-cli.sh" --check > /dev/null
[[ "$(grep -Fc '# BEGIN FRONTEND-AI-STACK LOCAL BIN PATH' "$HOME/.zshrc")" -eq 1 ]]
# Failure before executable creation should not damage user files.
export HOME="$T/fail-home"; mkdir -p "$HOME"
printf 'KEEP\n' > "$HOME/sentinel"
cat > "$T/fail-installer.sh" <<'FAIL'
#!/bin/sh
exit 9
FAIL
export MOCK_INSTALLER_SOURCE="$T/fail-installer.sh"
if "$ROOT/setup-omp-cli.sh" --install > /dev/null 2>&1; then echo 'expected failure not observed'; exit 1; fi
[[ "$(cat "$HOME/sentinel")" == 'KEEP' ]]
[[ ! -e "$HOME/.local/bin/omp" ]]
# Refuse to overwrite broken existing CLI.
printf '#!/bin/sh\nexit 1\n' > "$HOME/.local/bin/omp"
chmod +x "$HOME/.local/bin/omp"
if "$ROOT/setup-omp-cli.sh" --install > /dev/null 2>&1; then echo 'broken omp not rejected'; exit 1; fi
[[ -x "$HOME/.local/bin/omp" ]]
echo 'PASS OMP auto-install: install, verify, skip, PATH, fail-safe, no overwrite'
