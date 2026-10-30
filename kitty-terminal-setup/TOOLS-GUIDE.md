# Kitty Workspace Pack — Tools Guide v1.6.0

# 1. Kitty — terminal + persistent state

Kitty is the terminal emulator. In v1.6.0 there is no project-session switcher. One live state is continuously maintained and restored.

First run gives two tabs:

```text
Unified Frontend 1
Unified Frontend 2
```

Create everything else yourself. New tabs/windows become part of the next automatic save.

# 2. Persistent state

Kitty saves the current terminal structure to:

```text
~/.config/kitty/last-state.kitty-session
```

A global watcher requests a guarded save roughly every ten seconds and on state changes. It validates a temporary session before atomic replacement and keeps rotating backups. `startup_session` loads the saved state on the next start. Run `./state-status.py` for the current status.

Foreground commands are not replayed; only the safe terminal/session structure is restored.

Manual save:

```text
Ctrl+Space, S
```

Reset to the two-tab baseline:

```bash
./reset-kitty-state.sh
```

# 3. Tabs and extra windows

```text
Ctrl+Shift+T       new tab, same cwd
Ctrl+Shift+W       close tab
Ctrl+Space, N      rename tab
Ctrl+Space, W      new OS window
```

All of these are ordinary Kitty tabs/windows, not named project sessions.

# 4. Oh My Zsh — shell framework

Zsh is the shell running inside Kitty.

Oh My Zsh adds:

```text
plugins
Git aliases
completion
history helpers
theme support
NVM integration
fzf integration
zoxide integration
```

It does **not** replace Kitty.

Think of it this way:

```text
Kitty = terminal window
Zsh   = command shell inside the window
OMZ   = helpers/plugins for Zsh
```

The system login shell can remain Bash while Kitty uses Zsh.

---

# 5. Git plugin — daily Git shortcuts

The Oh My Zsh Git plugin gives short aliases for common Git commands.

Useful examples:

```text
gst      git status
gss      git status --short

ga       git add
gaa      git add --all

gd       git diff
gds      git diff --staged

gcmsg    git commit --message

gl       git pull
gp       git push

gsw      git switch
gswc     git switch -c

grt      jump to repository root
```

You can always use normal Git commands as well.

The aliases are only shortcuts.

Example:

```bash
gst
```

is equivalent to:

```bash
git status
```

---

# 6. gitfast — faster Git completion

`gitfast` improves Git command completion.

Example:

```bash
git switch fe<TAB>
```

or:

```bash
git checkout ma<TAB>
```

Completion can suggest matching branches.

It does not replace Git and does not change repository behavior.

It only improves interactive completion.

---

# 7. Git Worktrees — parallel branches without stashing

This is one of the most useful developer features in the pack.

Normally a Git repository has one working directory:

```text
unified-frontend/
```

and only one branch can be checked out there at a time.

A Git worktree allows the same repository to have **multiple working directories at the same time**.

Example:

```text
unified-frontend/
    main branch

unified-frontend-worktrees/
    feature-header/
        feature/header branch

    hotfix-player/
        hotfix/player branch
```

All of these share the same Git repository data, but each has its own:

```text
files
HEAD
index
checked-out branch
working changes
```

## Why this is useful

Imagine OMP is doing a larger refactor in:

```text
feature/refactor-player
```

but you suddenly need to fix a small bug on `main`.

Without worktrees you might need to:

```text
stash changes
switch branch
fix bug
switch back
restore stash
```

With worktrees:

```bash
gwnew hotfix/player main
```

You get a second clean working directory immediately.

The first one remains untouched.

## Create a worktree

```bash
gwnew feature/new-header
```

This creates something like:

```text
~/dev/gitlab/unified-frontend-worktrees/feature-new-header/
```

and automatically enters it.

Specify a starting branch:

```bash
gwnew hotfix/player main
```

Meaning:

```text
create branch hotfix/player
starting from main
```

## List worktrees

```bash
gwl
```

Equivalent conceptually to:

```bash
git worktree list
```

## Jump to another worktree

```bash
gwcd
```

This opens an fzf selection.

Choose a worktree and the shell changes into it.

## Remove a worktree

```bash
gwrm
```

The helper intentionally refuses dangerous cases.

It will not:

```text
remove the main worktree
remove your current worktree
remove a dirty worktree
use --force
delete the Git branch
```

This is important:

> Removing a worktree does not automatically mean deleting its branch.

For example, after:

```bash
gwrm
```

the branch may still exist:

```bash
git branch
```

If you want to delete the branch later, do that explicitly after checking it.

## Clean stale metadata

```bash
gwprune
```

This runs Git's worktree metadata cleanup.

Use it if a worktree folder was manually deleted or Git reports a stale worktree.

---

# 8. delta — better Git diffs

`delta` makes Git diffs easier to read.

Without delta:

```text
plain Git patch output
```

With delta:

```text
syntax highlighting
line numbers
better headers
clearer added/removed lines
navigation
```

It works automatically for normal Git commands.

Examples:

```bash
gd
gds
git show
git log -p
```

Useful navigation inside delta:

```text
n    next diff section
N    previous diff section
```

Delta does not modify your files.

It is only a pager/display layer.

---

# 9. lazygit — optional visual Git interface

Lazygit is optional.

Start it with:

```bash
lg
```

It gives a terminal UI for:

```text
status
files
staging
commits
branches
logs
stash
rebases
```

Use it when you want a visual overview without leaving the terminal.

You do not need it for normal Git work.

All Git aliases and commands still work without lazygit.

---

# 10. eza — nicer directory listings

`eza` is a modern replacement for the visual output of `ls`.

The pack keeps your familiar commands:

```bash
ls
ll
la
l
```

but uses eza when installed.

Useful commands:

```bash
ll
```

Long listing including Git information.

```bash
tree
```

Directory tree with two levels.

```bash
tree3
```

Directory tree with three levels.

Example:

```text
apps
├── web
├── admin
└── shared

packages
├── ui
└── config
```

This is especially useful in monorepos.

---

# 11. bat — better file viewing

`bat` is similar to `cat`, but adds:

```text
syntax highlighting
line numbers
paging
Git change markers
```

The pack deliberately leaves the normal `cat` command untouched.

Use:

```bash
b package.json
```

or:

```bash
b src/components/Header.tsx
```

For forced pager mode:

```bash
bp very-large-file.ts
```

Use `cat` when you want plain raw output.

Use `b` when you want to read code comfortably.

---

# 12. fzf — fuzzy finder

fzf lets you search interactively by typing only parts of a name.

Example:

```text
mel min
```

might match:

```text
~/dev/gitlab/unified-frontend
```

Useful shortcuts:

```text
Ctrl+T    fuzzy file selection
Alt+C     fuzzy directory selection
```

fzf is also used by:

```text
gwcd
```

for Git worktree selection.

You do not have to type exact filenames or paths.

---

# 13. zoxide — smarter `cd`

zoxide remembers directories you use frequently.

At first you use normal commands:

```bash
cd ~/dev/gitlab/unified-frontend
```

After zoxide has learned the path, this can become:

```bash
z unified
```

Likewise:

```bash
z unified
```

may jump to:

```text
~/dev/gitlab/unified-frontend
```

zoxide ranks locations based on your real usage.

It becomes more useful over time.

---

# 14. Atuin — better shell history

Atuin replaces the normal `Ctrl+R` search with a much more powerful history database.

Use:

```text
Ctrl+R
```

Atuin stores metadata such as:

```text
command
working directory
exit code
time
duration
session
```

This is useful when you remember:

> "I ran that pnpm command in Unified Frontend two weeks ago."

Atuin can find it much more easily than a simple text history.

## Local-first setup

In this pack:

```text
cloud sync       OFF
automatic sync   OFF
AI               OFF
```

Atuin remains a local history tool.

## Workspace mode

Inside a Git repository, history can be grouped by repository/workspace.

So commands executed in different directories inside:

```text
~/dev/gitlab/unified-frontend
```

can still be searched together.

The normal Up/Down history remains available.

---

# 15. NVM — project-specific Node versions

NVM manages multiple Node.js versions.

A project can declare its Node version in:

```text
.nvmrc
```

Example:

```text
22.12.0
```

When you enter that project, the pack automatically activates the matching installed Node version.

Example:

```bash
cd ~/dev/github/project-a
node -v
```

may produce:

```text
v22.12.0
```

Then:

```bash
cd ~/dev/github/project-b
```

may automatically switch to Node 20.

## Missing version

The pack never downloads Node just because you entered a directory.

Instead it tells you:

```text
Node version from .nvmrc is not installed
Run: nvm install
```

Then:

```bash
nvm install
```

installs the project's requested version.

## Helper

```bash
./ensure-nvmrc.sh /path/to/project
```

checks or creates `.nvmrc`.

For monorepos, keep the main `.nvmrc` in the repository root unless you deliberately need different Node versions for subprojects.

---

# 16. direnv — directory-specific environment variables

direnv loads environment variables when you enter a directory.

A project can contain:

```text
.envrc
```

Example:

```bash
export API_BASE_URL=http://localhost:3000
export FEATURE_TEST=true
```

The first time:

```bash
direnv allow
```

After that:

```bash
cd project
```

loads the environment.

Leaving the project unloads it again.

## Important

Always review `.envrc` before running:

```bash
direnv allow
```

because `.envrc` is executable shell code.

---

# 17. Kitty choose-files — file picker

Use:

```text
Ctrl+Space, E
```

to search for a file.

The selected path is inserted into your current command line.

Example:

```bash
b <Ctrl+Space,E>
```

Choose:

```text
src/components/Header.tsx
```

Result:

```bash
b src/components/Header.tsx
```

Directory picker:

```text
Ctrl+Space, D
```

Favorite locations:

```text
Alt+D    ~/dev
Alt+U    Unified Frontend
```

---

# 18. Kitty diff

Alias:

```bash
kd old.ts new.ts
```

This uses Kitty's built-in diff viewer.

Good for comparing:

```text
config files
generated output
two versions of a document
two source files
```

For Git diffs, use normal Git + delta.

For arbitrary files, `kd` is very handy.

---

# 19. Kitty image viewer

Alias:

```bash
img cover.png
```

This renders supported images directly in Kitty.

Useful for:

```text
album covers
screenshots
generated assets
article images
UI references
```

No separate image window is needed for a quick check.

---

# 20. Kitty Quick Access Terminal

This is the small drop-down terminal.

Inside Kitty:

```text
Ctrl+Space, Q
```

For a global desktop shortcut, bind:

```text
~/.local/bin/kitty-quick-access
```

Recommended:

```text
Super + `
```

Good for fast commands such as:

```bash
systemctl --user status ...
git status
ps aux
journalctl ...
```

without opening a full project workspace.

---

# 21. Shell Doctor

After upgrades or when something looks wrong:

```bash
./shell-doctor.sh
```

The doctor checks the important pieces of the environment.

Examples:

```text
Kitty config
Zsh
Oh My Zsh
NVM
fzf
zoxide
Atuin
Git
delta
eza
bat
pnpm
Node
OMP
Codex
Claude
```

It is a diagnostic tool only.

It does not intentionally repair or rewrite your projects.

---

# 22. Recommended everyday workflow

## Start coding

Open Kitty normally. It restores the state you were using last time. On a first/reset start you get:

```text
1  Unified Frontend 1
2  Unified Frontend 2
```

Use `Alt+1..9` to jump directly between visible tabs. Add your own tabs with `Ctrl+Shift+T`, rename them with `Ctrl+Space, N`, and let autosave remember the result.

## Need another branch in parallel?

```bash
gwnew feature/my-change
```

## Need an old command?

```text
Ctrl+R
```

## Need to jump to a directory?

```bash
z unified
```

or:

```text
Alt+C
```

## Need to inspect a file?

```bash
b file.ts
```

## Need Git status?

```bash
gst
```

## Need a readable diff?

```bash
gd
```

## Need a visual Git UI?

```bash
lg
```

if lazygit is installed.

## Long build?

```bash
pnpm build
```

Switch to another Kitty session.

Kitty notifies you when the long command finishes while the window is not visible.

---

# 23. Which tool should I use?

| Goal | Tool |
|---|---|
| Organize project terminals | Kitty Sessions |
| Temporary terminal workspace | Kitty Scratch Workspace |
| Shell plugins/completion | Oh My Zsh |
| Git shortcuts | OMZ Git plugin |
| Git completion | gitfast |
| Parallel branches | Git Worktrees |
| Pretty Git diffs | delta |
| Visual Git UI | lazygit |
| Better `ls` | eza |
| Better file viewer | bat |
| Fuzzy file/directory search | fzf |
| Jump to remembered directories | zoxide |
| Search old commands | Atuin |
| Per-project Node version | NVM + `.nvmrc` |
| Per-directory environment | direnv |
| Pick files from Kitty | choose-files |
| Compare arbitrary files | `kd` / Kitty diff |
| Preview images | `img` / Kitty icat |
| Fast global shell | Kitty Quick Access |
| Diagnose the setup | `shell-doctor.sh` |

---

# 24. The main idea

The tools deliberately have separate jobs:

```text
Kitty         terminal + workspaces
Zsh / OMZ     shell experience
Git           version control
Worktrees     parallel Git working directories
delta         Git diff presentation
lazygit       optional Git UI
fzf           fuzzy selection
zoxide        directory jumping
Atuin         shell history
NVM           Node version management
direnv        project environment variables
eza / bat     nicer CLI output
OMP           coding agent / workflow
```

Keeping those responsibilities separate is what makes the setup powerful without becoming another all-in-one terminal platform.
