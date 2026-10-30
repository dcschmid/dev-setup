# Zsh Developer Extras — v1.6.0

## Enabled Oh My Zsh plugins

```text
git
gitfast
aliases
nvm
fzf
zoxide
zsh-interactive-cd
direnv
sudo
extract
colored-man-pages
dirhistory
history-substring-search
zsh-autosuggestions
zsh-syntax-highlighting
```

`zsh-syntax-highlighting` is sourced manually at the very end of the managed Zsh config so it remains compatible with later widgets such as Atuin.


Plugins that require an external binary are enabled only when that binary exists.


## NVM automatic project versions

When a project contains `.nvmrc`, entering that project automatically selects the matching **already-installed** Node version. The safe hook never downloads Node automatically.

```bash
echo "22.12.0" > .nvmrc
cd ..
cd my-project
node -v
```

If the requested version is not installed:

```bash
nvm install
```

The pack does not download Node automatically during `cd`.

When leaving an `.nvmrc` project, NVM returns to its default version.

Helper:

```bash
./ensure-nvmrc.sh /path/to/project
```


## fzf

```text
Ctrl+T   fuzzy file picker
Alt+C    fuzzy directory picker
```

`Ctrl+R` is reserved for Atuin.

## zoxide

```bash
z unified
z frontend
```

## Interactive cd

```text
cd <Tab>
```

## direnv

Review `.envrc`, then:

```bash
direnv allow
```

## Atuin

```text
Ctrl+R   search history
Up       normal shell history
```

Inside a Git repo, Atuin starts in workspace mode so commands from any directory in that repository can be found together.

AI and automatic sync are disabled.
