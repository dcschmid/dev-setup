# Node / NVM / pnpm on Fedora (Framework 16)

The Oh-My-Zsh plugin `nvm` provides **no Node installation**.
Our Zsh profile can only activate `.nvmrc` automatically if
`~/.nvm/nvm.sh` exists and the Node version is already installed.

## Diagnostics (no changes)

```bash
./setup-node.sh --check
```

## Install NVM on request

```bash
./setup-node.sh --install-nvm
```

Explicitly installs upstream nvm v0.40.8 without foreign additions into
`.zshrc`. Then open a **new Kitty tab**.

## Install the project version

```bash
./setup-node.sh --install-project
```

If `~/dev/gitlab/unified-frontend/.nvmrc` exists, the script asks
before `nvm install`. Without a `.nvmrc`, **no version is guessed** deliberately.

## pnpm and Corepack

First use the `packageManager` version defined in the repo.
Corepack was bundled with Node 14.19 up to Node 25; with newer
versions, `npm install -g corepack` may be required.
Before `corepack enable pnpm`, check whether a separate `pnpm`
installation already exists: global installations and Corepack shims
can otherwise conflict. Even with an NVM version switch,
separate Corepack shims may be necessary.

## Missing optional tools

`uv`, `cargo`, `conda`, `codex`, `claude`, and `omp` are described by the doctor
as **optional**; `omp` stands for
Oh My Pi in this context, not for the Zsh prompt. Nothing is installed without need.
