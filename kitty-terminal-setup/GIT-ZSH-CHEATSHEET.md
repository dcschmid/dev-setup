# Git + Oh My Zsh Cheat Sheet

The pack enables both:

```text
git
gitfast
```

`git` provides the aliases/functions; `gitfast` provides a faster upstream-style Git completion.

## Daily commands

| Alias | Command |
|---|---|
| `g` | `git` |
| `gst` | `git status` |
| `gss` | `git status --short` |
| `gsb` | `git status --short -b` |
| `ga` | `git add` |
| `gaa` | `git add --all` |
| `gd` | `git diff` |
| `gds` | `git diff --staged` |
| `gcmsg` | `git commit --message` |
| `gl` | `git pull` |
| `gp` | `git push` |
| `gf` | `git fetch` |

## Branches

| Alias | Command |
|---|---|
| `gb` | `git branch` |
| `gco` | `git checkout` |
| `gsw` | `git switch` |
| `gswc` | `git switch -c` |
| `gswm` | switch to main branch |
| `grt` | jump to repository root |

## History

| Alias | Command |
|---|---|
| `glo` | compact decorated log |
| `glog` | compact Git graph |
| `gloga` | compact Git graph including all refs |
| `glg` | log with stats |

## Stash

| Alias | Command |
|---|---|
| `gsta` | stash push |
| `gstp` | stash pop |
| `gstl` | stash list |
| `gsts` | stash show --patch |

## Restore

| Alias | Command |
|---|---|
| `grs` | `git restore` |
| `grst` | `git restore --staged` |

Tip: run `alias | grep git` or use the Oh My Zsh `aliases` plugin when you want to explore more shortcuts.


## delta

When installed, all ordinary Git diff output uses delta automatically:

```text
gd
gds
git show
git log -p
```

Use `n` / `N` inside delta to jump between diff sections.

## Worktrees

```text
gwl                  list
gwnew feature/foo    create + cd
gwcd                 fuzzy choose + cd
gwrm                 safe remove
gwprune               prune stale metadata
```

The worktree removal helper never force-removes and never deletes the branch.
