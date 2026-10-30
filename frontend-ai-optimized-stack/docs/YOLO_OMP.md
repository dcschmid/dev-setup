## OMP CLI automatic installation (v3.13.3)

Running `./install-profiles.sh` now installs Oh My Pi automatically **if missing**,
using the official upstream installer (`https://omp.sh/install`) with `--binary`.
The upstream binary installer verifies a SHA-256 digest obtained from the build
service. No extra Bun installation is required. A previously working OMP CLI is
never replaced. This downloads and runs third-party code; review the upstream
script before running the installer on a sensitive workstation.

```bash
./setup-omp-cli.sh --check
./setup-omp-cli.sh --install  # manually retry if missing or first install failed
./setup-yolo-omp.sh --check
```

An automatic install failure stops the main installer before it changes the
managed profile configs. OMP itself is placed in `~/.local/bin/omp`, and the
installer adds a guarded `~/.local/bin` PATH entry in `~/.zshrc` only if needed.
No Claude/Codex credentials or existing `~/.omp` profiles are erased. The OMP
login to YOLO-Auto is still interactive and separate for Working and Private.

# Native YOLO-Auto (OMP) profile integration

Official provider docs: https://yolo-auto.com/docs#agent-oh-my-pi
OMP profiles & config: https://github.com/can1357/oh-my-pi/blob/main/docs/config-usage.md
OMP MCP behavior: https://github.com/can1357/oh-my-pi/blob/main/docs/mcp-config.md

## Working/private protection

OMP uses native named profiles (`omp --profile working`, `omp --profile private`).
The stack installs a `config.yml` per profile with `disabledProviders` covering
`claude`, `codex`, `gemini`, `opencode` to prevent importing unrelated tool-user
skills/MCPs. Working `mcp.json` additionally has `disabledServers: ["blender"]`
so an inherited same-name Blender server from a project cannot be selected.
Private's `mcp.json` registers Blender MCP v2.2.0 plus TinySuite.

These settings are only the **agent discovery surface**. They do not create
separate OS users or physically isolate all project files. OMP will still read
native project `.omp` capabilities. Inspect repository `.omp` files before using
untrusted projects; respect employer policy for cloud requests.

## Existing OMP user config

`setup-yolo-omp.sh` refuses to modify an existing profile `config.yml` if the
external discovery block cannot be verified. Back up and add the policy manually
inside the existing YAML (without duplicate keys):

```yaml
disabledProviders:
  - claude
  - codex
  - gemini
  - opencode
modelRoles:
  default: yolo-auto/qwen3.8-27b
```

If there is already a `modelRoles` setting, merge the `default` inside it.
Rerun `./setup-yolo-omp.sh` to validate MCPs and manage skill links.

If `mcp.json` already has same-name MCP servers with different settings, the
installer refuses to overwrite them. Review them and migrate yourself.
The OMP profile files are backed up without copying auth/token stores.

## Optional extension

Yolo's official planning extension: https://github.com/yolo-auto-org/yolo-auto-omp
The official generic install instructions target `~/.omp/agent/extensions/`.
That is the default profile, **not** our Working/Private setup. Install a
reviewed copy separately into `~/.omp/profiles/working/agent/extensions/` and
`~/.omp/profiles/private/agent/extensions/` if you want the behavior in both.
Do not mix these directories or blindly install a giant plugin pack.

## Model/credentials

After `omp-working` (alias: `yolo-working`), type `/login yolo-auto`. Repeat with `omp-private` (alias: `yolo-private`);
those profiles keep their own OMP state. You can use the same authorized Yolo key
if company policy allows it. The official provider lists supported models with
`omp models yolo-auto`. The default is a suggestion, not proof of plan access.
The Stack installer does not read or back up token stores.

## OMP-only workflow skill (v3.13.1)

The stack installs `mm-omp-code-workflow` into both named profiles in addition to the shared/profile-specific package skills. It is deliberately absent from Claude/Codex skill stores. OMP provides built-in LSP, task delegation, worktrees and `learn`/`manage_skill`; see `docs/UPDATES_OMP_SKILLS_2026-10-29.md` for recommended use and extension review.

## v3.13.2 advanced workflows

Refer to [OMP_ADVANCED_FEATURES.md](OMP_ADVANCED_FEATURES.md). The external
Todo Discipline extension is staged/reviewed/activated by SHA256 with
`setup-yolo-todo.sh`; OMP LSP, subagent isolation, controlled skill management
and the browser/computer toggles are provided by `setup-omp-features.sh`.
Native OMP memory stays off in favor of TinyContext.
